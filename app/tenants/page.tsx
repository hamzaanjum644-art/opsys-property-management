import Link from "next/link";
import Shell from "@/components/shell";
import StatusBadge from "@/components/status-badge";
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isAdmin } from "@/lib/auth";

// Section 8 - Tenant Management. The list shows the property and unit each
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