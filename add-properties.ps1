$ErrorActionPreference='Stop'
if (-not (Test-Path 'package.json')) { Write-Host "  Run this from D:\dev\opsys-property-management" -ForegroundColor Red; exit 1 }
function Save-File($p,$c){ $f=Join-Path (Get-Location) $p; $d=Split-Path $f -Parent
 if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
 $e=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($f,$c,$e)
 Write-Host "  [ok] $p" -ForegroundColor Green }
Write-Host ""; Write-Host "  Adding property register, units and dashboard" -ForegroundColor Cyan; Write-Host ""

Save-File 'components/shell.tsx' @'
import Link from "next/link";
import { requireUser } from "@/lib/auth";

// Shared chrome for every signed-in page. Nav order follows the lifecycle in
// project file section 3: Property -> Unit -> Tenant.

const NAV = [
  { href: "/dashboard", label: "Dashboard", icon: "M3 12h7V3H3v9zm0 9h7v-7H3v7zm11 0h7V12h-7v9zm0-18v7h7V3h-7z" },
  { href: "/properties", label: "Properties", icon: "M3 21h18M5 21V7l7-4 7 4v14M9 21v-6h6v6" },
  { href: "/tenants", label: "Tenants", icon: "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z" },
];

export default async function Shell({
  children,
  title,
  subtitle,
  action,
}: {
  children: React.ReactNode;
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  const user = await requireUser();

  return (
    <div className="min-h-screen flex bg-bg">
      <aside className="w-52 shrink-0 bg-forest text-white flex flex-col">
        <div className="px-5 py-6">
          <p className="font-mono text-[11px] tracking-widest text-brass">OPSYS PRO</p>
        </div>

        <nav className="flex-1">
          {NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center gap-3 px-5 py-2.5 text-sm text-sage hover:bg-slate hover:text-white transition-colors"
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d={item.icon} />
              </svg>
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="px-5 py-4 border-t border-slate">
          <p className="text-xs text-white">{user.fullName}</p>
          <p className="text-[11px] text-sage mt-0.5">{user.role}</p>
        </div>
      </aside>

      <main className="flex-1 min-w-0 px-8 py-7">
        <div className="flex items-start justify-between gap-4 mb-6">
          <div>
            <h1 className="text-xl font-medium text-ink">{title}</h1>
            {subtitle && <p className="text-sm text-ink-muted mt-0.5">{subtitle}</p>}
          </div>
          {action}
        </div>
        {children}
      </main>
    </div>
  );
}
'@

Save-File 'components/status-badge.tsx' @'
// Status colours are defined once here so Vacant/Occupied (section 7) and the
// four tenant states (section 8) read consistently everywhere in the app.

const STYLES: Record<string, string> = {
  VACANT: "bg-sage text-forest",
  OCCUPIED: "bg-forest text-white",
  PENDING: "bg-brass text-forest",
  ACTIVE: "bg-forest text-white",
  MOVE_OUT: "bg-slate text-white",
  CLOSED: "bg-sage text-forest",
  VERIFIED: "bg-forest text-white",
  REJECTED: "bg-danger text-white",
  INACTIVE: "bg-sage text-forest",
};

const LABELS: Record<string, string> = {
  VACANT: "Vacant",
  OCCUPIED: "Occupied",
  PENDING: "Pending",
  ACTIVE: "Active",
  MOVE_OUT: "Move-out",
  CLOSED: "Closed",
  VERIFIED: "Verified",
  REJECTED: "Rejected",
  INACTIVE: "Inactive",
  HMO: "HMO",
  SELF_CONTAINED: "Self-contained",
  NORTH: "North",
  SOUTH: "South",
  EAST: "East",
  WEST: "West",
};

export function label(value: string) {
  return LABELS[value] ?? value;
}

export default function StatusBadge({ status }: { status: string }) {
  return (
    <span
      className={`inline-block rounded px-2 py-0.5 text-xs ${STYLES[status] ?? "bg-sage text-forest"}`}
    >
      {label(status)}
    </span>
  );
}
'@

Save-File 'components/property-form.tsx' @'
"use client";

import { useActionState } from "react";
import Link from "next/link";
import type { ActionState } from "@/lib/actions/properties";

type Values = {
  name?: string;
  address?: string;
  region?: string;
  type?: string;
  status?: string;
};

export default function PropertyForm({
  action,
  values,
  submitLabel,
  cancelHref,
}: {
  action: (prev: ActionState, formData: FormData) => Promise<ActionState>;
  values?: Values;
  submitLabel: string;
  cancelHref: string;
}) {
  const [state, formAction, pending] = useActionState(action, undefined);

  return (
    <form action={formAction} className="max-w-lg rounded-lg border border-line bg-surface p-6">
      <label className="block text-sm text-ink" htmlFor="name">
        Property name
      </label>
      <input
        id="name"
        name="name"
        defaultValue={values?.name}
        required
        className="mt-1 mb-4 w-full rounded border border-line px-3 py-2 text-sm text-ink"
      />

      <label className="block text-sm text-ink" htmlFor="address">
        Address
      </label>
      <input
        id="address"
        name="address"
        defaultValue={values?.address}
        required
        className="mt-1 mb-4 w-full rounded border border-line px-3 py-2 text-sm text-ink"
      />

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm text-ink" htmlFor="region">
            Region
          </label>
          <select
            id="region"
            name="region"
            defaultValue={values?.region ?? "NORTH"}
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          >
            <option value="NORTH">North</option>
            <option value="SOUTH">South</option>
            <option value="EAST">East</option>
            <option value="WEST">West</option>
          </select>
        </div>

        <div>
          <label className="block text-sm text-ink" htmlFor="type">
            Property type
          </label>
          <select
            id="type"
            name="type"
            defaultValue={values?.type ?? "HMO"}
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          >
            <option value="HMO">HMO</option>
            <option value="SELF_CONTAINED">Self-contained</option>
          </select>
        </div>
      </div>

      <label className="block text-sm text-ink mt-4" htmlFor="status">
        Status
      </label>
      <select
        id="status"
        name="status"
        defaultValue={values?.status ?? "ACTIVE"}
        className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
      >
        <option value="ACTIVE">Active</option>
        <option value="INACTIVE">Inactive</option>
      </select>

      {state?.error && (
        <p className="mt-4 text-sm text-danger" role="alert">
          {state.error}
        </p>
      )}

      <div className="mt-6 flex gap-2">
        <button
          type="submit"
          disabled={pending}
          className="rounded bg-forest px-4 py-2 text-sm text-white disabled:opacity-50"
        >
          {pending ? "Saving…" : submitLabel}
        </button>
        <Link
          href={cancelHref}
          className="rounded border border-line px-4 py-2 text-sm text-ink-muted"
        >
          Cancel
        </Link>
      </div>
    </form>
  );
}
'@

Save-File 'components/unit-form.tsx' @'
"use client";

import { useActionState, useEffect, useRef } from "react";
import { createUnit } from "@/lib/actions/properties";

// Section 7 — a unit is always created from inside its parent property, so
// there is no route that can produce an orphan unit.

export default function AddUnitForm({ propertyId }: { propertyId: string }) {
  const [state, formAction, pending] = useActionState(createUnit, undefined);
  const ref = useRef<HTMLFormElement>(null);

  useEffect(() => {
    if (!pending && !state?.error) ref.current?.reset();
  }, [pending, state]);

  return (
    <form
      ref={ref}
      action={formAction}
      className="rounded-lg border border-line bg-surface p-5 max-w-lg"
    >
      <p className="text-sm text-ink mb-3">Add a unit</p>
      <input type="hidden" name="propertyId" value={propertyId} />

      <div className="flex gap-2">
        <input
          name="flatNumber"
          placeholder="Flat 1A"
          required
          className="flex-1 rounded border border-line px-3 py-2 text-sm text-ink"
        />
        <button
          type="submit"
          disabled={pending}
          className="rounded bg-forest px-4 py-2 text-sm text-white disabled:opacity-50"
        >
          {pending ? "Adding…" : "Add unit"}
        </button>
      </div>

      {state?.error && (
        <p className="mt-3 text-sm text-danger" role="alert">
          {state.error}
        </p>
      )}

      <p className="mt-3 text-xs text-ink-muted">
        New units start as vacant. Reference is generated automatically.
      </p>
    </form>
  );
}
'@

Save-File 'lib/actions/properties.ts' @'
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import { friendlyDbError } from "@/lib/tenant-workflow";

// Section 6 (Property Register) and Section 7 (Unit Management).
// Section 19 requires validation of required fields — that is the Zod schema.
// Section 5: writes are Administrator-only, enforced server-side.

const PropertySchema = z.object({
  name: z.string().trim().min(1, "Property name is required."),
  address: z.string().trim().min(1, "Address is required."),
  region: z.enum(["NORTH", "SOUTH", "EAST", "WEST"]),
  type: z.enum(["HMO", "SELF_CONTAINED"]),
  status: z.enum(["ACTIVE", "INACTIVE"]),
});

const UnitSchema = z.object({
  propertyId: z.string().min(1),
  flatNumber: z.string().trim().min(1, "Flat number is required."),
});

export type ActionState = { error?: string } | undefined;

async function nextReference(prefix: string, seq: string) {
  const rows = await prisma.$queryRawUnsafe<{ next_reference: string }[]>(
    `SELECT next_reference('${prefix}', '${seq}')`
  );
  return rows[0].next_reference;
}

export async function createProperty(_prev: ActionState, formData: FormData): Promise<ActionState> {
  await requireAdmin();

  const parsed = PropertySchema.safeParse({
    name: formData.get("name"),
    address: formData.get("address"),
    region: formData.get("region"),
    type: formData.get("type"),
    status: formData.get("status"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0].message };
  }

  let id: string;
  try {
    const created = await prisma.property.create({
      data: { ...parsed.data, reference: await nextReference("PRP", "property_ref_seq") },
    });
    id = created.id;
  } catch (e) {
    return { error: friendlyDbError(e) ?? "Could not create the property. Try again." };
  }

  revalidatePath("/properties");
  revalidatePath("/dashboard");
  redirect(`/properties/${id}`);
}

export async function updateProperty(
  id: string,
  _prev: ActionState,
  formData: FormData
): Promise<ActionState> {
  await requireAdmin();

  const parsed = PropertySchema.safeParse({
    name: formData.get("name"),
    address: formData.get("address"),
    region: formData.get("region"),
    type: formData.get("type"),
    status: formData.get("status"),
  });

  if (!parsed.success) return { error: parsed.error.issues[0].message };

  try {
    await prisma.property.update({ where: { id }, data: parsed.data });
  } catch (e) {
    return { error: friendlyDbError(e) ?? "Could not save changes. Try again." };
  }

  revalidatePath("/properties");
  revalidatePath(`/properties/${id}`);
  redirect(`/properties/${id}`);
}

export async function createUnit(_prev: ActionState, formData: FormData): Promise<ActionState> {
  await requireAdmin();

  const parsed = UnitSchema.safeParse({
    propertyId: formData.get("propertyId"),
    flatNumber: formData.get("flatNumber"),
  });

  if (!parsed.success) return { error: parsed.error.issues[0].message };

  try {
    await prisma.unit.create({
      data: {
        ...parsed.data,
        reference: await nextReference("UNT", "unit_ref_seq"),
      },
    });
  } catch (e) {
    // Section 7: @@unique([propertyId, flatNumber]) surfaces here as P2002.
    const friendly = friendlyDbError(e);
    return {
      error:
        friendly === "That value is already in use. Try a different one."
          ? "That flat number already exists in this property."
          : friendly ?? "Could not add the unit. Try again.",
    };
  }

  revalidatePath(`/properties/${parsed.data.propertyId}`);
  revalidatePath("/dashboard");
  return undefined;
}
'@

Save-File 'app/globals.css' @'
@import "tailwindcss";

/* Opsys Pro — design tokens.
   Palette supplied by Hamza and approved (Decision 22).
   Nothing outside this block may introduce a new colour. */

@theme {
  /* ---- the five approved values ---- */
  --color-forest: #07332c; /* deepest — primary actions, sidebar, headings */
  --color-slate: #485046; /* secondary text, borders, move-out state */
  --color-sage: #afb7ac; /* muted text, dividers, vacant state */
  --color-brass: #bca879; /* the single accent — pending, highlights */
  --color-paper: #ededed; /* page background, card surfaces */

  /* ---- semantic roles derived from the five ---- */
  --color-bg: var(--color-paper);
  --color-surface: #ffffff;
  --color-ink: var(--color-forest);
  --color-ink-muted: var(--color-slate);
  --color-line: var(--color-sage);
  --color-accent: var(--color-brass);

  /* Status colours (sections 7 & 8) mapped into the palette.
     Occupied/Active read as the strongest green because they are the
     "working" state; vacant is deliberately quiet, not alarming. */
  --color-status-vacant: var(--color-sage);
  --color-status-occupied: var(--color-forest);
  --color-status-pending: var(--color-brass);
  --color-status-active: var(--color-forest);
  --color-status-moveout: var(--color-slate);
  --color-status-closed: var(--color-sage);

  /* Destructive is the one hue outside the palette — a delete confirmation
     cannot be sage green. Kept desaturated so it sits with the scheme. */
  --color-danger: #8c3a30;

  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "IBM Plex Mono", ui-monospace, monospace;

  --radius-card: 0.5rem;
}

/* References (PRP-0001, TEN-0001) are data, not prose — they get the mono
   face so they stay scannable in dense tables. This is the one typographic
   signature of the interface. */
.ref {
  font-family: var(--font-mono);
  font-size: 0.8125rem;
  letter-spacing: 0.02em;
  color: var(--color-ink-muted);
}

body {
  background: var(--color-bg);
  color: var(--color-ink);
}

:focus-visible {
  outline: 2px solid var(--color-forest);
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
'@

Save-File 'app/login/page.tsx' @'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function signIn() {
    setBusy(true);
    setError(null);

    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );

    const { error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      // Section 19: errors say what happened and how to fix it.
      setError("That email and password don't match an account. Check both and try again.");
      setBusy(false);
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <main className="min-h-screen grid place-items-center bg-[--color-bg] px-6">
      <div className="w-full max-w-sm">
        <div className="mb-8">
          <p className="ref mb-2">OPSYS PRO</p>
          <h1 className="text-2xl font-semibold text-[--color-ink]">
            Property &amp; tenant management
          </h1>
          <p className="mt-1 text-sm text-[--color-ink-muted]">
            Sign in to manage properties, units and tenants.
          </p>
        </div>

        <div className="rounded-[--radius-card] border border-[--color-line] bg-[--color-surface] p-6">
          <label className="block text-sm font-medium text-[--color-ink]" htmlFor="email">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && signIn()}
            className="mt-1 w-full rounded border border-[--color-line] bg-white px-3 py-2 text-sm text-[--color-ink]"
          />

          <label
            className="mt-4 block text-sm font-medium text-[--color-ink]"
            htmlFor="password"
          >
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && signIn()}
            className="mt-1 w-full rounded border border-[--color-line] bg-white px-3 py-2 text-sm text-[--color-ink]"
          />

          {error && (
            <p className="mt-4 text-sm text-[--color-danger]" role="alert">
              {error}
            </p>
          )}

          <button
            onClick={signIn}
            disabled={busy || !email || !password}
            className="mt-6 w-full rounded bg-[--color-forest] px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
          >
            {busy ? "Signing in…" : "Sign in"}
          </button>
        </div>
      </div>
    </main>
  );
}
'@

