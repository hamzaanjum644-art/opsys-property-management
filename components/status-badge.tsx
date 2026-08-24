// Status colours are defined once here so Vacant/Occupied (section 7) and the
// four tenant states (section 8) read consistently everywhere in the app.

const STYLES: Record<string, string> = {
  VACANT: "bg-sage text-forest",
  OCCUPIED: "bg-forest text-white",
  PENDING: "bg-brass text-forest",
  ACTIVE: "bg-forest text-white",
  MOVE_OUT: "bg-slate text-white",
  CLOSED: "bg-sage text-forest",
  VERIFIED: "bg-forest text-white",
  REJECTED: "bg-danger text-white",
  INACTIVE: "bg-sage text-forest",
};

const LABELS: Record<string, string> = {
  VACANT: "Vacant",
  OCCUPIED: "Occupied",
  PENDING: "Pending",
  ACTIVE: "Active",
  MOVE_OUT: "Move-out",
  CLOSED: "Closed",
  VERIFIED: "Verified",
  REJECTED: "Rejected",
  INACTIVE: "Inactive",
  HMO: "HMO",
  SELF_CONTAINED: "Self-contained",
  NORTH: "North",
  SOUTH: "South",
  EAST: "East",
  WEST: "West",
};

export function label(value: string) {
  return LABELS[value] ?? value;
}

export default function StatusBadge({ status }: { status: string }) {
  return (
    <span
      className={`inline-block rounded px-2 py-0.5 text-xs ${STYLES[status] ?? "bg-sage text-forest"}`}
    >
      {label(status)}
    </span>
  );
}