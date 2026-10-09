const VARIANTS = {
  success: "badge-success",
  warning: "badge-warning",
  danger: "badge-danger",
  info: "badge-info",
};

export default function Badge({ variant = "info", children }) {
  return <span className={VARIANTS[variant] || VARIANTS.info}>{children}</span>;
}

// Maps common status strings across the app to a consistent color.
export function statusVariant(status) {
  const s = (status || "").toLowerCase();
  if (["ok", "on_time", "pass", "planned", "issued", "complete"].includes(s)) return "success";
  if (["pending", "shortage", "hold", "in_process"].includes(s)) return "warning";
  if (["delayed", "fail", "rejected"].includes(s)) return "danger";
  return "info";
}