Save-File 'app/dashboard/page.tsx' @'
import Link from "next/link";
import Shell from "@/components/shell";
import { prisma } from "@/lib/prisma";

// Section 11 — Management dashboard.
// "The numbers must come from the database/application records, not hard-coded
// values." Every figure below is a live count. Nothing is stored or cached.

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const [
    properties,
    units,
    occupied,
    vacant,
    activeTenants,
    pendingTenants,
    moveOutTenants,
  ] = await Promise.all([
    prisma.property.count(),
    prisma.unit.count(),
    prisma.unit.count({ where: { status: "OCCUPIED" } }),
    prisma.unit.count({ where: { status: "VACANT" } }),
    prisma.tenant.count({ where: { status: "ACTIVE", archived: false } }),
    prisma.tenant.count({ where: { status: "PENDING", archived: false } }),
    prisma.tenant.count({ where: { status: "MOVE_OUT", archived: false } }),
  ]);

  const metrics = [
    { label: "Total properties", value: properties },
    { label: "Total units", value: units },
    { label: "Occupied units", value: occupied },
    { label: "Vacant units", value: vacant },
    { label: "Active tenants", value: activeTenants },
    { label: "Pending move-in", value: pendingTenants },
    { label: "In move-out", value: moveOutTenants },
  ];

  const occupancy = units > 0 ? Math.round((occupied / units) * 100) : 0;

  return (
    <Shell title="Dashboard" subtitle={`${occupancy}% of units occupied`}>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {metrics.map((m) => (
          <div key={m.label} className="rounded-lg bg-surface border border-line p-4">
            <p className="text-xs text-ink-muted">{m.label}</p>
            <p className="text-2xl font-medium text-ink mt-1">{m.value}</p>
          </div>
        ))}
      </div>

      {properties === 0 && (
        <div className="mt-8 rounded-lg border border-line bg-surface p-8 text-center">
          <p className="text-ink font-medium">Start your first property</p>
          <p className="text-sm text-ink-muted mt-1">
            Add a property, then create the units inside it.
          </p>
          <Link
            href="/properties/new"
            className="inline-block mt-4 rounded bg-forest px-4 py-2 text-sm text-white"
          >
            Create property
          </Link>
        </div>
      )}
    </Shell>
  );
}
'@

