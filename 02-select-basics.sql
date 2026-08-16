-- ============================================================
-- 02 - SELECT, WHERE, ORDER BY
-- Run 01-setup.sql first.
-- Run each query one at a time and read the result before moving on.
-- ============================================================


-- ------------------------------------------------------------
-- 1. SELECT — choosing columns
-- ------------------------------------------------------------

-- Everything, every column:
SELECT * FROM staff;

-- Only the columns you need. Do this instead of * in real work —
-- it is faster and it shows a reviewer you thought about it.
SELECT first_name, last_name, role
FROM staff;

-- Rename a column in the output with AS.
SELECT first_name AS given_name,
       hourly_rate AS rate_per_hour
FROM staff;


-- ------------------------------------------------------------
-- 2. WHERE — choosing rows
-- ------------------------------------------------------------

SELECT first_name, last_name, site
FROM staff
WHERE site = 'Prospect';

-- Numeric comparison
SELECT first_name, hourly_rate
FROM staff
WHERE hourly_rate > 28;

-- AND: both conditions must be true
SELECT first_name, site, hourly_rate
FROM staff
WHERE site = 'Glenelg'
  AND hourly_rate > 28;

-- OR: either condition
SELECT first_name, role
FROM staff
WHERE role = 'Shift Supervisor'
   OR role = 'Site Manager';

-- IN: cleaner than a chain of ORs
SELECT first_name, role
FROM staff
WHERE role IN ('Shift Supervisor', 'Site Manager');

-- BETWEEN: inclusive on both ends
SELECT first_name, hourly_rate
FROM staff
WHERE hourly_rate BETWEEN 27 AND 29;

-- LIKE: pattern matching. % means "any characters".
SELECT first_name, role
FROM staff
WHERE role LIKE '%Operator%';

-- NOT: excluding
SELECT first_name, site
FROM staff
WHERE site NOT IN ('Prospect');


-- ------------------------------------------------------------
-- 3. ORDER BY — sorting
-- ------------------------------------------------------------

SELECT first_name, hourly_rate
FROM staff
ORDER BY hourly_rate DESC;      -- DESC = highest first, ASC = lowest first

-- Sort by two columns: site first, then rate within each site.
SELECT site, first_name, hourly_rate
FROM staff
ORDER BY site ASC, hourly_rate DESC;

-- LIMIT: just the top few
SELECT first_name, hourly_rate
FROM staff
ORDER BY hourly_rate DESC
LIMIT 3;


-- ------------------------------------------------------------
-- 4. Putting it together
-- ------------------------------------------------------------

-- The three highest-paid console operators, cheapest info a manager
-- could actually ask you for.
SELECT first_name, last_name, site, hourly_rate
FROM staff
WHERE role = 'Console Operator'
ORDER BY hourly_rate DESC
LIMIT 3;


-- ============================================================
-- EXERCISES — write these yourself before looking anything up.
-- Put your answer under each question, then commit the file.
-- ============================================================

-- Q1. List every staff member at the Modbury site.

SELECT * FROM staff where site = Modbury;
-- Q2.  Show first name, last name and hourly rate for everyone
--     earning less than $28 per hour.
SELECT first_name, last_name, hourly_rate from staff where hourly_rate<28;

-- Q3. List all shifts that were overnight (is_overnight = 1).
select * from shifts where is_overnight = 1;

-- Q4. Show all shifts longer than 8 hours, longest first.
SELECT * from shifts where hours>8 ORDER by hours DESC;

-- Q5. List staff who started before 2024, sorted oldest start date first.
SELECT * FROM staff where start_date < '2024-01-01' ORDER BY start_date ASC;

-- Q6. Show every shift on 2026-08-03.
SELECT * from shifts where shift_date = '2026-08-03';

-- Q7. List staff whose role contains the word 'Supervisor',
--     sorted by hourly rate, highest first.
Select * from staff where role like '%Supervisor%' ORDER BY hourly_rate DESC;

-- Q8. Show the five shortest shifts in the table.
SELECT * from shifts ORDER BY hours ASC LIMIT 5;