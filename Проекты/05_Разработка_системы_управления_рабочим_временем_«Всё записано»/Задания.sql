/* Задание 1
В Dream Big ежемесячно оценивают производительность сотрудников. В результате бывает, кому-то повышают, а изредка понижают почасовую ставку. 
Напишите хранимую процедуру update_employees_rate, которая обновляет почасовую ставку сотрудников на определённый процент. 
При понижении ставка не может быть ниже минимальной — 500 рублей в час. Если по расчётам выходит меньше, устанавливают минимальную ставку.
На вход процедура принимает строку в формате json:

[
    -- uuid сотрудника                                      процент изменения ставки
    {"employee_id": "6bfa5e20-918c-46d0-ab18-54fc61086cba", "rate_change": 10}, 
    -- -- -- 
    {"employee_id": "5a6aed8f-8f53-4931-82f4-66673633f2a8", "rate_change": -5}
]
*/

  CREATE OR REPLACE PROCEDURE update_employees_rate(rate_changes_json json)
LANGUAGE plpgsql
AS
$$
DECLARE
        row_rate_change jsonb;
        employee_id UUID;
        rate_change NUMERIC;
        current_rate NUMERIC;
        new_rate NUMERIC;
  BEGIN
    FOR row_rate_change IN
        SELECT * 
          FROM jsonb_array_elements(rate_changes_json::jsonb)
          
          LOOP employee_id := (row_rate_change ->> 'employee_id')::UUID;
               rate_change := (row_rate_change ->> 'rate_change')::NUMERIC;

            SELECT rate
              INTO current_rate
              FROM employees
             WHERE id = employee_id;

            new_rate := current_rate * (1 + rate_change / 100);

            IF new_rate < 500 THEN
                new_rate := 500;
            END IF;

            UPDATE employees
               SET rate = new_rate
             WHERE id = employee_id;
         END LOOP;

    COMMIT;
END;
$$;

/* Задание 2
С ростом доходов компании и учётом ежегодной инфляции Dream Big индексирует зарплату всем сотрудникам.
Напишите хранимую процедуру indexing_salary, которая повышает зарплаты всех сотрудников на определённый процент. 
Процедура принимает один целочисленный параметр — процент индексации p. 
Сотрудникам, которые получают зарплату по ставке ниже средней относительно всех сотрудников до индексации, начисляют дополнительные 2% (p + 2). 
Ставка остальных сотрудников увеличивается на p%.
Зарплата хранится в БД в типе данных integer, поэтому если в результате повышения зарплаты образуется дробное число, его нужно округлить до целого.
*/
  CREATE OR REPLACE PROCEDURE indexing_salary(p INTEGER)
LANGUAGE plpgsql
AS
$$
DECLARE
        avg_hour_rate NUMERIC;
  BEGIN
        SELECT AVG(rate)
        INTO avg_hour_rate
        FROM employees;

        UPDATE employees
        SET rate = ROUND(
        CASE
             WHEN rate < avg_hour_rate THEN rate * (1 + (p + 2) / 100.0)
             ELSE rate * (1 + p / 100.0)
             END)::INTEGER;

    COMMIT;
END;
$$;

/* Задание 3
Завершая проект, нужно сделать два действия в системе учёта:
Изменить значение поля is_active в записи проекта на false — чтобы рабочее время по этому проекту больше не учитывалось.
Посчитать бонус, если он есть — то есть распределить неизрасходованное время между всеми членами команды проекта. 
Неизрасходованное время — это разница между временем, которое выделили на проект (estimated_time), и фактически потраченным. 
Если поле estimated_time не задано, бонусные часы не распределятся. Если отработанных часов нет — расчитывать бонус не нужно.
*/
   CREATE OR REPLACE PROCEDURE close_project(project_id UUID)
LANGUAGE plpgsql
AS
$$
DECLARE
    total_time NUMERIC;
    p_estimated_time NUMERIC;
    unused_time NUMERIC;
    bonus_time_ NUMERIC;
    project_cnt INTEGER;
