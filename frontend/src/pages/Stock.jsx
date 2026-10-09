import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import api from "../api/client";

export default function Stock() {
  const [items, setItems] = useState([]);
  const [shortage, setShortage] = useState([]);
  const [moveForm, setMoveForm] = useState({ material_name: "", movement_type: "in", qty: "", reason: "" });
  const [reorderForm, setReorderForm] = useState({ material_name: "", reorder_level: "" });
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const load = async () => {
    const [itemsRes, shortageRes] = await Promise.all([api.get("/stock/items"), api.get("/stock/shortage")]);
    setItems(itemsRes.data);
    setShortage(shortageRes.data);
  };

  useEffect(() => {
    load();
  }, []);

  const handleMovementSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      await api.post("/stock/movements", { ...moveForm, qty: Number(moveForm.qty) });
      setMoveForm({ material_name: "", movement_type: "in", qty: "", reason: "" });
      await load();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not log the movement.");
    } finally {
      setSaving(false);
    }
  };

  const handleReorderSubmit = async (e) => {
    e.preventDefault();
    setError("");
    try {
      await api.put("/stock/items/reorder-level", { ...reorderForm, reorder_level: Number(reorderForm.reorder_level) });
      setReorderForm({ material_name: "", reorder_level: "" });
      await load();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not update the reorder level.");
    }
  };

  const shortageSet = new Set(shortage.map((s) => s.material_name));

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Stock &amp; Shortage</h1>
      <p className="text-sm text-ink-soft mb-5">Manual stock log — current quantity is derived automatically from receipts and issues.</p>

      {shortage.length > 0 && (
        <motion.div className="card mb-6 border-danger/30" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
          <div className="text-sm font-semibold text-danger mb-3">Shortage Highlight — below reorder level</div>
          <table className="table-base">
            <thead>
              <tr>
                <th>Material</th>
                <th>Current</th>
                <th>Reorder Level</th>
                <th>Short By</th>
              </tr>
            </thead>
            <tbody>
              {shortage.map((s) => (
                <tr key={s.material_name}>
                  <td className="font-medium">{s.material_name}</td>
                  <td>{s.current_qty}</td>
                  <td>{s.reorder_level}</td>
                  <td className="text-danger font-semibold">{s.short_by}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </motion.div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <motion.form onSubmit={handleMovementSubmit} className="card" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <div className="text-sm font-semibold mb-3">Log a Stock Movement</div>
          <div className="space-y-3">
            <div>
              <label className="label">Material</label>
              <input
                className="input"
                value={moveForm.material_name}
                onChange={(e) => setMoveForm({ ...moveForm, material_name: e.target.value })}
                required
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Type</label>
                <select
                  className="input"
                  value={moveForm.movement_type}
                  onChange={(e) => setMoveForm({ ...moveForm, movement_type: e.target.value })}
                >
                  <option value="in">In (receipt)</option>
                  <option value="out">Out (issue)</option>
                </select>
              </div>
              <div>
                <label className="label">Qty</label>
                <input
                  type="number"
                  className="input"
                  value={moveForm.qty}
                  onChange={(e) => setMoveForm({ ...moveForm, qty: e.target.value })}
                  required
                />
              </div>
            </div>
            <div>
              <label className="label">Reason</label>
              <input className="input" value={moveForm.reason} onChange={(e) => setMoveForm({ ...moveForm, reason: e.target.value })} />
            </div>
          </div>
          <button type="submit" disabled={saving} className="btn-primary mt-4">
            {saving ? "Saving\u2026" : "Log Movement"}
          </button>
        </motion.form>

        <motion.form onSubmit={handleReorderSubmit} className="card" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <div className="text-sm font-semibold mb-3">Set Reorder Level</div>
          <div className="space-y-3">
            <div>
              <label className="label">Material</label>
              <input
                className="input"
                value={reorderForm.material_name}
                onChange={(e) => setReorderForm({ ...reorderForm, material_name: e.target.value })}
                required
              />
            </div>
            <div>
              <label className="label">Reorder Level</label>
              <input
                type="number"
                className="input"
                value={reorderForm.reorder_level}
                onChange={(e) => setReorderForm({ ...reorderForm, reorder_level: e.target.value })}
                required
              />
            </div>
          </div>
          <button type="submit" className="btn-secondary mt-4">
            Update
          </button>
        </motion.form>
      </div>

      {error && <div className="text-sm text-danger mb-4">{error}</div>}

      <div className="card">
        <div className="text-sm font-semibold mb-3">Current Stock</div>
        <table className="table-base">
          <thead>
            <tr>
              <th>Material</th>
              <th>Current Qty</th>
              <th>Reorder Level</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((i) => (
              <tr key={i.id}>
                <td className="font-medium">{i.material_name}</td>
                <td>{i.current_qty}</td>
                <td>{i.reorder_level}</td>
                <td>{shortageSet.has(i.material_name) && <span className="badge-danger">Short</span>}</td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={4} className="text-center text-ink-soft py-6">
                  No stock logged yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
