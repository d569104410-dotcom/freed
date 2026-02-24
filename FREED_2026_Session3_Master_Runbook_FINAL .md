
# FREED 2026 — Session 3 Executor Master Runbook (FINAL)
## Batch 1/4 Freeze + Gatekeeper B1→B4 + ALL
### Purpose
This single runbook is the **master operational reference** for Session 3 (Executor): baseline DB setup, schema+seed execution, Gatekeeper validation (B1→B4 / ALL), PASS/FAIL rules, failure handling path, and freeze verdict template.

---

## 0) Scope and Inputs
### Required Inputs
- `schema.mysql.sql`
- `seed.mysql.sql`
- `RUN_S3_GATEKEEPER_B1_DEMO_2026.sql`
- `RUN_S3_GATEKEEPER_B2_DEMO_2026.sql`
- `RUN_S3_GATEKEEPER_B3_DEMO_2026.sql`
- `RUN_S3_GATEKEEPER_B4_DEMO_2026.sql`
- `RUN_S3_GATEKEEPER_ALL_DEMO_2026.sql`

### Key Data Rules (Confirmed)
- SSOT table name is **`allocations`**
- Table **`finance_allocations` must NOT exist**
- Demo dataset ID = **`DEMO_2026`**
- Bootstrap rows use:
  - `demo_marker = 0`
  - `demo_dataset_id IS NULL`
- Demo rows use:
  - `demo_marker = 1`
  - `demo_dataset_id = 'DEMO_2026'`

### Important Runtime Note
`RUN_S3_GATEKEEPER_ALL_DEMO_2026.sql` uses `SOURCE` with **relative filenames**, so run it from the same folder (or run B1→B4 separately).

---

## 1) Consistency Audit Summary (PASS / Warnings Only)
## Overall Result
**CONSISTENCY AUDIT = PASS ✅**

### PASS Items
- `schema.mysql.sql` matches Batch1 freeze package copy (byte/hash match)
- `seed.mysql.sql` matches Batch1 freeze package copy (byte/hash match)
- Gatekeeper scripts B1/B2/B3/B4/ALL match the pack copies (byte/hash match)
- `FREEZE_NOTES_SESSION1_BATCH1.md` hash expectation aligns with current `seed.mysql.sql` (`$2b$10$...`)
- B1 checks align with actual schema fields/tables
- B2 checks align with actual seed data and counts
- B3 orphan checks align with reference patterns used in seed
- B4 date/FX checks align with current demo records

### Warning (Non-Blocking)
- `RUN_S3_GATEKEEPER_ALL_DEMO_2026.sql` uses relative `SOURCE` paths and may fail if launched from a different working folder.

---

## 2) Session 3 — Claude Executor Playbook (Short)
1. **Preflight**
   - Use a clean MySQL 8.x database
   - Set charset/collation to `utf8mb4 / utf8mb4_unicode_ci`
   - Ensure schema/seed + Gatekeeper B1..B4 + ALL are available

2. **Baseline Load (Batch 1/4)**
   - Run `schema.mysql.sql`
   - Run `seed.mysql.sql`

3. **Baseline Validation**
   - Run Gatekeeper B1 → B2 → B3 → B4
   - Baseline is valid only if all checks return `PASS`

4. **Build Batch 2**
   - Implement B2 scope (finance / RBAC runtime / attachments as per project plan)
   - Run local/API/UI tests
   - Re-run Gatekeeper B2 (recommended B3/B4 quick regression)

5. **Build Batch 3**
   - Implement B3 scope (initiatives/tasks flows)
   - Run local/API/UI tests
   - Re-run Gatekeeper B3 (recommended B2/B4 quick regression)

6. **Build Batch 4**
   - Implement B4 scope (recon/reporting/ops/hardening per project plan)
   - Run local/API/UI tests
   - Re-run Gatekeeper B4

7. **Final Verdict**
   - Run Gatekeeper ALL (or B1→B4 separately)
   - Update Freeze Verdict record
   - Declare `PASS` / `FAIL` / `HOLD`

