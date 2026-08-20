-- ============================================================
-- 06b - Dirty the data
--
-- Every check in file 06 came back clean, because the practice
-- data was built clean. A profiling report where nothing is found
-- proves nothing: you have not shown your checks can catch
-- anything.
--
-- This script introduces nine realistic problems — the kinds that
-- actually turn up in production systems. Run it, then re-run
-- every query in file 06 and see which ones find what.
--
-- TO RESET: re-run 01-setup.sql. It drops and rebuilds both tables.
-- ============================================================


-- 1. The same person entered twice under a new ID.
--    (Rejoined the company, re-registered. Their hours will now
--    split across two IDs and headcount will be wrong.)
INSERT INTO staff VALUES
 (13, 'Priya', 'Nair', 'Console Operator', 'Prospect', 29.10, '2026-03-02');


-- 2. A site value with a trailing space and different casing.
--    Looks identical on screen. Groups separately.
INSERT INTO staff VALUES
 (14, 'Omar', 'Haddad', 'Console Operator', 'prospect ', 27.10, '2026-04-15');


-- 3. Missing values that are not NULL — the disguises.
INSERT INTO staff VALUES
 (15, 'Lena', 'Vogel',  'Console Operator', 'N/A', 28.50, '2026-05-01'),
 (16, 'Tariq', 'Aziz',  'Console Operator', '',    28.50, '2026-05-06');


-- 4. A genuinely NULL role.
INSERT INTO staff VALUES
 (17, 'Hana', 'Sato', NULL, 'Modbury', 28.50, '2026-05-20');


-- 5. An implausible pay rate.
INSERT INTO staff VALUES
 (18, 'Dev', 'Kapoor', 'Console Operator', 'Glenelg', 285.00, '2026-06-01');


-- 6. A duplicate shift — same person, same date, same start time.
--    Double-counted hours.
INSERT INTO shifts VALUES
 (21, 1, '2026-08-01', '22:00', 8.0, 1);


-- 7. Impossible shift lengths.
INSERT INTO shifts VALUES
 (22, 3, '2026-08-11', '06:00',  0.0, 0),
 (23, 5, '2026-08-12', '14:00', 26.0, 0);


-- 8. An orphan shift — staff_id 99 does not exist in staff.
--    An INNER JOIN will silently drop this and its hours.
INSERT INTO shifts VALUES
 (24, 99, '2026-08-13', '22:00', 8.0, 1);


-- 9. Inconsistent time format, and a flag holding a value
--    it should never hold.
INSERT INTO shifts VALUES
 (25, 2, '2026-08-14', '9:00', 7.0, 0),
 (26, 4, '2026-08-15', '22:00', 8.0, 2);


-- ============================================================
-- NOW GO BACK TO FILE 06 AND RUN EVERY QUERY AGAIN.
--
-- For each check, ask three things:
--   1. Did it find the problem I planted?
--   2. If not, why not — and what query WOULD have found it?
--   3. How many rows does it affect, and what would I do about it?
--
-- Then rewrite your Q8 summary. This time it will have content.
--
-- Two of the nine problems are NOT caught by any query currently
-- in file 06. Finding out which two, and writing the checks that
-- would catch them, is the real exercise.
-- ============================================================
