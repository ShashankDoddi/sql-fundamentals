-- ============================================================
-- 06 - Data profiling
-- Run one query at a time.
--
-- Analysis asks "what does this data say?"
-- Profiling asks "can I trust this data at all?"
-- Profiling comes first. Always.
--
-- The output of profiling is not a number. It is a written list
-- of the problems you found and what you would do about each one.
-- That list is called a data quality report, and producing one is
-- a real job that employers hire for.
-- ============================================================


-- ------------------------------------------------------------
-- 1. How much is here, and is any of it duplicated?
-- ------------------------------------------------------------

-- Always start here. Every number you produce later depends on
-- this one being what you think it is.
SELECT COUNT(*) AS row_count FROM staff;
SELECT COUNT(*) AS row_count FROM shifts;

-- If these two numbers differ, you have duplicate IDs, and every
-- SUM and AVG you write afterwards is silently wrong.
SELECT COUNT(*)             AS total_rows,
       COUNT(DISTINCT staff_id) AS distinct_ids
FROM staff;

-- Which IDs are duplicated, if any. HAVING filters groups,
-- the same way WHERE filters rows.
SELECT staff_id, COUNT(*) AS times_seen
FROM staff
GROUP BY staff_id
HAVING COUNT(*) > 1;

-- Duplicates are not always duplicate IDs. The same human can be
-- entered twice under two IDs. Check the natural key too.
SELECT first_name, last_name, COUNT(*) AS times_seen
FROM staff
GROUP BY first_name, last_name
HAVING COUNT(*) > 1;

-- The same shift entered twice: same person, same date, same start.
SELECT staff_id, shift_date, start_time, COUNT(*) AS times_seen
FROM shifts
GROUP BY staff_id, shift_date, start_time
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 2. What is missing?
-- ------------------------------------------------------------

-- COUNT(column) skips NULLs. COUNT(*) does not. The gap between
-- them is your NULL count — one query, every column.
SELECT COUNT(*)              AS rows_total,
       COUNT(first_name)     AS has_first_name,
       COUNT(last_name)      AS has_last_name,
       COUNT(hourly_rate)    AS has_rate,
       COUNT(site)           AS has_site,
       COUNT(role)           AS has_role
FROM staff;

-- Missingness disguises itself. An empty string is not NULL,
-- and neither is a space, or the text 'N/A'. All three look
-- blank on screen and all three behave differently in SQL.
SELECT COUNT(*) AS blank_looking_sites
FROM staff
WHERE site IS NULL
   OR TRIM(site) = ''
   OR UPPER(TRIM(site)) IN ('N/A', 'NA', 'UNKNOWN', 'NULL', '-');

-- A zero can be a real measurement or a missing value pretending
-- to be one. You cannot tell from the data — you have to ask.
SELECT COUNT(*) AS zero_hour_shifts
FROM shifts
WHERE hours = 0;


-- ------------------------------------------------------------
-- 3. What is the range? (impossible values)
-- ------------------------------------------------------------

-- MIN and MAX on every numeric and date column. This is the
-- cheapest check in analytics and it catches the worst errors.
SELECT MIN(hourly_rate) AS min_rate,
       MAX(hourly_rate) AS max_rate,
       ROUND(AVG(hourly_rate), 2) AS avg_rate
FROM staff;

SELECT MIN(hours)      AS min_hours,
       MAX(hours)      AS max_hours,
       MIN(shift_date) AS earliest,
       MAX(shift_date) AS latest
FROM shifts;

-- Now state what "impossible" means for this data, and look for it.
-- Nobody works a negative shift or a 30-hour one.
SELECT *
FROM shifts
WHERE hours <= 0 OR hours > 16;

-- A rate below minimum wage or above something absurd is either
-- an error or something you need explained before you report on it.
SELECT staff_id, first_name, hourly_rate
FROM staff
WHERE hourly_rate < 20 OR hourly_rate > 100;


-- ------------------------------------------------------------
-- 4. What are the actual categories?
-- ------------------------------------------------------------

-- GROUP BY every text column you plan to group by later.
-- This is where you find three spellings of one thing.
SELECT site, COUNT(*) AS staff_count
FROM staff
GROUP BY site
ORDER BY staff_count DESC;