8. **Failure Rule**
   - Do **NOT** modify SSOT schema/seed in Session 3
   - On failure: clean DB / recreate DB / rerun in correct order only

---

## 3) Freeze Verdict Template (PASS / FAIL / HOLD)
```md
# FREEZE VERDICT — Session 3 (Executor) — FREED 2026

## Context
- Scope: Batch [B1/B2/B3/B4/ALL]
- Dataset: DEMO_2026
- Environment: MySQL 8.x
- DB Charset/Collation: utf8mb4 / utf8mb4_unicode_ci
- Execution Date: [YYYY-MM-DD]
- Executor: [Name / Claude Session ID]
- Gatekeeper Pack Version: Session3 Gatekeeper SQL Pack (current)

---

## Inputs Used
- schema.mysql.sql: [path]
- seed.mysql.sql: [path]
- RUN_S3_GATEKEEPER_B1_DEMO_2026.sql: [path]
- RUN_S3_GATEKEEPER_B2_DEMO_2026.sql: [path]
- RUN_S3_GATEKEEPER_B3_DEMO_2026.sql: [path]
- RUN_S3_GATEKEEPER_B4_DEMO_2026.sql: [path]
- RUN_S3_GATEKEEPER_ALL_DEMO_2026.sql: [path]

---

## Execution Sequence
1. [ ] Created clean database
2. [ ] Ran schema
3. [ ] Ran seed
4. [ ] Ran Gatekeeper B1
5. [ ] Ran Gatekeeper B2
6. [ ] Ran Gatekeeper B3
7. [ ] Ran Gatekeeper B4
8. [ ] Ran Gatekeeper ALL (optional/recommended)

---

## Gatekeeper Results Summary

### B1 — Schema Checks
- Status: [PASS / FAIL / HOLD]
- Failed Checks (if any): [None / list]
- Notes: [text]

### B2 — Data Checks
- Status: [PASS / FAIL / HOLD]
- Failed Checks (if any): [None / list]
- Notes: [text]

### B3 — Integrity Checks
- Status: [PASS / FAIL / HOLD]
- Failed Checks (if any): [None / list]
- Notes: [text]

### B4 — Reconciliation Checks
- Status: [PASS / FAIL / HOLD]
- Failed Checks (if any): [None / list]
- Notes: [text]

### ALL — Combined Run
- Status: [PASS / FAIL / NOT_RUN]
- Notes: [text]

---

## Build/Test Status (for current batch scope)
- API Tests: [PASS / FAIL / N/A]
- UI Smoke Tests: [PASS / FAIL / N/A]
- Regression Tests: [PASS / FAIL / N/A]
- Evidence Logs: [paths]

---

## Risks / Warnings (No SSOT changes)
- [None / list]
- Example: RUN_S3_GATEKEEPER_ALL uses relative SOURCE paths; run from same folder.

---

## Final Verdict
- **Verdict:** [PASS / FAIL / HOLD]
- **Decision Rule Applied:** If any Gatekeeper check result = FAIL => batch verdict FAIL.
- **Next Action:** [Proceed to next batch / Rebuild clean DB / Investigate logs / Hold for review]

---

## Sign-off
- Executor: [name]
- Gatekeeper Reviewer: [name]
- Timestamp: [ISO datetime]
```

---

## 4) Unified Command Pack (Windows + Linux + mysql SOURCE)

### A) Create Clean Database — Linux / macOS / Git Bash
```bash
mysql -h <HOST> -P <PORT> -u <USER> -p -e "CREATE DATABASE <DB_NAME_NEW> CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME_NEW> < /path/to/schema.mysql.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME_NEW> < /path/to/seed.mysql.sql
```

### B) Create Clean Database — Windows CMD
```cmd
mysql -h <HOST> -P <PORT> -u <USER> -p -e "CREATE DATABASE <DB_NAME_NEW> CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME_NEW> < C:\path\to\schema.mysql.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME_NEW> < C:\path\to\seed.mysql.sql
```

