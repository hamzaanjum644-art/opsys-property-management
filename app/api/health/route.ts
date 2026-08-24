import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// Two jobs:
//  1. Confirms the Vercel deploy is alive and can reach Postgres.
//  2. Acts as the keep-alive ping. Supabase pauses free projects after a week
//     without database activity â€” this query counts as activity.
//
// Deliberately public (no auth) so a reviewer or an uptime pinger can hit it.

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const [properties, units, tenants] = await Promise.all([
      prisma.property.count(),
      prisma.unit.count(),
      prisma.tenant.count(),
    ]);

    return NextResponse.json({
      status: "ok",
      database: "connected",
      records: { properties, units, tenants },
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error("[opsys] Health check failed:", err);
    return NextResponse.json(
      { status: "error", database: "unreachable" },
      { status: 503 }
    );
  }
}