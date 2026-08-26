import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

/**
 * Section 12, Automation 2 - called by Make.com, not by the browser.
 *
 * Two responsibilities in one endpoint, matching the two remaining pieces of
 * Automation 2 that the app itself is best placed to do:
 *
 *   1. "Log the move-out event" - writes a MoveOutLog row.
 *   2. "Where technically practical, update/confirm the unit as vacant" -
 *      returns the unit's CURRENT status. This endpoint never writes unit
 *      status; that stays the sole responsibility of transitionTenant()
 *      (section 10). Make only reads the confirmation back to put in its
 *      email - it does not decide or set the state.
 *
 * Authenticated with a shared secret rather than a user session, because the
 * caller is Make, not a signed-in person.
 */

export async function POST(req: NextRequest) {
  const key = req.headers.get("x-opsys-key");
  if (key !== process.env.OPSYS_API_KEY) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json().catch(() => null);
  if (!body) {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { event, tenantRef, tenantName, propertyName, unitNumber, unitId } = body as {
    event?: string;
    tenantRef?: string;
    tenantName?: string;
    propertyName?: string;
    unitNumber?: string;
    unitId?: string;
  };

  if (!event || !tenantRef || !tenantName || !propertyName || !unitNumber) {
    return NextResponse.json(
      { error: "event, tenantRef, tenantName, propertyName and unitNumber are required" },
      { status: 400 }
    );
  }

  const log = await prisma.moveOutLog.create({
    data: { event, tenantRef, tenantName, propertyName, unitNumber },
  });

  // Confirmation, not a write - reports whatever transitionTenant() already
  // set. See section 10 in lib/tenant-workflow.ts for the actual state change.
  let unitStatus: string | null = null;
  if (unitId) {
    const unit = await prisma.unit.findUnique({
      where: { id: unitId },
      select: { status: true },
    });
    unitStatus = unit?.status ?? null;
  }

  return NextResponse.json({ logged: true, logId: log.id, unitStatus });
}