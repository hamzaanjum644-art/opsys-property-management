import { PrismaClient, Region, PropertyType, UnitStatus, TenantStatus, Gender } from "@prisma/client";

const prisma = new PrismaClient();

// Section 14: fictional test data only. No real tenant or client information.

async function ref(prefix: string, seq: string) {
  const r = await prisma.$queryRawUnsafe<{ next_reference: string }[]>(
    `SELECT next_reference('${prefix}', '${seq}')`
  );
  return r[0].next_reference;
}

async function main() {
  console.log("Seeding Opsys Pro with fictional data…");

  const properties = [
    { name: "Ashgrove House", address: "14 Ashgrove Road, Leeds LS6 2QT", region: Region.NORTH, type: PropertyType.HMO, units: ["Flat 1A", "Flat 1B", "Flat 2A", "Flat 2B"] },
    { name: "Weaver Court", address: "8 Weaver Street, Manchester M4 5JR", region: Region.NORTH, type: PropertyType.SELF_CONTAINED, units: ["Apt 1", "Apt 2", "Apt 3"] },
    { name: "Pemberton Lodge", address: "52 Pemberton Lane, Bristol BS3 4NH", region: Region.SOUTH, type: PropertyType.HMO, units: ["Room 1", "Room 2", "Room 3", "Room 4", "Room 5"] },
  ];

  const created = [];
  for (const p of properties) {
    const property = await prisma.property.create({
      data: {
        reference: await ref("PRP", "property_ref_seq"),
        name: p.name,
        address: p.address,
        region: p.region,
        type: p.type,
      },
    });
    for (const flatNumber of p.units) {
      await prisma.unit.create({
        data: {
          reference: await ref("UNT", "unit_ref_seq"),
          flatNumber,
          propertyId: property.id,
          status: UnitStatus.VACANT,
        },
      });
    }
    created.push(property);
    console.log(`  ${property.reference}  ${property.name} (${p.units.length} units)`);
  }

  // One tenant left at PENDING so the reviewer can immediately press
  // "Complete move-in" and watch the unit flip to Occupied (section 18).
  const ashgrove = created[0];
  const firstUnit = await prisma.unit.findFirst({ where: { propertyId: ashgrove.id } });

  if (firstUnit) {
    const tenant = await prisma.tenant.create({
      data: {
        reference: await ref("TEN", "tenant_ref_seq"),
        fullName: "Marianne Okafor",
        dateOfBirth: new Date("1991-04-17"),
        gender: Gender.FEMALE,
        phone: "07700 900142",
        email: "m.okafor@example.test",
        status: TenantStatus.PENDING,
        propertyId: ashgrove.id,
        unitId: firstUnit.id,
      },
    });
    console.log(`  ${tenant.reference}  ${tenant.fullName} — PENDING in ${firstUnit.flatNumber}`);
  }

  console.log("Done.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());