Save-File 'app/properties/page.tsx' @'
import Link from "next/link";
import Shell from "@/components/shell";
import { prisma } from "@/lib/prisma";
import { label } from "@/components/status-badge";
import { isAdmin, getCurrentUser } from "@/lib/auth";

// Section 6 — Property Register.
// Occupancy and unit count are DERIVED from unit records (Decision 8), never
// stored, per section 19's rule against duplicating referenceable data.

export const dynamic = "force-dynamic";

export default async function PropertiesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; region?: string }>;
}) {
  const { q, region } = await searchParams;
  const user = await getCurrentUser();

  const properties = await prisma.property.findMany({
    where: {
      ...(q
        ? {
            OR: [
              { name: { contains: q, mode: "insensitive" as const } },
              { address: { contains: q, mode: "insensitive" as const } },
              { reference: { contains: q, mode: "insensitive" as const } },
            ],
          }
        : {}),
      ...(region ? { region: region as "NORTH" | "SOUTH" | "EAST" | "WEST" } : {}),
    },
    include: {
      units: { select: { status: true } },
    },
    orderBy: { reference: "asc" },
  });

  return (
    <Shell
      title="Property register"
      subtitle={`${properties.length} ${properties.length === 1 ? "property" : "properties"}`}
      action={
        isAdmin(user) ? (
          <Link
            href="/properties/new"
            className="rounded bg-forest px-4 py-2 text-sm text-white shrink-0"
          >
            New property
          </Link>
        ) : null
      }
    >
      <form className="flex gap-2 mb-4">
        <input
          name="q"
          defaultValue={q ?? ""}
          placeholder="Search name, address or reference"
          className="flex-1 rounded border border-line bg-surface px-3 py-2 text-sm text-ink"
        />
        <select
          name="region"
          defaultValue={region ?? ""}
          className="rounded border border-line bg-surface px-3 py-2 text-sm text-ink"
        >
          <option value="">All regions</option>
          <option value="NORTH">North</option>
          <option value="SOUTH">South</option>
          <option value="EAST">East</option>
          <option value="WEST">West</option>
        </select>
        <button type="submit" className="rounded border border-line bg-surface px-4 py-2 text-sm text-ink">
          Search
        </button>
      </form>

      <div className="rounded-lg border border-line bg-surface overflow-hidden">
        <div className="grid grid-cols-[100px_minmax(0,1fr)_90px_150px] gap-3 px-4 py-2.5 border-b border-line text-xs text-ink-muted">
          <div>Reference</div>
          <div>Property</div>
          <div>Units</div>
          <div>Occupancy</div>
        </div>

        {properties.length === 0 && (
          <p className="px-4 py-10 text-center text-sm text-ink-muted">
            {q || region ? "No properties match that search." : "No properties yet."}
          </p>
        )}

        {properties.map((p) => {
          const total = p.units.length;
          const occupied = p.units.filter((u) => u.status === "OCCUPIED").length;

          return (
            <Link
              key={p.id}
              href={`/properties/${p.id}`}
              className="grid grid-cols-[100px_minmax(0,1fr)_90px_150px] gap-3 px-4 py-3 border-b border-bg last:border-0 items-center hover:bg-bg transition-colors"
            >
              <div className="ref">{p.reference}</div>
              <div className="min-w-0">
                <p className="text-sm text-ink truncate">{p.name}</p>
                <p className="text-xs text-ink-muted truncate">
                  {p.address} · {label(p.region)} · {label(p.type)}
                </p>
              </div>
              <div className="text-sm text-ink">{total}</div>
              <div>
                <span
                  className={`inline-block rounded px-2 py-0.5 text-xs ${
                    occupied > 0 ? "bg-forest text-white" : "bg-sage text-forest"
                  }`}
                >
                  {occupied} / {total} occupied
                </span>
              </div>
            </Link>
          );
        })}
      </div>
    </Shell>
  );
}
'@

