"use client";

import { useActionState, useEffect, useRef } from "react";
import { createUnit } from "@/lib/actions/properties";

// Section 7 - a unit is always created from inside its parent property, so
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
          {pending ? "Adding..." : "Add unit"}
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