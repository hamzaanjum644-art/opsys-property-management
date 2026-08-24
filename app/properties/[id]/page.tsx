import Link from "next/link";
import { notFound } from "next/navigation";
import Shell from "@/components/shell";
import StatusBadge, { label } from "@/components/status-badge";
import AddUnitForm from "@/components/unit-form";
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isAdmin } from "@/lib/auth";

// Section 6 â€” "Open a property and see its units." / "Show occupancy summary."
// Section 7 â€” PROPERTY -> contains -> UNIT, with the current tenant shown.

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
                <span className="text-ink-muted">â€”</span>
              )}
            </div>
          </div>
        ))}
      </div>

      {isAdmin(user) && <AddUnitForm propertyId={property.id} />}
    </Shell>
  );
}