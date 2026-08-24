$ErrorActionPreference='Stop'
$root = "D:\dev\opsys-property-management"
if (-not (Test-Path (Join-Path $root 'package.json'))) { Write-Host "  Project not found at $root" -ForegroundColor Red; exit 1 }
function Save-File($p,$c){ $f=Join-Path $root $p; $d=Split-Path $f -Parent
 if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
 $e=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($f,$c,$e)
 Write-Host "  [ok] $p" -ForegroundColor Green }
Write-Host ""; Write-Host "  Adding tenant module and status workflow" -ForegroundColor Cyan; Write-Host ""

Save-File 'lib/actions/tenants.ts' @'
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

// Section 8 — Tenant Management.
// Section 10 — status transitions route through transitionTenant() only.

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

  // Property is derived from the unit rather than submitted separately —
  // section 19: don't duplicate data that can be referenced.
  const unit = await prisma.unit.findUnique({
    where: { id: unitId },
    select: { id: true, propertyId: true, currentTenantId: true, flatNumber: true },
  });

  if (!unit) return { error: "That unit no longer exists." };

  // Decision D1 — one live tenant per unit.
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
        // Section 10 step 1 — new tenant is always PENDING.
        status: "PENDING",
      },
      include: { property: true, unit: true },
    });

    tenantId = created.id;

    // Section 13 — the creation itself is a traceable event.
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

    // Section 12, Automation 1 — New Tenant Notification.
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
'@

Save-File 'components/tenant-form.tsx' @'
"use client";

import { useActionState } from "react";
import Link from "next/link";
import { createTenant, type ActionState } from "@/lib/actions/tenants";

type UnitOption = { id: string; flatNumber: string };
type PropertyGroup = { id: string; name: string; reference: string; units: UnitOption[] };

export default function TenantForm({ groups }: { groups: PropertyGroup[] }) {
  const [state, formAction, pending] = useActionState<ActionState, FormData>(
    createTenant,
    undefined
  );

  const hasVacancy = groups.some((g) => g.units.length > 0);

  return (
    <form action={formAction} className="max-w-lg rounded-lg border border-line bg-surface p-6">
      <label className="block text-sm text-ink" htmlFor="fullName">
        Full name
      </label>
      <input
        id="fullName"
        name="fullName"
        required
        className="mt-1 mb-4 w-full rounded border border-line px-3 py-2 text-sm text-ink"
      />

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm text-ink" htmlFor="phone">
            Phone
          </label>
          <input
            id="phone"
            name="phone"
            required
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          />
        </div>
        <div>
          <label className="block text-sm text-ink" htmlFor="email">
            Email <span className="text-ink-muted">(optional)</span>
          </label>
          <input
            id="email"
            name="email"
            type="email"
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm text-ink" htmlFor="dateOfBirth">
            Date of birth <span className="text-ink-muted">(optional)</span>
          </label>
          <input
            id="dateOfBirth"
            name="dateOfBirth"
            type="date"
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          />
        </div>
        <div>
          <label className="block text-sm text-ink" htmlFor="gender">
            Gender <span className="text-ink-muted">(optional)</span>
          </label>
          <select
            id="gender"
            name="gender"
            defaultValue=""
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          >
            <option value="">Not specified</option>
            <option value="MALE">Male</option>
            <option value="FEMALE">Female</option>
            <option value="OTHER">Other</option>
            <option value="PREFER_NOT_TO_SAY">Prefer not to say</option>
          </select>
        </div>
      </div>

      <label className="block text-sm text-ink" htmlFor="unitId">
        Unit
      </label>
      <select
        id="unitId"
        name="unitId"
        required
        defaultValue=""
        disabled={!hasVacancy}
        className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
      >
        <option value="" disabled>
          {hasVacancy ? "Select a unit" : "No units available"}
        </option>
        {groups
          .filter((g) => g.units.length > 0)
          .map((g) => (
            <optgroup key={g.id} label={`${g.reference} — ${g.name}`}>
              {g.units.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.flatNumber}
                </option>
              ))}
            </optgroup>
          ))}
      </select>
      <p className="mt-1.5 text-xs text-ink-muted">
        Only units without a current tenant are listed. The property is taken from the unit.
      </p>

      {!hasVacancy && (
        <p className="mt-4 text-sm text-ink-muted">
          Every unit currently has a tenant. Add a unit to a property first.
        </p>
      )}

      {state?.error && (
        <p className="mt-4 text-sm text-danger" role="alert">
          {state.error}
        </p>
      )}

      <div className="mt-6 flex gap-2">
        <button
          type="submit"
          disabled={pending || !hasVacancy}
          className="rounded bg-forest px-4 py-2 text-sm text-white disabled:opacity-50"
        >
          {pending ? "Creating…" : "Create tenant"}
        </button>
        <Link href="/tenants" className="rounded border border-line px-4 py-2 text-sm text-ink-muted">
          Cancel
        </Link>
      </div>

      <p className="mt-4 text-xs text-ink-muted">
        New tenants start as Pending. Complete the move-in from the tenant profile.
      </p>
    </form>
  );
}
'@

