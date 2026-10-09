import { useEffect, useState } from "react";
import Layout from "../components/Layout";
import api from "../api/client";

const LINE_OPTIONS = ["All", "Tube", "Fabrication", "Press Shop"];

const pct = (v) => (v == null ? "—" : `${(v * 100).toFixed(1)}%`);
const pct0 = (v) => (v == null ? "" : `${Math.round(v * 100)}%`);

// Matches the shop's own convention from the paper OEE sheet:
// >80% highlighted, <60% highlighted.
const cellClass = (v) => {
  if (v == null) return "";
  if (v >= 0.8) return "bg-green-100 text-green-800 font-medium";
  if (v < 0.6) return "bg-red-100 text-red-800 font-medium";
  return "";
};

// ---- Monthly "Production & OEE Report" grid helpers ----
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

const mean = (arr) => arr.reduce((s, v) => s + v, 0) / arr.length;
const dayOf = (e) => Number(e.entry_date.split("-")[2]);

export default function OeeReport() {
  const [line, setLine] = useState("All");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(false);

  // monthly grid
  const [gridMonth, setGridMonth] = useState(monthStr());
  const [gridEntries, setGridEntries] = useState([]);
  const [gridLoading, setGridLoading] = useState(false);
  const [selected, setSelected] = useState(null); // { operator, day|null }

  const load = async (selectedLine, from, to) => {
    setLoading(true);
    const params = { line: selectedLine };
    if (from) params.date_from = from;
    if (to) params.date_to = to;
    try {
      const entriesRes = await api.get("/production-log/entries", { params });
      setEntries(entriesRes.data);
    } catch {
      setEntries([]);
    }
    setLoading(false);
  };

  useEffect(() => {
    load(line, dateFrom, dateTo);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // The grid has its own month picker. Fetched a week at a time so a busy
  // month never runs into the 500-entry cap on a single request.
  useEffect(() => {
    let cancelled = false;
    setSelected(null);
    if (line === "Press Shop") {
      setGridEntries([]);
      return undefined;
    }
    const run = async () => {
      setGridLoading(true);
      const n = daysInMonth(gridMonth);
      const pad = (d) => String(d).padStart(2, "0");
      const ranges = [];
      for (let start = 1; start <= n; start += 7) {
        ranges.push([start, Math.min(start + 6, n)]);
      }
      try {
        const results = await Promise.all(
          ranges.map(([s, e]) =>
            api.get("/production-log/entries", {
              params: { line, date_from: `${gridMonth}-${pad(s)}`, date_to: `${gridMonth}-${pad(e)}` },
            })
          )
        );
        if (!cancelled) setGridEntries(results.flatMap((r) => r.data));
      } catch {
        if (!cancelled) setGridEntries([]);
      } finally {
        if (!cancelled) setGridLoading(false);
      }
    };
    run();
    return () => {
      cancelled = true;
    };
  }, [line, gridMonth]);

  const handleLineChange = (e) => {
    const l = e.target.value;
    setLine(l);
    load(l, dateFrom, dateTo);
  };
  const handleFromChange = (e) => {
    setDateFrom(e.target.value);
    load(line, e.target.value, dateTo);
  };
  const handleToChange = (e) => {
    setDateTo(e.target.value);
    load(line, dateFrom, e.target.value);
  };
  const clearDates = () => {
    setDateFrom("");
    setDateTo("");
    load(line, "", "");
  };

  const isPressShop = line === "Press Shop";

  const withOee = entries.filter((e) => e.oee != null);
  const avgOee = withOee.length ? withOee.reduce((s, e) => s + e.oee, 0) / withOee.length : null;
  const avgAvail = withOee.length ? withOee.reduce((s, e) => s + (e.availability || 0), 0) / withOee.length : null;
  const avgPerf = withOee.length ? withOee.reduce((s, e) => s + (e.performance || 0), 0) / withOee.length : null;
  const avgQual = withOee.length ? withOee.reduce((s, e) => s + (e.quality || 0), 0) / withOee.length : null;

  const totalStrokes = entries.reduce((s, e) => s + Number(e.produced_qty || e.ok_qty || 0), 0);
  const totalPlannedStrokes = entries.reduce((s, e) => s + Number(e.planned_qty || 0), 0);

  // ---- build the operator x day OEE grid ----
  // Press Shop is measured in strokes (see the note at the top), so it is
  // left out of this OEE grid even when Line = All.
  const gridRows = gridEntries.filter((e) => e.oee != null && e.line !== "Press Shop");
  const days = gridRows.map(dayOf);
  const lastDay = days.length ? Math.max(...days) : 0; // only show days up to the last one with data
  const dayNumbers = Array.from({ length: lastDay }, (_, i) => i + 1);
  const gridOperators = [...new Set(gridRows.map((e) => e.operator_name || "—"))].sort((a, b) => a.localeCompare(b));

  // operator -> day -> [oee, oee, ...]
  const cells = {};
  gridRows.forEach((e) => {
    const op = e.operator_name || "—";
    const d = dayOf(e);
    cells[op] = cells[op] || {};
    cells[op][d] = cells[op][d] || [];
    cells[op][d].push(Number(e.oee));
  });

  // A day's cell = average OEE of that operator's entries that day.
  const dayOee = (op, d) => (cells[op]?.[d] ? mean(cells[op][d]) : null);
  // Average = average of the day values (days with no entry aren't counted).
  const opAvg = (op) => {
    const vals = dayNumbers.map((d) => dayOee(op, d)).filter((v) => v != null);
    return vals.length ? mean(vals) : null;
  };

  // Entries behind a clicked operator (all month) or a clicked day cell.
  const detailRows = selected
    ? gridRows
        .filter(
          (e) =>
            (e.operator_name || "—") === selected.operator &&
            (selected.day == null || dayOf(e) === selected.day)
        )
        .sort(
          (a, b) =>
            (a.entry_date || "").localeCompare(b.entry_date || "") ||
            (a.start_time || "").localeCompare(b.start_time || "")
        )
    : [];

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">OEE Report</h1>
      <p className="text-sm text-ink-soft mb-5">
        {isPressShop
          ? "Press Shop is measured in strokes, not OEE %."
          : "Calculated automatically from Production Log entries — Availability × Performance × Quality."}
      </p>

      <div className="card mb-6">
        <div className="flex flex-wrap items-end gap-4">
          <div>
            <label className="label">Line</label>
            <select className="input w-48" value={line} onChange={handleLineChange}>
              {LINE_OPTIONS.map((l) => (
                <option key={l} value={l}>
                  {l}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="label">From Date</label>
            <input type="date" className="input w-44" value={dateFrom} onChange={handleFromChange} />
          </div>
          <div>
            <label className="label">To Date</label>
            <input type="date" className="input w-44" value={dateTo} onChange={handleToChange} />
          </div>
          {(dateFrom || dateTo) && (
            <button type="button" className="btn-secondary" onClick={clearDates}>
              Clear dates
            </button>
          )}
        </div>

        {isPressShop ? (
          <div className="mt-4 flex gap-6 text-sm">
            <div>
              Planned Strokes: <span className="font-semibold">{totalPlannedStrokes}</span>
            </div>
            <div>
              Actual Strokes: <span className="font-semibold">{totalStrokes} Strokes</span>
            </div>
          </div>
        ) : (
          <div className="mt-4 flex gap-6 text-sm">
            <div>
              Avg Availability: <span className="font-semibold">{pct(avgAvail)}</span>
            </div>
            <div>
              Avg Performance: <span className="font-semibold">{pct(avgPerf)}</span>
            </div>
            <div>
              Avg Quality: <span className="font-semibold">{pct(avgQual)}</span>
            </div>
            <div>
              Avg OEE: <span className="font-semibold">{pct(avgOee)}</span>
            </div>
          </div>
        )}
      </div>

      {!isPressShop && (
        <div className="card mb-6 overflow-x-auto">
          <div className="flex flex-wrap items-end justify-between gap-4 mb-3">
            <div>
              <div className="text-sm font-semibold">Production &amp; OEE Report</div>
              <div className="text-xs text-ink-soft">
                MONTH — {monthLabel(gridMonth)} · {line === "All" ? "All lines (Press Shop not included)" : line}
              </div>
            </div>
            <div>
              <label className="label">Month</label>
              <input type="month" className="input w-44" value={gridMonth} onChange={(e) => e.target.value && setGridMonth(e.target.value)} />
            </div>
          </div>
          <p className="text-xs text-ink-soft mb-2">
            Click an operator's name to see every entry behind their average, or click a day's % to see that day's entries.
          </p>

          <table className="table-base text-xs">
            <thead>
              <tr>
                <th>Sr.</th>
                <th>Operator Name</th>
                {dayNumbers.map((d) => (
                  <th key={d} className={`text-center ${isSunday(gridMonth, d) ? "bg-blue-100" : ""}`}>
                    {d}
                  </th>
                ))}
                <th className="text-center font-semibold">Average</th>
              </tr>
            </thead>
            <tbody>
              {gridOperators.map((op, i) => {
                const avg = opAvg(op);
                return (
                  <tr key={op}>
                    <td>{i + 1}</td>
                    <td
                      className={`font-medium whitespace-nowrap cursor-pointer underline decoration-dotted hover:bg-black/5 ${
                        selected && selected.operator === op && selected.day == null ? "bg-orange-50" : ""
                      }`}
                      onClick={() => setSelected({ operator: op, day: null })}
                    >
                      {op}
                    </td>
                    {dayNumbers.map((d) => {
                      const v = dayOee(op, d);
                      const sunday = isSunday(gridMonth, d);
                      if (v == null) {
                        return <td key={d} className={`text-center ${sunday ? "bg-blue-50" : ""}`} />;
                      }
                      const isSel = selected && selected.operator === op && selected.day === d;
                      return (
                        <td
                          key={d}
                          onClick={() => setSelected({ operator: op, day: d })}
                          className={`text-center cursor-pointer ${cellClass(v)} ${isSel ? "ring-2 ring-inset ring-orange-400" : ""}`}
                          title="Click to see this day's entries"
                        >
                          {pct0(v)}
                        </td>
                      );
                    })}
                    <td className={`text-center font-semibold ${cellClass(avg)}`}>{pct0(avg)}</td>
                  </tr>
                );
              })}
              {!gridLoading && gridOperators.length === 0 && (
                <tr>
                  <td colSpan={3} className="text-center text-ink-soft py-6">
                    No entries with complete OEE data for {monthLabel(gridMonth)} yet.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
          <p className="text-xs text-ink-soft mt-3">
            A day's % = average OEE of that operator's entries that day. Average = average of the day values (days with no entry aren't counted). Entries where OEE couldn't be calculated (start/end time or quantities missing) are left out. Press Shop is measured in strokes, so it isn't in this report.
          </p>
        </div>
      )}

      {!isPressShop && selected && (
        <div className="card mb-6">
          <div className="flex items-center justify-between mb-3">
            <div className="text-sm font-semibold">
              {selected.day == null
                ? `${selected.operator} — Entries behind the average (${monthLabel(gridMonth)})`
                : `${selected.operator} — ${selected.day} ${monthLabel(gridMonth)} — Entries`}
            </div>
            <button type="button" className="btn-secondary text-xs" onClick={() => setSelected(null)}>
              Close
            </button>
          </div>
          <table className="table-base text-xs">
            <thead>
              <tr>
                <th>Date</th>
                <th>Line</th>
                <th>Part</th>
                <th>Operation</th>
                <th>Machine</th>
                <th>Std. Cycle (sec)</th>
                <th>Total (min)</th>
                <th>Down (min)</th>
                <th>Run (min)</th>
                <th>Availability</th>
                <th>Performance</th>
                <th>Quality</th>
                <th>OEE</th>
              </tr>
            </thead>
            <tbody>
              {detailRows.map((e) => (
                <tr key={e.id}>
                  <td>{e.entry_date}</td>
                  <td>{e.line}</td>
                  <td>{e.part_number}</td>
                  <td>{e.operation_name}</td>
                  <td>{e.machine_no || "—"}</td>
                  <td>{e.standard_cycle_time_sec ?? "—"}</td>
                  <td>{e.total_time_min ?? "—"}</td>
                  <td>{e.down_time_min ?? "—"}</td>
                  <td>{e.run_time_min ?? "—"}</td>
                  <td className={cellClass(e.availability)}>{pct(e.availability)}</td>
                  <td className={cellClass(e.performance)}>{pct(e.performance)}</td>
                  <td className={cellClass(e.quality)}>{pct(e.quality)}</td>
                  <td className={cellClass(e.oee)}>{pct(e.oee)}</td>
                </tr>
              ))}
              {detailRows.length === 0 && (
                <tr>
                  <td colSpan={13} className="text-center text-ink-soft py-4">
                    No entries found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {isPressShop && (
        <div className="card">
          <div className="text-sm font-semibold mb-3">Press Shop — Strokes</div>
          <table className="table-base text-xs">
            <thead>
              <tr>
                <th>Date</th>
                <th>Part</th>
                <th>Operation</th>
                <th>Machine</th>
                <th>Operator</th>
                <th>Planned Strokes</th>
                <th>Actual Strokes</th>
              </tr>
            </thead>
            <tbody>
              {entries.map((e) => (
                <tr key={e.id}>
                  <td>{e.entry_date}</td>
                  <td>{e.part_number}</td>
                  <td>{e.operation_name}</td>
                  <td>{e.machine_no || "—"}</td>
                  <td>{e.operator_name || "—"}</td>
                  <td>{e.planned_qty ?? "—"}</td>
                  <td className="font-medium">{e.produced_qty != null ? `${e.produced_qty} Strokes` : "—"}</td>
                </tr>
              ))}
              {!loading && entries.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center text-ink-soft py-4">
                    No entries found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </Layout>
  );
}
