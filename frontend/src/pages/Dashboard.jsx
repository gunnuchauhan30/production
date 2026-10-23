import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import StatCard from "../components/StatCard";
import Badge, { statusVariant } from "../components/Badge";
import api from "../api/client";

export default function Dashboard() {
  const [routeCards, setRouteCards] = useState([]);
  const [delayedDispatch, setDelayedDispatch] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const [rcRes, dispatchRes] = await Promise.all([
          api.get("/route-cards"),
          api.get("/dispatch", { params: { status_filter: "delayed" } }),
        ]);
        setRouteCards(rcRes.data);
        setDelayedDispatch(dispatchRes.data.length);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-5">Production Dashboard</h1>

      <div className="grid grid-cols-2 gap-4 mb-6">
        <StatCard label="Route Cards" value={routeCards.length} delay={0} />
        <StatCard label="Delayed Dispatches" value={delayedDispatch} tone="danger" delay={0.05} />
      </div>

      <motion.div className="card" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2 }}>
        <div className="text-sm font-semibold mb-3">Recent Route Cards</div>
        {loading ? (
          <div className="text-sm text-ink-soft">Loading…</div>
        ) : routeCards.length === 0 ? (
          <div className="text-sm text-ink-soft">No route cards entered yet.</div>
        ) : (
          <table className="table-base">
            <thead>
              <tr>
                <th>Job Card No</th>
                <th>Part</th>
                <th>Customer</th>
                <th>Issued Qty</th>
                <th>Entered</th>
              </tr>
            </thead>
            <tbody>
              {routeCards.slice(0, 10).map((rc) => (
                <tr key={rc.id}>
                  <td className="font-medium">{rc.job_card_no}</td>
                  <td>{rc.part_number}</td>
                  <td>{rc.customer || "\u2014"}</td>
                  <td>{rc.issued_qty}</td>
                  <td>{new Date(rc.entered_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </motion.div>
    </Layout>
  );
}
