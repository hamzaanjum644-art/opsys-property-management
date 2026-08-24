import Link from "next/link";
import { notFound } from "next/navigation";
import Shell from "@/components/shell";
import StatusBadge, { label } from "@/components/status-badge";
import StatusActions from "@/components/status-actions";
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isAdmin } from "@/lib/auth";

// Section 8 - "The tenant profile should clearly show the property and unit
// they occupy."
// Section 10 - workflow actions.
// Section 13 - "Tenant status changes must be traceable" (the history below).

export const dynamic = "force-dynamic";

function fmt(d: Date | null) {
  if (!d) return "-";
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
    { label: "Email", value: tenant.email ?? "-" },
    { label: "Date of birth", value: fmt(tenant.dateOfBirth) },
    { label: "Gender", value: tenant.gender ? label(tenant.gender) : "-" },
    { label: "Move-in date", value: fmt(tenant.moveInDate) },
    { label: "Move-out date", value: fmt(tenant.moveOutDate) },
  ];

  return (
    <Shell
      title={tenant.fullName}
      subtitle={`${tenant.property.name} | ${tenant.unit.flatNumber}`}
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
              <span className="text-ink-muted">-></span>
              <div className="rounded border border-line px-3 py-2 text-sm text-ink">
                <span className="ref block">{tenant.unit.reference}</span>
                {tenant.unit.flatNumber}
              </div>
              <StatusBadge status={tenant.unit.status} />
            </div>
            <p className="mt-3 text-xs text-ink-muted">
              {tenant.property.address} | {label(tenant.property.region)} |{" "}
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
                      {e.fromStatus ? `${label(e.fromStatus)} -> ` : ""}
                      {label(e.toStatus)}
                    </p>
                    <p className="text-xs text-ink-muted">
                      {new Intl.DateTimeFormat("en-GB", {
                        day: "numeric",
                        month: "short",
                        hour: "2-digit",
                        minute: "2-digit",
                      }).format(e.changedAt)}
                      {e.note ? ` | ${e.note}` : ""}
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