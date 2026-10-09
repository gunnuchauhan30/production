import { motion } from "framer-motion";

export default function StatCard({ label, value, tone = "default", delay = 0 }) {
  const toneClass =
    tone === "danger" ? "text-danger" : tone === "warning" ? "text-warning" : tone === "success" ? "text-success" : "text-brand";

  return (
    <motion.div
      className="card"
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, delay }}
    >
      <div className="label">{label}</div>
      <div className={`text-3xl font-semibold mt-1 ${toneClass}`}>{value}</div>
    </motion.div>
  );
}
