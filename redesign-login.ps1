$ErrorActionPreference='Stop'
$root = "D:\dev\opsys-property-management"
if (-not (Test-Path (Join-Path $root 'package.json'))) { Write-Host "  Project not found at $root" -ForegroundColor Red; exit 1 }
function Save-File($p,$c){ $f=Join-Path $root $p; $d=Split-Path $f -Parent
 if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
 $e=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($f,$c,$e)
 Write-Host "  [ok] $p" -ForegroundColor Green }
Write-Host ""; Write-Host "  Redesigning sign in page" -ForegroundColor Cyan; Write-Host ""

Save-File 'app/globals.css' @'
@import "tailwindcss";

/* Opsys Pro - design tokens.
   Palette supplied by Hamza and approved (Decision 22).

   Every value below is a literal hex. Tailwind v4 cannot generate utility
   classes from tokens that reference other tokens via var(), which is why
   bg-forest and bg-surface silently did nothing in the first version. */

@theme {
  /* the five approved values */
  --color-forest: #07332c;
  --color-slate: #485046;
  --color-sage: #afb7ac;
  --color-brass: #bca879;
  --color-paper: #ededed;

  /* semantic roles - literal values, not var() references */
  --color-bg: #ededed;
  --color-surface: #ffffff;
  --color-ink: #07332c;
  --color-ink-muted: #485046;
  --color-line: #afb7ac;
  --color-accent: #bca879;

  /* status colours (sections 7 and 8) */
  --color-status-vacant: #afb7ac;
  --color-status-occupied: #07332c;
  --color-status-pending: #bca879;
  --color-status-active: #07332c;
  --color-status-moveout: #485046;
  --color-status-closed: #afb7ac;

  /* the one hue outside the palette - a delete confirmation cannot be
     sage green. Desaturated so it still sits with the scheme. */
  --color-danger: #8c3a30;

  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "IBM Plex Mono", ui-monospace, monospace;

  --radius-card: 0.5rem;
}

/* References like PRP-0001 are data, not prose, so they take the mono face
   and stay scannable in dense tables. */
.ref {
  font-family: var(--font-mono);
  font-size: 0.8125rem;
  letter-spacing: 0.02em;
  color: #485046;
}

body {
  background: #ededed;
  color: #07332c;
}

:focus-visible {
  outline: 2px solid #07332c;
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
'@

Save-File 'app/login/page.tsx' @'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";

// Section 5 - sign in as Administrator or Staff User.
// Split layout: the brand panel carries the deep forest green so the palette
// is established before the reviewer reaches the dashboard.

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
      setError("That email and password do not match an account. Check both and try again.");
      setBusy(false);
      return;
    }

    router.push("/dashboard");
    router.refresh();
  }

  return (
    <main className="min-h-screen flex flex-col lg:flex-row">
      {/* Brand panel */}
      <div className="bg-[#07332c] text-white lg:w-[44%] px-8 py-10 lg:px-14 lg:py-16 flex flex-col justify-between">
        <div>
          <p className="font-mono text-xs tracking-[0.2em] text-[#bca879]">OPSYS PRO</p>
          <h1 className="mt-6 text-3xl lg:text-4xl font-medium leading-tight">
            Property
            <br />
            Management
            <br />
            System
          </h1>
          <div className="mt-6 h-px w-16 bg-[#bca879]" />
          <p className="mt-6 text-sm text-[#afb7ac] max-w-xs leading-relaxed">
            Properties, units, tenants and documents in one connected record.
          </p>
        </div>

        <div className="hidden lg:block mt-12">
          <div className="flex items-center gap-3 text-xs text-[#afb7ac]">
            <span className="rounded border border-[#485046] px-2 py-1">Property</span>
            <span>-&gt;</span>
            <span className="rounded border border-[#485046] px-2 py-1">Unit</span>
            <span>-&gt;</span>
            <span className="rounded border border-[#485046] px-2 py-1">Tenant</span>
          </div>
        </div>
      </div>

      {/* Form panel */}
      <div className="flex-1 bg-[#ededed] flex items-center justify-center px-6 py-12">
        <div className="w-full max-w-sm">
          <h2 className="text-xl font-medium text-[#07332c]">Sign in</h2>
          <p className="mt-1 text-sm text-[#485046]">
            Use your administrator or staff account.
          </p>

          <div className="mt-7">
            <label className="block text-sm font-medium text-[#07332c]" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && signIn()}
              className="mt-1.5 w-full rounded-md border border-[#afb7ac] bg-white px-3 py-2.5 text-sm text-[#07332c] outline-none focus:border-[#07332c]"
            />

            <label
              className="mt-5 block text-sm font-medium text-[#07332c]"
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
              className="mt-1.5 w-full rounded-md border border-[#afb7ac] bg-white px-3 py-2.5 text-sm text-[#07332c] outline-none focus:border-[#07332c]"
            />

            {error && (
              <p className="mt-4 text-sm text-[#8c3a30]" role="alert">
                {error}
              </p>
            )}

            <button
              onClick={signIn}
              disabled={busy || !email || !password}
              className="mt-7 w-full rounded-md bg-[#07332c] px-4 py-3 text-sm font-medium text-white hover:bg-[#0a453b] disabled:bg-[#afb7ac] disabled:text-[#485046] transition-colors"
            >
              {busy ? "Signing in..." : "Sign in"}
            </button>
          </div>
        </div>
      </div>
    </main>
  );
}
'@

Save-File 'app/layout.tsx' @'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Opsys Pro Property Management System",
  description: "Properties, units, tenants and documents in one connected record.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
'@

Write-Host ""
Write-Host "  Done. Refresh the sign in page." -ForegroundColor Green
Write-Host ""
