import { useEffect, useState } from "react";

const pad2 = (n) => String(n).padStart(2, "0");

// "17:05:00" or "17:05" -> "5:05 PM". Empty -> a dash.
export function fmtTime(t) {
  if (!t) return "\u2014";
  const [hh, mm] = String(t).split(":");
  const h = Number(hh);
  if (Number.isNaN(h) || mm == null) return String(t);
  return `${h % 12 || 12}:${mm.slice(0, 2)} ${h >= 12 ? "PM" : "AM"}`;
}

// End time for tables: marks a night shift that ended the next day.
export function fmtEndTime(start, end) {
  if (!end) return "\u2014";
  const next = start && String(end).slice(0, 5) < String(start).slice(0, 5);
  return next ? `${fmtTime(end)} (next day)` : fmtTime(end);
}

const to24 = (h12, m, ap) => {
  const h = Number(h12);
  const h24 = ap === "AM" ? (h === 12 ? 0 : h) : h === 12 ? 12 : h + 12;
  return `${pad2(h24)}:${pad2(Number(m))}`;
};

const parse = (value) => {
  if (!value) return { h: "", m: "", ap: "" };
  const [hh, mm] = String(value).split(":");
  const h24 = Number(hh);
  if (Number.isNaN(h24) || mm == null) return { h: "", m: "", ap: "" };
  return { h: String(h24 % 12 || 12), m: pad2(Number(mm.slice(0, 2))), ap: h24 >= 12 ? "PM" : "AM" };
};

/**
 * Time picker with Hour / Minute / AM-PM written out, so 6 in the evening is never
 * saved as 6 in the morning by mistake. `value` and `onChange` use 24-hour "HH:MM".
 */
export default function TimeInput({ value, onChange }) {
  const [parts, setParts] = useState(() => parse(value));
  const complete = parts.h && parts.m !== "" && parts.ap;
  const composed = complete ? to24(parts.h, parts.m, parts.ap) : "";

  // The form was cleared or changed from outside (for example after saving): follow it.
  useEffect(() => {
    if ((value || "") !== composed) setParts(parse(value));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const set = (key, v) => {
    const next = { ...parts, [key]: v };
    setParts(next);
    if (next.h && next.m !== "" && next.ap) onChange(to24(next.h, next.m, next.ap));
    else if (value) onChange("");
  };

  const partial = !complete && (parts.h || parts.m !== "" || parts.ap);

  return (
    <div>
      <div className="flex gap-2">
        <select className="input" aria-label="Hour" value={parts.h} onChange={(e) => set("h", e.target.value)}>
          <option value="">Hr</option>
          {Array.from({ length: 12 }, (_, i) => (
            <option key={i + 1} value={String(i + 1)}>
              {i + 1}
            </option>
          ))}
        </select>
        <select className="input" aria-label="Minute" value={parts.m} onChange={(e) => set("m", e.target.value)}>
          <option value="">Min</option>
          {Array.from({ length: 60 }, (_, i) => (
            <option key={i} value={pad2(i)}>
              {pad2(i)}
            </option>
          ))}
        </select>
        <select className="input" aria-label="AM or PM" value={parts.ap} onChange={(e) => set("ap", e.target.value)}>
          <option value="">AM/PM</option>
          <option value="AM">AM</option>
          <option value="PM">PM</option>
        </select>
      </div>
      {partial && <div className="text-[11px] text-danger mt-1">Pick hour, minute and AM/PM</div>}
    </div>
  );
}
