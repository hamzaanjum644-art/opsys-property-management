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
          {pending ? "Saving..." : submitLabel}
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