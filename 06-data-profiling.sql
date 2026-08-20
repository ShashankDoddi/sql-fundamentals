-- ============================================================
-- 06 - Data profiling
--
-- Analysis asks "what does this data say?"
-- Profiling asks "can I trust this data at all?"
-- Profiling comes first. Always.
--
-- The output of profiling is not a number. It is a written list
-- of the problems found and what to do about each one. That list
-- is a data quality report, and producing one is a real job.
--
-- NOTE: this file was run against a deliberately corrupted copy of
-- the practice database (see 06b-dirty-data.sql). A profiling pass
-- where nothing is found proves nothing — it does not show the
-- checks are capable of catching anything.
-- ============================================================


-- ------------------------------------------------------------
-- 0. Read the schema first
-- ------------------------------------------------------------

-- Before profiling, find out what the database already prevents.
-- A check the schema enforces will always pass, and a passing
-- check that could never fail tells you nothing.
SELECT sql FROM sqlite_master WHERE type = 'table';

-- SQLite does not enforce foreign keys by default. Confirm before
-- relying on them. 1 = on, 0 = off.
PRAGMA foreign_keys;


-- ------------------------------------------------------------
-- 1. How much is here, and is any of it duplicated?
-- ------------------------------------------------------------

SELECT COUNT(*) AS row_count FROM staff;
SELECT COUNT(*) AS row_count FROM shifts;

SELECT COUNT(*)                 AS total_rows,
       COUNT(DISTINCT staff_id) AS distinct_ids
FROM staff;

-- Duplicate IDs. Guaranteed empty here — PRIMARY KEY prevents them.
SELECT staff_id, COUNT(*) AS times_seen
FROM staff
GROUP BY staff_id
HAVING COUNT(*) > 1;

-- Duplicate PEOPLE under different IDs. Nothing prevents this,
-- so this is the check that matters.
SELECT first_name, last_name, COUNT(*) AS times_seen
FROM staff
GROUP BY first_name, last_name
HAVING COUNT(*) > 1;

-- The same shift entered twice: same person, date and start time.
SELECT staff_id, shift_date, start_time, COUNT(*) AS times_seen
FROM shifts
GROUP BY staff_id, shift_date, start_time
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 2. What is missing?
-- ------------------------------------------------------------

-- COUNT(column) skips NULLs, COUNT(*) does not. The gap is the
-- NULL count. This proves absence of NULLs, NOT absence of
-- missing values.
SELECT COUNT(*)           AS rows_total,
       COUNT(first_name)  AS has_first_name,
       COUNT(last_name)   AS has_last_name,
       COUNT(hourly_rate) AS has_rate,
       COUNT(site)        AS has_site,
       COUNT(role)        AS has_role
FROM staff;

-- Missingness disguises itself. '', ' ' and 'N/A' are not NULL.
-- All look blank on screen and all behave differently in SQL.
SELECT COUNT(*) AS blank_looking_sites
FROM staff
WHERE site IS NULL
   OR TRIM(site) = ''
   OR UPPER(TRIM(site)) IN ('N/A', 'NA', 'UNKNOWN', 'NULL', '-');

-- A zero may be a real measurement or a missing value in disguise.
-- You cannot tell from the data — you have to ask.
SELECT COUNT(*) AS zero_hour_shifts
FROM shifts
WHERE hours = 0;


-- ------------------------------------------------------------
-- 3. What is the range? (impossible values)
-- ------------------------------------------------------------

SELECT MIN(hourly_rate)          AS min_rate,
       MAX(hourly_rate)          AS max_rate,
       ROUND(AVG(hourly_rate),2) AS avg_rate
FROM staff;

SELECT MIN(hours)      AS min_hours,
       MAX(hours)      AS max_hours,
       MIN(shift_date) AS earliest,
       MAX(shift_date) AS latest
FROM shifts;

-- State what "impossible" means for this data, then look for it.
SELECT *
FROM shifts
WHERE hours <= 0 OR hours > 16;

