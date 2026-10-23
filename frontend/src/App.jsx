import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import ProtectedRoute from "./components/ProtectedRoute";

import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import RouteCards from "./pages/RouteCards";
import ProductionEntry from "./pages/ProductionEntry";
import ProductionReport from "./pages/ProductionReport";
import OeeReport from "./pages/OeeReport";
import FinishedGoodsDispatch from "./pages/FinishedGoodsDispatch";
import CustomerSchedule from "./pages/CustomerSchedule";
import MasterData from "./pages/MasterData";
import PressStock from "./pages/PressStock";
import Reports from "./pages/Reports";
import ManageUsers from "./pages/ManageUsers";
import Settings from "./pages/Settings";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          {/* <Route path="/route-cards" element={<ProtectedRoute><RouteCards /></ProtectedRoute>} /> */}
          <Route path="/production" element={<ProtectedRoute><ProductionEntry /></ProtectedRoute>} />
          <Route path="/production-report" element={<ProtectedRoute><ProductionReport /></ProtectedRoute>} />
          <Route path="/oee" element={<ProtectedRoute><OeeReport /></ProtectedRoute>} />
          <Route path="/press-stock" element={<ProtectedRoute><PressStock /></ProtectedRoute>} />
          <Route path="/finished-goods" element={<ProtectedRoute><FinishedGoodsDispatch /></ProtectedRoute>} />
          <Route path="/schedule" element={<ProtectedRoute><CustomerSchedule /></ProtectedRoute>} />
          <Route path="/reports" element={<ProtectedRoute><Reports /></ProtectedRoute>} />
          <Route path="/master-data" element={<ProtectedRoute><MasterData /></ProtectedRoute>} />
          <Route path="/users" element={<ProtectedRoute><ManageUsers /></ProtectedRoute>} />
          <Route path="/settings" element={<ProtectedRoute><Settings /></ProtectedRoute>} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
