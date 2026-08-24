"use client";

import { useState, useTransition } from "react";
import { runTransition } from "@/lib/actions/tenants";
import type { TransitionAction } from "@/lib/tenant-workflow";

// Section 10 â€” the connected workflow, as explicit actions rather than a free
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
        {pending ? "Updatingâ€¦" : next.label}
      </button>

      {error && (
        <p className="mt-3 text-sm text-danger" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}