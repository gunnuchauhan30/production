import { Fragment, useCallback, useEffect, useState } from "react";
import Layout from "../components/Layout";
import api from "../api/client";

const num = (v) => (v == null || v === "" ? "\u2014" : Number(v).toLocaleString("en-IN", { maximumFractionDigits: 2 }));
const dash = (v) => (v == null || v === "" ? "\u2014" : v);

function CardView({ jobCardNo, onClose }) {
  const [card, setCard] = useState(null);
  const [error, setError] = useState("");
  const [openStep, setOpenStep] = useState(null);

  useEffect(() => {
    let alive = true;
    setCard(null);
    setError("");
    setOpenStep(null);
    api
      .get(`/store/job-cards/${encodeURIComponent(jobCardNo)}`)
      .then((r) => alive && setCard(r.data))
      .catch((err) => alive && setError(err.response?.data?.detail || "Could not load this Route Card."));
    return () => {
      alive = false;
    };
  }, [jobCardNo]);

  if (error) return <div className="card mb-6 text-sm text-danger">{error}</div>;
  if (!card) return <div className="card mb-6 text-sm text-ink-soft">Loading Route Card…</div>;

  const qty = card.issued_qty != null ? `${num(card.issued_qty)} ${card.uom || ""}`.trim() : "\u2014";
  const consumed = card.consumed_qty != null ? `${num(card.consumed_qty)} ${card.uom || ""}`.trim() : "\u2014";
  const head = [
    ["Job Card No.", card.job_card_no],
    ["Material", dash(card.material)],
    ["Qty Issued", qty],
    ["MTC No / Heat No.", dash(card.lots)],
    ["Department", dash(card.department)],
    ["Job Card Issue Date", dash(card.issue_date)],
    ["Part (in Production)", card.parts_in_entries.length ? card.parts_in_entries.join(", ") : "\u2014"],
    ["Consumed Qty (Store)", consumed],
  ];

  return (
    <div className="card mb-6">
      <div className="flex items-start justify-between mb-3">
        <div className="text-base font-semibold">Route Card — {card.job_card_no}</div>
        <button type="button" className="btn-secondary text-xs" onClick={onClose}>
          Close
        </button>
      </div>

      {!card.in_store && (
        <div className="text-xs text-danger mb-3">
          This Job Card No. was typed by hand in Production Logs and is not in the Store, so the top part is empty.
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-1 mb-5 text-sm">
        {head.map(([k, v]) => (
          <div key={k} className="flex gap-2 border-b border-black/5 py-1">
            <div className="w-44 shrink-0 text-ink-soft">{k}</div>
            <div className="font-medium break-words">{v}</div>
          </div>
        ))}
      </div>

      <div className="text-sm font-semibold mb-2">Operation Details</div>
      {card.steps.length === 0 ? (
        <div className="text-sm text-ink-soft py-3">
          No Production Log entry carries this Job Card No. yet. Pick it in the “Job Card No.” box when saving an entry in Production Logs and the row appears here by itself.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="table-base text-xs">
            <thead>
              <tr>
                <th>Operation Name</th>
                <th>Production Date</th>
                <th>Qty Planned</th>
                <th>Qty Produced</th>
                <th>OK Qty</th>
                <th>Rejected Qty</th>
                <th>R/W Qty</th>
                <th>Hold Qty</th>
                <th>Actual Prod. Remarks</th>
                <th>Operator</th>
              </tr>
            </thead>
            <tbody>
              {card.steps.map((s, i) => {
                const isOpen = openStep === i;
                const remarks = [s.reasons.join(", "), s.machines.join(", ")].filter(Boolean).join(" · ");
                return (
                  <Fragment key={`${s.item_name}-${s.operation_name}`}>
                    <tr className="cursor-pointer hover:bg-black/5" onClick={() => setOpenStep(isOpen ? null : i)}>
                      <td className="font-medium">
                        {s.operation_name}
                        {s.item_name && <span className="block text-[10px] text-ink-soft">{s.item_name}</span>}
                      </td>
                      <td>{s.first_date === s.last_date ? s.first_date : `${s.first_date} → ${s.last_date}`}</td>
                      <td>{num(s.planned)}</td>
                      <td>{num(s.produced)}</td>
                      <td>{num(s.ok)}</td>
                      <td>{num(s.ng)}</td>
                      <td>{"\u2014"}</td>
                      <td>{"\u2014"}</td>
                      <td>{dash(remarks)}</td>
                      <td>{s.operators.join(", ") || "\u2014"}</td>
                    </tr>
                    {isOpen &&
                      s.entries.map((e) => (
                        <tr key={`e-${e.id}`} className="bg-orange-50/60">
                          <td className="text-ink-soft pl-4">
                            Shift {dash(e.shift)} · {dash(e.machine_no)}
                          </td>
                          <td>{e.entry_date}</td>
                          <td>{num(e.planned)}</td>
                          <td>{num(e.produced)}</td>
                          <td>{num(e.ok)}</td>
                          <td>{num(e.ng)}</td>
                          <td></td>
                          <td></td>
                          <td>{dash(e.rejection_reason)}</td>
                          <td>{dash(e.operator_name)}</td>
                        </tr>
                      ))}
                  </Fragment>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {card.steps.length > 0 && (
        <div className="mt-3 text-sm flex flex-wrap gap-x-8 gap-y-1">
          <div>
            Total rejected: <b>{num(card.total_ng)}</b>
          </div>
          <div>
            OK after last operation ({card.last_step_name}): <b>{num(card.last_step_ok)}</b>
          </div>
          <div>
            Entries: <b>{card.entry_count}</b>
          </div>
        </div>
      )}

      <p className="text-[11px] text-ink-soft mt-3">
        Rows fill by themselves from Production Logs entries that carry this Job Card No. Click an operation to see its separate entries. R/W and Hold are not recorded in Production Logs.
        The Store quantity is in the Store’s unit ({card.uom || "KG/NOS"}) while production counts pieces, so the two are not subtracted from each other.
      </p>
    </div>
  );
}

export default function RouteCard() {
  const [data, setData] = useState({ configured: true, last_synced: null, sync_error: null, cards: [] });
  const [loading, setLoading] = useState(true);
  const [q, setQ] = useState("");
  const [selected, setSelected] = useState(null);
  const [syncing, setSyncing] = useState(false);
  const [message, setMessage] = useState("");

  const load = useCallback(async (search) => {
    setLoading(true);
    try {
      const res = await api.get("/store/job-cards", { params: search ? { q: search } : {} });
      setData(res.data);
    } catch (err) {
      setMessage(err.response?.data?.detail || "Could not load the Job Cards.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const t = setTimeout(() => load(q), q ? 300 : 0);
    return () => clearTimeout(t);
  }, [q, load]);

  const syncNow = async () => {
    setSyncing(true);
    setMessage("");
    try {
      const res = await api.post("/store/sync");
      setMessage(`Synced ${res.data.synced_issues} issues from the Store.`);
      await load(q);
    } catch (err) {
      setMessage(err.response?.data?.detail || "Sync failed.");
    } finally {
      setSyncing(false);
    }
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Route Card</h1>
      <p className="text-sm text-ink-soft mb-5">
        Route Cards made in the Store come here by themselves. Pick one to see where it was used: each Production Log entry saved with that Job Card No. fills the operation table.
      </p>

      {!data.configured && (
        <div className="card mb-5 text-sm">
          The Store is not connected yet. In Railway, open the PPC backend service → Variables and add <b>STORE_USERNAME</b> and{" "}
          <b>STORE_PASSWORD</b> (a Store user made for this, e.g. ppc_sync). Job Cards then appear here within a minute.
        </div>
      )}
      {data.sync_error && <div className="card mb-5 text-sm text-danger">Store sync problem: {data.sync_error}</div>}

      {selected && <CardView jobCardNo={selected} onClose={() => setSelected(null)} />}

      <div className="card">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-3">
          <div>
            <div className="text-sm font-semibold">Job Cards from the Store</div>
            <div className="text-[11px] text-ink-soft">
              {data.last_synced ? `Last synced ${new Date(data.last_synced + "Z").toLocaleString()}` : "Not synced yet"}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input className="input max-w-xs" placeholder="Search job card, material, lot…" value={q} onChange={(e) => setQ(e.target.value)} />
            <button type="button" className="btn-secondary text-xs whitespace-nowrap" onClick={syncNow} disabled={syncing || !data.configured}>
              {syncing ? "Syncing…" : "Sync from Store"}
            </button>
          </div>
        </div>
        {message && <div className="text-xs text-ink-soft mb-2">{message}</div>}

        <div className="overflow-x-auto">
          <table className="table-base text-xs">
            <thead>
              <tr>
                <th>Job Card No</th>
                <th>Material</th>
                <th>Qty Issued</th>
                <th>Lot</th>
                <th>Department</th>
                <th>Issue Date</th>
                <th>Entries</th>
              </tr>
            </thead>
            <tbody>
              {data.cards.map((c) => (
                <tr
                  key={c.job_card_no}
                  className={`cursor-pointer hover:bg-black/5 ${selected === c.job_card_no ? "bg-orange-50" : ""}`}
                  onClick={() => {
                    setSelected(c.job_card_no);
                    window.scrollTo({ top: 0, behavior: "smooth" });
                  }}
                >
                  <td className="font-medium">{c.job_card_no}</td>
                  <td>{dash(c.material)}</td>
                  <td>{c.issued_qty != null ? `${num(c.issued_qty)} ${c.uom || ""}` : "\u2014"}</td>
                  <td>{dash(c.lots)}</td>
                  <td>{dash(c.department)}</td>
                  <td>{dash(c.issue_date)}</td>
                  <td>{c.entries}</td>
                </tr>
              ))}
              {!loading && data.cards.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center text-ink-soft py-6">
                    {data.configured ? "No Job Cards found." : "Connect the Store to see Job Cards."}
                  </td>
                </tr>
              )}
              {loading && data.cards.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center text-ink-soft py-6">
                    Loading…
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </Layout>
  );
}
