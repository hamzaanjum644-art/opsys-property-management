import Shell from "@/components/shell";
import { prisma } from "@/lib/prisma";

// Section 12, Automation 2 - visible proof that "log the move-out event" is
// satisfied. Written by Make via /api/moveout-log; read here like any other
// record, inside the same app and the same database as everything else.

export const dynamic = "force-dynamic";

export default async function MoveOutLogPage() {
  const logs = await prisma.moveOutLog.findMany({
    orderBy: { loggedAt: "desc" },
    take: 100,
  });

  return (
    <Shell
      title="Move-out log"
      subtitle={`${logs.length} event${logs.length === 1 ? "" : "s"} recorded by the move-out automation`}
    >
      <div className="rounded-lg border border-line bg-surface overflow-hidden">
        <div className="grid grid-cols-[140px_minmax(0,1fr)_minmax(0,1fr)_170px] gap-3 px-4 py-2.5 border-b border-line text-xs text-ink-muted">
          <div>Reference</div>
          <div>Tenant</div>
          <div>Property / Unit</div>
          <div>Logged</div>
        </div>

        {logs.length === 0 && (
          <p className="px-4 py-10 text-center text-sm text-ink-muted">
            No move-out events logged yet. This fills in automatically when
            Automation 2 runs.
          </p>
        )}

        {logs.map((log) => (
          <div
            key={log.id}
            className="grid grid-cols-[140px_minmax(0,1fr)_minmax(0,1fr)_170px] gap-3 px-4 py-3 border-b border-bg last:border-0 items-center"
          >
            <div className="ref">{log.tenantRef}</div>
            <div className="text-sm text-ink truncate">{log.tenantName}</div>
            <div className="text-sm text-ink-muted truncate">
              {log.propertyName} | {log.unitNumber}
            </div>
            <div className="text-xs text-ink-muted">
              <span className="mr-2 rounded bg-bg px-1.5 py-0.5">
                {log.event === "move_out_completed" ? "Completed" : "Marked"}
              </span>
              {new Intl.DateTimeFormat("en-GB", {
                day: "numeric",
                month: "short",
                hour: "2-digit",
                minute: "2-digit",
              }).format(log.loggedAt)}
            </div>
          </div>
        ))}
      </div>
    </Shell>
  );
}