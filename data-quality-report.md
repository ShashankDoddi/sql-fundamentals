# Data Quality Report — Staff & Shifts Database

**Author:** Shashank Doddi
**Date:** August 2026
**Dataset:** `practice.db` — `staff` (17 rows) and `shifts` (25 rows)
**Purpose:** Assess whether this data can be trusted before any analysis is run.

---

## Summary

Eleven checks were run across both tables, covering row counts, duplicates,
missing values, value ranges, category consistency, join integrity and data
types.

**Three problem categories are impossible in this database** because the schema
prevents them. **Seven were found and require cleaning** before the data is used
for reporting. The most serious are a duplicated person recorded under two IDs
and a duplicated shift, both of which would overstate totals without producing
any error.

**Recommendation:** do not report on hours or wage cost until the duplicate
records and the impossible shift lengths are resolved.

---

## What the schema already guarantees

Before profiling, the table definitions were reviewed. Three checks were
found to be unnecessary — the database enforces them at write time, so the
problems cannot exist:

| Problem | Prevented by |
|---|---|
| Duplicate `staff_id` | `PRIMARY KEY` on `staff.staff_id` |
| Missing `role` | `NOT NULL` on `staff.role` |
| Shifts belonging to a non-existent staff member | `FOREIGN KEY` on `shifts.staff_id` |

This distinction matters: a check the schema already enforces will always pass,
and a passing check that could never fail tells you nothing about the data.

*(Note: SQLite does not enforce foreign keys by default. Enforcement was
confirmed active on this database before relying on the third guarantee.)*

---

## Issues found

| Issue | Size | Action |
|---|---|---|
| Same person under two staff IDs | 1 duplicate pair (2 rows) — Priya Nair, IDs 1 and 13 | Confirm with HR, merge to one ID and consolidate hours |
| Duplicate shift record | 1 duplicate pair (2 rows) — shift_id 21 repeats shift_id 1 | Remove the duplicate; verify hours against the roster |
| Casing and whitespace variant in `site` | 1 row — `'prospect '` vs `'Prospect'` | Standardise on write; use `UPPER(TRIM())` when grouping |
| Placeholder and blank `site` values | 2 rows — `'N/A'` and `''` | Establish what these mean; recode or set to `NULL` |
| Implausible `hourly_rate` | 1 row — $285.00 against a $26–$42 range | Likely a decimal entry error; confirm before reporting payroll |
| Impossible shift lengths | 2 rows — 0.0 and 26.0 hours | Investigate the source; no legal single shift exceeds 16 hours |
| Inconsistent time format | 1 row — `'9:00'` where all others are `'09:00'` | Pad to 5 characters; text comparison is unsafe until fixed |
| Invalid flag value | 1 row — `is_overnight = 2` | Recode to 0 or 1; add a `CHECK` constraint to prevent recurrence |

---

## Why the time format matters more than it looks

`start_time` is stored as text, and text sorts alphabetically rather than
chronologically. `'9:00'` is **greater than** `'12:00'` as text, because the
character `9` sorts after `1`.

A query classifying shifts as morning or afternoon by comparing `start_time`
against `'12:00'` would misclassify that row — and would not error. Until every
value is padded to `HH:MM`, the hour must be extracted and cast to an integer
before comparison.

---

## Gaps in the checks themselves

Two categories of problem would not have been caught by the checks run:

**1. Blank and placeholder detection was applied to `site` only.**
The same disguised-missing check (`''`, `' '`, `'N/A'`, `'Unknown'`) was never
run against `role`, `first_name` or `last_name`. A role recorded as `'N/A'`
would pass both the `NOT NULL` constraint and every check performed.

**2. No cross-field consistency checks were run.**
Every check examined one column in isolation. Nothing tested whether columns
agree with one another — for example, a shift flagged `is_overnight = 1` but
starting at 06:00, or a shift long enough to run past its own recorded date.
In production data this is usually where the most damaging errors sit, because
each individual value looks entirely plausible.

Both gaps should be closed before this profiling routine is reused on a larger
dataset.

---

## Method

| Check | Technique |
|---|---|
| Row counts | `COUNT(*)` verified against expected values before analysis |
| Duplicate keys | `GROUP BY` with `HAVING COUNT(*) > 1` |
| Duplicate entities | `GROUP BY` on the natural key (first name, last name) |
| Missing values | `COUNT(*)` vs `COUNT(column)`; plus explicit blank and placeholder tests |
| Value ranges | `MIN` / `MAX` on every numeric and date column, with plausible bounds stated in advance |
| Category consistency | `GROUP BY` raw values compared against `UPPER(TRIM())` normalised values |
| Join integrity | `LEFT JOIN` with `WHERE ... IS NULL` in both directions |
| Data types | `LENGTH()` distribution on text columns used in comparisons |

---

## Conclusion

The dataset is **not currently safe for reporting on hours or wage cost.** The
duplicate person and duplicate shift would overstate both, and neither produces
an error — the totals would simply be wrong and look reasonable.

The remaining issues are lower severity but should be resolved before the data
feeds a dashboard, since inconsistent site values would fragment any grouping
and the invalid flag value would misclassify one shift.

Estimated effort to clean: under a day, assuming source records are available to
confirm the correct values.
