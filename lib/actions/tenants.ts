"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireAdmin, requireUser } from "@/lib/auth";
import {
  transitionTenant,
  WorkflowError,
  friendlyDbError,
  type TransitionAction,
} from "@/lib/tenant-workflow";
import { dispatchWebhook } from "@/lib/webhooks";

// Section 8 - Tenant Management.
// Section 10 - status transitions route through transitionTenant() only.

const TenantSchema = z.object({
  fullName: z.string().trim().min(1, "Full name is required."),
  phone: z.string().trim().min(1, "Phone number is required."),
  unitId: z.string().min(1, "Select a unit."),
  email: z.string().trim().email("Enter a valid email address.").optional().or(z.literal("")),
  dateOfBirth: z.string().optional().or(z.literal("")),
  gender: z.enum(["MALE", "FEMALE", "OTHER", "PREFER_NOT_TO_SAY"]).optional().or(z.literal("")),
});

export type ActionState = { error?: string } | undefined;

async function nextReference(prefix: string, seq: string) {
  const rows = await prisma.$queryRawUnsafe<{ next_reference: string }[]>(
    `SELECT next_reference('${prefix}', '${seq}')`
  );
  return rows[0].next_reference;
}

export async function createTenant(_prev: ActionState, formData: FormData): Promise<ActionState> {
  await requireAdmin();

  const parsed = TenantSchema.safeParse({
    fullName: formData.get("fullName"),
    phone: formData.get("phone"),
    unitId: formData.get("unitId"),
    email: formData.get("email"),
    dateOfBirth: formData.get("dateOfBirth"),
    gender: formData.get("gender"),
  });

  if (!parsed.success) return { error: parsed.error.issues[0].message };

  const { unitId, fullName, phone, email, dateOfBirth, gender } = parsed.data;

  // Property is derived from the unit rather than submitted separately -
  // section 19: don't duplicate data that can be referenced.
  const unit = await prisma.unit.findUnique({
    where: { id: unitId },
    select: { id: true, propertyId: true, currentTenantId: true, flatNumber: true },
  });

  if (!unit) return { error: "That unit no longer exists." };

  // Decision D1 - one live tenant per unit.
  if (unit.currentTenantId) {
    return { error: `${unit.flatNumber} already has a current tenant.` };
  }

  let tenantId: string;
  try {
    const created = await prisma.tenant.create({
      data: {
        reference: await nextReference("TEN", "tenant_ref_seq"),
        fullName,
        phone,
        email: email || null,
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
        gender: gender ? (gender as "MALE" | "FEMALE" | "OTHER" | "PREFER_NOT_TO_SAY") : null,
        propertyId: unit.propertyId,
        unitId: unit.id,
        // Section 10 step 1 - new tenant is always PENDING.
        status: "PENDING",
      },
      include: { property: true, unit: true },
    });

    tenantId = created.id;

    // Section 13 - the creation itself is a traceable event.
    await prisma.tenancyEvent.create({
      data: {
        tenantId: created.id,
        unitId: created.unitId,
        fromStatus: null,
        toStatus: "PENDING",
        changedBy: (await requireUser()).id,
        note: "Tenant created",
      },
    });

    // Section 12, Automation 1 - New Tenant Notification.
    void dispatchWebhook("tenant.created", created);
  } catch (e) {
    return { error: friendlyDbError(e) ?? "Could not create the tenant. Try again." };
  }

  revalidatePath("/tenants");
  revalidatePath("/dashboard");
  redirect(`/tenants/${tenantId}`);
}

export async function runTransition(
  tenantId: string,
  action: TransitionAction
): Promise<ActionState> {
  const user = await requireAdmin();

  try {
    await transitionTenant(tenantId, action, user.id);
  } catch (e) {
    if (e instanceof WorkflowError) return { error: e.message };
    return { error: friendlyDbError(e) ?? "Could not update the tenant status." };
  }

  revalidatePath(`/tenants/${tenantId}`);
  revalidatePath("/tenants");
  revalidatePath("/dashboard");
  revalidatePath("/properties");
  return undefined;
}