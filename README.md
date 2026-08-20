# SQL Fundamentals

Notes, worked solutions and a data quality assessment, written as I built up SQL for data and BI analyst work.

Everything runs against a small practice database — a staff roster for a multi-site retail operation — so the questions stay close to the kind a real business would ask. Each file covers one topic and ends with exercises and written findings.

**Start here:** [`data-quality-report.md`](data-quality-report.md) — a written assessment of the dataset, covering duplicates, missing values, range violations, join integrity and type consistency, with the issues found, their size, and what I'd do about each.

---

## Contents

| File | Topic |
|---|---|
| `01-setup.sql` | Creates the practice database and loads the data |
| `02-select-basics.sql` | SELECT, WHERE, ORDER BY, LIMIT |
| `03-aggregation.sql` | COUNT, SUM, AVG, GROUP BY, HAVING, execution order |
| `04-joins.sql` | INNER JOIN, LEFT JOIN, NULL handling, joins with GROUP BY |
| `05-case-subqueries.sql` | CASE WHEN, conditional aggregation, subqueries, CTEs |
| `06-data-profiling.sql` | Duplicates, missing values, ranges, categories, join integrity, data types |
| `06b-dirty-data.sql` | Deliberately corrupts the data so the profiling checks have something to find |
| `data-quality-report.md` | Written data quality assessment |

---

## Setup

1. Install [DB Browser for SQLite](https://sqlitebrowser.org) — free, Windows/Mac/Linux
2. Open it → **New Database** → save as `practice.db`
3. Go to the **Execute SQL** tab
4. Paste and run `01-setup.sql` — this creates the tables and loads the data
5. Work through the numbered files in order, one query at a time
6. Click **Write Changes** on the toolbar before closing, or nothing is saved

To reset at any point, re-run `01-setup.sql` — it drops and rebuilds both tables.

---

## The data

**`staff`** — people across three sites
`staff_id · first_name · last_name · role · site · hourly_rate · start_date`

**`shifts`** — rostered shifts
`shift_id · staff_id · shift_date · start_time · hours · is_overnight`

The two tables link on `staff_id`.

---

## On the profiling exercise

The practice data was clean by construction, so every profiling check passed on the first run. A check that passes when nothing is wrong looks identical to a check that doesn't work at all.

`06b-dirty-data.sql` plants realistic problems — a duplicated person under a second ID, whitespace and casing variants, placeholder values, implausible pay rates, impossible shift lengths, an invalid flag value — and file 06 is then re-run against them.

Three of the planted problems were rejected outright by the schema's `PRIMARY KEY`, `NOT NULL` and `FOREIGN KEY` constraints. That turned out to be the more useful finding: it separates what the database guarantees from what has to be checked manually, and section 7 of file 06 adds the checks that were missing after reviewing the method.

---

## Progress

- [x] SELECT, WHERE, ORDER BY
- [x] Aggregations — COUNT, SUM, AVG, GROUP BY, HAVING
- [x] JOINs — INNER, LEFT, NULL handling
- [x] CASE WHEN and conditional aggregation
- [x] Subqueries and CTEs
- [x] Data profiling and quality assessment
- [ ] Window functions
- [ ] Date and time-series handling