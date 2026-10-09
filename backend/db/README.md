# backend/db

init/       Naya (khaali) database banne par Docker ye files number ke order me apne aap chalata hai.
            Existing database par ye dobara NAHI chalti.
patches/    Haath se ek baar chalayi gayi fixes aur naye parts. Live database me already lagi hui hain.
            Dobara chalane se pehle dekh lena - kuch patches do baar chalane par data double kar sakti hain.
imports/    Purane data ke bulk imports.
history/    Purani sql_history.
schema_baseline.sql   Live database ke structure ka snapshot (pg_dump --schema-only).

Naya patch likho to naam me tareekh rakho (jaise patch_2026-10-09_kuch_fix.sql) aur patches/ me daalo.

Backup (hafte me ek baar):
  docker exec chanda_ppe_db pg_dump -U ppe_user -d chanda_ppe -F c -f /tmp/backup.dump
  docker cp chanda_ppe_db:/tmp/backup.dump C:\Users\HP\Downloads\chanda_ppe_backup_TAREEKH.dump