BEGIN
     IF EXISTS (SELECT 1 FROM projects WHERE id = project_id AND is_active = false) THEN
        RAISE EXCEPTION 'The project is already closed.';
    END IF;

    SELECT estimated_time
      INTO p_estimated_time
      FROM projects
     WHERE id = project_id;

     IF p_estimated_time IS NULL THEN
        UPDATE projects
        SET is_active = false
        WHERE id = project_id;
        RETURN;
    END IF;

    SELECT COALESCE(SUM(work_hours), 0)
      INTO total_time
      FROM logs
     WHERE logs.project_id = close_project.project_id;

     IF total_time = 0 THEN
        UPDATE projects
        SET is_active = false
        WHERE id = project_id;
        RETURN;
    END IF;

    unused_time := p_estimated_time - total_time;

     IF unused_time <= 0 THEN
        UPDATE projects
        SET is_active = false
        WHERE id = project_id;
        RETURN;
    END IF;

    SELECT COUNT(DISTINCT employee_id)
      INTO project_cnt
      FROM logs
     WHERE logs.project_id = close_project.project_id;

    bonus_time := FLOOR((unused_time * 0.75) / project_cnt);

     IF bonus_time > 16 THEN
        bonus_time := 16;
    END IF;

     IF bonus_time > 0 THEN
        INSERT INTO logs (employee_id, project_id, work_hours, work_date)
        SELECT DISTINCT l.employee_id, p.id, bonus_time, CURRENT_DATE
        FROM projects p
                 JOIN logs l ON p.id = l.project_id
        WHERE p.id = close_project.project_id;
    END IF;

    UPDATE projects
       SET is_active = false
     WHERE id = project_id;

    COMMIT;
END;
$$;

/* Задание 4
Напишите процедуру log_work для внесения отработанных сотрудниками часов. Процедура добавляет новые записи о работе сотрудников над проектами.
Процедура принимает id сотрудника, id проекта, дату и отработанные часы и вносит данные в таблицу logs. 
Если проект завершён, добавить логи нельзя — процедура должна вернуть ошибку Project closed. 
Количество залогированных часов может быть в этом диапазоне: от 1 до 24 включительно — нельзя внести менее 1 часа или больше 24. 
Если количество часов выходит за эти пределы, необходимо вывести предупреждение о недопустимых данных и остановить выполнение процедуры.
Запись помечается флагом required_review, если:
залогированно более 16 часов за один день — Dream Big заботится о здоровье сотрудников;
запись внесена будущим числом;
запись внесена более ранним числом, чем на неделю назад от текущего дня — например, если сегодня 10.04.2023, все записи старше 3.04.2023 получат флажок.
*/
CREATE OR REPLACE PROCEDURE log_work(employee_id UUID,
                                     project_id UUID,
                                     work_date DATE,
                                     work_hours NUMERIC)
LANGUAGE plpgsql
AS
$$
DECLARE
    project_active BOOLEAN;
    flag BOOLEAN := FALSE;
BEGIN
    SELECT is_active
      INTO project_active
      FROM projects
     WHERE id = project_id;

     IF project_active = FALSE THEN
        RAISE EXCEPTION 'Project closed';
    END IF;

     IF work_hours < 1 OR work_hours > 24 THEN
        RAISE EXCEPTION 'Invalid number of hours. Must be between 1 and 24.';
    END IF;

     IF work_hours > 16 THEN
        flag := TRUE;
    END IF;

     IF work_date > CURRENT_DATE THEN
        flag := TRUE;
    END IF;

     IF work_date < CURRENT_DATE - INTERVAL '7 days' THEN
        flag := TRUE;
    END IF;

    INSERT INTO logs (employee_id, project_id, work_hours, work_date, required_review)
    VALUES (log_work.employee_id, log_work.project_id, log_work.work_hours,
            log_work.work_date, flag);

    COMMIT;
END;

