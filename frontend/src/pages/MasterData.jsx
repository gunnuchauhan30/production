import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import Layout from "../components/Layout";
import { useAuth } from "../context/AuthContext";
import api from "../api/client";

const BOP_LABEL = "BOP";
const isBop = (spec) => (spec || "").trim().toUpperCase() === BOP_LABEL;

export default function MasterData() {
  const { user } = useAuth();
  const [bomItems, setBomItems] = useState([]);
  const [bomOperations, setBomOperations] = useState([]);
  const [machines, setMachines] = useState([]);
  const [rejectionReasons, setRejectionReasons] = useState([]);
  const [downTimeReasons, setDownTimeReasons] = useState([]);
  const [parts, setParts] = useState([]);

  const [selectedPart, setSelectedPart] = useState(null);
  const [selectedBomItem, setSelectedBomItem] = useState(null);
  const [bomItemForm, setBomItemForm] = useState({ part_number: "", part_name: "", customer_name: "", item_name: "", spec: "", item_seq: "1" });
  const [bomOpForm, setBomOpForm] = useState({ operation_seq: "", operation_name: "", cycle_time_sec: "", machine_no: "" });
  const [machineForm, setMachineForm] = useState({ machine_no: "", machine_name: "", department: "" });
  const [reasonForm, setReasonForm] = useState({ reason: "", category: "" });
  const [downTimeForm, setDownTimeForm] = useState({ reason: "" });
  const [error, setError] = useState("");

  const [editingItemId, setEditingItemId] = useState(null);
  const [editItemForm, setEditItemForm] = useState({ item_name: "", spec: "" });
  const [editingPartName, setEditingPartName] = useState(false);
  const [partNameDraft, setPartNameDraft] = useState("");
  const [customerNameDraft, setCustomerNameDraft] = useState("");

  const load = async () => {
    const [r1, r2, r3, r4, r5] = await Promise.all([
      api.get("/master-data/bom-items"),
      api.get("/master-data/machines"),
      api.get("/master-data/rejection-reasons"),
      api.get("/master-data/down-time-reasons"),
      api.get("/master-data/parts"),
    ]);
    setBomItems(r1.data);
    setMachines(r2.data);
    setRejectionReasons(r3.data);
    setDownTimeReasons(r4.data);
    setParts(r5.data);
  };

  const loadOperations = async (bomItemId) => {
    const res = await api.get(`/master-data/bom-items/${bomItemId}/operations`);
    setBomOperations(res.data);
  };

  useEffect(() => {
    load();
  }, []);

  const partNameOf = (partNumber) => parts.find((p) => p.part_number === partNumber)?.part_name || "";
  const customerNameOf = (partNumber) => parts.find((p) => p.part_number === partNumber)?.customer_name || "";
  const partLabel = (partNumber) => {
    const name = partNameOf(partNumber);
    return name ? `${name} ${partNumber}` : partNumber;
  };

  const savePartDetails = async (partNumber, name, customer) => {
    setError("");
    try {
      await api.post("/master-data/parts", { part_number: partNumber, part_name: name || null, customer_name: customer || null });
      await load();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save part details.");
    }
  };

  const startEditItem = (b) => {
    setEditingItemId(b.id);
    setEditItemForm({ item_name: b.item_name, spec: b.spec || "" });
  };

  const saveEditItem = async (bomItemId) => {
    setError("");
    try {
      await api.patch(`/master-data/bom-items/${bomItemId}`, {
        item_name: editItemForm.item_name,
        spec: editItemForm.spec === "" ? null : editItemForm.spec,
      });
      setEditingItemId(null);
      await load();
      if (selectedBomItem?.id === bomItemId) {
        const updated = (await api.get("/master-data/bom-items", { params: { part_number: selectedPart } })).data.find((x) => x.id === bomItemId);
        if (updated) setSelectedBomItem(updated);
      }
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save changes.");
    }
  };

  if (user?.role !== "admin") {
    return (
      <Layout>
        <div className="card text-sm text-ink-soft">Master Data is admin-only.</div>
      </Layout>
    );
  }

  const submit = async (endpoint, payload, resetForm, extra = {}) => {
    setError("");
    try {
      await api.post(endpoint, { ...payload, ...extra });
      resetForm();
      await load();
    } catch (err) {
      setError(err.response?.data?.detail || "Could not save.");
    }
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-5">Master Data</h1>
      {error && <div className="text-sm text-danger mb-4">{error}</div>}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <motion.div className="card md:col-span-2" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <div className="text-sm font-semibold mb-3">Part → BOM → Operations</div>

          {(() => {
            const partNumbers = [...new Set(bomItems.map((b) => b.part_number))].sort();

            // Level 3: showing operations for a selected BOM item
            if (selectedPart && selectedBomItem) {
              const bopItem = isBop(selectedBomItem.spec);
              return (
                <div>
                  <button
                    className="text-xs text-brand font-medium mb-3"
                    onClick={() => {
                      setSelectedBomItem(null);
                      setBomOperations([]);
                    }}
                  >
                    ← Back to {partLabel(selectedPart)} BOM
                  </button>
                  <div className="text-sm font-semibold mb-1">
                    {partLabel(selectedPart)} — {selectedBomItem.item_name}
                  </div>
                  {selectedBomItem.spec && (
                    <div className={bopItem ? "text-xs font-semibold text-brand mb-3 whitespace-pre-line" : "text-xs text-ink-soft mb-3 whitespace-pre-line"}>
                      {selectedBomItem.spec}
                    </div>
                  )}

                  {bopItem ? (
                    <div className="text-xs text-ink-soft">
                      Bought-Out Part — no in-house operations.
                    </div>
                  ) : (
                    <>
                      <form
                        onSubmit={(e) => {
                          e.preventDefault();
                          submit(
                            `/master-data/bom-items/${selectedBomItem.id}/operations`,
                            {
                              operation_seq: Number(bomOpForm.operation_seq),
                              operation_name: bomOpForm.operation_name,
                              cycle_time_sec: bomOpForm.cycle_time_sec === "" ? null : Number(bomOpForm.cycle_time_sec),
                              machine_no: bomOpForm.machine_no === "" ? null : bomOpForm.machine_no,
                            },
                            () => {
                              setBomOpForm({ operation_seq: "", operation_name: "", cycle_time_sec: "", machine_no: "" });
                              loadOperations(selectedBomItem.id);
                            }
                          );
                        }}
                        className="grid grid-cols-4 gap-2 mb-3"
                      >
                        <input className="input" placeholder="Seq" type="number" value={bomOpForm.operation_seq} onChange={(e) => setBomOpForm({ ...bomOpForm, operation_seq: e.target.value })} required />
                        <input className="input" placeholder="Operation" value={bomOpForm.operation_name} onChange={(e) => setBomOpForm({ ...bomOpForm, operation_name: e.target.value })} required />
                        <input className="input" placeholder="Cycle (sec)" type="number" step="0.01" value={bomOpForm.cycle_time_sec} onChange={(e) => setBomOpForm({ ...bomOpForm, cycle_time_sec: e.target.value })} />
                        <input className="input" placeholder="Machine" value={bomOpForm.machine_no} onChange={(e) => setBomOpForm({ ...bomOpForm, machine_no: e.target.value })} />
                        <button className="btn-primary col-span-4">Add Operation</button>
                      </form>

                      <table className="table-base text-xs">
                        <thead>
                          <tr>
                            <th>Seq</th>
                            <th>Operation</th>
                            <th>Cycle (sec)</th>
                            <th>Machine</th>
                          </tr>
                        </thead>
                        <tbody>
                          {bomOperations.map((o) => (
                            <tr key={o.id}>
                              <td>{o.operation_seq}</td>
                              <td>{o.operation_name}</td>
                              <td>{o.cycle_time_sec ?? "—"}</td>
                              <td>{o.machine_no ?? "—"}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </>
                  )}
                </div>
              );
            }

            // Level 2: showing BOM items for a selected part
            if (selectedPart) {
              const items = bomItems
                .filter((b) => b.part_number === selectedPart)
                .sort((a, b) => a.item_seq - b.item_seq);
              return (
                <div>
                  <button
                    className="text-xs text-brand font-medium mb-3"
                    onClick={() => {
                      setSelectedPart(null);
                      setEditingPartName(false);
                      setEditingItemId(null);
                    }}
                  >
                    ← Back to parts
                  </button>

                  {editingPartName ? (
                    <div className="flex items-center gap-2 mb-2 flex-wrap">
                      <input
                        className="input text-sm"
                        placeholder="Part name (e.g. Handle Bar)"
                        value={partNameDraft}
                        onChange={(e) => setPartNameDraft(e.target.value)}
                        autoFocus
                      />
                      <span className="text-sm text-ink-soft">{selectedPart}</span>
                      <input
                        className="input text-sm"
                        placeholder="Customer (e.g. UNO MINDA, VARROC)"
                        value={customerNameDraft}
                        onChange={(e) => setCustomerNameDraft(e.target.value)}
                      />
                      <button
                        className="text-xs text-brand font-medium"
                        onClick={async () => {
                          await savePartDetails(selectedPart, partNameDraft, customerNameDraft);
                          setEditingPartName(false);
                        }}
                      >
                        Save
                      </button>
                      <button className="text-xs text-ink-soft" onClick={() => setEditingPartName(false)}>
                        Cancel
                      </button>
                    </div>
                  ) : (
                    <div className="mb-2">
                      <div className="flex items-center gap-2">
                        <div className="text-sm font-semibold">{partLabel(selectedPart)} — BOM</div>
                        <button
                          className="text-xs text-brand"
                          onClick={() => {
                            setPartNameDraft(partNameOf(selectedPart));
                            setCustomerNameDraft(customerNameOf(selectedPart));
                            setEditingPartName(true);
                          }}
                        >
                          Edit details
                        </button>
                      </div>
                      {customerNameOf(selectedPart) && (
                        <div className="text-xs text-ink-soft mt-0.5">Customer: {customerNameOf(selectedPart)}</div>
                      )}
                    </div>
                  )}

                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      submit(
                        "/master-data/bom-items",
                        { part_number: selectedPart, item_name: bomItemForm.item_name, spec: bomItemForm.spec, item_seq: Number(bomItemForm.item_seq) || 1 },
                        () => setBomItemForm({ part_number: "", part_name: "", customer_name: "", item_name: "", spec: "", item_seq: "1" })
                      );
                    }}
                    className="grid grid-cols-3 gap-2 mb-3"
                  >
                    <input className="input" placeholder="Item name (e.g. Tube, Assembly)" value={bomItemForm.item_name} onChange={(e) => setBomItemForm({ ...bomItemForm, item_name: e.target.value })} required />
                    <input className="input" placeholder="Spec (e.g. 22.2 X 2.0 X 841 MM, or BOP)" value={bomItemForm.spec} onChange={(e) => setBomItemForm({ ...bomItemForm, spec: e.target.value })} />
                    <button className="btn-primary">Add BOM Item</button>
                  </form>

                  <div className="grid grid-cols-3 gap-2">
                    {items.map((b) =>
                      editingItemId === b.id ? (
                        <div key={b.id} className="border rounded-lg px-3 py-2 text-xs space-y-1 border-brand">
                          <input className="input text-xs" value={editItemForm.item_name} onChange={(e) => setEditItemForm({ ...editItemForm, item_name: e.target.value })} placeholder="Item name" />
                          <textarea className="input text-xs" rows={2} value={editItemForm.spec} onChange={(e) => setEditItemForm({ ...editItemForm, spec: e.target.value })} placeholder={"Spec / BOP\n(2nd line = Grade, etc.)"} />
                          <div className="flex gap-2 pt-1">
                            <button className="text-brand font-medium" onClick={() => saveEditItem(b.id)}>Save</button>
                            <button className="text-ink-soft" onClick={() => setEditingItemId(null)}>Cancel</button>
                          </div>
                        </div>
                      ) : (
                        <div key={b.id} className="border rounded-lg px-3 py-2 text-xs font-medium hover:border-brand transition relative group">
                          <button
                            onClick={() => {
                              setSelectedBomItem(b);
                              loadOperations(b.id);
                            }}
                            className="text-left w-full hover:bg-brand/5"
                          >
                            <div>{b.item_name}</div>
                            {b.spec && <div className={isBop(b.spec) ? "text-brand font-semibold whitespace-pre-line" : "text-ink-soft font-normal whitespace-pre-line"}>{b.spec}</div>}
                          </button>
                          <button
                            className="absolute top-1 right-1 text-[10px] text-ink-soft hover:text-brand"
                            onClick={(e) => {
                              e.stopPropagation();
                              startEditItem(b);
                            }}
                          >
                            Edit
                          </button>
                        </div>
                      )
                    )}
                  </div>
                </div>
              );
            }

            // Level 1: showing part numbers
            return (
              <div>
                <form
                  onSubmit={async (e) => {
                    e.preventDefault();
                    setError("");
                    try {
                      await api.post("/master-data/bom-items", {
                        part_number: bomItemForm.part_number,
                        item_name: bomItemForm.item_name,
                        spec: bomItemForm.spec,
                        item_seq: Number(bomItemForm.item_seq) || 1,
                      });
                      if (bomItemForm.part_name || bomItemForm.customer_name) {
                        await api.post("/master-data/parts", {
                          part_number: bomItemForm.part_number,
                          part_name: bomItemForm.part_name || null,
                          customer_name: bomItemForm.customer_name || null,
                        });
                      }
                      setBomItemForm({ part_number: "", part_name: "", customer_name: "", item_name: "", spec: "", item_seq: "1" });
                      await load();
                    } catch (err) {
                      setError(err.response?.data?.detail || "Could not save.");
                    }
                  }}
                  className="grid grid-cols-6 gap-2 mb-3"
                >
                  <input className="input" placeholder="Part No. (e.g. J1A)" value={bomItemForm.part_number} onChange={(e) => setBomItemForm({ ...bomItemForm, part_number: e.target.value })} required />
                  <input className="input" placeholder="Part name (e.g. Handle Bar)" value={bomItemForm.part_name} onChange={(e) => setBomItemForm({ ...bomItemForm, part_name: e.target.value })} />
                  <input className="input" placeholder="Customer (e.g. UNO MINDA)" value={bomItemForm.customer_name} onChange={(e) => setBomItemForm({ ...bomItemForm, customer_name: e.target.value })} />
                  <input className="input" placeholder="Item name (e.g. Tube)" value={bomItemForm.item_name} onChange={(e) => setBomItemForm({ ...bomItemForm, item_name: e.target.value })} required />
                  <input className="input" placeholder="Spec" value={bomItemForm.spec} onChange={(e) => setBomItemForm({ ...bomItemForm, spec: e.target.value })} />
                  <button className="btn-primary">Add New Part + BOM Item</button>
                </form>

                <div className="grid grid-cols-3 gap-2">
                  {partNumbers.map((p) => (
                    <button
                      key={p}
                      onClick={() => setSelectedPart(p)}
                      className="border rounded-lg px-3 py-2 text-xs font-medium text-left hover:bg-brand/5 hover:border-brand transition"
                    >
                      {partLabel(p)}
                    </button>
                  ))}
                </div>
              </div>
            );
          })()}
        </motion.div>

        <motion.div className="card" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 }}>
          <div className="text-sm font-semibold mb-3">Machines</div>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              submit("/master-data/machines", machineForm, () => setMachineForm({ machine_no: "", machine_name: "", department: "" }));
            }}
            className="grid grid-cols-3 gap-2 mb-4"
          >
            <input className="input" placeholder="No." value={machineForm.machine_no} onChange={(e) => setMachineForm({ ...machineForm, machine_no: e.target.value })} required />
            <input className="input" placeholder="Name" value={machineForm.machine_name} onChange={(e) => setMachineForm({ ...machineForm, machine_name: e.target.value })} />
            <input className="input" placeholder="Dept" value={machineForm.department} onChange={(e) => setMachineForm({ ...machineForm, department: e.target.value })} />
            <button className="btn-primary col-span-3">Add</button>
          </form>
          <table className="table-base text-xs">
            <tbody>
              {machines.map((m) => (
                <tr key={m.machine_no}>
                  <td>{m.machine_no}</td>
                  <td>{m.machine_name}</td>
                  <td>{m.department}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </motion.div>

        <motion.div className="card" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}>
          <div className="text-sm font-semibold mb-3">Rejection Reasons</div>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              submit("/master-data/rejection-reasons", reasonForm, () => setReasonForm({ reason: "", category: "" }));
            }}
            className="grid grid-cols-2 gap-2 mb-4"
          >
            <input className="input" placeholder="Reason" value={reasonForm.reason} onChange={(e) => setReasonForm({ ...reasonForm, reason: e.target.value })} required />
            <input className="input" placeholder="Category" value={reasonForm.category} onChange={(e) => setReasonForm({ ...reasonForm, category: e.target.value })} />
            <button className="btn-primary col-span-2">Add</button>
          </form>
          <ul className="text-xs space-y-1">
            {rejectionReasons.map((r) => (
              <li key={r.id}>
                {r.reason} <span className="text-ink-soft">({r.category})</span>
              </li>
            ))}
          </ul>
        </motion.div>

        <motion.div className="card" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }}>
          <div className="text-sm font-semibold mb-3">Down-time Reasons</div>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              submit("/master-data/down-time-reasons", downTimeForm, () => setDownTimeForm({ reason: "" }));
            }}
            className="grid grid-cols-2 gap-2 mb-4"
          >
            <input className="input" placeholder="Reason" value={downTimeForm.reason} onChange={(e) => setDownTimeForm({ reason: e.target.value })} required />
            <button className="btn-primary">Add</button>
          </form>
          <ul className="text-xs space-y-1">
            {downTimeReasons.map((r) => (
              <li key={r.id}>{r.reason}</li>
            ))}
          </ul>
        </motion.div>
      </div>
    </Layout>
  );
}