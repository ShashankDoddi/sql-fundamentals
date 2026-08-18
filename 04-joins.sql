-- ============================================================
-- 04 - JOINs: combining tables
-- Run 01-setup.sql first if you need to rebuild.
-- Run one query at a time.
-- ============================================================

-- Until now every query hit ONE table. Real databases split data
-- across many, and joining them is the single most-tested SQL skill
-- in analyst interviews.


-- ------------------------------------------------------------
-- 0. Add two staff who have never worked a shift
--    (needed for the LEFT JOIN section — run this once)
-- ------------------------------------------------------------

INSERT OR IGNORE INTO staff VALUES
 (11, 'Noah',  'Fischer', 'Console Operator', 'Glenelg', 27.10, '2026-07-28'),
 (12, 'Grace', 'Okafor',  'Cleaner',          'Modbury', 26.00, '2026-08-04');


-- ------------------------------------------------------------
-- 1. The problem JOINs solve
-- ------------------------------------------------------------

-- The shifts table only knows staff_id — a number.
SELECT * FROM shifts LIMIT 5;

-- Nobody wants a report that says "staff_id 4 worked 25 hours".
-- The names live in the staff table. JOIN puts them together.


-- ------------------------------------------------------------
-- 2. INNER JOIN — rows that match in BOTH tables
-- ------------------------------------------------------------

SELECT staff.first_name,
       staff.last_name,
       shifts.shift_date,
       shifts.hours
FROM shifts
INNER JOIN staff ON shifts.staff_id = staff.staff_id;

-- ON says how the tables connect. Here: the staff_id column
-- in shifts matches the staff_id column in staff.

-- Table aliases save typing. sh and st are just short names.
SELECT st.first_name, st.site, sh.shift_date, sh.hours
FROM shifts AS sh
INNER JOIN staff AS st ON sh.staff_id = st.staff_id
WHERE sh.is_overnight = 1
ORDER BY st.first_name;

-- Note: JOIN on its own means INNER JOIN. Both are correct;
-- writing INNER is clearer for anyone reading it later.


-- ------------------------------------------------------------
-- 3. LEFT JOIN — keep everything from the left table
-- ------------------------------------------------------------

-- INNER JOIN silently drops staff who have no shifts.
-- Count the rows: this returns 10, not 12.
SELECT COUNT(DISTINCT st.staff_id) AS staff_with_shifts
FROM staff AS st
INNER JOIN shifts AS sh ON st.staff_id = sh.staff_id;

-- LEFT JOIN keeps every row from the FIRST (left) table,
-- filling in NULL where there is no match.
SELECT st.first_name, st.last_name, sh.shift_date, sh.hours
FROM staff AS st
LEFT JOIN shifts AS sh ON st.staff_id = sh.staff_id
ORDER BY st.staff_id;

-- Noah and Grace appear with NULL shift details.

-- Finding what is MISSING is a classic analyst question:
-- which staff have never been rostered?
SELECT st.first_name, st.last_name, st.site
FROM staff AS st
LEFT JOIN shifts AS sh ON st.staff_id = sh.staff_id
WHERE sh.shift_id IS NULL;

-- NULL means "no value". You test it with IS NULL,
-- never with = NULL — that never matches anything.


-- ------------------------------------------------------------
-- 4. JOIN + GROUP BY — where it gets useful
-- ------------------------------------------------------------

-- Total hours per person, with real names:
SELECT st.first_name,
       st.last_name,
       COUNT(sh.shift_id) AS shifts_worked,
       SUM(sh.hours)      AS total_hours
FROM staff AS st
INNER JOIN shifts AS sh ON st.staff_id = sh.staff_id
GROUP BY st.staff_id, st.first_name, st.last_name
ORDER BY total_hours DESC;

-- Hours by site — a question you cannot answer without a join,
-- because site lives in staff and hours live in shifts.
SELECT st.site,
       SUM(sh.hours) AS total_hours
FROM staff AS st
INNER JOIN shifts AS sh ON st.staff_id = sh.staff_id
GROUP BY st.site
ORDER BY total_hours DESC;

-- Estimated wage cost: rate lives in one table, hours in the other.
SELECT st.first_name,
       ROUND(SUM(sh.hours * st.hourly_rate), 2) AS wage_cost
FROM staff AS st
INNER JOIN shifts AS sh ON st.staff_id = sh.staff_id
GROUP BY st.staff_id, st.first_name
ORDER BY wage_cost DESC;


-- ============================================================
-- EXERCISES
-- ============================================================

-- Q1. List every shift with the first name and last name of the
--     person who worked it, plus the shift date and hours.
SELECT st.first_name,
       st.last_name,
       sh.shift_date,
       sh.hours
FROM shifts AS sh
INNER JOIN staff AS st
  ON sh.staff_id = st.staff_id
ORDER BY sh.shift_date;


-- Q2. Show all overnight shifts with the worker's name and site.
SELECT st.first_name,
       st.last_name,
       st.site,
       sh.shift_date,
       sh.hours
FROM shifts AS sh
INNER JOIN staff AS st
  ON sh.staff_id = st.staff_id
WHERE sh.is_overnight = 1
ORDER BY sh.shift_date;


-- Q3. For each site, count how many shifts were worked there.
SELECT st.site,
       COUNT(sh.shift_id) AS shifts_worked
FROM staff AS st
INNER JOIN shifts AS sh
  ON st.staff_id = sh.staff_id
GROUP BY st.site
ORDER BY shifts_worked DESC;


-- Q4. Show every staff member and their total hours, INCLUDING
--     those who have worked none (they should show NULL or 0).
SELECT st.first_name,
       st.last_name,
       COALESCE(SUM(sh.hours), 0) AS total_hours
FROM staff AS st
LEFT JOIN shifts AS sh
  ON st.staff_id = sh.staff_id
GROUP BY st.staff_id, st.first_name, st.last_name
ORDER BY total_hours DESC;


-- Q5. Which staff have never worked an overnight shift?
--     (harder — think about where the is_overnight condition goes)
SELECT st.first_name,
       st.last_name,
       st.site
FROM staff AS st
LEFT JOIN shifts AS sh
  ON st.staff_id = sh.staff_id
  AND sh.is_overnight = 1
WHERE sh.shift_id IS NULL;


-- Q6. List the top three people by total hours worked, with names.
SELECT st.first_name,
       st.last_name,
       SUM(sh.hours) AS total_hours
FROM staff AS st
INNER JOIN shifts AS sh
  ON st.staff_id = sh.staff_id
GROUP BY st.staff_id, st.first_name, st.last_name
ORDER BY total_hours DESC
LIMIT 3;



-- Q7. For each role, show the total hours worked by people in it.
SELECT st.role,
       SUM(sh.hours) AS total_hours
FROM staff AS st
INNER JOIN shifts AS sh
  ON st.staff_id = sh.staff_id
GROUP BY st.role
ORDER BY total_hours DESC;


-- Q8. Calculate the total estimated wage cost per site,
--     rounded to two decimal places, highest first.
SELECT st.site,
       ROUND(SUM(sh.hours * st.hourly_rate), 2) AS total_wage_cost
FROM staff AS st
INNER JOIN shifts AS sh
  ON st.staff_id = sh.staff_id
GROUP BY st.site
ORDER BY total_wage_cost DESC;
