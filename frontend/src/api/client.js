import axios from "axios";

// Points at the standalone PPE backend — never at Store. Configurable via
// VITE_API_URL at build time (see .env.example); defaults to the local
// docker-compose service name/port.
const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8010";

const api = axios.create({ baseURL: API_URL });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("ppe_token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem("ppe_token");
      localStorage.removeItem("ppe_user");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }
    return Promise.reject(err);
  }
);

export default api;
export { API_URL };
