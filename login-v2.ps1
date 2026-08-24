$ErrorActionPreference='Stop'
$root = "D:\dev\opsys-property-management"
if (-not (Test-Path (Join-Path $root 'package.json'))) { Write-Host "  Project not found at $root" -ForegroundColor Red; exit 1 }
function Save-File($p,$c){ $f=Join-Path $root $p; $d=Split-Path $f -Parent
 if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
 $e=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($f,$c,$e)
 Write-Host "  [ok] $p" -ForegroundColor Green }
Write-Host ""; Write-Host "  New sign in page" -ForegroundColor Cyan; Write-Host ""

Save-File 'app/login/page.tsx' @'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";

// Section 5 - sign in as Administrator or Staff User.
//
// The backdrop is a grid of unit tiles: most sage (vacant), a few forest
// (occupied). It is the occupancy summary the app is built around, used as
// ornament. Deterministic, so it does not flicker between renders.

const OCCUPIED = new Set([3, 7, 12, 18, 21, 29, 34, 41, 47, 52, 58, 63, 70, 77, 83, 91]);

function UnitGrid() {
  return (
    <div
      aria-hidden="true"
      className="absolute inset-0 grid gap-1.5 p-6 opacity-[0.13] pointer-events-none"
      style={{
        gridTemplateColumns: "repeat(auto-fill, minmax(34px, 1fr))",
        gridAutoRows: "34px",
      }}
    >
      {Array.from({ length: 220 }).map((_, i) => (
        <div
          key={i}
          className="rounded-sm"
          style={{ background: OCCUPIED.has(i % 97) ? "#bca879" : "#afb7ac" }}
        />
      ))}
    </div>
  );
}

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
    <main className="relative min-h-screen overflow-hidden bg-[#07332c] flex items-center justify-center px-5 py-12">
      <UnitGrid />

      <div className="relative w-full max-w-[380px]">
        <div className="mb-7 text-center">
          <p className="font-mono text-[11px] tracking-[0.28em] text-[#bca879]">
            OPSYS PRO
          </p>
          <h1 className="mt-3 text-[26px] leading-tight font-medium text-white">
            Property Management
            <br />
            System
          </h1>
        </div>

        <div className="rounded-xl bg-white shadow-[0_18px_50px_-20px_rgba(0,0,0,0.6)]">
          <div className="h-1 rounded-t-xl bg-[#bca879]" />

          <div className="px-8 py-8">
            <label
              className="block text-[13px] font-medium text-[#07332c]"
              htmlFor="email"
            >
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              placeholder="admin@opsys.test"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && signIn()}
              className="mt-1.5 w-full rounded-md border border-[#d5d9d3] bg-[#fafbfa] px-3.5 py-2.5 text-sm text-[#07332c] placeholder:text-[#afb7ac] outline-none focus:border-[#07332c] focus:bg-white transition-colors"
            />

            <label
              className="mt-5 block text-[13px] font-medium text-[#07332c]"
              htmlFor="password"
            >
              Password
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && signIn()}
              className="mt-1.5 w-full rounded-md border border-[#d5d9d3] bg-[#fafbfa] px-3.5 py-2.5 text-sm text-[#07332c] outline-none focus:border-[#07332c] focus:bg-white transition-colors"
            />

            {error && (
              <p
                className="mt-4 rounded-md bg-[#f7ecea] px-3 py-2 text-[13px] text-[#8c3a30]"
                role="alert"
              >
                {error}
              </p>
            )}

            <button
              onClick={signIn}
              disabled={busy || !email || !password}
              className="mt-7 w-full rounded-md bg-[#07332c] px-4 py-3 text-sm font-medium text-white hover:bg-[#0b4b40] disabled:bg-[#d5d9d3] disabled:text-[#8b938a] transition-colors"
            >
              {busy ? "Signing in..." : "Sign in"}
            </button>
          </div>
        </div>

        <p className="mt-5 text-center text-[11px] text-[#7f8f88]">
          Administrator and Staff accounts available
        </p>
      </div>
    </main>
  );
}
'@

Write-Host ""
Write-Host "  Done. Run: npm run build   then commit and push." -ForegroundColor Green
Write-Host ""
