/**
 * Section 12 - Make.com automation.
 *
 * One payload shape serves all three events; Scenario 2 routes on `event`.
 * Fire-and-forget: failures are logged, never surfaced as a blocked action.
 */

export type OpsysEvent =
  | "tenant.created"
  | "tenant.move_out_marked"
  | "tenant.move_out_completed";

type TenantWithRelations = {
  reference: string;
  fullName: string;
  status: string;
  phone: string;
  email: string | null;
  property: { reference: string; name: string; address: string };
  unit: { id: string; reference: string; flatNumber: string };
};

const TARGET: Record<OpsysEvent, string | undefined> = {
  "tenant.created": process.env.MAKE_WEBHOOK_NEW_TENANT,
  "tenant.move_out_marked": process.env.MAKE_WEBHOOK_MOVE_OUT,
  "tenant.move_out_completed": process.env.MAKE_WEBHOOK_MOVE_OUT,
};

export async function dispatchWebhook(event: OpsysEvent, tenant: TenantWithRelations) {
  const url = TARGET[event];
  if (!url) {
    console.warn(`[opsys] No webhook URL configured for ${event} - skipped.`);
    return;
  }

  const payload = {
    event,
    timestamp: new Date().toISOString(),
    tenant: {
      reference: tenant.reference,
      fullName: tenant.fullName,
      status: tenant.status,
      phone: tenant.phone,
      email: tenant.email,
    },
    property: {
      reference: tenant.property.reference,
      name: tenant.property.name,
      address: tenant.property.address,
    },
    unit: {
      id: tenant.unit.id,
      reference: tenant.unit.reference,
      flatNumber: tenant.unit.flatNumber,
    },
  };

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    clearTimeout(timeout);
    if (!res.ok) console.error(`[opsys] Webhook ${event} returned ${res.status}`);
  } catch (err) {
    console.error(`[opsys] Webhook ${event} failed:`, err);
  }
}