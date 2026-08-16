-- ============================================================
-- 03 - Aggregation: COUNT, SUM, AVG, GROUP BY, HAVING
-- Run 01-setup.sql first if you haven't.
-- Run one query at a time.
-- ============================================================

-- Lesson 2 answered "which rows?"  This one answers
-- "what do the rows add up to?" — which is most of analytics.


-- ------------------------------------------------------------
-- 1. Aggregate functions — many rows in, one number out
-- ------------------------------------------------------------

SELECT COUNT(*) AS total_staff FROM staff;

SELECT SUM(hours) AS total_hours FROM shifts;

SELECT AVG(hourly_rate) AS average_rate FROM staff;

SELECT MIN(hourly_rate) AS lowest,
       MAX(hourly_rate) AS highest
FROM staff;

-- AVG gives long decimals. ROUND makes it readable.
-- The 2 means two decimal places.
SELECT ROUND(AVG(hourly_rate), 2) AS average_rate FROM staff;

-- Aggregates respect WHERE — filter first, then total.
SELECT COUNT(*) AS overnight_shifts
FROM shifts
WHERE is_overnight = 1;


-- ------------------------------------------------------------
-- 2. GROUP BY — one number per category
-- ------------------------------------------------------------

-- Without GROUP BY you get one row for the whole table.
-- With it, you get one row per distinct value.

SELECT site, COUNT(*) AS staff_count
FROM staff
GROUP BY site;

SELECT role, ROUND(AVG(hourly_rate), 2) AS avg_rate
FROM staff
GROUP BY role
ORDER BY avg_rate DESC;

-- Group the shifts table by person.
SELECT staff_id,
       COUNT(*)   AS shifts_worked,
       SUM(hours) AS total_hours
FROM shifts
GROUP BY staff_id
ORDER BY total_hours DESC;

-- You can group by more than one column.
SELECT site, role, COUNT(*) AS headcount
FROM staff
GROUP BY site, role
ORDER BY site, role;

-- THE RULE: every column in your SELECT must either be
-- inside an aggregate function, or listed in GROUP BY.
-- Breaking this is the most common GROUP BY error there is.


-- ------------------------------------------------------------
-- 3. HAVING — filtering the groups
-- ------------------------------------------------------------

-- WHERE filters rows BEFORE grouping.
-- HAVING filters groups AFTER grouping.
-- You cannot put an aggregate in WHERE.

-- Sites with more than three staff:
SELECT site, COUNT(*) AS staff_count
FROM staff
GROUP BY site
HAVING COUNT(*) > 3;

-- People who worked more than 16 hours in total:
SELECT staff_id, SUM(hours) AS total_hours
FROM shifts
GROUP BY staff_id
HAVING SUM(hours) > 16
ORDER BY total_hours DESC;

-- Both together: overnight shifts only (WHERE),
-- then only people with 2 or more of them (HAVING).
SELECT staff_id, COUNT(*) AS overnight_count
FROM shifts
WHERE is_overnight = 1
GROUP BY staff_id
HAVING COUNT(*) >= 2
ORDER BY overnight_count DESC;


-- ------------------------------------------------------------
-- 4. The order SQL actually runs in
-- ------------------------------------------------------------

-- You write it:   SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY
-- It runs as:     FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
--
-- That is why WHERE cannot see an alias you created in SELECT:
-- the alias does not exist yet when WHERE runs.
-- ORDER BY runs last, so it CAN use aliases.


-- ============================================================
-- EXERCISES
-- Write your answer under each question, then commit.
-- ============================================================

-- Q1. How many shifts are in the shifts table altogether?


-- Q2. What is the total number of hours worked across all shifts?


-- Q3. Show the average hourly rate for each site,
--     rounded to two decimal places, highest first.


-- Q4. Count how many staff hold each role.


-- Q5. For each staff_id, show how many shifts they worked
--     and their total hours, ordered by total hours descending.


-- Q6. Which sites have an average hourly rate above 28?


-- Q7. Count the overnight shifts and the day shifts
--     (hint: GROUP BY is_overnight).


-- Q8. Find staff_ids who worked three or more shifts.


-- Q9. What is the longest single shift, and the shortest?


-- Q10. For overnight shifts only, show the total hours
--      per staff_id, highest first.
