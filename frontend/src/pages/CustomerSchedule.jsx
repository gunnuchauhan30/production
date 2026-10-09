import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import Badge, { statusVariant } from "../components/Badge";
import api from "../api/client";

export default function CustomerSchedule() {
  const [rows, setRows] = useState([]);
  const [form, setForm] = useState({ customer: "", part_number: "", qty: "", required_date: "" });
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const load = async () => {
    const res = await api.get("/customer-schedule");
    setRows(res.data);
  };

  useEffect(() => {
    load();
  }, []);

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      await api.post("/customer-schedule", { ...form, qty: Number(form.qty) });
      setForm({ customer: "", part_number: "", qty: "", required_date: "" });
      await load();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save the schedule.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Customer Schedule</h1>
      <p className="text-sm text-ink-soft mb-5">Planning entries — check Stock &amp; Shortage before committing to a schedule.</p>

      <motion.form onSubmit={handleSubmit} className="card mb-6" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label className="label">Customer</label>
            <input name="customer" className="input" value={form.customer} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Part Number</label>
            <input name="part_number" className="input" value={form.part_number} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Qty</label>
            <input name="qty" type="number" className="input" value={form.qty} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Required Date</label>
            <input name="required_date" type="date" className="input" value={form.required_date} onChange={handleChange} required />
          </div>
        </div>
        {error && <div className="text-sm text-danger mt-3">{error}</div>}
        <button type="submit" disabled={saving} className="btn-primary mt-4">
          {saving ? "Saving\u2026" : "Add Schedule"}
        </button>
      </motion.form>

      <div className="card">
        <table className="table-base">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Part</th>
              <th>Qty</th>
              <th>Required Date</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td className="font-medium">{r.customer}</td>
                <td>{r.part_number}</td>
                <td>{r.qty}</td>
                <td>{r.required_date}</td>
                <td>
                  <Badge variant={statusVariant(r.status)}>{r.status}</Badge>
                </td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={5} className="text-center text-ink-soft py-6">
                  No schedules yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