SELECT role, COUNT(*) AS staff_count
FROM staff
GROUP BY role
ORDER BY staff_count DESC;

-- 'Elizabeth', 'elizabeth' and 'Elizabeth ' are three rows in your
-- report and one site in real life. Normalising first shows you
-- whether the raw values are already clean.
SELECT UPPER(TRIM(site)) AS site_normalised,
       COUNT(*)          AS staff_count,
       COUNT(DISTINCT site) AS raw_spellings
FROM staff
GROUP BY UPPER(TRIM(site))
ORDER BY staff_count DESC;

-- A flag column should only ever hold its allowed values.
-- Anything else is a bug you inherited.
SELECT is_overnight, COUNT(*) AS times_seen
FROM shifts
GROUP BY is_overnight;


-- ------------------------------------------------------------
-- 5. Does it join cleanly?
-- ------------------------------------------------------------

-- This is the one that quietly ruins reports.
-- An INNER JOIN drops rows that do not match, without warning.
-- Shifts belonging to a staff_id that does not exist in staff
-- simply vanish from your totals, and nobody notices.
SELECT sh.*
FROM shifts AS sh
LEFT JOIN staff AS st ON sh.staff_id = st.staff_id
WHERE st.staff_id IS NULL;

-- Count them, and count what they are worth. "We are missing
-- 40 hours of shifts" is a sentence a manager understands.
SELECT COUNT(*)        AS orphan_shifts,
       SUM(sh.hours)   AS orphan_hours
FROM shifts AS sh
LEFT JOIN staff AS st ON sh.staff_id = st.staff_id
WHERE st.staff_id IS NULL;

-- The other direction: staff with no shifts at all. Not
-- necessarily an error, but you should know before you divide
-- a total by "number of staff".
SELECT st.staff_id, st.first_name, st.last_name
FROM staff AS st
LEFT JOIN shifts AS sh ON st.staff_id = sh.staff_id
WHERE sh.staff_id IS NULL;

-- Proof your join did not change the row count. Run this before
-- and after adding a join to a working query.
SELECT (SELECT COUNT(*) FROM shifts) AS shifts_before,
       (SELECT COUNT(*) FROM shifts AS sh
        INNER JOIN staff AS st ON sh.staff_id = st.staff_id) AS shifts_after;


-- ------------------------------------------------------------
-- 6. A note on data types
-- ------------------------------------------------------------

-- SQLite stores whatever you give it. A "time" column is usually
-- just text, and text sorts alphabetically, not chronologically.
-- '9:00' is GREATER than '12:00' as text, because '9' > '1'.
-- Check before you ever compare a time or date as a string.
SELECT DISTINCT LENGTH(start_time) AS characters,
       COUNT(*) AS times_seen
FROM shifts
GROUP BY LENGTH(start_time);

-- If every value is 5 characters ('09:00'), string comparison is
-- safe. If some are 4 ('9:00'), it is not, and you must pad or
-- convert before comparing.


-- ============================================================
-- EXERCISES
--
-- For each one, write the query AND write a one-line finding
-- underneath it as a comment. The finding is the real deliverable.
-- ============================================================

-- Q1. Confirm whether shifts contains any duplicate rows for the
--     same staff member, date and start time. State how many.


-- Q2. Produce a single result showing, for every column in staff,
--     how many rows have a value. Which column is least complete?


-- Q3. Find any shift with hours outside a plausible range that you
--     define yourself. State the range you chose and why.


-- Q4. List the distinct values of site exactly as stored, then list
--     them normalised with UPPER(TRIM(...)). Do the two counts match?


-- Q5. Are there shifts whose staff_id does not exist in staff?
--     How many hours do they represent?


-- Q6. Are there staff who have never worked a shift?


-- Q7. Check whether start_time is stored consistently. Is it safe to
--     compare it as text, as you did in file 05 Q2?


-- Q8. Write a short data quality summary as a block comment: every
--     problem you found, how many rows it affects, and what you would
--     do about it. Three columns of thinking — issue, size, action.
--     This is the artifact. Everything above it was just evidence.
