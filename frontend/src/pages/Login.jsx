import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import ThreeBackground from "../components/ThreeBackground";
import { useAuth } from "../context/AuthContext";

export default function Login() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await login(username, password);
      navigate("/");
    } catch (err) {
      setError(
        err.response?.status === 401
          ? "Incorrect username or password"
          : "Could not reach the PPC backend. Is it running?"
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden bg-app-gradient">
      <ThreeBackground />

      <motion.div
        className="relative z-10 w-full max-w-sm mx-4"
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, ease: "easeOut" }}
      >
        <div className="card p-8">
          <div className="text-center mb-6">
            <img src="/chanda-logo.jpeg" alt="Chanda Enterprises" className="w-16 h-16 mx-auto mb-3 rounded-lg object-contain" />
            <div className="text-xs uppercase tracking-widest text-ink-soft">Chanda Enterprises Pvt Ltd</div>
            <div className="text-2xl font-semibold text-brand mt-1">PPC</div>
            <div className="text-xs text-ink-soft mt-1">Production Planning &amp; Control</div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="label">Username</label>
              <input
                className="input"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                autoFocus
                required
              />
            </div>
            <div>
              <label className="label">Password</label>
              <input
                className="input"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>

            {error && <div className="text-sm text-danger">{error}</div>}

            <button type="submit" disabled={loading} className="btn-primary w-full">
              {loading ? "Signing in\u2026" : "Sign in"}
            </button>
          </form>
        </div>

        <p className="text-center text-xs text-ink-soft mt-4">
          This login is separate from the Store system.
        </p>
      </motion.div>
    </div>
  );
}
