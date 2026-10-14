import { useEffect, useMemo, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import Badge, { statusVariant } from "../components/Badge";
import api from "../api/client";
import { useAuth } from "../context/AuthContext";

const pad = (n) => String(n).padStart(2, "0");
const thisMonth = () => {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}`;
};
const monthLabel = (ym) => {
  const [y, m] = ym.split("-").map(Number);
  return new Date(y, m - 1, 1).toLocaleString("en-US", { month: "long", year: "numeric" });
};
const shortDay = (ym, day) => {
  const [y, m] = ym.split("-").map(Number);
  return `${day} ${new Date(y, m - 1, day).toLocaleString("en-US", { month: "short" })}`;
};
const partLabel = (p) => (p.part_name ? `${p.part_name} ${p.part_number}` : p.part_number);
const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

// Calendar cells for a month ("2026-10"), plus holiday / working-day counts.
// Every Sunday is a holiday automatically; holidayMap holds the extra ones (date -> name).
const monthInfo = (ym, holidayMap) => {
  const [y, m] = ym.split("-").map(Number);
  const firstWeekday = new Date(y, m - 1, 1).getDay(); // 0 = Sunday
  const totalDays = new Date(y, m, 0).getDate();
  const cells = [];
  for (let i = 0; i < firstWeekday; i++) cells.push(null);
  for (let d = 1; d <= totalDays; d++) {
    const iso = `${ym}-${pad(d)}`;
    const sunday = new Date(y, m - 1, d).getDay() === 0;
    cells.push({ day: d, iso, sunday, holiday: !sunday && holidayMap[iso] !== undefined, name: holidayMap[iso] || "" });
  }
  const days = cells.filter(Boolean);
  const sundays = days.filter((c) => c.sunday);
  const extra = days.filter((c) => c.holiday);
  return { cells, totalDays, sundays, extra, working: totalDays - sundays.length - extra.length };
};

export default function CustomerSchedule() {
  const { user } = useAuth();
  const canEditHolidays = ["admin", "planning"].includes(user?.role);

  const [rows, setRows] = useState([]);
  const [parts, setParts] = useState([]);
  const [form, setForm] = useState({ customer: "", part_number: "", qty: "", month: thisMonth() });
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const [calMonth, setCalMonth] = useState(thisMonth());
  const [holidays, setHolidays] = useState([]);
  const [holError, setHolError] = useState("");

  const load = async () => {
    const res = await api.get("/customer-schedule");
    setRows(res.data);
  };

  const loadHolidays = async (ym) => {
    try {
      const res = await api.get("/customer-schedule/holidays", { params: { month: ym } });
      setHolidays(res.data);
      setHolError("");
    } catch (err) {
      setHolidays([]);
      setHolError(err.response?.data?.detail || "Could not load holidays.");
    }
  };

  useEffect(() => {
    load();
    api.get("/master-data/parts").then((r) => setParts(r.data)).catch(() => setParts([]));
  }, []);

  useEffect(() => {
    loadHolidays(calMonth);
  }, [calMonth]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm({ ...form, [name]: value });
    if (name === "month" && value) setCalMonth(value); // calendar follows the month being planned
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSaving(true);
    try {
      await api.post("/customer-schedule", {
        customer: form.customer,
        part_number: form.part_number,
        qty: Number(form.qty),
        required_date: `${form.month}-01`,
      });
      setForm({ customer: "", part_number: "", qty: "", month: form.month });
      await load();
    } catch (err) {
      const d = err.response?.data?.detail;
      setError(typeof d === "string" ? d : "Could not save the schedule.");
    } finally {
      setSaving(false);
    }
  };

  const holidayMap = useMemo(() => {
    const map = {};
    holidays.forEach((h) => {
      map[h.holiday_date] = h.name || "";
    });
    return map;
  }, [holidays]);
  const info = useMemo(() => monthInfo(calMonth, holidayMap), [calMonth, holidayMap]);

  const toggleHoliday = async (cell) => {
    if (!canEditHolidays || cell.sunday) return;
    setHolError("");
    try {
      if (cell.holiday) {
        if (!window.confirm(`Remove the holiday on ${shortDay(calMonth, cell.day)}?`)) return;
        await api.delete(`/customer-schedule/holidays/${cell.iso}`);
      } else {
        const name = window.prompt(`Holiday on ${shortDay(calMonth, cell.day)} - name (optional, e.g. Gandhi Jayanti):`, "");
        if (name === null) return;
        await api.post("/customer-schedule/holidays", { holiday_date: cell.iso, name: name.trim() || null });
      }
      await loadHolidays(calMonth);
    } catch (err) {
      const d = err.response?.data?.detail;
      setHolError(typeof d === "string" ? d : "Could not update the holiday.");
    }
  };

  const partName = (partNumber) => {
    const p = parts.find((x) => x.part_number === partNumber);
    return p ? partLabel(p) : partNumber;
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Customer Schedule</h1>
      <p className="text-sm text-ink-soft mb-5">
        Monthly planning - check Stock &amp; Shortage before committing to a schedule.
      </p>

      <motion.form onSubmit={handleSubmit} className="card mb-6" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <label className="label">Customer</label>
            <input name="customer" className="input" value={form.customer} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Part Name</label>
            <select name="part_number" className="input" value={form.part_number} onChange={handleChange} required>
              <option value="">Select...</option>
              {parts.map((p) => (
                <option key={p.part_number} value={p.part_number}>
                  {partLabel(p)}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">Quantity</label>
            <input name="qty" type="number" min="1" className="input" value={form.qty} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Schedule Month</label>
            <input name="month" type="month" className="input" value={form.month} onChange={handleChange} required />
          </div>
        </div>
        {error && <div className="text-sm text-danger mt-3">{error}</div>}
        <button type="submit" disabled={saving} className="btn-primary mt-4">
          {saving ? "Saving..." : "Add Schedule"}
        </button>
      </motion.form>

      <div className="card mb-6 max-w-2xl">
        <div className="flex flex-wrap items-end justify-between gap-4 mb-3">
          <div>
            <div className="text-sm font-semibold">Holidays &amp; Working Days</div>
            <div className="text-xs text-ink-soft">
              Sundays are holidays automatically.
              {canEditHolidays
                ? " Click any other date to mark or unmark a holiday (e.g. 2 Oct)."
                : " Only an admin or planner can mark other holidays."}
            </div>
          </div>
          <div>
            <label className="label">Month</label>
            <input type="month" className="input w-44" value={calMonth} onChange={(e) => e.target.value && setCalMonth(e.target.value)} />
          </div>
        </div>

        {holError && <div className="text-sm text-danger mb-2">{holError}</div>}

        <div className="grid grid-cols-7 gap-1 text-center text-xs text-ink-soft mb-1">
          {WEEKDAYS.map((w) => (
            <div key={w} className={w === "Sun" ? "text-blue-700 font-medium" : ""}>
              {w}
            </div>
          ))}
        </div>
        <div className="grid grid-cols-7 gap-1">
          {info.cells.map((c, i) =>
            c === null ? (
              <div key={`blank-${i}`} />
            ) : (
              <button
                key={c.iso}
                type="button"
                onClick={() => toggleHoliday(c)}
                disabled={c.sunday || !canEditHolidays}
                title={c.sunday ? "Sunday" : c.holiday ? c.name || "Holiday" : canEditHolidays ? "Click to mark as holiday" : ""}
                className={`h-14 rounded-lg border text-sm flex flex-col items-center justify-center ${
                  c.sunday
                    ? "bg-blue-50 border-blue-100 text-blue-700"
                    : c.holiday
                    ? "bg-red-100 border-red-200 text-red-800 font-medium"
                    : "bg-white border-black/10 " + (canEditHolidays ? "hover:bg-black/5 cursor-pointer" : "")
                }`}
              >
                <span>{c.day}</span>
                {c.sunday && <span className="text-[10px] leading-none">Sun</span>}
                {c.holiday && <span className="text-[10px] leading-none truncate max-w-full px-1">{c.name || "Holiday"}</span>}
              </button>
            )
          )}
        </div>

        <div className="mt-4 text-sm space-y-1">
          <div>
            <span className="text-ink-soft">Sundays ({info.sundays.length}): </span>
            {info.sundays.map((c) => c.day).join(", ") || "-"}
          </div>
          <div>
            <span className="text-ink-soft">Other holidays ({info.extra.length}): </span>
            {info.extra.length
              ? info.extra.map((c) => `${shortDay(calMonth, c.day)}${c.name ? ` - ${c.name}` : ""}`).join(", ")
              : "-"}
          </div>
          <div className="font-semibold">
            Working days in {monthLabel(calMonth)}: {info.working} of {info.totalDays}
          </div>
        </div>
      </div>

      <div className="card">
        <table className="table-base">
          <thead>
            <tr>
              <th>Customer</th>
              <th>Part</th>
              <th>Qty</th>
              <th>Month</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td className="font-medium">{r.customer}</td>
                <td>{partName(r.part_number)}</td>
                <td>{r.qty}</td>
                <td>{monthLabel(r.required_date.slice(0, 7))}</td>
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
