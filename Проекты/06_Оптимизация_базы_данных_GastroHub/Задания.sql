-- Часть 1

/* Задание 1
Клиенты сервиса начали замечать, что после нажатия на кнопку Оформить заказ система на какое-то время подвисает. 
*/

INSERT INTO orders
    (order_id, order_dt, user_id, device_type, city_id, total_cost, discount, 
    final_cost)
SELECT MAX(order_id) + 1, current_timestamp, 
    '329551a1-215d-43e6-baee-322f2467272d', 
    'Mobile', 1, 1000.00, null, 1000.00
FROM orders;

/* [рассуждения]
order_id не primary key, нужно исправить
order_dt добавить значение по умолчанию current_timestamp
discount добавить значение по умолчанию 0
*/

-- [действия]
-- добавим PK
ALTER TABLE orders 
  ADD PRIMARY KEY (order_id);
  
-- добавим значение по умолчанию current_timestamp для order_dt
ALTER TABLE orders 
ALTER COLUMN order_dt 
  SET DEFAULT CURRENT_TIMESTAMP;

-- добавим значение по умолчанию 0 для discount
ALTER TABLE orders 
ALTER COLUMN discount 
  SET DEFAULT 0;

-- избавимся от лишних индексов, освободим место
DROP INDEX orders_total_final_cost_discount_idx,
           orders_total_cost_idx,
           orders_order_dt_idx,
           orders_final_cost_idx,
           orders_discount_idx,
           orders_device_type_idx,
           orders_device_type_city_id_idx

-- [решение]
INSERT INTO orders (user_id, device_type, city_id, total_cost, final_cost)
VALUES ('329551a1-215d-43e6-baee-322f2467272d', 'Mobile', 1, 1000.00, 1000.00);



/* Задание 2 
Клиенты сервиса в свой день рождения получают скидку. 
Расчёт скидки и отправка клиентам промокодов происходит на стороне сервера приложения. 
*/

SELECT user_id::text::uuid, first_name::text, last_name::text, 
    city_id::bigint, gender::text
FROM users
WHERE city_id::integer = 4
    AND date_part('day', to_date(birth_date::text, 'yyyy-mm-dd')) 
        = date_part('day', to_date('31-12-2023', 'dd-mm-yyyy'))
    AND date_part('month', to_date(birth_date::text, 'yyyy-mm-dd')) 
        = date_part('month', to_date('31-12-2023', 'dd-mm-yyyy'))
/* [Рассуждения]
Я бы поменял тип даных у ряда полей, а также создал ENUM для поля с полом
*/
        
-- [действия]
-- Создаем enum тип для пола перед его использованием
CREATE TYPE gender_type AS ENUM ('male', 'female');

-- корректируем типы данных на более предпочтительные по моему мнению
ALTER TABLE users
ALTER COLUMN user_id SET DATA TYPE VARCHAR(255),
ALTER COLUMN user_id SET DATA TYPE uuid USING user_id::uuid,
ALTER COLUMN first_name SET DATA TYPE VARCHAR(50),
ALTER COLUMN last_name SET DATA TYPE VARCHAR(50),
ALTER COLUMN gender SET DATA TYPE VARCHAR(20),
ALTER COLUMN gender SET DATA TYPE gender_type USING gender::gender_type,
ALTER COLUMN birth_date SET DATA TYPE DATE USING birth_date::date,
ALTER COLUMN registration_date SET DATA TYPE DATE USING registration_date::date,
ALTER COLUMN city_id SET DATA TYPE integer;

-- добавим PK для cities 
ALTER TABLE cities 
  ADD PRIMARY KEY (city_id);
  
-- очистим некорректные ссылки и добавляем внешний ключ
UPDATE users SET city_id = NULL WHERE city_id = 0;
 ALTER TABLE users 
   ADD CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES cities(city_id);

--[Решение]
SELECT user_id, 
       first_name, 
       last_name, 
       city_id, 
       gender
  FROM users
 WHERE 1 = 1 
   AND city_id = 4
   AND (birth_date::text LIKE '%-12-31' OR birth_date = MAKE_DATE(EXTRACT(YEAR FROM birth_date)::int, 12, 31));

--[Задание 3]--
/*Также пользователи жалуются, что оплата при оформлении заказа проходит долго.
Разработчик сервера приложения Матвей проанализировал ситуацию и заключил, 
что оплата «висит» из-за того, что выполнение процедуры add_payment требует довольно много времени 
по меркам БД.*/

--[Рассуждения]
/*Первое, что приходит в голову - индексы! ИНдексы и ключи!*/

--[Действия]
-- добавим внешние ключи
ALTER TABLE payments
  ADD CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_statuses
  ADD CONSTRAINT fk_order_statuses_status FOREIGN KEY (status_id) REFERENCES statuses(status_id);
  
