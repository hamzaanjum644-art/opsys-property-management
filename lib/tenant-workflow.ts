import { Prisma, TenantStatus, UnitStatus } from "@prisma/client";
import { prisma } from "./prisma";
import { dispatchWebhook } from "./webhooks";

/**
 * Section 10 - Tenant Status & Connected Workflow.
 *
 * This is the ONLY place in the codebase that writes Tenant.status or
 * Unit.status. Nothing else may touch those two fields. That single rule is
 * what makes the connected-system requirement (section 2) provable rather
 * than accidental.
 *
 * Every transition runs inside one transaction: tenant, unit and the audit
 * event either all commit or none do. There is no state in which a tenant is
 * CLOSED while its unit still reads OCCUPIED.
 */

export type TransitionAction =
  | "COMPLETE_MOVE_IN"
  | "MARK_MOVE_OUT"
  | "COMPLETE_MOVE_OUT";

const RULES: Record<
  TransitionAction,
  { from: TenantStatus; to: TenantStatus; unit: UnitStatus | null; label: string }
> = {
  // New tenant created -> PENDING is handled at creation, not here.
  COMPLETE_MOVE_IN: {
    from: TenantStatus.PENDING,
    to: TenantStatus.ACTIVE,
    unit: UnitStatus.OCCUPIED,
    label: "Complete move-in",
  },
  MARK_MOVE_OUT: {
    from: TenantStatus.ACTIVE,
    to: TenantStatus.MOVE_OUT,
    unit: null, // Decision D2: unit stays OCCUPIED until move-out completes
    label: "Mark for move-out",
  },
  COMPLETE_MOVE_OUT: {
    from: TenantStatus.MOVE_OUT,
    to: TenantStatus.CLOSED,
    unit: UnitStatus.VACANT,
    label: "Complete move-out",
  },
};

export class WorkflowError extends Error {}

export async function transitionTenant(
  tenantId: string,
  action: TransitionAction,
  userId: string,
  note?: string
) {
  const rule = RULES[action];
  if (!rule) throw new WorkflowError("Unknown action.");

  const result = await prisma.$transaction(async (tx) => {
    const tenant = await tx.tenant.findUnique({
      where: { id: tenantId },
      include: { unit: true, property: true },
    });

    if (!tenant) throw new WorkflowError("Tenant not found.");

    // Guard: forward-only lifecycle (Decision D3).
    if (tenant.status !== rule.from) {
      throw new WorkflowError(
        `Cannot ${rule.label.toLowerCase()} - this tenant is ${labelFor(tenant.status)}, not ${labelFor(rule.from)}.`
      );
    }

    // Guard: don't occupy a unit that another live tenant already holds
    // (Decision D1). The DB unique constraint is the real backstop; this
    // produces a readable message before we get there.
    if (action === "COMPLETE_MOVE_IN") {
      const holder = await tx.unit.findUnique({ where: { id: tenant.unitId } });
      if (holder?.currentTenantId && holder.currentTenantId !== tenant.id) {
        throw new WorkflowError(
          "Cannot complete move-in - this unit already has a current tenant."
        );
      }
    }

    const now = new Date();

    const updatedTenant = await tx.tenant.update({
      where: { id: tenantId },
      data: {
        status: rule.to,
        ...(action === "COMPLETE_MOVE_IN" ? { moveInDate: now } : {}),
        ...(action === "COMPLETE_MOVE_OUT" ? { moveOutDate: now } : {}),
      },
      include: { unit: true, property: true },
    });

    if (rule.unit) {
      await tx.unit.update({
        where: { id: tenant.unitId },
        data: {
          status: rule.unit,
          currentTenantId:
            action === "COMPLETE_MOVE_IN" ? tenant.id : null, // Decision D4
        },
      });
    }

    // Section 13 - status changes must be traceable.
    await tx.tenancyEvent.create({
      data: {
        tenantId: tenant.id,
        unitId: tenant.unitId,
        fromStatus: rule.from,
        toStatus: rule.to,
        changedBy: userId,
        note,
      },
    });

    return updatedTenant;
  });

  // Section 12 - automation fires AFTER commit, outside the transaction.
  // A Make.com outage must never roll back or block a real business action.
  if (action === "MARK_MOVE_OUT" || action === "COMPLETE_MOVE_OUT") {
    void dispatchWebhook(
      action === "MARK_MOVE_OUT" ? "tenant.move_out_marked" : "tenant.move_out_completed",
      result
    );
  }

  return result;
}

function labelFor(s: TenantStatus) {
  return {
    PENDING: "pending",
    ACTIVE: "active",
    MOVE_OUT: "marked for move-out",
    CLOSED: "closed",
  }[s];
}

/** Maps Prisma referential-integrity errors to plain English (section 19). */
export function friendlyDbError(e: unknown): string | null {
  if (e instanceof Prisma.PrismaClientKnownRequestError) {
    if (e.code === "P2003" || e.code === "P2014")
      return "Cannot delete this record - other records still reference it.";
    if (e.code === "P2002")
      return "That value is already in use. Try a different one.";
  }
  return null;
}