/* Задание 5
Чтобы бухгалтерия корректно начисляла зарплату, нужно хранить историю изменения почасовой ставки сотрудников. 
Создайте отдельную таблицу employee_rate_history с такими столбцами:
id — id записи,
employee_id — id сотрудника,
rate — почасовая ставка сотрудника,
from_date — дата назначения новой ставки.
Внесите в таблицу текущие данные всех сотрудников. В качестве from_date используйте дату основания компании: '2020-12-26'.
Напишите триггерную функцию save_employee_rate_history и триггер change_employee_rate. 
При добавлении сотрудника в таблицу employees и изменении ставки сотрудника триггер автоматически вносит запись в таблицу 
employee_rate_history из трёх полей: id сотрудника, его ставки и текущей даты.
*/
CREATE TABLE employee_rate_history
(
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
employee_id UUID NOT NULL,
rate NUMERIC NOT NULL,
from_date DATE NOT NULL);

INSERT INTO employee_rate_history (employee_id, rate, from_date)
SELECT id, rate, '2020-12-26'::DATE
 FROM employees;

  CREATE OR REPLACE FUNCTION save_employee_rate_history()
 RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO employee_rate_history (employee_id, rate, from_date)
    VALUES (NEW.id, NEW.rate, CURRENT_DATE);

    RETURN NEW;
END;
$$;

 CREATE TRIGGER change_employee_rate
  AFTER INSERT OR UPDATE OF rate
     ON employees
    FOR EACH ROW
EXECUTE FUNCTION save_employee_rate_history();

/* Задание 6
После завершения каждого проекта Dream Big проводит корпоративную вечеринку, чтобы отпраздновать очередной успех и поощрить сотрудников. 
Тех, кто посвятил проекту больше всего часов, награждают премией «Айтиголик» — они получают почётные грамоты и ценные подарки от заказчика.
Чтобы вычислить айтиголиков проекта, напишите функцию best_project_workers.
Функция принимает id проекта и возвращает таблицу с именами трёх сотрудников, которые залогировали максимальное количество часов в этом проекте. 
Результирующая таблица состоит из двух полей: имени сотрудника и количества часов, отработанных на проекте.
*/
  CREATE OR REPLACE FUNCTION best_project_workers(project_uuid UUID)
 RETURNS TABLE (employee_name TEXT, total_hours NUMERIC)
LANGUAGE plpgsql;
AS
$$
BEGIN
    RETURN QUERY
        SELECT e.name AS employee_name,
               SUM(l.work_hours)::NUMERIC AS total_hours
          FROM employees e
          JOIN logs l ON e.id = l.employee_id
         WHERE 1 = 1
           AND l.project_id = project_uuid
         GROUP BY e.name
         ORDER BY total_hours DESC
         LIMIT 3;
END;
$$ 

/* Задание 7
Напишите для бухгалтерии функцию calculate_month_salary для расчёта зарплаты за месяц.
Функция принимает в качестве параметров даты начала и конца месяца и возвращает результат в виде таблицы с четырьмя полями: 
id (сотрудника), employee (имя сотрудника), worked_hours и salary.
Процедура суммирует все залогированные часы за определённый месяц и умножает на актуальную почасовую ставку сотрудника. 
Исключения — записи с флажками required_review и is_paid.
Если суммарно по всем проектам сотрудник отработал более 160 часов в месяц, все часы свыше 160 оплатят с коэффициентом 1.25.
*/
  CREATE OR REPLACE FUNCTION calculate_month_salary(start_date DATE, end_date DATE)
 RETURNS TABLE(id UUID, employee TEXT, worked_hours NUMERIC, salary NUMERIC)
LANGUAGE plpgsql;
AS
$$
BEGIN
    RETURN QUERY
        SELECT e.id,
               e.name AS employee,
               SUM(l.work_hours)::NUMERIC AS worked_hours,
               (CASE
                     WHEN SUM(l.work_hours) > 160 THEN 160 * r.rate + (SUM(l.work_hours) - 160) * r.rate * 1.25
                ELSE SUM(l.work_hours) * r.rate
                END)::NUMERIC AS salary
           FROM employees e
           JOIN logs l ON e.id = l.employee_id
           JOIN employee_rate_history r ON e.id = r.employee_id
        WHERE 1 = 1
          AND l.work_date BETWEEN start_date AND end_date
          AND l.required_review = false
          AND l.is_paid = false
          AND r.from_date <= end_date
        GROUP BY e.id, 
                 e.name, 
                 r.rate
        ORDER BY e.name;
END;
$$  