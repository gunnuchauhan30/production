import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import api from "../api/client";

const LINES = ["Tube Line", "Fabrication Line"];

const empty = {
  entry_date: new Date().toISOString().slice(0, 10),
  line: "Fabrication Line",
  shift: "",
  operator_name: "",
  machine_no: "",
  operation_name: "",
  part_name: "",
  standard_cycle_time_sec: "",
  ok_qty: "",
  rejected_qty: "",
  rejection_reason: "",
  total_time_min: "",
  run_time_min: "",
  down_time_min: "",
  down_time_reason: "",
};

export default function OeeLog() {
  const [form, setForm] = useState(empty);
  const [rows, setRows] = useState([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [lineFilter, setLineFilter] = useState("All");

  const load = async (line) => {
    const params = line && line !== "All" ? { line } : {};
    const res = await api.get("/oee-entries", { params });
    setRows(res.data);
  };

  useEffect(() => {
    load(lineFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lineFilter]);

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      const numeric = ["standard_cycle_time_sec", "ok_qty", "rejected_qty", "total_time_min", "run_time_min", "down_time_min"];
      const payload = { ...form };
      numeric.forEach((k) => {
        payload[k] = payload[k] === "" ? undefined : Number(payload[k]);
      });
      await api.post("/oee-entries", payload);
      setForm({ ...empty, entry_date: form.entry_date, line: form.line });
      await load(lineFilter);
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save the entry.");
    } finally {
      setSaving(false);
    }
  };

  const oeePct = (v) => (v === null || v === undefined ? "\u2014" : `${(Number(v) * 100).toFixed(1)}%`);

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Daily OEE Log</h1>
      <p className="text-sm text-ink-soft mb-5">
        One row per shift / machine / operation — matches the paper OEE sheet exactly. Independent of route cards.
      </p>

      <div className="flex gap-2 mb-5">
        {["All", ...LINES].map((l) => (
          <button
            key={l}
            type="button"
            onClick={() => setLineFilter(l)}
            className={lineFilter === l ? "nav-item-active !inline-block px-4 py-1.5 text-xs" : "nav-item !inline-block px-4 py-1.5 text-xs"}
          >
            {l}
          </button>
        ))}
      </div>

      <motion.form onSubmit={handleSubmit} className="card mb-6" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label className="label">Date</label>
            <input name="entry_date" type="date" className="input" value={form.entry_date} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Line</label>
            <select name="line" className="input" value={form.line} onChange={handleChange} required>
              {LINES.map((l) => (
                <option key={l} value={l}>{l}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Shift</label>
            <input name="shift" className="input" value={form.shift} onChange={handleChange} placeholder="A / B / C" />
          </div>
          <div>
            <label className="label">Operator</label>
            <input name="operator_name" className="input" value={form.operator_name} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Machine No.</label>
            <input name="machine_no" className="input" value={form.machine_no} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Operation</label>
            <input name="operation_name" className="input" value={form.operation_name} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Part Name</label>
            <input name="part_name" className="input" value={form.part_name} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Std. Cycle Time (sec)</label>
            <input name="standard_cycle_time_sec" type="number" className="input" value={form.standard_cycle_time_sec} onChange={handleChange} />
          </div>
          <div>
            <label className="label">OK Qty</label>
            <input name="ok_qty" type="number" className="input" value={form.ok_qty} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Rejected Qty</label>
            <input name="rejected_qty" type="number" className="input" value={form.rejected_qty} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Rejection Reason</label>
            <input name="rejection_reason" className="input" value={form.rejection_reason} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Total Time (min)</label>
            <input name="total_time_min" type="number" className="input" value={form.total_time_min} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Run Time (min)</label>
            <input name="run_time_min" type="number" className="input" value={form.run_time_min} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Down Time (min)</label>
            <input name="down_time_min" type="number" className="input" value={form.down_time_min} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Down Time Reason</label>
            <input name="down_time_reason" className="input" value={form.down_time_reason} onChange={handleChange} />
          </div>
        </div>
        {error && <div className="text-sm text-danger mt-3">{error}</div>}
        <button type="submit" disabled={saving} className="btn-primary mt-4">
          {saving ? "Saving\u2026" : "Save OEE Entry"}
        </button>
      </motion.form>

      <div className="card overflow-x-auto">
        <div className="text-sm font-semibold mb-3">Recent Entries</div>
        <table className="table-base">
          <thead>
            <tr>
              <th>Date</th>
              <th>Line</th>
              <th>Shift</th>
              <th>Machine</th>
              <th>Operation</th>
              <th>OK</th>
              <th>Rej</th>
              <th>Avail.</th>
              <th>Perf.</th>
              <th>Qual.</th>
              <th>OEE</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td>{r.entry_date}</td>
                <td>{r.line}</td>
                <td>{r.shift}</td>
                <td>{r.machine_no}</td>
                <td>{r.operation_name}</td>
                <td>{r.ok_qty}</td>
                <td>{r.rejected_qty}</td>
                <td>{oeePct(r.availability)}</td>
                <td>{oeePct(r.performance)}</td>
                <td>{oeePct(r.quality)}</td>
                <td className="font-semibold">{oeePct(r.oee)}</td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={11} className="text-center text-ink-soft py-6">
                  No entries yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
