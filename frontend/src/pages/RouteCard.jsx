import { Fragment, useCallback, useEffect, useState } from "react";
import Layout from "../components/Layout";
import api from "../api/client";

const num = (v) => (v == null || v === "" ? "\u2014" : Number(v).toLocaleString("en-IN", { maximumFractionDigits: 2 }));
const dash = (v) => (v == null || v === "" ? "\u2014" : v);
const todayIso = () => new Date().toISOString().slice(0, 10);
const fmtDate = (iso) => {
  if (!iso) return "";
  const [y, m, d] = String(iso).slice(0, 10).split("-");
  return `${d}/${m}/${y}`;
};
const esc = (v) =>
  String(v ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
const numP = (v) => (v == null || v === "" ? "" : Number(v).toLocaleString("en-IN", { maximumFractionDigits: 2 }));

// The paper Route Card, as a printable page (browser "Save as PDF" makes the download).
function buildPrintHtml(card) {
  const uom = card.uom || "";
  const withUnit = (v) => (v == null ? "-" : `${numP(v)} ${uom}`.trim());
  const part = card.store_part || (card.parts_in_entries || []).join(", ") || "-";
  const mat = card.material || "-";
  const pad = (rows, n) => rows.concat(Array.from({ length: Math.max(0, n - rows.length) }, () => []));
  const grid = (head, rows, n, widths) =>
    `<table class="grid"><thead><tr>${head.map((h, i) => `<th style="width:${widths[i]}">${esc(h)}</th>`).join("")}</tr></thead><tbody>` +
    pad(rows, n)
      .map((r) => `<tr>${head.map((_, i) => `<td>${esc(r[i] ?? "")}</td>`).join("")}</tr>`)
      .join("") +
    "</tbody></table>";

  const ops = card.steps.map((s) => [
    s.operation_name,
    s.first_date === s.last_date ? fmtDate(s.first_date) : `${fmtDate(s.first_date)} - ${fmtDate(s.last_date)}`,
    numP(s.planned), numP(s.produced), numP(s.ok), numP(s.ng), "-", "-",
    [s.reasons.join(", "), s.operators.length ? `Operator: ${s.operators.join(", ")}` : ""].filter(Boolean).join(" | "),
    "",
  ]);
  const L = card.lines || { handover: [], receiving: [], dispatch: [] };
  const handover = L.handover.map((r, i) => [i + 1, r.name, fmtDate(r.line_date), numP(r.qty), r.remarks]);
  const receiving = L.receiving.map((r, i) => [i + 1, r.name, fmtDate(r.line_date), numP(r.qty), r.extra]);
  const dispatch = L.dispatch.map((r, i) => [i + 1, r.extra, fmtDate(r.line_date), numP(r.qty), numP(r.cumm_total)]);

  return `<!doctype html><html><head><meta charset="utf-8"><title>Route Card ${esc(card.job_card_no)}</title>
<style>
@page { size: A4; margin: 10mm; }
body { font-family: Arial, sans-serif; font-size: 11px; color: #000; }
table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
td, th { border: 1px solid #000; padding: 4px 6px; text-align: left; vertical-align: middle; }
th { background: #f0f0f0; }
.title { text-align: center; font-size: 18px; font-weight: bold; }
.logo { width: 70px; text-align: center; font-weight: bold; font-size: 14px; }
.lab { font-weight: bold; width: 17%; }
.grid th, .grid td { text-align: center; height: 19px; }
.grid td:nth-child(2) { text-align: left; }
h3 { margin: 12px 0 4px; font-size: 13px; }
.foot { margin-top: 6px; font-size: 10px; color: #444; }
.sign td { height: 34px; }
tr { page-break-inside: avoid; }
</style></head><body>
<table>
 <tr><td class="logo" rowspan="9">CEPL</td><td class="title" colspan="4">Route Card</td></tr>
 <tr><td class="lab">JOB CARD NO:</td><td>${esc(card.job_card_no)}</td><td class="lab">Assy No.:</td><td>-</td></tr>
 <tr><td class="lab">Assy Name:</td><td>${esc(mat)}</td><td class="lab">Part No.:</td><td>${esc(part)}</td></tr>
 <tr><td class="lab">Part Name:</td><td>${esc(mat)}</td><td class="lab">Requisition Qty:</td><td>${esc(withUnit(card.required_qty))}</td></tr>
 <tr><td class="lab">Issued By:</td><td>${esc(card.issued_by || "STORE")}</td><td class="lab">Qty Issued:</td><td>${esc(withUnit(card.issued_qty))}</td></tr>
 <tr><td class="lab">Material (Type, Size &amp; Grade):</td><td>${esc(mat)}</td><td class="lab">MTC No / Heat No.:</td><td>${esc(card.lots || card.batch_no || "-")}</td></tr>
 <tr><td class="lab">Supplier Name:</td><td colspan="3">${esc(card.supplier || "-")}</td></tr>
 <tr><td class="lab">TC No.:</td><td colspan="3">${esc(card.tc_no || "-")}</td></tr>
 <tr><td class="lab">Job Card Issue Date:</td><td>${esc(fmtDate(card.issue_date))}</td><td colspan="2"><b>Consumed Qty: ${esc(withUnit(card.consumed_qty))}</b></td></tr>
</table>
<h3>Operation Details</h3>
${grid(["Operation Name", "Production Date", "Qty Planned", "Qty Produced", "OK Qty", "Rejected Qty", "R/W Qty", "Hold Qty", "Actual Prod. Remarks", "Sup. Sign"], ops, 11, ["14%", "12%", "8%", "8%", "7%", "8%", "6%", "6%", "21%", "10%"])}
<p>SUP. SIGN: ____________________</p>
<h3>Handover to Dispatch</h3>
${grid(["S No", "Assy. Name / Part Name", "Date", "Qty", "Remarks"], handover, 9, ["8%", "42%", "14%", "12%", "24%"])}
<h3>Store Receiving</h3>
${grid(["S No", "Child Part Name", "Issue Date", "Issue Qty", "Next Operation"], receiving, 9, ["8%", "34%", "16%", "14%", "28%"])}
<h3>Desp. Details</h3>
${grid(["S No", "Invoice No", "Invoice Date", "Bill Qty", "Cumm Total"], dispatch, 6, ["8%", "30%", "20%", "20%", "22%"])}
<table class="sign"><tr><th>Store Receiving Sign:</th><th>Purchase Location Add:</th><th>SUP. SIGN:</th></tr><tr><td></td><td></td><td></td></tr></table>
<div class="foot">CEPL/STR/F/004-00: 10-JAN-2024 &nbsp;&middot;&nbsp; Printed from PPC on ${esc(fmtDate(todayIso()))}</div>
</body></html>`;
}

function openPrint(card) {
  const w = window.open("", "_blank");
  if (!w) {
    window.alert("The print window was blocked. Allow pop-ups for this site and try again.");
    return;
  }
  w.document.write(buildPrintHtml(card));
  w.document.close();
  w.focus();
  setTimeout(() => w.print(), 400);
}

// One of the three lower tables of the card (Handover / Store Receiving / Despatch).
function LineSection({ title, section, jobCardNo, rows, cols, fields, defaults, canDelete, onChanged }) {
  const [vals, setVals] = useState(defaults);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const add = async (e) => {
    e.preventDefault();
    setError("");
    setBusy(true);
    try {
      await api.post(`/store/job-cards/${encodeURIComponent(jobCardNo)}/lines`, {
        section,
        name: vals.name || null,
        line_date: vals.line_date || null,
        qty: vals.qty === "" || vals.qty == null ? null : Number(vals.qty),
        remarks: vals.remarks || null,
        extra: vals.extra || null,
      });
      setVals({ ...defaults, line_date: vals.line_date || defaults.line_date });
      await onChanged();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save this row.");
    } finally {
      setBusy(false);
    }
  };

  const remove = async (id) => {
    if (!window.confirm("Delete this row?")) return;
    try {
      await api.delete(`/store/job-cards/${encodeURIComponent(jobCardNo)}/lines/${id}`);
      await onChanged();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not delete this row.");
    }
  };

  return (
    <div className="mt-6">
      <div className="text-sm font-semibold mb-2">{title}</div>
      <div className="overflow-x-auto">
        <table className="table-base text-xs">
          <thead>
            <tr>
              <th>S No</th>
              {cols.map((c) => (
                <th key={c.label}>{c.label}</th>
              ))}
              {canDelete && <th></th>}
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={r.id}>
                <td>{i + 1}</td>
                {cols.map((c) => (
                  <td key={c.label}>{c.render(r)}</td>
                ))}
                {canDelete && (
                  <td>
                    <button type="button" className="text-danger text-xs" onClick={() => remove(r.id)}>
                      Delete
                    </button>
                  </td>
                )}
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={cols.length + 2} className="text-ink-soft text-center py-3">
                  Nothing added yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <form onSubmit={add} className="flex flex-wrap items-end gap-2 mt-2">
        {fields.map((f) => (
          <div key={f.key}>
            <label className="label text-[11px]">{f.label}</label>
            <input
              className="input"
              type={f.type || "text"}
              step={f.type === "number" ? "any" : undefined}
              min={f.type === "number" ? 0 : undefined}
              maxLength={f.type === "text" ? 255 : undefined}
              value={vals[f.key] ?? ""}
              onChange={(e) => setVals({ ...vals, [f.key]: e.target.value })}
              required={f.required}
            />
          </div>
        ))}
        <button type="submit" className="btn-secondary text-xs" disabled={busy}>
          {busy ? "Saving…" : "Add row"}
        </button>
      </form>
      {error && <div className="text-xs text-danger mt-1">{error}</div>}
    </div>
  );
}

function CardView({ jobCardNo, onClose }) {
  const [card, setCard] = useState(null);
  const [error, setError] = useState("");
  const [openStep, setOpenStep] = useState(null);

  const fetchCard = useCallback(async () => {
    try {
      const r = await api.get(`/store/job-cards/${encodeURIComponent(jobCardNo)}`);
      setCard(r.data);
      setError("");
    } catch (err) {
      setError(err.response?.data?.detail || "Could not load this Route Card.");
    }
  }, [jobCardNo]);

  useEffect(() => {
    setCard(null);
    setError("");
    setOpenStep(null);
    fetchCard();
  }, [fetchCard]);

  if (error) return <div className="card mb-6 text-sm text-danger">{error}</div>;
  if (!card) return <div className="card mb-6 text-sm text-ink-soft">Loading Route Card…</div>;

  const qty = card.issued_qty != null ? `${num(card.issued_qty)} ${card.uom || ""}`.trim() : "\u2014";
  const consumed = card.consumed_qty != null ? `${num(card.consumed_qty)} ${card.uom || ""}`.trim() : "\u2014";
  const head = [
    ["Job Card No.", card.job_card_no],
    ["Material", dash(card.material)],
    ["Requisition Qty", card.required_qty != null ? `${num(card.required_qty)} ${card.uom || ""}`.trim() : "\u2014"],
    ["Qty Issued", qty],
    ["Issued By", dash(card.issued_by)],
    ["MTC No / Heat No.", dash(card.lots)],
    ["Supplier Name", dash(card.supplier)],
    ["TC No.", dash(card.tc_no)],
    ["Department", dash(card.department)],
    ["Job Card Issue Date", dash(card.issue_date)],
    ["Part (in Production)", card.parts_in_entries.length ? card.parts_in_entries.join(", ") : "\u2014"],
    ["Consumed Qty (Store)", consumed],
  ];

  return (
    <div className="card mb-6">
      <div className="flex items-start justify-between mb-3">
        <div className="text-base font-semibold">Route Card — {card.job_card_no}</div>
        <div className="flex gap-2">
          <button type="button" className="btn-primary text-xs" onClick={() => openPrint(card)}>
            Download / Print PDF
          </button>
          <button type="button" className="btn-secondary text-xs" onClick={onClose}>
            Close
          </button>
        </div>
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

      <LineSection
        key={`handover-${card.job_card_no}`}
        title="Handover to Dispatch"
        section="handover"
        jobCardNo={card.job_card_no}
        rows={card.lines.handover}
        canDelete={card.can_delete_lines}
        onChanged={fetchCard}
        defaults={{ name: card.parts_in_entries[0] || card.material || "", line_date: todayIso(), qty: card.steps.length ? String(card.last_step_ok) : "", remarks: "" }}
        fields={[
          { key: "name", label: "Assy. Name / Part Name", required: true },
          { key: "line_date", label: "Date", type: "date" },
          { key: "qty", label: "Qty", type: "number" },
          { key: "remarks", label: "Remarks" },
        ]}
        cols={[
          { label: "Assy. Name / Part Name", render: (r) => r.name },
          { label: "Date", render: (r) => dash(r.line_date) },
          { label: "Qty", render: (r) => num(r.qty) },
          { label: "Remarks", render: (r) => dash(r.remarks) },
        ]}
      />
      <LineSection
        key={`receiving-${card.job_card_no}`}
        title="Store Receiving (child parts)"
        section="receiving"
        jobCardNo={card.job_card_no}
        rows={card.lines.receiving}
        canDelete={card.can_delete_lines}
        onChanged={fetchCard}
        defaults={{ name: "", line_date: todayIso(), qty: "", extra: "" }}
        fields={[
          { key: "name", label: "Child Part Name", required: true },
          { key: "line_date", label: "Issue Date", type: "date" },
          { key: "qty", label: "Issue Qty", type: "number" },
          { key: "extra", label: "Next Operation" },
        ]}
        cols={[
          { label: "Child Part Name", render: (r) => r.name },
          { label: "Issue Date", render: (r) => dash(r.line_date) },
          { label: "Issue Qty", render: (r) => num(r.qty) },
          { label: "Next Operation", render: (r) => dash(r.extra) },
        ]}
      />
      <LineSection
        key={`dispatch-${card.job_card_no}`}
        title="Desp. Details"
        section="dispatch"
        jobCardNo={card.job_card_no}
        rows={card.lines.dispatch}
        canDelete={card.can_delete_lines}
        onChanged={fetchCard}
        defaults={{ extra: "", line_date: todayIso(), qty: "" }}
        fields={[
          { key: "extra", label: "Invoice No", required: true },
          { key: "line_date", label: "Invoice Date", type: "date" },
          { key: "qty", label: "Bill Qty", type: "number" },
        ]}
        cols={[
          { label: "Invoice No", render: (r) => r.extra },
          { label: "Invoice Date", render: (r) => dash(r.line_date) },
          { label: "Bill Qty", render: (r) => num(r.qty) },
          { label: "Cumm Total", render: (r) => num(r.cumm_total) },
        ]}
      />

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
      setMessage(
        err.response?.data?.detail ||
          (err.response ? `Could not load the Job Cards (server error ${err.response.status}).` : "Could not reach the PPC server.")
      );
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
          <b>STORE_PASSWORD</b> (a Store user made for this, e.g. ppc_sync). Job Cards then appear here by themselves within a few minutes.
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
