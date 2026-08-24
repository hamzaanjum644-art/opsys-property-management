import Link from "next/link";
import Shell from "@/components/shell";
import { prisma } from "@/lib/prisma";
import { label } from "@/components/status-badge";
import { isAdmin, getCurrentUser } from "@/lib/auth";

// Section 6 â€” Property Register.
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