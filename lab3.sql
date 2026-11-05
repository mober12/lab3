--1. Сохраняем информацию о внешнем ключе--

DROP TABLE IF EXISTS _saved_department_fk;

CREATE TEMP TABLE _saved_department_fk
ON COMMIT PRESERVE ROWS AS
SELECT
    conname,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.work_schedules'::regclass
  AND confrelid = 'public.departments'::regclass
  AND contype = 'f';


-- 2. Временно удаляем внешний ключ--

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT conname FROM _saved_department_fk
    LOOP
        EXECUTE format(
            'ALTER TABLE public.work_schedules DROP CONSTRAINT %I',
            r.conname
        );
    END LOOP;
END
$$;


-- 3. Нарушаем ссылочную целостность--

DELETE FROM work_schedules
WHERE department_code = -999999;

INSERT INTO work_schedules (
    post_office_code,
    department_code,
    day_of_week,
    start_time,
    end_time,
    break_start_time,
    break_end_time
)
SELECT
    post_office_code,
    -999999,
    day_of_week,
    start_time,
    end_time,
    break_start_time,
    break_end_time
FROM work_schedules
WHERE department_code <> -999999
LIMIT 1;


-- 4. ЛЕВОСТОРОННЕЕ СОЕДИНЕНИЕ LEFT JOIN--

SELECT
    *
FROM departments d
LEFT JOIN work_schedules ws
    ON d.department_code = ws.department_code
ORDER BY d.department_code;


-- 5. ПРАВОСТОРОННЕЕ СОЕДИНЕНИЕ RIGHT JOIN--

SELECT*

FROM departments d
RIGHT JOIN work_schedules ws
    ON d.department_code = ws.department_code
ORDER BY ws.department_code;


-- 6. ПОЛНОЕ СОЕДИНЕНИЕ FULL OUTER JOIN--

SELECT* 

FROM departments d
FULL OUTER JOIN work_schedules ws
    ON d.department_code = ws.department_code
ORDER BY
    COALESCE(d.department_code, ws.department_code),
    ws.day_of_week;


-- 7. ПОИСК НАРУШЕНИЯ ССЫЛОЧНОЙ ЦЕЛОСТНОСТИ--

SELECT
    ws.department_code,
    ws.day_of_week,
    d.name
FROM work_schedules ws
LEFT JOIN departments d
    ON d.department_code = ws.department_code
WHERE d.department_code IS NULL;


-- 8. ВОССТАНОВЛЕНИЕ ССЫЛОЧНОЙ ЦЕЛОСТНОСТИ--

DELETE FROM work_schedules
WHERE department_code = -999999;


-- Восстанавливаем внешний ключ--

DO $$
DECLARE
    r RECORD;
BEGIN
    IF EXISTS (SELECT 1 FROM _saved_department_fk) THEN

        FOR r IN
            SELECT conname, definition
            FROM _saved_department_fk
        LOOP
            EXECUTE format(
                'ALTER TABLE public.work_schedules ADD CONSTRAINT %I %s',
                r.conname,
                r.definition
            );
        END LOOP;

    ELSIF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.work_schedules'::regclass
          AND confrelid = 'public.departments'::regclass
          AND contype = 'f'
    ) THEN

        ALTER TABLE public.work_schedules
        ADD CONSTRAINT fk_work_schedules_department_code
        FOREIGN KEY (department_code)
        REFERENCES public.departments(department_code);

    END IF;
END
$$;


-- 9. ПРОВЕРКА ВОССТАНОВЛЕНИЯ--

SELECT
    conname,
    pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.work_schedules'::regclass
  AND confrelid = 'public.departments'::regclass
  AND contype = 'f';
