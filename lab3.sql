-- 1. LEFT JOIN: все отделы, даже если графика нет.
SELECT
    d.department_code,
    d.name AS department_name,
    ws.post_office_code,
    ws.day_of_week,
    ws.start_time,
    ws.end_time,
    ws.break_start_time,
    ws.break_end_time
FROM departments d
LEFT JOIN work_schedules ws
    ON d.department_code = ws.department_code
ORDER BY d.department_code, ws.day_of_week;


-- 2. RIGHT JOIN: все графики, даже если отдел не зарегистрирован.
SELECT
    d.department_code,
    d.name AS department_name,
    ws.department_code AS schedule_department_code,
    ws.post_office_code,
    ws.day_of_week,
    ws.start_time,
    ws.end_time,
    ws.break_start_time,
    ws.break_end_time
FROM departments d
RIGHT JOIN work_schedules ws
    ON d.department_code = ws.department_code
ORDER BY ws.department_code, ws.day_of_week;


-- 3. FULL OUTER JOIN: основной запрос варианта 22.
-- Показывает все отделы и все графики; отсутствующие данные — NULL.
SELECT
    d.department_code,
    d.name AS department_name,
    ws.department_code AS schedule_department_code,
    ws.post_office_code,
    ws.day_of_week,
    ws.start_time,
    ws.end_time,
    ws.break_start_time,
    ws.break_end_time
FROM departments d
FULL OUTER JOIN work_schedules ws
    ON d.department_code = ws.department_code
ORDER BY
    COALESCE(d.department_code, ws.department_code),
    ws.day_of_week;


-- 4. Поиск нарушения ссылочной целостности:
-- графики, для которых не найден зарегистрированный отдел.
SELECT ws.*
FROM work_schedules ws
LEFT JOIN departments d
    ON d.department_code = ws.department_code
WHERE d.department_code IS NULL;


-- 5. Поиск отделов, для которых график не задан.
-- Это отсутствие графика, а не нарушение ссылочной целостности.
SELECT d.*
FROM departments d
LEFT JOIN work_schedules ws
    ON d.department_code = ws.department_code
WHERE ws.department_code IS NULL;
