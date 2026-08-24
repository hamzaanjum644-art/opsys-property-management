import Shell from "@/components/shell";
import TenantForm from "@/components/tenant-form";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

// Section 8 - create a tenant linked to a specific Unit and Property.
// Section 18 - "Create Tenant and assign them to a Unit" in one step.

export const dynamic = "force-dynamic";

export default async function NewTenantPage() {
  await requireAdmin();

  const properties = await prisma.property.findMany({
    where: { status: "ACTIVE" },
    select: {
      id: true,
      name: true,
      reference: true,
      units: {
        where: { currentTenantId: null },
        select: { id: true, flatNumber: true },
        orderBy: { reference: "asc" },
      },
    },
    orderBy: { reference: "asc" },
  });

  return (
    <Shell title="New tenant" subtitle="Assign the tenant to a unit as you create them.">
      <TenantForm groups={properties} />
    </Shell>
  );
}