SELECT staff_id, first_name, hourly_rate
FROM staff
WHERE hourly_rate < 20 OR hourly_rate > 100;


-- ------------------------------------------------------------
-- 4. What are the actual categories?
-- ------------------------------------------------------------

SELECT site, COUNT(*) AS staff_count
FROM staff
GROUP BY site
ORDER BY staff_count DESC;

SELECT role, COUNT(*) AS staff_count
FROM staff
GROUP BY role
ORDER BY staff_count DESC;

-- Raw vs normalised, counted rather than eyeballed. If these two
-- numbers differ, casing or whitespace variants exist.
SELECT COUNT(DISTINCT site)                AS raw_spellings,
       COUNT(DISTINCT UPPER(TRIM(site)))   AS normalised_values
FROM staff;

-- A flag column should only ever hold its allowed values.
SELECT is_overnight, COUNT(*) AS times_seen
FROM shifts
GROUP BY is_overnight;


-- ------------------------------------------------------------
-- 5. Does it join cleanly?
-- ------------------------------------------------------------

-- Orphan shifts. Guaranteed empty here — FOREIGN KEY prevents them.
-- Essential on any table without that constraint.
SELECT COUNT(*)      AS orphan_shifts,
       SUM(sh.hours) AS orphan_hours
FROM shifts AS sh
LEFT JOIN staff AS st ON sh.staff_id = st.staff_id
WHERE st.staff_id IS NULL;

-- The other direction: staff with no shifts. Not an error, but you
-- must know before dividing a total by "number of staff".
SELECT st.staff_id, st.first_name, st.last_name
FROM staff AS st
LEFT JOIN shifts AS sh ON st.staff_id = sh.staff_id
WHERE sh.staff_id IS NULL;

-- Proof a join did not change the row count.
SELECT (SELECT COUNT(*) FROM shifts) AS shifts_before,
       (SELECT COUNT(*) FROM shifts AS sh
        INNER JOIN staff AS st ON sh.staff_id = st.staff_id) AS shifts_after;


-- ------------------------------------------------------------
-- 6. Data types
-- ------------------------------------------------------------

-- Text sorts alphabetically, not chronologically. '9:00' is
-- GREATER than '12:00' as text, because '9' > '1'.
SELECT LENGTH(start_time) AS characters,
       COUNT(*)           AS times_seen
FROM shifts
GROUP BY LENGTH(start_time);


-- ============================================================
-- EXERCISES — worked answers with findings
-- ============================================================

-- Q1. Confirm whether shifts contains any duplicate rows for the
--     same staff member, date and start time. State how many.
SELECT staff_id, shift_date, start_time, COUNT(*) AS times_seen
FROM shifts
GROUP BY staff_id, shift_date, start_time
HAVING COUNT(*) > 1;
-- Finding: 1 duplicate pair (2 rows) — staff_id 1, 2026-08-01, 22:00.
-- Hours for that shift are double-counted in any SUM.


-- Q2. Produce a single result showing, for every column in staff,
--     how many rows have a value. Which column is least complete?
SELECT COUNT(*)           AS total_rows,
       COUNT(first_name)  AS has_first_name,
       COUNT(last_name)   AS has_last_name,
       COUNT(hourly_rate) AS has_rate,
       COUNT(site)        AS has_site,
       COUNT(role)        AS has_role
FROM staff;
-- Finding: no NULLs in any column. This does NOT mean no missing
-- values — COUNT() treats '', ' ' and 'N/A' as present. See Q4.


-- Q3. Find any shift with hours outside a plausible range that you
--     define yourself. State the range you chose and why.
SELECT *
FROM shifts
WHERE hours <= 0 OR hours > 16;
-- Range chosen: greater than 0 and up to 16 hours. A shift of zero
-- hours records no work and is almost certainly an entry error;
-- 16 hours exceeds any lawful single shift under Australian
-- workplace rules.
-- Finding: 2 rows outside range — 0.0 hours (shift 22) and
-- 26.0 hours (shift 23).


