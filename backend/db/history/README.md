# sql_history/

These SQL scripts were early, one-off fixes applied manually during setup
(9–10 Sep 2026) while getting the "Handle Bar" part family (J1A and friends)
right. They are **not** wired into docker-compose.yml and are **not** needed
to run this app — everything they did is already reflected in:

- `../bom_fix_j1a_handle_bar_09sep26.sql` (J1A: Tube/Long Bush/Assembly split)
- `../bom_fix_j1a_customer_09sep26.sql` (J1A: customer name)
- `../bom_full_clone_j1a_to_8parts_10sep26.sql` (J1B, J1C, J1C2, J1C5,
  J1C5-1, J1C5-2, J1D1, V1F — full clone of J1A's structure)

Kept here only as a paper trail of what was tried, in case it's ever useful
to see how the data evolved. Safe to delete entirely if you don't need the
history.
