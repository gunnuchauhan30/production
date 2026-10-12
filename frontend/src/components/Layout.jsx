import { NavLink, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { useAuth } from "../context/AuthContext";

const NAV_ITEMS = [
  { to: "/", label: "Dashboard", icon: "\u25A3" },
  { to: "/route-cards", label: "Route Cards", icon: "\u25A4" },
  { to: "/production", label: "Production Logs", icon: "\u2699" },
  { to: "/production-report", label: "Production Report", icon: "\u25A9" },
  { to: "/oee", label: "OEE Report", icon: "\u25CE" },
  { to: "/press-stock", label: "Press Strokes", icon: "\u25C9" },
  { to: "/pdi", label: "PDI Checklist", icon: "\u2713" },
  { to: "/finished-goods", label: "Finished Goods & Dispatch", icon: "\u25A6" },
  { to: "/schedule", label: "Customer Schedule", icon: "\u2317" },
  { to: "/stock", label: "Stock & Shortage", icon: "\u25B3" },
  { to: "/reports", label: "Reports", icon: "\u25A7" },
];

export default function Layout({ children }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div className="min-h-screen flex">
      <aside className="w-[280px] fixed inset-y-0 left-0 bg-white/60 backdrop-blur-md border-r border-black/5 flex flex-col">
        <div className="px-5 py-5 border-b border-black/5 flex items-center gap-3">
          <img src="/chanda-logo.jpeg" alt="Chanda Enterprises" className="w-10 h-10 rounded-md object-contain shrink-0" />
          <div>
            <div className="text-xs uppercase tracking-widest text-ink-soft">Chanda Enterprises</div>
            <div className="text-lg font-semibold text-brand mt-0.5">PPC — Production</div>
          </div>
        </div>
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/"}
              className={({ isActive }) => (isActive ? "nav-item-active" : "nav-item")}
            >
              <span className="text-base">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
          {user?.role === "admin" && (
            <NavLink to="/master-data" className={({ isActive }) => (isActive ? "nav-item-active" : "nav-item")}>
              <span className="text-base">&#9881;</span>
              Master Data
            </NavLink>
          )}
          {user?.role === "admin" && (
  <NavLink to="/users" className={({ isActive }) => (isActive ? "nav-item-active" : "nav-item")}>
    <span className="text-base">&#9786;</span>
    Manage Users
  </NavLink>
)}
<NavLink to="/settings" className={({ isActive }) => (isActive ? "nav-item-active" : "nav-item")}>
  <span className="text-base">&#9776;</span>
  Settings
</NavLink>
        </nav>
        <div className="px-4 py-4 border-t border-black/5">
          <div className="text-sm font-medium">{user?.full_name || user?.username}</div>
          <div className="text-xs text-ink-soft capitalize">{user?.role}</div>
          <button onClick={handleLogout} className="btn-secondary w-full mt-3 text-xs">
            Log out
          </button>
        </div>
      </aside>

      <div className="ml-[280px] flex-1 flex flex-col min-h-screen">
        <header className="sticky top-0 z-10 bg-white/70 backdrop-blur-md border-b border-black/5 px-6 py-3.5">
          <div className="text-xs text-ink-soft">Standalone system — zero connection to Store</div>
        </header>
        <motion.main
          className="flex-1 p-6"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.25 }}
        >
          {children}
        </motion.main>
      </div>
    </div>
  );
}