-- Q4. List the distinct values of site exactly as stored, then list
--     them normalised with UPPER(TRIM(...)). Do the two counts match?
SELECT COUNT(DISTINCT site)              AS raw_spellings,
       COUNT(DISTINCT UPPER(TRIM(site))) AS normalised_values
FROM staff;
-- Counted rather than eyeballed — a trailing space is invisible in
-- a visual comparison and this scales to any table size.

SELECT site, COUNT(*) AS staff_count
FROM staff
GROUP BY site
ORDER BY site;
-- Finding: raw count exceeds normalised count, so variants exist.
-- 'prospect ' (trailing space, lowercase) groups separately from
-- 'Prospect'. Also present: 'N/A' and '' as site values — blank in
-- appearance, not NULL, and invisible to the Q2 check.


-- Q5. Are there shifts whose staff_id does not exist in staff?
--     How many hours do they represent?
SELECT COUNT(*)      AS orphan_shifts,
       SUM(sh.hours) AS orphan_hours
FROM shifts AS sh
LEFT JOIN staff AS st ON sh.staff_id = st.staff_id
WHERE st.staff_id IS NULL;
-- Finding: 0 orphan shifts. Not a discovery about the data — the
-- FOREIGN KEY on shifts.staff_id makes this impossible. Confirmed
-- PRAGMA foreign_keys = 1 before relying on it.


-- Q6. Are there staff who have never worked a shift?
SELECT st.staff_id, st.first_name, st.last_name
FROM staff AS st
LEFT JOIN shifts AS sh ON st.staff_id = sh.staff_id
WHERE sh.staff_id IS NULL;
-- Finding: several staff have no shifts recorded, including Noah
-- Fischer and Grace Okafor. Not an error, but they must be excluded
-- from any per-shift average, and included in any headcount.


-- Q7. Check whether start_time is stored consistently. Is it safe to
--     compare it as text, as you did in file 05 Q2?
SELECT LENGTH(start_time) AS characters,
       COUNT(*)           AS times_seen
FROM shifts
GROUP BY LENGTH(start_time);
-- Finding: NOT safe. One row stores '9:00' (4 characters) where all
-- others store 5. As text, '9:00' > '12:00', so a morning/afternoon
-- classification comparing against '12:00' would misclassify it —
-- silently, with no error. Pad to HH:MM, or extract the hour and
-- cast to integer before comparing.


-- ------------------------------------------------------------
-- 7. Checks added after reviewing the method
-- ------------------------------------------------------------

-- Two categories of problem would have slipped through the checks
-- above. Both are added here.

-- GAP 1: blank/placeholder detection was applied to site only.
-- The same disguises can appear in any text column. A role of
-- 'N/A' passes both the NOT NULL constraint and every check above.
SELECT 'role' AS column_name, COUNT(*) AS blank_looking
FROM staff
WHERE role IS NULL
   OR TRIM(role) = ''
   OR UPPER(TRIM(role)) IN ('N/A', 'NA', 'UNKNOWN', 'NULL', '-')
UNION ALL
SELECT 'first_name', COUNT(*)
FROM staff
WHERE first_name IS NULL
   OR TRIM(first_name) = ''
   OR UPPER(TRIM(first_name)) IN ('N/A', 'NA', 'UNKNOWN', 'NULL', '-')
UNION ALL
SELECT 'last_name', COUNT(*)
FROM staff
WHERE last_name IS NULL
   OR TRIM(last_name) = ''
   OR UPPER(TRIM(last_name)) IN ('N/A', 'NA', 'UNKNOWN', 'NULL', '-')
UNION ALL
SELECT 'site', COUNT(*)
FROM staff
WHERE site IS NULL
   OR TRIM(site) = ''
   OR UPPER(TRIM(site)) IN ('N/A', 'NA', 'UNKNOWN', 'NULL', '-');
-- UNION ALL stacks separate result sets into one column of results,
-- so every text column is reported in a single output.


