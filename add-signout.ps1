$ErrorActionPreference='Stop'
$root = "D:\dev\opsys-property-management"
if (-not (Test-Path (Join-Path $root 'package.json'))) { Write-Host "  Project not found at $root" -ForegroundColor Red; exit 1 }
function Save-File($p,$c){ $f=Join-Path $root $p; $d=Split-Path $f -Parent
 if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
 $e=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($f,$c,$e)
 Write-Host "  [ok] $p" -ForegroundColor Green }
Write-Host ""; Write-Host "  Adding sign out" -ForegroundColor Cyan; Write-Host ""

Save-File 'components/shell.tsx' @'
import Link from "next/link";
import { requireUser } from "@/lib/auth";
import SignOutButton from "@/components/sign-out-button";

// Shared chrome for every signed-in page. Nav order follows the lifecycle in
// project file section 3: Property -> Unit -> Tenant.

const NAV = [
  { href: "/dashboard", label: "Dashboard", icon: "M3 12h7V3H3v9zm0 9h7v-7H3v7zm11 0h7V12h-7v9zm0-18v7h7V3h-7z" },
  { href: "/properties", label: "Properties", icon: "M3 21h18M5 21V7l7-4 7 4v14M9 21v-6h6v6" },
  { href: "/tenants", label: "Tenants", icon: "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z" },
];

export default async function Shell({
  children,
  title,
  subtitle,
  action,
}: {
  children: React.ReactNode;
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  const user = await requireUser();

  return (
    <div className="min-h-screen flex bg-bg">
      <aside className="w-52 shrink-0 bg-forest text-white flex flex-col">
        <div className="px-5 py-6">
          <p className="font-mono text-[11px] tracking-widest text-brass">OPSYS PRO</p>
        </div>

        <nav className="flex-1">
          {NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center gap-3 px-5 py-2.5 text-sm text-sage hover:bg-slate hover:text-white transition-colors"
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d={item.icon} />
              </svg>
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="px-5 py-4 border-t border-slate">
          <p className="text-xs text-white">{user.fullName}</p>
          <p className="text-[11px] text-sage mt-0.5">{user.role}</p>
          <SignOutButton />
        </div>
      </aside>

      <main className="flex-1 min-w-0 px-8 py-7">
        <div className="flex items-start justify-between gap-4 mb-6">
          <div>
            <h1 className="text-xl font-medium text-ink">{title}</h1>
            {subtitle && <p className="text-sm text-ink-muted mt-0.5">{subtitle}</p>}
          </div>
          {action}
        </div>
        {children}
      </main>
    </div>
  );
}
'@

Save-File 'components/sign-out-button.tsx' @'
"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { createBrowserClient } from "@supabase/ssr";

// Section 5 — lets a reviewer switch between the Administrator and Staff
// accounts to see the permission difference.

export default function SignOutButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function signOut() {
    setBusy(true);
    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  return (
    <button
      onClick={signOut}
      disabled={busy}
      className="mt-2 text-[11px] text-sage hover:text-white underline disabled:opacity-50"
    >
      {busy ? "Signing out" : "Sign out"}
    </button>
  );
}
'@

Write-Host ""
Write-Host "  Done. Sign out appears at the bottom of the sidebar." -ForegroundColor Green
Write-Host ""
