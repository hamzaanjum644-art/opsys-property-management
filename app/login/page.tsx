"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";

// Section 5 - sign in as Administrator or Staff User.
//
// Paper-grey field, forest-green panel. The green is reserved for the one
// thing the page is for, so the eye lands on it before reading anything.

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function signIn() {
    if (!email || !password) return;
    setBusy(true);
    setError(null);

    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );

    const { error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      setError("That email and password do not match an account.");
      setBusy(false);
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <main className="min-h-screen bg-[#ededed] flex items-center justify-center px-5 py-12">
      <div className="w-full max-w-[400px]">
        <div className="overflow-hidden rounded-2xl bg-[#07332c] shadow-[0_24px_60px_-28px_rgba(7,51,44,0.55)]">
          <div className="px-9 pt-9 pb-7">
            <p className="font-mono text-[11px] tracking-[0.28em] text-[#bca879]">
              OPSYS PRO
            </p>
            <h1 className="mt-3 text-[24px] leading-snug font-medium text-white">
              Property Management System
            </h1>
            <div className="mt-5 h-px w-12 bg-[#bca879]" />
            <p className="mt-5 text-[13px] leading-relaxed text-[#afb7ac]">
              Sign in to manage properties, units, tenants and documents.
            </p>
          </div>

          <div className="px-9 pb-9">
            <label
              className="block text-[12px] font-medium tracking-wide text-[#afb7ac]"
              htmlFor="email"
            >
              EMAIL
            </label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              placeholder="admin@opsys.test"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && signIn()}
              className="mt-2 w-full rounded-lg border border-[#2c5249] bg-[#0b3f36] px-3.5 py-3 text-sm text-white placeholder:text-[#6e8079] outline-none focus:border-[#bca879] transition-colors"
            />

            <label
              className="mt-5 block text-[12px] font-medium tracking-wide text-[#afb7ac]"
              htmlFor="password"
            >
              PASSWORD
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && signIn()}
              className="mt-2 w-full rounded-lg border border-[#2c5249] bg-[#0b3f36] px-3.5 py-3 text-sm text-white outline-none focus:border-[#bca879] transition-colors"
            />

            {error && (
              <p
                className="mt-4 rounded-lg bg-[#4a2622] px-3.5 py-2.5 text-[13px] text-[#e6b8b1]"
                role="alert"
              >
                {error}
              </p>
            )}

            <button
              onClick={signIn}
              disabled={busy || !email || !password}
              className="mt-7 w-full rounded-lg bg-[#bca879] px-4 py-3 text-sm font-semibold text-[#07332c] hover:bg-[#cbb98e] disabled:bg-[#2c5249] disabled:text-[#6e8079] transition-colors"
            >
              {busy ? "Signing in..." : "Sign in"}
            </button>
          </div>
        </div>

        <p className="mt-6 text-center text-[12px] text-[#7d8a83]">
          Administrator and Staff accounts available
        </p>
      </div>
    </main>
  );
}