-- GAP 2: no cross-field consistency checks were run. Every check
-- above examined one column in isolation. These test whether
-- columns AGREE with each other — where each individual value
-- looks perfectly plausible on its own.

-- 2a. Flagged overnight but starting in the morning.
SELECT shift_id, staff_id, shift_date, start_time, is_overnight
FROM shifts
WHERE is_overnight = 1
  AND CAST(SUBSTR(start_time, 1, INSTR(start_time, ':') - 1) AS INTEGER) < 12;

-- 2b. Not flagged overnight but starting at or after 10pm.
SELECT shift_id, staff_id, shift_date, start_time, is_overnight
FROM shifts
WHERE is_overnight = 0
  AND CAST(SUBSTR(start_time, 1, INSTR(start_time, ':') - 1) AS INTEGER) >= 22;

-- 2c. Flag holding a value outside its allowed set.
SELECT shift_id, staff_id, is_overnight
FROM shifts
WHERE is_overnight NOT IN (0, 1);

-- 2d. Shift long enough to run past its own recorded date.
SELECT shift_id, staff_id, shift_date, start_time, hours
FROM shifts
WHERE CAST(SUBSTR(start_time, 1, INSTR(start_time, ':') - 1) AS INTEGER)
      + hours > 30;


-- ============================================================
-- Q8. DATA QUALITY SUMMARY
-- staff (17 rows) and shifts (25 rows).
-- Row counts verified against expected values before profiling.
-- ============================================================
/*
CONSTRAINT-ENFORCED — cannot occur in this schema
Issue                             Prevented by
--------------------------------------------------------------------------
Duplicate staff_id                PRIMARY KEY on staff.staff_id
Missing role                      NOT NULL on staff.role
Orphan shifts                     FOREIGN KEY on shifts.staff_id

SQLite does not enforce foreign keys by default. PRAGMA foreign_keys was
confirmed = 1 before relying on the third guarantee.


ISSUES FOUND — require cleaning before analysis
Issue                          Size                        Action
--------------------------------------------------------------------------
Same person, two IDs           1 pair (2 rows)             Confirm with HR,
                               Priya Nair, IDs 1 and 13    merge, consolidate
                                                           hours
Duplicate shift record         1 pair (2 rows)             Remove duplicate,
                               shift 21 repeats shift 1    verify vs roster
Casing/whitespace in site      1 row — 'prospect '         Standardise on
                                                           write; UPPER(TRIM())
                                                           when grouping
Placeholder/blank site         2 rows — 'N/A' and ''       Establish meaning,
                                                           recode or set NULL
Implausible hourly_rate        1 row — $285.00 against     Likely decimal entry
                               a $26-$42 range             error; confirm
                                                           before payroll
                                                           reporting
Impossible shift lengths       2 rows — 0.0 and 26.0 hrs   Investigate source;
                                                           no lawful shift
                                                           exceeds 16h
Inconsistent time format       1 row — '9:00'              Pad to HH:MM; text
                                                           comparison unsafe
                                                           until fixed
Invalid flag value             1 row — is_overnight = 2    Recode to 0/1; add
                                                           CHECK constraint


GAPS IN THE CHECKS — found on review, now closed (section 7)
1. Blank/placeholder detection ran on site only. Never applied to role,
   first_name or last_name. A role of 'N/A' would pass both the NOT NULL
   constraint and every original check.

2. No cross-field consistency checks. Every original check examined one
   column in isolation. Nothing tested whether columns agree with each
   other — a shift flagged overnight but starting at 06:00, or a shift
   long enough to run past its own date. In production data this is
   usually where the most damaging errors sit, because each individual
   value looks entirely plausible.


CONCLUSION
Not currently safe for reporting on hours or wage cost. The duplicate
person and duplicate shift would overstate both, and neither produces an
error — the totals would simply be wrong and look reasonable. Remaining
issues are lower severity but would fragment any grouping by site and
misclassify one shift.

Estimated effort to clean: under a day, assuming source records are
available to confirm correct values.
*/
