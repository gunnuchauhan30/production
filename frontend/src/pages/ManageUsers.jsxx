import { useEffect, useState } from "react";
import Layout from "../components/Layout";
import Badge from "../components/Badge";
import api from "../api/client";
import { useAuth } from "../context/AuthContext";

const ROLES = ["planning", "operator", "qa", "dispatch", "admin"];

const emptyForm = { full_name: "", username: "", password: "", role: "operator" };

// FastAPI returns detail as a string for our own errors and as a list for validation errors.
const errText = (err, fallback) => {
  const d = err?.response?.data?.detail;
  if (typeof d === "string") return d;
  if (Array.isArray(d) && d.length) return d.map((x) => x.msg).join(", ");
  return fallback;
};

export default function ManageUsers() {
  const { user: me } = useAuth();
  const isAdmin = me?.role === "admin";

  const [users, setUsers] = useState([]);
  const [form, setForm] = useState(emptyForm);
  const [showPw, setShowPw] = useState(false);
  const [msg, setMsg] = useState(null); // { type: "ok" | "error", text }
  const [busy, setBusy] = useState(false);

  const load = async () => {
    try {
      const res = await api.get("/users");
      setUsers(res.data);
    } catch (err) {
      setMsg({ type: "error", text: errText(err, "Could not load users.") });
    }
  };

  useEffect(() => {
    if (isAdmin) load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAdmin]);

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const createUser = async (e) => {
    e.preventDefault();
    setMsg(null);
    setBusy(true);
    try {
      await api.post("/users", form);
      setMsg({
        type: "ok",
        text: `Account created. Give ${form.username.trim()} the username and temporary password, and ask them to change it in Settings.`,
      });
      setForm(emptyForm);
      await load();
    } catch (err) {
      setMsg({ type: "error", text: errText(err, "Could not create the account.") });
    } finally {
      setBusy(false);
    }
  };

  const update = async (u, changes, okText) => {
    setMsg(null);
    try {
      await api.patch(`/users/${u.id}`, changes);
      setMsg({ type: "ok", text: okText });
      await load();
    } catch (err) {
      setMsg({ type: "error", text: errText(err, "Could not update the account.") });
      await load();
    }
  };

  const resetPassword = async (u) => {
    const pw = window.prompt(`New temporary password for ${u.username} (at least 8 characters):`);
    if (pw === null) return;
    setMsg(null);
    try {
      await api.post(`/users/${u.id}/reset-password`, { new_password: pw });
      setMsg({ type: "ok", text: `Password for ${u.username} was reset.` });
    } catch (err) {
      setMsg({ type: "error", text: errText(err, "Could not reset the password.") });
    }
  };

  const deleteUser = async (u) => {
    if (!window.confirm(`Delete ${u.username} permanently? (To keep their history, use Disable instead.)`)) return;
    setMsg(null);
    try {
      await api.delete(`/users/${u.id}`);
      setMsg({ type: "ok", text: `${u.username} was deleted.` });
      await load();
    } catch (err) {
      setMsg({ type: "error", text: errText(err, "Could not delete the account.") });
    }
  };

  if (!isAdmin) {
    return (
      <Layout>
        <h1 className="text-xl font-semibold mb-1">Manage Users</h1>
        <p className="text-sm text-ink-soft">Only an admin can manage user accounts.</p>
      </Layout>
    );
  }

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-1">Manage Users</h1>
      <p className="text-sm text-ink-soft mb-5">
        There is no public sign-up. Only an admin can create accounts here.
      </p>

      {msg && (
        <div className={`card mb-4 text-sm ${msg.type === "ok" ? "text-success" : "text-danger"}`}>{msg.text}</div>
      )}

      <form onSubmit={createUser} className="card mb-6">
        <div className="text-sm font-semibold mb-3">Create New Account</div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="label">Full Name *</label>
            <input name="full_name" className="input" value={form.full_name} onChange={handleChange} required />
          </div>
          <div>
            <label className="label">Username *</label>
            <input name="username" className="input" value={form.username} onChange={handleChange} autoComplete="off" required />
          </div>
          <div>
            <label className="label">Temporary Password *</label>
            <input
              name="password"
              type={showPw ? "text" : "password"}
              className="input"
              value={form.password}
              onChange={handleChange}
              autoComplete="new-password"
              minLength={8}
              required
            />
            <label className="text-xs text-ink-soft mt-1 flex items-center gap-1">
              <input type="checkbox" checked={showPw} onChange={(e) => setShowPw(e.target.checked)} /> Show password
            </label>
          </div>
          <div>
            <label className="label">Role *</label>
            <select name="role" className="input" value={form.role} onChange={handleChange}>
              {ROLES.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>
        </div>
        <button type="submit" disabled={busy} className="btn-primary mt-4">
          {busy ? "Creating..." : "Create Account"}
        </button>
      </form>

      <div className="card overflow-x-auto">
        <div className="text-sm font-semibold mb-3">Existing Accounts</div>
        <table className="table-base">
          <thead>
            <tr>
              <th>Full Name</th>
              <th>Username</th>
              <th>Role</th>
              <th>Status</th>
              <th>Created</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => {
              const self = u.id === me.id;
              return (
                <tr key={u.id}>
                  <td>{u.full_name || "-"}</td>
                  <td className="font-medium">
                    {u.username}
                    {self && <span className="text-xs text-ink-soft"> (you)</span>}
                  </td>
                  <td>
                    <select
                      className="input w-36"
                      value={u.role}
                      disabled={self}
                      onChange={(e) => update(u, { role: e.target.value }, `Role of ${u.username} changed to ${e.target.value}.`)}
                    >
                      {ROLES.map((r) => (
                        <option key={r} value={r}>
                          {r}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td>
                    <Badge variant={u.is_active ? "success" : "danger"}>{u.is_active ? "ACTIVE" : "DISABLED"}</Badge>
                  </td>
                  <td className="text-xs text-ink-soft">{u.created_at ? u.created_at.slice(0, 10) : "-"}</td>
                  <td>
                    <div className="flex flex-wrap gap-2">
                      {!self && (
                        <button
                          type="button"
                          className="btn-secondary text-xs"
                          onClick={() =>
                            update(
                              u,
                              { is_active: !u.is_active },
                              u.is_active ? `${u.username} was disabled.` : `${u.username} was enabled.`
                            )
                          }
                        >
                          {u.is_active ? "Disable" : "Enable"}
                        </button>
                      )}
                      <button type="button" className="btn-secondary text-xs" onClick={() => resetPassword(u)}>
                        Reset password
                      </button>
                      {!self && (
                        <button type="button" className="btn-danger text-xs" onClick={() => deleteUser(u)}>
                          Delete
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
            {users.length === 0 && (
              <tr>
                <td colSpan={6} className="text-center text-ink-soft py-4">
                  No users found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
        <p className="text-xs text-ink-soft mt-3">
          Disable an account to stop someone logging in while keeping their entries. Delete only works for accounts with no entries.
        </p>
      </div>
    </Layout>
  );
}
