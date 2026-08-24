import { PrismaClient } from "@prisma/client";

// Vercel serverless spins up many function instances. Without this singleton,
// each hot reload / invocation opens new Postgres connections and Supabase's
// free-tier pool is exhausted within minutes. This is the single most common
// cause of "too many connections" on this exact stack.

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;