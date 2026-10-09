import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import api from "../api/client";

const LINES = ["Tube", "Fabrication", "Press Shop"];

// Reference only, shown on the form -- matches the router's PLANNED_BREAKS exactly.
const PLANNED_BREAKDOWN = [
  { time: "9:00 AM – 9:10 AM", label: "Morning Setup" },
  { time: "1:00 PM – 1:30 PM", label: "Lunch" },
  { time: "3:30 PM – 3:40 PM", label: "Tea Break" },
  { time: "6:30 PM – 6:40 PM", label: "Tea Break" },
];

const todayStr = () => new Date().toISOString().slice(0, 10);

const emptyForm = {
  line: "",
  part_number: "",
  bom_item_name: "",
  entry_date: todayStr(),
  machine_no: "",
  operation_name: "",
  operator_name: "",
  start_time: "",
  end_time: "",
  planned_qty: "",
  produced_qty: "",
  ok_qty: "",
  ng_qty: "",
  rejection_reason: "",
  unplanned_down_time_min: "",
  down_time_reason: "",
};

const partLabel = (p) => (p.part_name ? `${p.part_name} ${p.part_number}` : p.part_number);
const pct = (v) => (v == null ? "—" : `${(v * 100).toFixed(1)}%`);

export default function ProductionEntry() {
  const [parts, setParts] = useState([]);
  const [reasons, setReasons] = useState([]);
  const [downReasons, setDownReasons] = useState([]);
  const [items, setItems] = useState([]);
  const [operations, setOperations] = useState([]);
  const [form, setForm] = useState(emptyForm);
  const [entries, setEntries] = useState([]);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const loadEntries = async () => {
    const res = await api.get("/production-log/entries", { params: { line: "All" } });
    setEntries(res.data);
  };

  useEffect(() => {
    api.get("/master-data/parts").then((r) => setParts(r.data));
    api.get("/master-data/rejection-reasons").then((r) => setReasons(r.data));
    api.get("/master-data/down-time-reasons").then((r) => setDownReasons(r.data));
    loadEntries();
  }, []);

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const handlePartChange = async (e) => {
    const partNumber = e.target.value;
    setForm({ ...form, part_number: partNumber, bom_item_name: "", operation_name: "" });
    setOperations([]);
    if (!partNumber) return setItems([]);
    try {
      const res = await api.get(`/production-log/parts/${encodeURIComponent(partNumber)}/items`);
      setItems(res.data);
    } catch {
      setItems([]);
    }
  };

  const handleItemChange = async (e) => {
    const itemName = e.target.value;
    setForm({ ...form, bom_item_name: itemName, operation_name: "" });
    if (!form.part_number) return setOperations([]);
    try {
      const res = await api.get(`/production-log/parts/${encodeURIComponent(form.part_number)}/operations`, {
        params: itemName ? { item_name: itemName } : {},
      });
      setOperations(res.data);
    } catch {
      setOperations([]);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      const payload = {
        line: form.line,
        part_number: form.part_number,
        bom_item_name: form.bom_item_name || null,
        entry_date: form.entry_date,
        machine_no: form.machine_no || null,
        operation_name: form.operation_name,
        operator_name: form.operator_name || null,
        start_time: form.start_time || null,
        end_time: form.end_time || null,
        planned_qty: form.planned_qty === "" ? null : Number(form.planned_qty),
        produced_qty: form.produced_qty === "" ? null : Number(form.produced_qty),
        ok_qty: form.ok_qty === "" ? null : Number(form.ok_qty),
        ng_qty: form.ng_qty === "" ? null : Number(form.ng_qty),
        rejection_reason: form.rejection_reason || null,
        unplanned_down_time_min: form.unplanned_down_time_min === "" ? null : Number(form.unplanned_down_time_min),
        down_time_reason: form.down_time_reason || null,
      };
      await api.post("/production-log/entries", payload);
      setForm({ ...emptyForm, line: form.line, part_number: form.part_number, bom_item_name: form.bom_item_name });
      await loadEntries();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save the entry.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Production Logs</h1>
      <p className="text-sm text-ink-soft mb-5">Log what happened on the shop floor — fixed breaks are deducted automatically; only add Unplanned Breakdown if something extra stopped the machine.</p>

      <motion.form onSubmit={handleSubmit} className="card mb-6" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
        <div className="text-sm font-semibold mb-3">New Entry</div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label className="label">Line</label>
            <select name="line" className="input" value={form.line} onChange={handleChange} required>
              <option value="">Select…</option>
              {LINES.map((l) => (
                <option key={l} value={l}>
                  {l}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Part Number</label>
            <select name="part_number" className="input" value={form.part_number} onChange={handlePartChange} required>
              <option value="">Select…</option>
              {parts.map((p) => (
                <option key={p.part_number} value={p.part_number}>
                  {partLabel(p)}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Item</label>
            <select name="bom_item_name" className="input" value={form.bom_item_name} onChange={handleItemChange} disabled={!form.part_number}>
              <option value="">{form.part_number ? (items.length ? "Select…" : "No items in Master Data") : "Pick a part first"}</option>
              {items.map((it) => (
                <option key={it} value={it}>
                  {it}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Date</label>
            <input name="entry_date" type="date" className="input" value={form.entry_date} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Operation Name</label>
            <select name="operation_name" className="input" value={form.operation_name} onChange={handleChange} required disabled={!form.part_number}>
              <option value="">{form.part_number ? "Select…" : "Pick a part first"}</option>
              {operations.map((op) => (
                <option key={op} value={op}>
                  {op}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Machine No.</label>
            <input name="machine_no" className="input" placeholder="Type machine no." value={form.machine_no} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Operator Name</label>
            <input name="operator_name" className="input" value={form.operator_name} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Operation Start Time</label>
            <input name="start_time" type="time" className="input" value={form.start_time} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Operation End Time</label>
            <input name="end_time" type="time" className="input" value={form.end_time} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Planned Qty</label>
            <input name="planned_qty" type="number" className="input" value={form.planned_qty} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Produced Qty</label>
            <input name="produced_qty" type="number" className="input" value={form.produced_qty} onChange={handleChange} />
          </div>
          <div>
            <label className="label">OK Qty</label>
            <input name="ok_qty" type="number" className="input" value={form.ok_qty} onChange={handleChange} />
          </div>
          <div>
            <label className="label">NG Qty</label>
            <input name="ng_qty" type="number" className="input" value={form.ng_qty} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Reason for Rejection</label>
            <select name="rejection_reason" className="input" value={form.rejection_reason} onChange={handleChange}>
              <option value="">—</option>
              {reasons.map((r) => (
                <option key={r.id} value={r.reason}>
                  {r.reason}
                  {r.category ? ` (${r.category})` : ""}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Unplanned Breakdown (min)</label>
            <input name="unplanned_down_time_min" type="number" className="input" placeholder="e.g. 20" value={form.unplanned_down_time_min} onChange={handleChange} />
          </div>
          <div>
            <label className="label">Down Time Reason</label>
            <select name="down_time_reason" className="input" value={form.down_time_reason} onChange={handleChange}>
              <option value="">—</option>
              {downReasons.map((r) => (
                <option key={r.id} value={r.reason}>
                  {r.reason}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="mt-4 border rounded-lg p-3 bg-black/5">
          <div className="text-xs font-semibold mb-2">Planned Breakdown (fixed — subtracted automatically from Start/End Time, don't enter it yourself)</div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs text-ink-soft">
            {PLANNED_BREAKDOWN.map((b, i) => (
              <div key={i}>
                <span className="font-medium text-ink">{b.time}</span> — {b.label}
              </div>
            ))}
          </div>
        </div>

        {error && <div className="text-sm text-danger mt-3">{error}</div>}
        <button type="submit" disabled={saving} className="btn-primary mt-4">
          {saving ? "Saving…" : "Save Entry"}
        </button>
      </motion.form>

      <div className="card">
        <div className="text-sm font-semibold mb-3">Recent Entries</div>
        <table className="table-base text-xs">
          <thead>
            <tr>
              <th>Date</th>
              <th>Line</th>
              <th>Part</th>
              <th>Item</th>
              <th>Operation</th>
              <th>Machine No.</th>
              <th>Operator</th>
              <th>Total (min)</th>
              <th>Down (min)</th>
              <th>Planned</th>
              <th>Produced</th>
              <th>OK</th>
              <th>NG</th>
              <th>Rejection Reason</th>
              <th>OEE</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((e) => (
              <tr key={e.id}>
                <td>{e.entry_date}</td>
                <td>{e.line}</td>
                <td>{e.part_number}</td>
                <td>{e.bom_item_name || "—"}</td>
                <td>{e.operation_name}</td>
                <td>{e.machine_no || "—"}</td>
                <td>{e.operator_name || "—"}</td>
                <td>{e.total_time_min ?? "—"}</td>
                <td>{e.down_time_min ?? "—"}</td>
                <td>{e.planned_qty ?? "—"}</td>
                <td>{e.produced_qty ?? "—"}</td>
                <td>{e.ok_qty ?? "—"}</td>
                <td>{e.ng_qty ?? "—"}</td>
                <td>{e.rejection_reason || "—"}</td>
                <td>{pct(e.oee)}</td>
              </tr>
            ))}
            {entries.length === 0 && (
              <tr>
                <td colSpan={15} className="text-center text-ink-soft py-4">
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
