-- ============================================================
-- 01 - Build the practice database
-- Run this ONCE. It creates the tables and loads sample data.
-- ============================================================

-- A roster system for a small Adelaide site: staff and their shifts.

DROP TABLE IF EXISTS shifts;
DROP TABLE IF EXISTS staff;

CREATE TABLE staff (
    staff_id    INTEGER PRIMARY KEY,
    first_name  TEXT    NOT NULL,
    last_name   TEXT    NOT NULL,
    role        TEXT    NOT NULL,
    site        TEXT    NOT NULL,
    hourly_rate REAL    NOT NULL,
    start_date  TEXT    NOT NULL
);

CREATE TABLE shifts (
    shift_id    INTEGER PRIMARY KEY,
    staff_id    INTEGER NOT NULL,
    shift_date  TEXT    NOT NULL,
    start_time  TEXT    NOT NULL,
    hours       REAL    NOT NULL,
    is_overnight INTEGER NOT NULL,   -- 0 = no, 1 = yes
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
);

INSERT INTO staff VALUES
 (1,  'Priya',  'Nair',      'Console Operator', 'Prospect',   28.50, '2024-03-11'),
 (2,  'Liam',   'O''Connor',  'Console Operator', 'Prospect',   28.50, '2023-07-02'),
 (3,  'Mei',    'Chen',      'Shift Supervisor', 'Prospect',   34.20, '2022-01-17'),
 (4,  'Tom',    'Waters',    'Console Operator', 'Glenelg',    28.50, '2025-02-24'),
 (5,  'Aisha',  'Rahman',    'Shift Supervisor', 'Glenelg',    34.20, '2023-11-06'),
 (6,  'Ben',    'Hughes',    'Console Operator', 'Glenelg',    27.10, '2025-08-18'),
 (7,  'Sofia',  'Almeida',   'Cleaner',          'Prospect',   26.00, '2024-09-30'),
 (8,  'Raj',    'Menon',     'Console Operator', 'Modbury',    28.50, '2022-05-09'),
 (9,  'Ella',   'Novak',     'Site Manager',     'Modbury',    41.75, '2021-04-12'),
 (10, 'Jack',   'Thompson',  'Console Operator', 'Modbury',    27.10, '2026-01-19');

INSERT INTO shifts VALUES
 (1,  1, '2026-08-01', '22:00', 8.0, 1),
 (2,  1, '2026-08-02', '22:00', 8.0, 1),
 (3,  1, '2026-08-05', '14:00', 6.0, 0),
 (4,  2, '2026-08-01', '06:00', 8.0, 0),
 (5,  2, '2026-08-03', '22:00', 8.5, 1),
 (6,  3, '2026-08-01', '14:00', 7.5, 0),
 (7,  3, '2026-08-04', '06:00', 8.0, 0),
 (8,  4, '2026-08-02', '22:00', 9.0, 1),
 (9,  4, '2026-08-03', '22:00', 8.0, 1),
 (10, 4, '2026-08-06', '22:00', 8.0, 1),
 (11, 5, '2026-08-02', '14:00', 7.0, 0),
 (12, 6, '2026-08-05', '06:00', 5.5, 0),
 (13, 7, '2026-08-01', '05:00', 4.0, 0),
 (14, 7, '2026-08-08', '05:00', 4.0, 0),
 (15, 8, '2026-08-03', '22:00', 8.0, 1),
 (16, 8, '2026-08-04', '22:00', 8.0, 1),
 (17, 8, '2026-08-07', '14:00', 6.5, 0),
 (18, 9, '2026-08-05', '09:00', 8.0, 0),
 (19, 10,'2026-08-06', '06:00', 7.0, 0),
 (20, 10,'2026-08-09', '22:00', 8.0, 1);

-- Check it loaded. Should return 10 and 20.
SELECT COUNT(*) AS staff_count FROM staff;
SELECT COUNT(*) AS shift_count FROM shifts;
