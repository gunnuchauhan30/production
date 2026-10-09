import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Layout from "../components/Layout";
import { useAuth } from "../context/AuthContext";
import api from "../api/client";

export default function PdiChecklist() {
  const [tab, setTab] = useState("in_process");
  const [routeCards, setRouteCards] = useState([]);
  const [selected, setSelected] = useState("");
  const [remarks, setRemarks] = useState("");
  const [error, setError] = useState("");
  const [history, setHistory] = useState([]);
  const { user } = useAuth();

  const canFinal = user?.role === "qa" || user?.role === "admin";

  useEffect(() => {
    api.get("/route-cards").then((r) => setRouteCards(r.data));
  }, []);

  const loadHistory = async (routeCardId) => {
    if (!routeCardId) return setHistory([]);
    const res = await api.get("/pdi-checks", { params: { route_card_id: routeCardId } });
    setHistory(res.data);
  };

  const handleSelect = async (e) => {
    setSelected(e.target.value);
    await loadHistory(e.target.value);
  };

  const record = async (result) => {
    setError("");
    if (!selected) return setError("Select a route card first.");
    try {
      await api.post("/pdi-checks", { route_card_id: Number(selected), stage: tab, result, remarks });
      setRemarks("");
      await loadHistory(selected);
    } catch (err) {
      setError(err.response?.data?.detail || "Could not record the PDI check.");
    }
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">PDI Checklist</h1>
      <p className="text-sm text-ink-soft mb-5">Two quality gates: a quick in-process check, then a final QA sign-off before dispatch.</p>

      <div className="flex gap-2 mb-5">
        <button
          onClick={() => setTab("in_process")}
          className={tab === "in_process" ? "btn-primary" : "btn-secondary"}
        >
          In-process
        </button>
        <button
          onClick={() => setTab("final")}
          className={tab === "final" ? "btn-primary" : "btn-secondary"}
        >
          Final {!canFinal && "(QA only)"}
        </button>
      </div>

      <div className="card mb-6">
        <label className="label">Route Card</label>
        <select className="input max-w-md" value={selected} onChange={handleSelect}>
          <option value="">Select a route card…</option>
          {routeCards.map((rc) => (
            <option key={rc.id} value={rc.id}>
              {rc.job_card_no} — {rc.part_number}
            </option>
          ))}
        </select>

        <AnimatePresence mode="wait">
          <motion.div
            key={tab}
            initial={{ opacity: 0, x: 8 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -8 }}
            transition={{ duration: 0.2 }}
            className="mt-4"
          >
            <label className="label">Remarks (required on Fail)</label>
            <textarea className="input" rows={2} value={remarks} onChange={(e) => setRemarks(e.target.value)} />
            {tab === "final" && !canFinal && (
              <div className="text-sm text-warning mt-2">Only QA or Admin roles can record a final-stage result.</div>
            )}
            {error && <div className="text-sm text-danger mt-2">{error}</div>}
            <div className="flex gap-3 mt-3">
              <button onClick={() => record("pass")} disabled={tab === "final" && !canFinal} className="btn-success">
                Pass
              </button>
              <button onClick={() => record("fail")} disabled={tab === "final" && !canFinal} className="btn-danger">
                Fail
              </button>
            </div>
          </motion.div>
        </AnimatePresence>
      </div>

      {history.length > 0 && (
        <div className="card">
          <div className="text-sm font-semibold mb-3">History for this Route Card</div>
          <table className="table-base">
            <thead>
              <tr>
                <th>Stage</th>
                <th>Result</th>
                <th>Remarks</th>
                <th>Checked At</th>
              </tr>
            </thead>
            <tbody>
              {history.map((h) => (
                <tr key={h.id}>
                  <td className="capitalize">{h.stage.replace("_", " ")}</td>
                  <td className={h.result === "pass" ? "text-success font-medium" : "text-danger font-medium"}>{h.result}</td>
                  <td>{h.remarks || "\u2014"}</td>
                  <td>{new Date(h.checked_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Layout>
  );
}
