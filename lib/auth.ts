import { redirect } from "next/navigation";
import { createClient } from "./supabase/server";
import { prisma } from "./prisma";
import type { UserRole } from "@prisma/client";

/**
 * Section 5 — Administrator / Staff User.
 *
 * Full role-based permissions are NOT required for the 2-day MVP, but the
 * application must be structured so they can be added later. That structure
 * is this file: every write path calls requireAdmin(), so tightening
 * permissions later means editing one function, not auditing every route.
 *
 * Hiding a button is presentation, not security. Server-side checks are the
 * real control.
 */

export type SessionUser = {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
};

export async function getCurrentUser(): Promise<SessionUser | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const appUser = await prisma.appUser.findUnique({ where: { id: user.id } });
  if (!appUser) return null;

  return {
    id: appUser.id,
    email: appUser.email,
    fullName: appUser.fullName,
    role: appUser.role,
  };
}

export async function requireUser(): Promise<SessionUser> {
  const user = await getCurrentUser();
  if (!user) redirect("/login");
  return user;
}

export async function requireAdmin(): Promise<SessionUser> {
  const user = await requireUser();
  if (user.role !== "ADMIN") {
    throw new Error("Only administrators can make this change.");
  }
  return user;
}

export function isAdmin(user: SessionUser | null) {
  return user?.role === "ADMIN";
}