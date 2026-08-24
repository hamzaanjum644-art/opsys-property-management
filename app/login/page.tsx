"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function signIn() {
    setBusy(true);
    setError(null);

    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );

    const { error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      // Section 19: errors say what happened and how to fix it.
      setError("That email and password don't match an account. Check both and try again.");
      setBusy(false);
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <main className="min-h-screen grid place-items-center bg-[--color-bg] px-6">
      <div className="w-full max-w-sm">
        <div className="mb-8">
          <p className="ref mb-2">OPSYS PRO</p>
          <h1 className="text-2xl font-semibold text-[--color-ink]">
            Property &amp; tenant management
          </h1>
          <p className="mt-1 text-sm text-[--color-ink-muted]">
            Sign in to manage properties, units and tenants.
          </p>
        </div>

        <div className="rounded-[--radius-card] border border-[--color-line] bg-[--color-surface] p-6">
          <label className="block text-sm font-medium text-[--color-ink]" htmlFor="email">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && signIn()}
            className="mt-1 w-full rounded border border-[--color-line] bg-white px-3 py-2 text-sm text-[--color-ink]"
          />

          <label
            className="mt-4 block text-sm font-medium text-[--color-ink]"
            htmlFor="password"
          >
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && signIn()}
            className="mt-1 w-full rounded border border-[--color-line] bg-white px-3 py-2 text-sm text-[--color-ink]"
          />

          {error && (
            <p className="mt-4 text-sm text-[--color-danger]" role="alert">
              {error}
            </p>
          )}

          <button
            onClick={signIn}
            disabled={busy || !email || !password}
            className="mt-6 w-full rounded bg-[--color-forest] px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
          >
            {busy ? "Signing in…" : "Sign in"}
          </button>
        </div>
      </div>
    </main>
  );
}