Save-File 'components/status-actions.tsx' @'
"use client";

import { useState, useTransition } from "react";
import { runTransition } from "@/lib/actions/tenants";
import type { TransitionAction } from "@/lib/tenant-workflow";

// Section 10 — the connected workflow, as explicit actions rather than a free
// status dropdown. Only the one legal next step is ever offered, so an illegal
// transition cannot be attempted from the interface.

const NEXT: Record<string, { action: TransitionAction; label: string; effect: string } | null> = {
  PENDING: {
    action: "COMPLETE_MOVE_IN",
    label: "Complete move-in",
    effect: "Tenant becomes Active and the unit becomes Occupied.",
  },
  ACTIVE: {
    action: "MARK_MOVE_OUT",
    label: "Mark for move-out",
    effect: "Tenant becomes Move-out. The unit stays Occupied until it completes.",
  },
  MOVE_OUT: {
    action: "COMPLETE_MOVE_OUT",
    label: "Complete move-out",
    effect: "Tenant becomes Closed and the unit becomes Vacant.",
  },
  CLOSED: null,
};

export default function StatusActions({
  tenantId,
  status,
  canAct,
}: {
  tenantId: string;
  status: string;
  canAct: boolean;
}) {
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const next = NEXT[status];

  if (!next) {
    return (
      <div className="rounded-lg border border-line bg-surface p-5">
        <p className="text-sm text-ink">Tenancy closed</p>
        <p className="text-xs text-ink-muted mt-1">
          This tenancy has completed its lifecycle. The unit has been released.
        </p>
      </div>
    );
  }

  if (!canAct) {
    return (
      <div className="rounded-lg border border-line bg-surface p-5">
        <p className="text-sm text-ink">Next step: {next.label}</p>
        <p className="text-xs text-ink-muted mt-1">
          Administrators can advance the tenancy status.
        </p>
      </div>
    );
  }

  function advance() {
    setError(null);
    startTransition(async () => {
      const result = await runTransition(tenantId, next!.action);
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="rounded-lg border border-line bg-surface p-5">
      <p className="text-sm text-ink mb-1">Next step</p>
      <p className="text-xs text-ink-muted mb-4">{next.effect}</p>

      <button
        onClick={advance}
        disabled={pending}
        className="rounded bg-forest px-4 py-2 text-sm text-white disabled:opacity-50"
      >
        {pending ? "Updating…" : next.label}
      </button>

      {error && (
        <p className="mt-3 text-sm text-danger" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
'@

Save-File 'app/tenants/page.tsx' @'
import Link from "next/link";
import Shell from "@/components/shell";
import StatusBadge from "@/components/status-badge";
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isAdmin } from "@/lib/auth";

// Section 8 — Tenant Management. The list shows the property and unit each
// tenant occupies, satisfying "the tenant profile should clearly show the
// property and unit they occupy" at index level too.

export const dynamic = "force-dynamic";

const STATUSES = ["PENDING", "ACTIVE", "MOVE_OUT", "CLOSED"] as const;

export default async function TenantsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; status?: string }>;
}) {
  const { q, status } = await searchParams;
  const user = await getCurrentUser();

  const tenants = await prisma.tenant.findMany({
    where: {
      archived: false,
      ...(q
        ? {
            OR: [
              { fullName: { contains: q, mode: "insensitive" as const } },
              { reference: { contains: q, mode: "insensitive" as const } },
              { phone: { contains: q } },
            ],
          }
        : {}),
      ...(status && STATUSES.includes(status as (typeof STATUSES)[number])
        ? { status: status as (typeof STATUSES)[number] }
        : {}),
    },
    include: {
      property: { select: { name: true } },
      unit: { select: { flatNumber: true } },
    },
    orderBy: { reference: "asc" },
  });

  return (
    <Shell
      title="Tenants"
      subtitle={`${tenants.length} ${tenants.length === 1 ? "tenant" : "tenants"}`}
      action={
        isAdmin(user) ? (
          <Link href="/tenants/new" className="rounded bg-forest px-4 py-2 text-sm text-white shrink-0">
            New tenant
          </Link>
        ) : null
      }
    >
      <form className="flex gap-2 mb-4">
        <input
          name="q"
          defaultValue={q ?? ""}
          placeholder="Search name, reference or phone"
          className="flex-1 rounded border border-line bg-surface px-3 py-2 text-sm text-ink"
        />
        <select
          name="status"
          defaultValue={status ?? ""}
          className="rounded border border-line bg-surface px-3 py-2 text-sm text-ink"
        >
          <option value="">All statuses</option>
          <option value="PENDING">Pending</option>
          <option value="ACTIVE">Active</option>
          <option value="MOVE_OUT">Move-out</option>
          <option value="CLOSED">Closed</option>
        </select>
        <button type="submit" className="rounded border border-line bg-surface px-4 py-2 text-sm text-ink">
          Search
        </button>
      </form>

      <div className="rounded-lg border border-line bg-surface overflow-hidden">
        <div className="grid grid-cols-[100px_minmax(0,1fr)_minmax(0,1fr)_110px] gap-3 px-4 py-2.5 border-b border-line text-xs text-ink-muted">
          <div>Reference</div>
          <div>Tenant</div>
          <div>Property / Unit</div>
          <div>Status</div>
        </div>

        {tenants.length === 0 && (
          <p className="px-4 py-10 text-center text-sm text-ink-muted">
            {q || status ? "No tenants match that search." : "No tenants yet."}
          </p>
        )}

        {tenants.map((t) => (
          <Link
            key={t.id}
            href={`/tenants/${t.id}`}
            className="grid grid-cols-[100px_minmax(0,1fr)_minmax(0,1fr)_110px] gap-3 px-4 py-3 border-b border-bg last:border-0 items-center hover:bg-bg transition-colors"
          >
            <div className="ref">{t.reference}</div>
            <div className="min-w-0">
              <p className="text-sm text-ink truncate">{t.fullName}</p>
              <p className="text-xs text-ink-muted truncate">{t.phone}</p>
            </div>
            <div className="min-w-0">
              <p className="text-sm text-ink truncate">{t.property.name}</p>
              <p className="text-xs text-ink-muted truncate">{t.unit.flatNumber}</p>
            </div>
            <div>
              <StatusBadge status={t.status} />
            </div>
          </Link>
        ))}
      </div>
    </Shell>
  );
}
'@

Save-File 'app/tenants/new/page.tsx' @'
import Shell from "@/components/shell";
import TenantForm from "@/components/tenant-form";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

// Section 8 — create a tenant linked to a specific Unit and Property.
// Section 18 — "Create Tenant and assign them to a Unit" in one step.

export const dynamic = "force-dynamic";

export default async function NewTenantPage() {
  await requireAdmin();

  const properties = await prisma.property.findMany({
    where: { status: "ACTIVE" },
    select: {
      id: true,
      name: true,
      reference: true,
      units: {
        where: { currentTenantId: null },
        select: { id: true, flatNumber: true },
        orderBy: { reference: "asc" },
      },
    },
    orderBy: { reference: "asc" },
  });

  return (
    <Shell title="New tenant" subtitle="Assign the tenant to a unit as you create them.">
      <TenantForm groups={properties} />
    </Shell>
  );
}
'@

Save-File 'app/tenants/[id]/page.tsx' @'
import Link from "next/link";
import { notFound } from "next/navigation";
import Shell from "@/components/shell";
import StatusBadge, { label } from "@/components/status-badge";
import StatusActions from "@/components/status-actions";
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isAdmin } from "@/lib/auth";

// Section 8 — "The tenant profile should clearly show the property and unit
// they occupy."
// Section 10 — workflow actions.
// Section 13 — "Tenant status changes must be traceable" (the history below).

export const dynamic = "force-dynamic";

function fmt(d: Date | null) {
  if (!d) return "—";
  return new Intl.DateTimeFormat("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(d);
}

export default async function TenantProfilePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const user = await getCurrentUser();

  const tenant = await prisma.tenant.findUnique({
    where: { id },
    include: {
      property: true,
      unit: true,
      events: { orderBy: { changedAt: "desc" } },
      documents: { orderBy: { uploadDate: "desc" } },
    },
  });

  if (!tenant) notFound();

  const details = [
    { label: "Reference", value: tenant.reference, mono: true },
    { label: "Phone", value: tenant.phone },
    { label: "Email", value: tenant.email ?? "—" },
    { label: "Date of birth", value: fmt(tenant.dateOfBirth) },
    { label: "Gender", value: tenant.gender ? label(tenant.gender) : "—" },
    { label: "Move-in date", value: fmt(tenant.moveInDate) },
    { label: "Move-out date", value: fmt(tenant.moveOutDate) },
  ];

  return (
    <Shell
      title={tenant.fullName}
      subtitle={`${tenant.property.name} · ${tenant.unit.flatNumber}`}
      action={<StatusBadge status={tenant.status} />}
    >
      <div className="grid lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)] gap-5">
        <div className="space-y-5 min-w-0">
          <div className="rounded-lg border border-line bg-surface p-5">
            <p className="text-sm text-ink mb-4">Tenant details</p>
            <dl className="grid grid-cols-2 gap-y-3 gap-x-4">
              {details.map((d) => (
                <div key={d.label}>
                  <dt className="text-xs text-ink-muted">{d.label}</dt>
                  <dd className={`text-sm text-ink mt-0.5 ${d.mono ? "ref" : ""}`}>{d.value}</dd>
                </div>
              ))}
            </dl>
          </div>

          <div className="rounded-lg border border-line bg-surface p-5">
            <p className="text-sm text-ink mb-3">Occupies</p>
            <div className="flex items-center gap-3 flex-wrap">
              <Link
                href={`/properties/${tenant.propertyId}`}
                className="rounded border border-line px-3 py-2 text-sm text-ink hover:bg-bg"
              >
                <span className="ref block">{tenant.property.reference}</span>
                {tenant.property.name}
              </Link>
              <span className="text-ink-muted">→</span>
              <div className="rounded border border-line px-3 py-2 text-sm text-ink">
                <span className="ref block">{tenant.unit.reference}</span>
                {tenant.unit.flatNumber}
              </div>
              <StatusBadge status={tenant.unit.status} />
            </div>
            <p className="mt-3 text-xs text-ink-muted">
              {tenant.property.address} · {label(tenant.property.region)} ·{" "}
              {label(tenant.property.type)}
            </p>
          </div>

          <div className="rounded-lg border border-line bg-surface p-5">
            <div className="flex items-center justify-between mb-3">
              <p className="text-sm text-ink">Documents</p>
              <span className="text-xs text-ink-muted">{tenant.documents.length} uploaded</span>
            </div>
            {tenant.documents.length === 0 ? (
              <p className="text-sm text-ink-muted">
                No documents yet. Upload is added in the next step.
              </p>
            ) : (
              <ul className="space-y-2">
                {tenant.documents.map((d) => (
                  <li key={d.id} className="flex items-center justify-between text-sm">
                    <span className="text-ink truncate">{d.fileName}</span>
                    <StatusBadge status={d.status} />
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>

        <div className="space-y-5 min-w-0">
          <StatusActions
            tenantId={tenant.id}
            status={tenant.status}
            canAct={isAdmin(user)}
          />

          <div className="rounded-lg border border-line bg-surface p-5">
            <p className="text-sm text-ink mb-3">Status history</p>
            <ol className="space-y-3">
              {tenant.events.map((e) => (
                <li key={e.id} className="flex gap-3">
                  <div className="mt-1.5 h-1.5 w-1.5 rounded-full bg-brass shrink-0" />
                  <div className="min-w-0">
                    <p className="text-sm text-ink">
                      {e.fromStatus ? `${label(e.fromStatus)} → ` : ""}
                      {label(e.toStatus)}
                    </p>
                    <p className="text-xs text-ink-muted">
                      {new Intl.DateTimeFormat("en-GB", {
                        day: "numeric",
                        month: "short",
                        hour: "2-digit",
                        minute: "2-digit",
                      }).format(e.changedAt)}
                      {e.note ? ` · ${e.note}` : ""}
                    </p>
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </div>
      </div>
    </Shell>
  );
}
'@

Write-Host ""
Write-Host "  Done. Open http://localhost:3000/tenants" -ForegroundColor Green
Write-Host ""
