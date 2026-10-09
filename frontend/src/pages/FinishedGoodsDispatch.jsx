import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import Badge, { statusVariant } from "../components/Badge";
import api from "../api/client";

export default function FinishedGoodsDispatch() {
  const [fg, setFg] = useState([]);
  const [dispatches, setDispatches] = useState([]);
  const [routeCards, setRouteCards] = useState([]);
  const [form, setForm] = useState({ route_card_id: "", order_no: "", schedule_date: "", actual_dispatch_date: "", qty_dispatched: "" });
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const load = async () => {
    const [fgRes, dispatchRes, rcRes] = await Promise.all([
      api.get("/finished-goods"),
      api.get("/dispatch"),
      api.get("/route-cards"),
    ]);
    setFg(fgRes.data);
    setDispatches(dispatchRes.data);
    setRouteCards(rcRes.data);
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
      await api.post("/dispatch", {
        ...form,
        route_card_id: Number(form.route_card_id),
        qty_dispatched: form.qty_dispatched === "" ? undefined : Number(form.qty_dispatched),
      });
      setForm({ route_card_id: "", order_no: "", schedule_date: "", actual_dispatch_date: "", qty_dispatched: "" });
      await load();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save the dispatch.");
    } finally {
      setSaving(false);
    }
  };

  const jobCardFor = (routeCardId) => routeCards.find((rc) => rc.id === routeCardId)?.job_card_no || routeCardId;

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Finished Goods &amp; Dispatch</h1>
      <p className="text-sm text-ink-soft mb-5">Finished Goods rows appear automatically once a route card passes final PDI.</p>

      <div className="card mb-6">
        <div className="text-sm font-semibold mb-3">Finished Goods (auto-created)</div>
        <table className="table-base">
          <thead>
            <tr>
              <th>Route Card</th>
              <th>Qty</th>
              <th>FG Date</th>
            </tr>
          </thead>
          <tbody>
            {fg.map((f) => (
              <tr key={f.id}>
                <td className="font-medium">{jobCardFor(f.route_card_id)}</td>
                <td>{f.fg_qty}</td>
                <td>{f.fg_date}</td>
              </tr>
            ))}
            {fg.length === 0 && (
              <tr>
                <td colSpan={3} className="text-center text-ink-soft py-6">
                  No finished goods yet — pass a final PDI first.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <motion.form onSubmit={handleSubmit} className="card mb-6" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
        <div className="text-sm font-semibold mb-3">New Dispatch</div>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div>
            <label className="label">Route Card</label>
            <select name="route_card_id" className="input" value={form.route_card_id} onChange={handleChange} required>
              <option value="">Select…</option>
              {routeCards.map((rc) => (
                <option key={rc.id} value={rc.id}>
                  {rc.job_card_no}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Order No.</label>
            <input name="order_no" className="input" value={form.order_no} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Qty Dispatched</label>
            <input name="qty_dispatched" type="number" className="input" value={form.qty_dispatched} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Schedule Date</label>
            <input name="schedule_date" type="date" className="input" value={form.schedule_date} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Actual Dispatch Date</label>
            <input name="actual_dispatch_date" type="date" className="input" value={form.actual_dispatch_date} onChange={handleChange} />
          </div>
        </div>
        {error && <div className="text-sm text-danger mt-3">{error}</div>}
        <button type="submit" disabled={saving} className="btn-primary mt-4">
          {saving ? "Saving\u2026" : "Save Dispatch"}
        </button>
      </motion.form>

      <div className="card">
        <div className="text-sm font-semibold mb-3">Dispatch History</div>
        <table className="table-base">
          <thead>
            <tr>
              <th>Route Card</th>
              <th>Order No</th>
              <th>Schedule</th>
              <th>Actual</th>
              <th>Delay (days)</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {dispatches.map((d) => (
              <tr key={d.id}>
                <td className="font-medium">{jobCardFor(d.route_card_id)}</td>
                <td>{d.order_no || "\u2014"}</td>
                <td>{d.schedule_date || "\u2014"}</td>
                <td>{d.actual_dispatch_date || "\u2014"}</td>
                <td>{d.delay_days ?? "\u2014"}</td>
                <td>
                  <Badge variant={statusVariant(d.status)}>{d.status}</Badge>
                </td>
              </tr>
            ))}
            {dispatches.length === 0 && (
              <tr>
                <td colSpan={6} className="text-center text-ink-soft py-6">
                  No dispatches yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
