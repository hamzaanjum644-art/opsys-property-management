import Shell from "@/components/shell";
import PropertyForm from "@/components/property-form";
import { createProperty } from "@/lib/actions/properties";
import { requireAdmin } from "@/lib/auth";

// Section 6 â€” "Create a property."

export default async function NewPropertyPage() {
  await requireAdmin();

  return (
    <Shell title="New property" subtitle="Units are added after the property is created.">
      <PropertyForm action={createProperty} submitLabel="Create property" cancelHref="/properties" />
    </Shell>
  );
}