Save-File 'app/properties/new/page.tsx' @'
import Shell from "@/components/shell";
import PropertyForm from "@/components/property-form";
import { createProperty } from "@/lib/actions/properties";
import { requireAdmin } from "@/lib/auth";

// Section 6 — "Create a property."

export default async function NewPropertyPage() {
  await requireAdmin();

  return (
    <Shell title="New property" subtitle="Units are added after the property is created.">
      <PropertyForm action={createProperty} submitLabel="Create property" cancelHref="/properties" />
    </Shell>
  );
}
'@

Save-File 'app/properties/[id]/page.tsx' @'
import Link from "next/link";
import { notFound } from "next/navigation";
import Shell from "@/components/shell";
import StatusBadge, { label } from "@/components/status-badge";
import AddUnitForm from "@/components/unit-form";
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isAdmin } from "@/lib/auth";

// Section 6 — "Open a property and see its units." / "Show occupancy summary."
// Section 7 — PROPERTY -> contains -> UNIT, with the current tenant shown.

export const dynamic = "force-dynamic";

export default async function PropertyDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const user = await getCurrentUser();

  const property = await prisma.property.findUnique({
    where: { id },
    include: {
      units: {
        include: { currentTenant: { select: { id: true, fullName: true, status: true } } },
        orderBy: { reference: "asc" },
      },
    },
  });

  if (!property) notFound();

  const total = property.units.length;
  const occupied = property.units.filter((u) => u.status === "OCCUPIED").length;
  const percent = total > 0 ? Math.round((occupied / total) * 100) : 0;

  return (
    <Shell
      title={property.name}
      subtitle={`${property.address} · ${label(property.region)} · ${label(property.type)}`}
      action={
        isAdmin(user) ? (
          <Link
            href={`/properties/${property.id}/edit`}
            className="rounded border border-line bg-surface px-4 py-2 text-sm text-ink shrink-0"
          >
            Edit property
          </Link>
        ) : null
      }
    >
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        <div className="rounded-lg bg-surface border border-line p-4">
          <p className="text-xs text-ink-muted">Reference</p>
          <p className="ref mt-1 text-sm">{property.reference}</p>
        </div>
        <div className="rounded-lg bg-surface border border-line p-4">
          <p className="text-xs text-ink-muted">Total units</p>
          <p className="text-2xl font-medium text-ink mt-1">{total}</p>
        </div>
        <div className="rounded-lg bg-surface border border-line p-4">
          <p className="text-xs text-ink-muted">Occupied</p>
          <p className="text-2xl font-medium text-ink mt-1">{occupied}</p>
        </div>
        <div className="rounded-lg bg-surface border border-line p-4">
          <p className="text-xs text-ink-muted">Occupancy</p>
          <p className="text-2xl font-medium text-ink mt-1">{percent}%</p>
        </div>
      </div>

      <div className="rounded-lg border border-line bg-surface overflow-hidden mb-6">
        <div className="grid grid-cols-[100px_minmax(0,1fr)_110px_minmax(0,1fr)] gap-3 px-4 py-2.5 border-b border-line text-xs text-ink-muted">
          <div>Reference</div>
          <div>Flat number</div>
          <div>Status</div>
          <div>Current tenant</div>
        </div>

        {total === 0 && (
          <p className="px-4 py-10 text-center text-sm text-ink-muted">
            No units yet. Add the first one below.
          </p>
        )}

        {property.units.map((u) => (
          <div
            key={u.id}
            className="grid grid-cols-[100px_minmax(0,1fr)_110px_minmax(0,1fr)] gap-3 px-4 py-3 border-b border-bg last:border-0 items-center"
          >
            <div className="ref">{u.reference}</div>
            <div className="text-sm text-ink truncate">{u.flatNumber}</div>
            <div>
              <StatusBadge status={u.status} />
            </div>
            <div className="text-sm truncate">
              {u.currentTenant ? (
                <Link href={`/tenants/${u.currentTenant.id}`} className="text-ink underline">
                  {u.currentTenant.fullName}
                </Link>
              ) : (
                <span className="text-ink-muted">—</span>
              )}
            </div>
          </div>
        ))}
      </div>

      {isAdmin(user) && <AddUnitForm propertyId={property.id} />}
    </Shell>
  );
}
'@

Save-File 'app/properties/[id]/edit/page.tsx' @'
import { notFound } from "next/navigation";
import Shell from "@/components/shell";
import PropertyForm from "@/components/property-form";
import { updateProperty } from "@/lib/actions/properties";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

// Section 6 — "Edit a property."

export default async function EditPropertyPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  await requireAdmin();
  const { id } = await params;

  const property = await prisma.property.findUnique({ where: { id } });
  if (!property) notFound();

  const action = updateProperty.bind(null, id);

  return (
    <Shell title="Edit property" subtitle={property.reference}>
      <PropertyForm
        action={action}
        values={{
          name: property.name,
          address: property.address,
          region: property.region,
          type: property.type,
          status: property.status,
        }}
        submitLabel="Save changes"
        cancelHref={`/properties/${id}`}
      />
    </Shell>
  );
}
'@

Write-Host ""
Write-Host "  Done. Refresh http://localhost:3000/properties" -ForegroundColor Green
Write-Host ""
