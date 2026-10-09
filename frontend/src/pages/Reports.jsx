import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import api from "../api/client";

const pct = (v) => (v === null || v === undefined ? "\u2014" : `${(Number(v) * 100).toFixed(1)}%`);

function SectionTable({ title, headers, rows, renderRow, emptyText }) {
  return (
    <div className="card overflow-x-auto mb-6">
      <div className="text-sm font-semibold mb-3">{title}</div>
      <table className="table-base">
        <thead>
          <tr>
            {headers.map((h) => (
              <th key={h}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => renderRow(r, i))}
          {rows.length === 0 && (
            <tr>
              <td colSpan={headers.length} className="text-center text-ink-soft py-6">
                {emptyText}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

export default function Reports() {
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [error, setError] = useState("");

  const load = async () => {
    setLoading(true);
    setError("");
    try {
      const params = {};
      if (dateFrom) params.date_from = dateFrom;
      if (dateTo) params.date_to = dateTo;
      const res = await api.get("/reports/summary", { params });
      setSummary(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || "Could not load reports.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleDownload = async () => {
    setDownloading(true);
    setError("");
    try {
      const params = {};
      if (dateFrom) params.date_from = dateFrom;
      if (dateTo) params.date_to = dateTo;
      const res = await api.get("/reports/export", { params, responseType: "blob" });

      const disposition = res.headers["content-disposition"] || "";
      const match = disposition.match(/filename="?([^"]+)"?/);
      const filename = match ? match[1] : "Chanda_PPC_Report.xlsx";

      const url = window.URL.createObjectURL(new Blob([res.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", filename);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      setError("Could not download the report.");
    } finally {
      setDownloading(false);
    }
  };

  const oeeHeaders = ["Operator", "Machine", "Entries", "OK Qty", "Rejected", "Availability", "Performance", "Quality", "OEE"];
  const renderOeeRow = (r, i) => (
    <tr key={i}>
      <td>{r.operator_name || "\u2014"}</td>
      <td>{r.machine_no || "\u2014"}</td>
      <td>{r.entries_count}</td>
      <td>{r.total_ok_qty}</td>
      <td>{r.total_rejected_qty}</td>
      <td>{pct(r.avg_availability)}</td>
      <td>{pct(r.avg_performance)}</td>
      <td>{pct(r.avg_quality)}</td>
      <td className="font-semibold">{pct(r.avg_oee)}</td>
    </tr>
  );

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Reports</h1>
      <p className="text-sm text-ink-soft mb-5">
        OEE (Tube Line &amp; Fabrication Line), Production Sheet and Press Stock — live from the data you enter across the app.
      </p>

      <motion.div className="card mb-6 flex flex-wrap items-end gap-4" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
        <div>
          <label className="label">From</label>
          <input type="date" className="input" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
        </div>
        <div>
          <label className="label">To</label>
          <input type="date" className="input" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
        </div>
        <button type="button" className="btn-primary" onClick={load} disabled={loading}>
          {loading ? "Loading\u2026" : "Apply Filter"}
        </button>
        <button type="button" className="btn-primary ml-auto" onClick={handleDownload} disabled={downloading}>
          {downloading ? "Preparing\u2026" : "\u2B07 Download Excel Report"}
        </button>
      </motion.div>

      {error && <div className="text-sm text-danger mb-4">{error}</div>}

      {summary && (
        <>
          <SectionTable
            title="OEE Summary — Tube Line"
            headers={oeeHeaders}
            rows={summary.oee_tube_line}
            renderRow={renderOeeRow}
            emptyText="No Tube Line OEE entries in this range."
          />

          <SectionTable
            title="OEE Summary — Fabrication Line"
            headers={oeeHeaders}
            rows={summary.oee_fabrication_line}
            renderRow={renderOeeRow}
            emptyText="No Fabrication Line OEE entries in this range."
          />

          <SectionTable
            title="Production Sheet"
            headers={["Date", "Part Number", "Operation", "Qty Produced", "OK Qty", "Rejected", "Rework"]}
            rows={summary.production}
            renderRow={(r, i) => (
              <tr key={i}>
                <td>{r.entry_date}</td>
                <td>{r.part_number || "\u2014"}</td>
                <td>{r.operation_name || "\u2014"}</td>
                <td>{r.qty_produced}</td>
                <td>{r.ok_qty}</td>
                <td>{r.rejected_qty}</td>
                <td>{r.rework_qty}</td>
              </tr>
            )}
            emptyText="No production entries in this range."
          />

          <SectionTable
            title="Press Stock — No. of Stocks (Strokes)"
            headers={["Machine", "Operator", "Entries", "Total Strokes", "Total Calculation"]}
            rows={summary.press_stock}
            renderRow={(r, i) => (
              <tr key={i}>
                <td>{r.machine_no || "\u2014"}</td>
                <td>{r.operator_name || "\u2014"}</td>
                <td>{r.entries_count}</td>
                <td>{r.total_strokes}</td>
                <td className="font-semibold">{r.total_calculation}</td>
              </tr>
            )}
            emptyText="No press stock entries in this range."
          />
        </>
      )}
    </Layout>
  );
}
