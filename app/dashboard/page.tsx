import Link from "next/link";
import Shell from "@/components/shell";
import { prisma } from "@/lib/prisma";

// Section 11 - Management dashboard.
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