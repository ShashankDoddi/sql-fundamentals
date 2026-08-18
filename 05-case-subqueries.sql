-- ============================================================
-- 05 - CASE WHEN and subqueries
-- Run one query at a time.
-- ============================================================


-- ------------------------------------------------------------
-- 1. CASE WHEN — if/then/else inside a query
-- ------------------------------------------------------------

-- Turn a stored 0/1 into words a report can use.
SELECT shift_date,
       hours,
       CASE WHEN is_overnight = 1 THEN 'Overnight'
            ELSE 'Day'
       END AS shift_type
FROM shifts
ORDER BY shift_date;

-- Several conditions. SQL checks them TOP TO BOTTOM and stops
-- at the first one that is true, so order matters.
SELECT shift_date,
       hours,
       CASE WHEN hours >= 8.5 THEN 'Long'
            WHEN hours >= 6   THEN 'Standard'
            ELSE 'Short'
       END AS length_band
FROM shifts
ORDER BY hours DESC;

-- Without ELSE, anything unmatched becomes NULL.
SELECT first_name,
       hourly_rate,
       CASE WHEN hourly_rate >= 34 THEN 'Senior rate'
       END AS band
FROM staff;

-- CASE inside an aggregate: counting things conditionally.
-- This is the pattern that turns rows into a summary table.
SELECT COUNT(*) AS all_shifts,
       SUM(CASE WHEN is_overnight = 1 THEN 1 ELSE 0 END) AS overnight,
       SUM(CASE WHEN is_overnight = 0 THEN 1 ELSE 0 END) AS day_shifts
FROM shifts;

-- Same idea, per site — this is called a pivot.
SELECT st.site,
       SUM(CASE WHEN sh.is_overnight = 1 THEN sh.hours ELSE 0 END) AS overnight_hours,
       SUM(CASE WHEN sh.is_overnight = 0 THEN sh.hours ELSE 0 END) AS day_hours
FROM staff AS st
INNER JOIN shifts AS sh ON st.staff_id = sh.staff_id
GROUP BY st.site;

-- CASE also works in ORDER BY — custom sort orders.
SELECT first_name, role
FROM staff
ORDER BY CASE role
           WHEN 'Site Manager'     THEN 1
           WHEN 'Shift Supervisor' THEN 2
           WHEN 'Console Operator' THEN 3
           ELSE 4
         END;


-- ------------------------------------------------------------
-- 2. Subqueries — a query inside a query
-- ------------------------------------------------------------

-- The inner query runs first. Run it alone to see what it returns.
SELECT AVG(hourly_rate) FROM staff;

-- Now use that single value in an outer query.
SELECT first_name, last_name, hourly_rate
FROM staff
WHERE hourly_rate > (SELECT AVG(hourly_rate) FROM staff)
ORDER BY hourly_rate DESC;

-- You could not write this in one pass: the average does not exist
-- until every row has been read.

-- A subquery returning a LIST, used with IN.
SELECT first_name, last_name, site
FROM staff
WHERE staff_id IN (SELECT staff_id FROM shifts WHERE is_overnight = 1);

-- NOT IN gives you the opposite — who never worked overnight.
SELECT first_name, last_name
FROM staff
WHERE staff_id NOT IN (SELECT staff_id FROM shifts WHERE is_overnight = 1);

-- A subquery in SELECT: compare each row to a whole-table figure.
SELECT first_name,
       hourly_rate,
       ROUND(hourly_rate - (SELECT AVG(hourly_rate) FROM staff), 2) AS diff_from_avg
FROM staff
ORDER BY diff_from_avg DESC;

-- A subquery in FROM — treat a result as if it were a table.
-- Needed when you want to filter or aggregate an aggregate.
SELECT AVG(total_hours) AS avg_hours_per_person
FROM (SELECT staff_id, SUM(hours) AS total_hours
      FROM shifts
      GROUP BY staff_id);


-- ------------------------------------------------------------
-- 3. CTEs — the readable way to write a subquery
-- ------------------------------------------------------------

