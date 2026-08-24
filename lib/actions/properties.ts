"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";
import { friendlyDbError } from "@/lib/tenant-workflow";

// Section 6 (Property Register) and Section 7 (Unit Management).
// Section 19 requires validation of required fields â€” that is the Zod schema.
// Section 5: writes are Administrator-only, enforced server-side.

const PropertySchema = z.object({
  name: z.string().trim().min(1, "Property name is required."),
  address: z.string().trim().min(1, "Address is required."),
  region: z.enum(["NORTH", "SOUTH", "EAST", "WEST"]),
  type: z.enum(["HMO", "SELF_CONTAINED"]),
  status: z.enum(["ACTIVE", "INACTIVE"]),
});

const UnitSchema = z.object({
  propertyId: z.string().min(1),
  flatNumber: z.string().trim().min(1, "Flat number is required."),
});

export type ActionState = { error?: string } | undefined;

async function nextReference(prefix: string, seq: string) {
  const rows = await prisma.$queryRawUnsafe<{ next_reference: string }[]>(
    `SELECT next_reference('${prefix}', '${seq}')`
  );
  return rows[0].next_reference;
}

export async function createProperty(_prev: ActionState, formData: FormData): Promise<ActionState> {
  await requireAdmin();

  const parsed = PropertySchema.safeParse({
    name: formData.get("name"),
    address: formData.get("address"),
    region: formData.get("region"),
    type: formData.get("type"),
    status: formData.get("status"),
  });

  if (!parsed.success) {
    return { error: parsed.error.issues[0].message };
  }

  let id: string;
  try {
    const created = await prisma.property.create({
      data: { ...parsed.data, reference: await nextReference("PRP", "property_ref_seq") },
    });
    id = created.id;
  } catch (e) {
    return { error: friendlyDbError(e) ?? "Could not create the property. Try again." };
  }

  revalidatePath("/properties");
  revalidatePath("/dashboard");
  redirect(`/properties/${id}`);
}

export async function updateProperty(
  id: string,
  _prev: ActionState,
  formData: FormData
): Promise<ActionState> {
  await requireAdmin();

  const parsed = PropertySchema.safeParse({
    name: formData.get("name"),
    address: formData.get("address"),
    region: formData.get("region"),
    type: formData.get("type"),
    status: formData.get("status"),
  });

  if (!parsed.success) return { error: parsed.error.issues[0].message };

  try {
    await prisma.property.update({ where: { id }, data: parsed.data });
  } catch (e) {
    return { error: friendlyDbError(e) ?? "Could not save changes. Try again." };
  }

  revalidatePath("/properties");
  revalidatePath(`/properties/${id}`);
  redirect(`/properties/${id}`);
}

export async function createUnit(_prev: ActionState, formData: FormData): Promise<ActionState> {
  await requireAdmin();

  const parsed = UnitSchema.safeParse({
    propertyId: formData.get("propertyId"),
    flatNumber: formData.get("flatNumber"),
  });

  if (!parsed.success) return { error: parsed.error.issues[0].message };

  try {
    await prisma.unit.create({
      data: {
        ...parsed.data,
        reference: await nextReference("UNT", "unit_ref_seq"),
      },
    });
  } catch (e) {
    // Section 7: @@unique([propertyId, flatNumber]) surfaces here as P2002.
    const friendly = friendlyDbError(e);
    return {
      error:
        friendly === "That value is already in use. Try a different one."
          ? "That flat number already exists in this property."
          : friendly ?? "Could not add the unit. Try again.",
    };
  }

  revalidatePath(`/properties/${parsed.data.propertyId}`);
  revalidatePath("/dashboard");
  return undefined;
}