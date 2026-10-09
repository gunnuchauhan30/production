import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import api from "../api/client";

const empty = { job_card_no: "", part_number: "", material_name: "", issued_qty: "", department: "", customer: "" };

export default function RouteCards() {
  const [form, setForm] = useState(empty);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [cards, setCards] = useState([]);
  const [search, setSearch] = useState("");

  const load = async (q = "") => {
    const res = await api.get("/route-cards", { params: q ? { search: q } : {} });
    setCards(res.data);
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
      await api.post("/route-cards", { ...form, issued_qty: Number(form.issued_qty) });
      setForm(empty);
      await load(search);
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save the route card.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Route Card Entry</h1>
      <p className="text-sm text-ink-soft mb-5">
        Type in the header fields exactly as printed on the Store Route Card. This is a one-time manual entry — no live connection to Store.
      </p>

      <motion.form
        onSubmit={handleSubmit}
        className="card mb-6"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div>
            <label className="label">Job Card No.</label>
            <input name="job_card_no" className="input" value={form.job_card_no} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Part Number</label>
            <input name="part_number" className="input" value={form.part_number} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Material</label>
            <input name="material_name" className="input" value={form.material_name} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Issued Qty</label>
            <input name="issued_qty" type="number" className="input" value={form.issued_qty} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Department</label>
            <input name="department" className="input" value={form.department} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Customer</label>
            <input name="customer" className="input" value={form.customer} onChange={handleChange} />
          </div>
        </div>
        {error && <div className="text-sm text-danger mt-3">{error}</div>}
        <button type="submit" disabled={saving} className="btn-primary mt-4">
          {saving ? "Saving\u2026" : "Save Route Card"}
        </button>
      </motion.form>

      <div className="card">
        <div className="flex items-center justify-between mb-3">
          <div className="text-sm font-semibold">Existing Route Cards</div>
          <input
            className="input max-w-xs"
            placeholder="Search job card or part…"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              load(e.target.value);
            }}
          />
        </div>
        <table className="table-base">
          <thead>
            <tr>
              <th>Job Card No</th>
              <th>Part</th>
              <th>Material</th>
              <th>Issued Qty</th>
              <th>Customer</th>
            </tr>
          </thead>
          <tbody>
            {cards.map((rc) => (
              <tr key={rc.id}>
                <td className="font-medium">{rc.job_card_no}</td>
                <td>{rc.part_number}</td>
                <td>{rc.material_name || "\u2014"}</td>
                <td>{rc.issued_qty}</td>
                <td>{rc.customer || "\u2014"}</td>
              </tr>
            ))}
            {cards.length === 0 && (
              <tr>
                <td colSpan={5} className="text-center text-ink-soft py-6">
                  No route cards yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