-- WITH names a subquery up front. Same result, far easier to read,
-- and this is how professional SQL is written.
WITH staff_totals AS (
    SELECT staff_id, SUM(hours) AS total_hours
    FROM shifts
    GROUP BY staff_id
)
SELECT st.first_name, st.last_name, t.total_hours
FROM staff_totals AS t
INNER JOIN staff AS st ON t.staff_id = st.staff_id
WHERE t.total_hours > 15
ORDER BY t.total_hours DESC;

-- You can chain several CTEs, separated by commas.
-- Prefer CTEs over nested subqueries once a query gets long.


-- ============================================================
-- EXERCISES
-- ============================================================

-- Q1. List every staff member with a column called pay_band that
--     says 'High' if hourly_rate is 34 or more, otherwise 'Standard'.
SELECT first_name,
       last_name,
       hourly_rate,
       CASE WHEN hourly_rate >= 34 THEN 'High'
            ELSE 'Standard'
       END AS pay_band
FROM staff;


-- Q2. Show each shift with a column saying 'Morning' if start_time
--     is before '12:00', otherwise 'Afternoon/Night'.
SELECT shift_date,
       start_time,
       hours,
       CASE WHEN start_time < '12:00' THEN 'Morning'
            ELSE 'Afternoon/Night'
       END AS shift_period
FROM shifts
ORDER BY shift_date;


-- Q3. Count how many staff are in each pay band from Q1.
SELECT CASE WHEN hourly_rate >= 34 THEN 'High'
            ELSE 'Standard'
       END AS pay_band,
       COUNT(*) AS staff_count
FROM staff
GROUP BY pay_band;


-- Q4. For each site, show the number of overnight shifts and the
--     number of day shifts as two separate columns.
SELECT st.site,
       SUM(CASE WHEN sh.is_overnight = 1 THEN 1 ELSE 0 END) AS overnight_shifts,
       SUM(CASE WHEN sh.is_overnight = 0 THEN 1 ELSE 0 END) AS day_shifts
FROM staff AS st
INNER JOIN shifts AS sh ON st.staff_id = sh.staff_id
GROUP BY st.site;


-- Q5. List staff who earn LESS than the average hourly rate.
SELECT first_name,
       last_name,
       hourly_rate
FROM staff
WHERE hourly_rate < (SELECT AVG(hourly_rate) FROM staff)
ORDER BY hourly_rate;


-- Q6. Which staff worked more hours than the average hours
--     worked per person? (hint: subquery in FROM, or a CTE)
SELECT st.first_name,
       st.last_name,
       t.total_hours
FROM (
    SELECT staff_id, SUM(hours) AS total_hours
    FROM shifts
    GROUP BY staff_id
) AS t
INNER JOIN staff AS st ON st.staff_id = t.staff_id
WHERE t.total_hours > (SELECT AVG(total_hours)
                       FROM (
                           SELECT staff_id, SUM(hours) AS total_hours
                           FROM shifts
                           GROUP BY staff_id
                       ));


-- Q7. Show every staff member with their total hours and a column
--     labelling them 'Above average' or 'Below average'.
WITH staff_totals AS (
    SELECT staff_id, SUM(hours) AS total_hours
    FROM shifts
    GROUP BY staff_id
),
avg_hours AS (
    SELECT AVG(total_hours) AS avg_val
    FROM staff_totals
)
SELECT st.first_name,
       st.last_name,
       t.total_hours,
       CASE WHEN t.total_hours > a.avg_val THEN 'Above average'
            ELSE 'Below average'
       END AS hours_band
FROM staff_totals AS t
CROSS JOIN avg_hours AS a
INNER JOIN staff AS st ON st.staff_id = t.staff_id
ORDER BY t.total_hours DESC;


-- Q8. Using a CTE, find the site with the highest total wage cost
--     and return just that one row.
WITH site_costs AS (
    SELECT st.site,
           SUM(sh.hours * st.hourly_rate) AS total_wage_cost
    FROM staff AS st
    INNER JOIN shifts AS sh ON st.staff_id = sh.staff_id
    GROUP BY st.site
)
SELECT site,
       ROUND(total_wage_cost, 2) AS total_wage_cost
FROM site_costs
ORDER BY total_wage_cost DESC
LIMIT 1;
