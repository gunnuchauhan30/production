import { useEffect, useState } from "react";
import Layout from "../components/Layout";
import api from "../api/client";

const LINE_OPTIONS = ["All", "Tube", "Fabrication"];
const pct = (v) => (v == null ? "—" : `${(v * 100).toFixed(1)}%`);

// Matches the shop's own convention from the paper OEE sheet:
// >80% highlighted, <60% highlighted.
const cellClass = (v) => {
  if (v == null) return "";
  if (v >= 0.8) return "bg-green-100 text-green-800 font-medium";
  if (v < 0.6) return "bg-red-100 text-red-800 font-medium";
  return "";
};

export default function ProductionReport() {
  const [line, setLine] = useState("All");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(false);

  const load = async (selectedLine, from, to) => {
    setLoading(true);
    try {
      const params = { line: selectedLine };
      if (from) params.date_from = from;
      if (to) params.date_to = to;
      const res = await api.get("/production-log/entries", { params });
      setEntries(res.data);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load(line, dateFrom, dateTo);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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

  const rangeText = dateFrom || dateTo ? ` (${dateFrom || "start"} to ${dateTo || "today"})` : "";

  const totals = entries.reduce(
    (acc, e) => {
      acc.planned += Number(e.planned_qty || 0);
      acc.produced += Number(e.produced_qty || 0);
      acc.ok += Number(e.ok_qty || 0);
      acc.ng += Number(e.ng_qty || 0);
      return acc;
    },
    { planned: 0, produced: 0, ok: 0, ng: 0 }
  );

  const withOee = entries.filter((e) => e.oee != null);
  const avgOee = withOee.length ? withOee.reduce((s, e) => s + e.oee, 0) / withOee.length : null;

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Production Report</h1>
      <p className="text-sm text-ink-soft mb-5">All Production Log entries — filter by line, with the full OEE breakdown. For operator-wise averages, see the OEE Report page.</p>

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

        <div className="mt-4 flex gap-6 text-sm">
          <div>
            Planned: <span className="font-semibold">{totals.planned}</span>
          </div>
          <div>
            Produced: <span className="font-semibold">{totals.produced}</span>
          </div>
          <div>
            OK: <span className="font-semibold text-success">{totals.ok}</span>
          </div>
          <div>
            NG: <span className="font-semibold text-danger">{totals.ng}</span>
          </div>
          <div>
            Avg OEE: <span className="font-semibold">{pct(avgOee)}</span>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="text-sm font-semibold mb-3">{line} — Entries{rangeText}</div>
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
              <th>Start</th>
              <th>End</th>
              <th>Planned</th>
              <th>Produced</th>
              <th>OK</th>
              <th>NG</th>
              <th>Rejection Reason</th>
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
            {entries.map((e) => (
              <tr key={e.id}>
                <td>{e.entry_date}</td>
                <td>{e.line}</td>
                <td>{e.part_number}</td>
                <td>{e.bom_item_name || "—"}</td>
                <td>{e.operation_name}</td>
                <td>{e.machine_no || "—"}</td>
                <td>{e.operator_name || "—"}</td>
                <td>{e.start_time || "—"}</td>
                <td>{e.end_time || "—"}</td>
                <td>{e.planned_qty ?? "—"}</td>
                <td>{e.produced_qty ?? "—"}</td>
                <td>{e.ok_qty ?? "—"}</td>
                <td>{e.ng_qty ?? "—"}</td>
                <td>{e.rejection_reason || "—"}</td>
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
            {!loading && entries.length === 0 && (
              <tr>
                <td colSpan={22} className="text-center text-ink-soft py-4">
                  No entries found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