-- добавим индексы
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_statuses_composite ON order_statuses(order_id, status_id);
CREATE INDEX IF NOT EXISTS idx_order_statuses_dt ON order_statuses(status_dt);

--[замечания 1] все есть в payments, я бы вообще salws удалил если честно
--[Решение]
BEGIN;
    -- Регистрация статуса заказа с текущей датой
    INSERT INTO order_statuses (order_id, status_id, status_dt)
    VALUES (p_order_id, 2, NOW()); 
    
    -- Фиксация платежа
    INSERT INTO payments (order_id, payment_sum)
    VALUES (p_order_id, p_sum_payment);
COMMIT;

--[Задание 4]--
/*Все действия пользователей в системе логируются и записываются в таблицу user_logs. 
Потом эти данные используются для анализа — как правило, анализируются данные за текущий квартал.
Время записи данных в эту таблицу сильно увеличилось, 
а это тормозит практически все действия пользователя.*/

--[Рассуждения]
/*Про это было в курсе - партицирование*/

--[Решение]
 CREATE TABLE user_logs_2024_q1 PARTITION OF user_logs
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

 CREATE TABLE user_logs_2024_q2 PARTITION OF user_logs
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

 CREATE TABLE user_logs_2024_q3 PARTITION OF user_logs
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

 CREATE TABLE user_logs_2024_q4 PARTITION OF user_logs
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

  
--[Задание 5]--
/*Маркетологи сервиса регулярно анализируют предпочтения различных возрастных групп. 
Для этого они формируют отчёт:
day age spicy fish meat
0–20            
20–30           
30–40           
40–100          
*/
 
--[Рассуждения]
/* ну раз запросы регулярные и они постоянно нагружают базу а текущий день не включается, 
давайте создадим матвью. Пусть рассчитывается раз в сутки и менеджеры будут ходить в нее в течение дня
следующего за расчетным
*/

--[решение]
CREATE MATERIALIZED VIEW report_preferences_by_age AS
  WITH age_categories AS (
       SELECT u.user_id,
              CASE
                  WHEN EXTRACT(YEAR FROM AGE(u.birth_date)) < 20 THEN '0–20'
                  WHEN EXTRACT(YEAR FROM AGE(u.birth_date)) < 30 THEN '20–30'
                  WHEN EXTRACT(YEAR FROM AGE(u.birth_date)) < 40 THEN '30–40'
                  ELSE '40–100'
              END AS age_group
         FROM users u)
         
SELECT ac.age_group,
       ROUND(AVG(d.spicy::int) * 100, 2) AS spicy_prc,
       ROUND(AVG(d.fish::int) * 100, 2) AS fish_prc,
       ROUND(AVG(d.meat::int) * 100, 2) AS meat_prc
  FROM orders o
  JOIN age_categories AS ac ON o.user_id = ac.user_id
  JOIN order_items AS oi ON o.order_id = oi.order_id
  JOIN dishes AS d ON oi.item = d.object_id
 GROUP BY ac.age_group
 ORDER BY ac.age_group;

-- часть 2

-- выбираем топ-5 медленных запросов
SELECT queryid,
       calls,
       total_exec_time,
       rows,
       query
  FROM pg_stat_statements
 ORDER BY total_exec_time DESC
 LIMIT 5;
 
-- отобранные запросы:
-- [1] поиск заказов без оплаты
SELECT count(*)
FROM order_statuses os
JOIN orders o ON o.order_id = os.order_id
WHERE (SELECT count(*)
       FROM order_statuses os1
       WHERE os1.order_id = o.order_id AND os1.status_id = $1) = $2
    AND o.city_id = $3;

-- [2] собирает логи текущего дня
SELECT *
FROM user_logs
WHERE datetime::date > current_date;

-- [3] поиск события и его дате и времени по определенному пользователю
SELECT event, datetime
FROM user_logs
WHERE visitor_uuid = $1
ORDER BY 2;

-- [4] вывод информации по заказу
SELECT o.order_id, o.order_dt, o.final_cost, s.status_name
FROM order_statuses os
    JOIN orders o ON o.order_id = os.order_id
    JOIN statuses s ON s.status_id = os.status_id
WHERE o.user_id = $1::uuid
    AND os.status_dt IN (
    SELECT max(status_dt)
    FROM order_statuses
    WHERE order_id = o.order_id
    );

-- [5] возвращает количество заказов, продажи которых выше среднего
SELECT d.name, SUM(count) AS orders_quantity
FROM order_items oi
    JOIN dishes d ON d.object_id = oi.item
WHERE oi.item IN (
    SELECT item
    FROM (SELECT item, SUM(count) AS total_sales
          FROM order_items oi
          GROUP BY 1) dishes_sales
    WHERE dishes_sales.total_sales > (
        SELECT SUM(t.total_sales)/ COUNT(*)
        FROM (SELECT item, SUM(count) AS total_sales
            FROM order_items oi
            GROUP BY
                1) t)
)
GROUP BY 1
ORDER BY orders_quantity DESC;

