/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          dark: "#7f1d1d",
          DEFAULT: "#c1121f",
          light: "#e8590c",
          accent: "#d7263d",
        },
        success: "#10b981",
        warning: "#f59e0b",
        danger: "#ef4444",
        info: "#3b82f6",
        ink: "#262322",
        "ink-soft": "#6b6360",
        offwhite: "#f7f5f3",
      },
      fontFamily: {
        sans: ["Segoe UI", "Tahoma", "Geneva", "Verdana", "sans-serif"],
      },
      backgroundImage: {
        "app-gradient": "linear-gradient(180deg, #ffffff 0%, #f7f5f3 100%)",
      },
    },
  },
  plugins: [],
};
