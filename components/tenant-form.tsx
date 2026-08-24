"use client";

import { useActionState } from "react";
import Link from "next/link";
import { createTenant, type ActionState } from "@/lib/actions/tenants";

type UnitOption = { id: string; flatNumber: string };
type PropertyGroup = { id: string; name: string; reference: string; units: UnitOption[] };

export default function TenantForm({ groups }: { groups: PropertyGroup[] }) {
  const [state, formAction, pending] = useActionState<ActionState, FormData>(
    createTenant,
    undefined
  );

  const hasVacancy = groups.some((g) => g.units.length > 0);

  return (
    <form action={formAction} className="max-w-lg rounded-lg border border-line bg-surface p-6">
      <label className="block text-sm text-ink" htmlFor="fullName">
        Full name
      </label>
      <input
        id="fullName"
        name="fullName"
        required
        className="mt-1 mb-4 w-full rounded border border-line px-3 py-2 text-sm text-ink"
      />

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm text-ink" htmlFor="phone">
            Phone
          </label>
          <input
            id="phone"
            name="phone"
            required
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          />
        </div>
        <div>
          <label className="block text-sm text-ink" htmlFor="email">
            Email <span className="text-ink-muted">(optional)</span>
          </label>
          <input
            id="email"
            name="email"
            type="email"
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm text-ink" htmlFor="dateOfBirth">
            Date of birth <span className="text-ink-muted">(optional)</span>
          </label>
          <input
            id="dateOfBirth"
            name="dateOfBirth"
            type="date"
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          />
        </div>
        <div>
          <label className="block text-sm text-ink" htmlFor="gender">
            Gender <span className="text-ink-muted">(optional)</span>
          </label>
          <select
            id="gender"
            name="gender"
            defaultValue=""
            className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
          >
            <option value="">Not specified</option>
            <option value="MALE">Male</option>
            <option value="FEMALE">Female</option>
            <option value="OTHER">Other</option>
            <option value="PREFER_NOT_TO_SAY">Prefer not to say</option>
          </select>
        </div>
      </div>

      <label className="block text-sm text-ink" htmlFor="unitId">
        Unit
      </label>
      <select
        id="unitId"
        name="unitId"
        required
        defaultValue=""
        disabled={!hasVacancy}
        className="mt-1 w-full rounded border border-line px-3 py-2 text-sm text-ink"
      >
        <option value="" disabled>
          {hasVacancy ? "Select a unit" : "No units available"}
        </option>
        {groups
          .filter((g) => g.units.length > 0)
          .map((g) => (
            <optgroup key={g.id} label={`${g.reference} - ${g.name}`}>
              {g.units.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.flatNumber}
                </option>
              ))}
            </optgroup>
          ))}
      </select>
      <p className="mt-1.5 text-xs text-ink-muted">
        Only units without a current tenant are listed. The property is taken from the unit.
      </p>

      {!hasVacancy && (
        <p className="mt-4 text-sm text-ink-muted">
          Every unit currently has a tenant. Add a unit to a property first.
        </p>
      )}

      {state?.error && (
        <p className="mt-4 text-sm text-danger" role="alert">
          {state.error}
        </p>
      )}

      <div className="mt-6 flex gap-2">
        <button
          type="submit"
          disabled={pending || !hasVacancy}
          className="rounded bg-forest px-4 py-2 text-sm text-white disabled:opacity-50"
        >
          {pending ? "Creating..." : "Create tenant"}
        </button>
        <Link href="/tenants" className="rounded border border-line px-4 py-2 text-sm text-ink-muted">
          Cancel
        </Link>
      </div>

      <p className="mt-4 text-xs text-ink-muted">
        New tenants start as Pending. Complete the move-in from the tenant profile.
      </p>
    </form>
  );
}