-- [оптимизация запросов] 
-- [1]
-- вреия выполнения исходного запроса "Execution Time: 60978.115 ms"

-- добавим индексы
-- 1. Сначала индексы для таблицы orders (т.к. основная фильтрация по city_id)
CREATE INDEX orders_city_id_order_id_idx ON orders(city_id, order_id);  
CREATE INDEX orders_order_id_idx ON orders(order_id);

-- 2. Индексы для таблицы order_statuses (основная таблица)
CREATE INDEX order_statuses_order_id_status_id_idx ON order_statuses(order_id, status_id); 
CREATE INDEX order_statuses_status_id_order_id_idx ON order_statuses(status_id, order_id);  
CREATE INDEX order_statuses_order_id_idx ON order_statuses(order_id); 

-- 3. Индекс для cities 
CREATE INDEX cities_city_id_idx ON cities(city_id);

-- 4. покрывающий индекс, предположу, что запрос часто выбирает конкретные поля
CREATE INDEX orders_covering_idx ON orders(city_id, order_id) INCLUDE (status_id);  -- если status_id часто запрашивается

SELECT count(*)
  FROM orders o
  LEFT JOIN order_statuses os1 ON os1.order_id = o.order_id 
                              AND os1.status_id = 2
 WHERE 1 = 1
   AND o.city_id = 1
   AND os1.order_id IS NULL;
-- время выполнения модифицированного запроса "Execution Time: 16.778 ms"
   
-- [2]
-- время выполнения исходного запроса "Execution Time: 2911.634 ms"

-- добавим индекс
CREATE INDEX idx_user_logs_datetime ON user_logs(datetime);

SELECT *
  FROM user_logs
 WHERE 1 = 1
   AND datetime >= current_date AND datetime < current_date + interval '1 day';
-- вреия выполнения модифицированного запроса "Execution Time: 0.097 ms"
   
-- [3]
-- время выполнения исходного запроса "Execution Time: 303.255 ms"
-- видимо я что-то упустил в курсе, но ожидал наследование индексов на партициях исходной таблицы. Проставлю руками пока

CREATE INDEX user_logs_visitor_uuid_datetime_idx ON user_logs(visitor_uuid,datetime);
CREATE INDEX user_logs_y2021q2_visitor_uuid_datetime_idx ON user_logs_y2021q2 (visitor_uuid, datetime);
CREATE INDEX user_logs_y2021q3_visitor_uuid_datetime_idx ON user_logs_y2021q3 (visitor_uuid, datetime);
CREATE INDEX user_logs_y2021q4_visitor_uuid_datetime_idx ON user_logs_y2021q4 (visitor_uuid, datetime);

-- Само по себе добавление индексов улучшило время выполнения запроса многократно, без перестройки запроса
-- вреия выполнения модифицированного запроса "Execution Time: 0.097 ms"

-- [4]
-- время выполнения исходного запроса "Execution Time: 105.176 ms"
-- попробуем через сте
  WITH last_statuses AS (
SELECT os.order_id,
       os.status_id,
       os.status_dt,
       ROW_NUMBER() OVER (PARTITION BY os.order_id ORDER BY os.status_dt DESC) as rn
  FROM order_statuses os
)
SELECT o.order_id, 
       o.order_dt, 
       o.final_cost, 
       s.status_name
  FROM orders o
  JOIN last_statuses ls ON ls.order_id = o.order_id AND ls.rn = 1
  JOIN statuses s ON s.status_id = ls.status_id
 WHERE o.user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid;
-- время выполнения измененного запроса "Execution Time: 52.331 ms"

-- [5]
-- время выполнения исходного запроса "Execution Time: 77.201 ms"
-- добавим индексы и перепишем запрос через сте
 
CREATE INDEX idx_order_items_item ON order_items(item); -- идея в том, чтобы ускорит ьгруппировку и соединение по items
CREATE INDEX idx_order_items_item_count ON order_items(item, count); -- попробуем ускорить агрегацию SUM(count) по item
CREATE INDEX idx_dishes_object_id ON dishes(object_id); -- надеюсь это ускорит соединение с dishes

  WITH item_sales_stats AS MATERIALIZED (
SELECT item, SUM(count) AS sales_volume
  FROM order_items
 GROUP BY item),
 
       filtered_items AS (
SELECT item
  FROM item_sales_stats
 WHERE 1 = 1 
   AND sales_volume > (SELECT AVG(sales_volume) FROM item_sales_stats))
   
SELECT d.name, 
       SUM(oi.count) AS orders_quantity
  FROM filtered_items fi
  JOIN order_items oi ON oi.item = fi.item
  JOIN dishes d ON d.object_id = oi.item
 GROUP BY d.name
 ORDER BY orders_quantity DESC;
-- время выполнения запроса "Execution Time: 22.349 ms"