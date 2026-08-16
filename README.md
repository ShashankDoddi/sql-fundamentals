# SQL Fundamentals

My notes and worked solutions as I learn SQL for data and BI analyst work.

Each file is a topic. Queries are written against a small practice database — a staff roster for a multi-site retail operation — so the questions stay close to the kind a real business would ask.

## Setup

1. Install [DB Browser for SQLite](https://sqlitebrowser.org) (free, Windows/Mac/Linux)
2. Open it → **New Database** → save as `practice.db`
3. Go to the **Execute SQL** tab
4. Paste and run `01-setup.sql` — this creates the tables and loads the data
5. Work through the numbered files in order

## Contents

| File | Topic |
|---|---|
| `01-setup.sql` | Creates the practice database |
| `02-select-basics.sql` | SELECT, WHERE, ORDER BY, LIMIT |

## The data

**`staff`** — 10 people across three sites
`staff_id · first_name · last_name · role · site · hourly_rate · start_date`

**`shifts`** — 20 rostered shifts
`shift_id · staff_id · shift_date · start_time · hours · is_overnight`

The two tables link on `staff_id`.

## Progress

- [x] SELECT, WHERE, ORDER BY
- [ ] Aggregations — COUNT, SUM, AVG, GROUP BY, HAVING
- [ ] JOINs
- [ ] Subqueries and CTEs
- [ ] Window functions
- [ ] Date handling