### C) Create Clean Database — Windows PowerShell
```powershell
& mysql -h <HOST> -P <PORT> -u <USER> -p -e "CREATE DATABASE <DB_NAME_NEW> CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME_NEW> < C:\path\to\schema.mysql.sql
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME_NEW> < C:\path\to\seed.mysql.sql
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

### D) Verify DB Charset/Collation
```sql
SELECT @@character_set_database, @@collation_database;
```
Expected:
- `utf8mb4`
- `utf8mb4_unicode_ci`

### E) Run Gatekeeper B1→B4 (Recommended — Separate)
#### Linux / Git Bash
```bash
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < /path/to/RUN_S3_GATEKEEPER_B1_DEMO_2026.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < /path/to/RUN_S3_GATEKEEPER_B2_DEMO_2026.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < /path/to/RUN_S3_GATEKEEPER_B3_DEMO_2026.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < /path/to/RUN_S3_GATEKEEPER_B4_DEMO_2026.sql
```

#### Windows CMD
```cmd
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B1_DEMO_2026.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B2_DEMO_2026.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B3_DEMO_2026.sql
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B4_DEMO_2026.sql
```

#### Windows PowerShell
```powershell
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B1_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B2_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B3_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\path\to\RUN_S3_GATEKEEPER_B4_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

### F) Run Gatekeeper ALL (Interactive mysql; depends on SOURCE relative paths)
```bash
mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME>
```
Then inside mysql:
```sql
SOURCE /path/to/RUN_S3_GATEKEEPER_ALL_DEMO_2026.sql;
```

If `ALL` fails due to relative paths, run B1→B4 separately and use those outputs as the official verdict.

### G) PowerShell Quick Pipeline (Schema + Seed + B1..B4)
```powershell
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\install\schema.mysql.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\install\seed.mysql.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\gatekeeper\RUN_S3_GATEKEEPER_B1_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\gatekeeper\RUN_S3_GATEKEEPER_B2_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\gatekeeper\RUN_S3_GATEKEEPER_B3_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& mysql --default-character-set=utf8mb4 -h <HOST> -P <PORT> -u <USER> -p <DB_NAME> < C:\gatekeeper\RUN_S3_GATEKEEPER_B4_DEMO_2026.sql; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

### H) PASS / FAIL / HOLD Rule (Operational)
- **PASS**: all Gatekeeper checks return `PASS`
- **FAIL**: any Gatekeeper check returns `FAIL` or SQL execution error occurs
- **HOLD**: verification could not be completed (e.g., path/environment issue) without evidence of PASS/FAIL

---

## 5) Troubleshooting (No SSOT Changes)
### Duplicate Key Errors
Cause: seed re-run on non-clean DB.  
Action:
1. Create a **new clean database**
2. Re-run schema then seed
3. Re-run Gatekeeper B1→B4

### FK Errors
Cause: wrong execution order or partial seed.  
Action:
1. Confirm schema ran completely first
2. Use clean DB
3. Re-run schema then seed in exact order

### Encoding Issues (Arabic text garbled)
Action:
1. Use `--default-character-set=utf8mb4`
2. Create DB with `utf8mb4` + `utf8mb4_unicode_ci`
3. Verify:
   `SELECT @@character_set_database, @@collation_database;`

### Seed Run Before Schema
Cause: missing tables / columns.  
Action:
1. Stop
2. Create clean DB
3. Run schema first, then seed

### MySQL 8 Environment Differences
Action:
1. Confirm MySQL 8.x
2. Re-run on clean DB with utf8mb4
3. Run B1 first to confirm schema compatibility before any build steps

---

## 6) Final Operational Rule
Session 3 is **Executor only**:
- Execute in order
- Validate with Gatekeeper
- Record verdict
- Do not modify SSOT schema/seed in this session
