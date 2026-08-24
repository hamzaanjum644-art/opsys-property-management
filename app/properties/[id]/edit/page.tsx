import { notFound } from "next/navigation";
import Shell from "@/components/shell";
import PropertyForm from "@/components/property-form";
import { updateProperty } from "@/lib/actions/properties";
import { prisma } from "@/lib/prisma";
import { requireAdmin } from "@/lib/auth";

// Section 6 - "Edit a property."

export default async function EditPropertyPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  await requireAdmin();
  const { id } = await params;

  const property = await prisma.property.findUnique({ where: { id } });
  if (!property) notFound();

  const action = updateProperty.bind(null, id);

  return (
    <Shell title="Edit property" subtitle={property.reference}>
      <PropertyForm
        action={action}
        values={{
          name: property.name,
          address: property.address,
          region: property.region,
          type: property.type,
          status: property.status,
        }}
        submitLabel="Save changes"
        cancelHref={`/properties/${id}`}
      />
    </Shell>
  );
}