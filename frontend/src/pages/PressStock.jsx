import { useEffect, useState } from "react";
import Layout from "../components/Layout";
import api from "../api/client";

// Press Strokes — Operator Daily Strokes (automatic, built from Production
// Log entries where line = "Press Shop"). One row per operator, one column
// per day -- but only up to the last day that actually has an entry, so the
// table grows by itself day by day. After the last day come Total and
// Average. Sundays show as a shaded "WEEK END" column. Click any day's
// number to see that operator's time-slot breakdown for that date.

const monthStr = () => new Date().toISOString().slice(0, 7); // "2026-10"

const daysInMonth = (ym) => {
  const [y, m] = ym.split("-").map(Number);
  return new Date(y, m, 0).getDate();
};

const monthLabel = (ym) => {
  const [y, m] = ym.split("-").map(Number);
  return new Date(y, m - 1, 1).toLocaleString("en-US", { month: "long", year: "numeric" }).toUpperCase();
};

const isSunday = (ym, day) => {
  const [y, m] = ym.split("-").map(Number);
  return new Date(y, m - 1, day).getDay() === 0;
};

const fmtTime = (t) => (t ? t.slice(0, 5) : "—");

export default function PressStock() {
  const [month, setMonth] = useState(monthStr());
  const [logEntries, setLogEntries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState(null); // { operator, day }

  const load = async (ym) => {
    setLoading(true);
    try {
      const from = `${ym}-01`;
      const to = `${ym}-${String(daysInMonth(ym)).padStart(2, "0")}`;
      const res = await api.get("/production-log/entries", {
        params: { line: "Press Shop", date_from: from, date_to: to },
      });
      setLogEntries(res.data);
    } catch {
      setLogEntries([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load(month);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleMonthChange = (e) => {
    const ym = e.target.value;
    setMonth(ym);
    setSelected(null);
    load(ym);
  };

  // Only show days up to the last day that has data.
  const entryDays = logEntries.map((e) => Number(e.entry_date.split("-")[2]));
  const lastDay = entryDays.length ? Math.max(...entryDays) : 0;
  const dayNumbers = Array.from({ length: lastDay }, (_, i) => i + 1);

  const operators = [...new Set(logEntries.map((e) => e.operator_name || "—"))].sort();

  // operator -> day -> total strokes
  const pivot = {};
  logEntries.forEach((e) => {
    const op = e.operator_name || "—";
    const day = Number(e.entry_date.split("-")[2]);
    const strokes = Number(e.produced_qty ?? e.ok_qty ?? 0);
    pivot[op] = pivot[op] || {};
    pivot[op][day] = (pivot[op][day] || 0) + strokes;
  });

  const rowTotal = (op) => dayNumbers.reduce((s, d) => s + (pivot[op]?.[d] || 0), 0);
  // Average = Total / number of days that operator actually has strokes on.
  const rowAvg = (op) => {
    const worked = dayNumbers.filter((d) => pivot[op]?.[d]).length;
    return worked ? Math.round(rowTotal(op) / worked) : 0;
  };
  const colTotal = (d) => operators.reduce((s, op) => s + (pivot[op]?.[d] || 0), 0);
  const grandTotal = operators.reduce((s, op) => s + rowTotal(op), 0);
  const daysWithData = dayNumbers.filter((d) => colTotal(d) > 0).length;
  const grandAvg = daysWithData ? Math.round(grandTotal / daysWithData) : 0;

  // Detail rows for the clicked (operator, day) cell, in time order.
  const detailRows = selected
    ? logEntries
        .filter(
          (e) =>
            (e.operator_name || "—") === selected.operator &&
            Number(e.entry_date.split("-")[2]) === selected.day
        )
        .sort((a, b) => (a.start_time || "").localeCompare(b.start_time || ""))
    : [];

  const handleCellClick = (op, d) => {
    if (isSunday(month, d) || !pivot[op]?.[d]) return;
    setSelected({ operator: op, day: d });
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Press Strokes — Operator Daily Strokes</h1>
      <p className="text-sm text-ink-soft mb-5">
        Built automatically from Production Logs (Line = Press Shop) — nothing to enter here, just log entries in Production Logs. Click any day's number to see the time-slot breakdown.
      </p>

      <div className="card overflow-x-auto mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4 mb-4">
          <div className="text-sm font-semibold">{monthLabel(month)}</div>
          <div>
            <label className="label">Month</label>
            <input type="month" className="input w-44" value={month} onChange={handleMonthChange} />
          </div>
        </div>

        <table className="table-base text-xs">
          <thead>
            <tr>
              <th>Operator Name</th>
              {dayNumbers.map((d) =>
                isSunday(month, d) ? (
                  <th key={d} className="text-center bg-blue-100">{d}</th>
                ) : (
                  <th key={d} className="text-center">{d}</th>
                )
              )}
              <th className="text-center font-semibold">Total</th>
              <th className="text-center font-semibold">Average</th>
            </tr>
          </thead>
          <tbody>
            {operators.map((op) => (
              <tr key={op}>
                <td className="font-medium whitespace-nowrap">{op}</td>
                {dayNumbers.map((d) => {
                  if (isSunday(month, d)) {
                    return (
                      <td key={d} className="text-center bg-blue-50 text-ink-soft text-[10px] align-middle">
                        WEEK<br />END
                      </td>
                    );
                  }
                  const val = pivot[op]?.[d];
                  const isSelected = selected && selected.operator === op && selected.day === d;
                  return (
                    <td
                      key={d}
                      onClick={() => handleCellClick(op, d)}
                      className={`text-center ${val ? "cursor-pointer hover:bg-black/5 underline decoration-dotted" : ""} ${isSelected ? "bg-orange-100 font-semibold" : ""}`}
                      title={val ? "Click to see time-slot breakdown" : ""}
                    >
                      {val ? val : "—"}
                    </td>
                  );
                })}
                <td className="text-center font-semibold">{rowTotal(op)}</td>
                <td className="text-center font-semibold">{rowAvg(op)}</td>
              </tr>
            ))}
            {operators.length > 0 && (
              <tr className="border-t-2">
                <td className="font-semibold">Total</td>
                {dayNumbers.map((d) =>
                  isSunday(month, d) ? (
                    <td key={d} className="text-center bg-blue-50">—</td>
                  ) : (
                    <td key={d} className="text-center font-semibold">{colTotal(d) || "—"}</td>
                  )
                )}
                <td className="text-center font-semibold">{grandTotal}</td>
                <td className="text-center font-semibold">{grandAvg}</td>
              </tr>
            )}
            {!loading && operators.length === 0 && (
              <tr>
                <td colSpan={3} className="text-center text-ink-soft py-6">
                  No Press Shop entries for {monthLabel(month)} yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
        <p className="text-xs text-ink-soft mt-3">
          Average = Total ÷ number of days that operator has strokes logged. Bottom Average = Grand Total ÷ days with any entry.
        </p>
      </div>

      {selected && (
        <div className="card">
          <div className="flex items-center justify-between mb-3">
            <div className="text-sm font-semibold">
              {selected.operator} — {selected.day} {monthLabel(month)} — Time-wise Breakdown
            </div>
            <button type="button" className="btn-secondary text-xs" onClick={() => setSelected(null)}>
              Close
            </button>
          </div>
          <table className="table-base text-xs">
            <thead>
              <tr>
                <th>Start</th>
                <th>End</th>
                <th>Part</th>
                <th>Operation</th>
                <th>Item</th>
                <th>Machine</th>
                <th className="text-center">Strokes</th>
              </tr>
            </thead>
            <tbody>
              {detailRows.map((e) => (
                <tr key={e.id}>
                  <td>{fmtTime(e.start_time)}</td>
                  <td>{fmtTime(e.end_time)}</td>
                  <td>{e.part_number}</td>
                  <td>{e.operation_name}</td>
                  <td>{e.bom_item_name || "—"}</td>
                  <td>{e.machine_no || "—"}</td>
                  <td className="text-center font-medium">{e.produced_qty ?? e.ok_qty ?? "—"}</td>
                </tr>
              ))}
              <tr className="border-t-2">
                <td colSpan={6} className="font-semibold text-right">Total</td>
                <td className="text-center font-semibold">
                  {detailRows.reduce((s, e) => s + Number(e.produced_qty ?? e.ok_qty ?? 0), 0)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      )}
    </Layout>
  );
}
