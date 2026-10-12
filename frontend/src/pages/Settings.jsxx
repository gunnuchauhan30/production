import { useState } from "react";
import Layout from "../components/Layout";
import Badge from "../components/Badge";
import api from "../api/client";
import { useAuth } from "../context/AuthContext";

const errText = (err, fallback) => {
  const d = err?.response?.data?.detail;
  if (typeof d === "string") return d;
  if (Array.isArray(d) && d.length) return d.map((x) => x.msg).join(", ");
  return fallback;
};

const emptyForm = { current_password: "", new_password: "", confirm: "" };

export default function Settings() {
  const { user } = useAuth();
  const [form, setForm] = useState(emptyForm);
  const [msg, setMsg] = useState(null);
  const [busy, setBusy] = useState(false);

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setMsg(null);
    if (form.new_password !== form.confirm) {
      setMsg({ type: "error", text: "New password and confirmation do not match." });
      return;
    }
    setBusy(true);
    try {
      await api.post("/account/change-password", {
        current_password: form.current_password,
        new_password: form.new_password,
      });
      setMsg({ type: "ok", text: "Password changed. Use the new password the next time you log in." });
      setForm(emptyForm);
    } catch (err) {
      setMsg({ type: "error", text: errText(err, "Could not change the password.") });
    } finally {
      setBusy(false);
    }
  };

  return (
    <Layout>
      <h1 className="text-xl font-semibold mb-5">Settings</h1>

      <div className="card mb-6 max-w-2xl">
        <div className="text-sm font-semibold mb-3">My Profile</div>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="label">Full Name</div>
            {user?.full_name || "-"}
          </div>
          <div>
            <div className="label">Username</div>
            {user?.username}
          </div>
          <div>
            <div className="label">Role</div>
            <Badge variant="info">{(user?.role || "").toUpperCase()}</Badge>
          </div>
        </div>
      </div>

      <form onSubmit={submit} className="card max-w-2xl">
        <div className="text-sm font-semibold mb-3">Change Password</div>
        {msg && (
          <div className={`text-sm mb-3 ${msg.type === "ok" ? "text-success" : "text-danger"}`}>{msg.text}</div>
        )}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="label">Current Password</label>
            <input
              name="current_password"
              type="password"
              className="input"
              value={form.current_password}
              onChange={handleChange}
              autoComplete="current-password"
              required
            />
          </div>
          <div>
            <label className="label">New Password</label>
            <input
              name="new_password"
              type="password"
              className="input"
              value={form.new_password}
              onChange={handleChange}
              autoComplete="new-password"
              minLength={8}
              required
            />
          </div>
          <div>
            <label className="label">Confirm New Password</label>
            <input
              name="confirm"
              type="password"
              className="input"
              value={form.confirm}
              onChange={handleChange}
              autoComplete="new-password"
              minLength={8}
              required
            />
          </div>
        </div>
        <p className="text-xs text-ink-soft mt-2">At least 8 characters.</p>
        <button type="submit" disabled={busy} className="btn-primary mt-4">
          {busy ? "Saving..." : "Change Password"}
        </button>
      </form>
    </Layout>
  );
}
