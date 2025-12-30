/* Этап 1. Создание дополнительных таблиц */

-- Шаг 1. Cоздайте enum cafe.restaurant_type с типом заведения coffee_shop, restaurant, bar, pizzeria. Используйте этот тип данных при создании таблицы restaurants.
CREATE TYPE cafe.restaurant_type AS ENUM
('coffee_shop', 'restaurant', 'bar', 'pizzeria');

-- Шаг 2. Создайте таблицу cafe.restaurants с информацией о ресторанах. В качестве первичного ключа используйте случайно сгенерированный uuid. 
CREATE TABLE IF NOT EXISTS cafe.restaurants ( 
       restaurant_uuid uuid DEFAULT gen_random_uuid(),
       name varchar(128) NOT NULL,
       loc geometry NOT NULL,
       type cafe.restaurant_type NOT NULL,
       menu jsonb NOT NULL,
       
       CONSTRAINT primary_key_rest PRIMARY KEY (restaurant_uuid));

-- Наполним таблицу
INSERT INTO cafe.restaurants (name, loc, type, menu)
SELECT distinct s.cafe_name,
       ST_SetSRID(st_point(s.longitude, s.latitude),4326),
       s.type::cafe.restaurant_type,
       m.menu
  FROM raw_data.sales s
  LEFT JOIN raw_data.menu m USING (cafe_name);

SELECT *
  FROM cafe.restaurants; -- проверяем корректность внесения данных

-- Шаг 3. Создайте таблицу cafe.managers с информацией о менеджерах. В качестве первичного ключа используйте случайно сгенерированный uuid. 
CREATE TABLE IF NOT EXISTS cafe.managers ( 
       manager_uuid uuid DEFAULT gen_random_uuid(),
       name varchar(128) NOT NULL, 
       phone varchar(32) NOT NULL,
       
       CONSTRAINT primary_key_manager PRIMARY KEY (manager_uuid));
       
 -- Наполним таблицу
INSERT INTO cafe.managers (name, phone)
       SELECT DISTINCT manager,
              manager_phone
  FROM raw_data.sales;      

SELECT *
  FROM cafe.managers; -- проверяем корректность внесения данных
  
-- Шаг 4. Создайте таблицу cafe.restaurant_manager_work_dates
CREATE TABLE IF NOT EXISTS cafe.restaurant_manager_work_dates ( 
       restaurant_uuid uuid NOT NULL,
       manager_uuid uuid NOT NULL,
       start_work_date date NOT NULL,
       end_work_date date,
       
       CONSTRAINT primary_key_restaurant_manager PRIMARY KEY (restaurant_uuid, manager_uuid), -- добавляем ограничение в виде составного первичного ключа
       CONSTRAINT foreign_key_restaurant FOREIGN KEY (restaurant_uuid) REFERENCES cafe.restaurants, -- задаем внешние ключи
       CONSTRAINT foreign_key_manager FOREIGN KEY (manager_uuid) REFERENCES cafe.managers
);

-- Наполним таблицу
INSERT INTO cafe.restaurant_manager_work_dates (restaurant_uuid, manager_uuid, start_work_date, end_work_date)
       SELECT r.restaurant_uuid,
              m.manager_uuid,
              MIN(report_date) AS start_work_date,
              MAX(report_date) AS end_work_date
         FROM raw_data.sales AS s
         JOIN cafe.restaurants AS r ON s.cafe_name = r.name
         JOIN cafe.managers AS m ON s.manager = m.name
        GROUP BY r.restaurant_uuid, m.manager_uuid;

SELECT *
  FROM cafe.restaurant_manager_work_dates; -- проверяем корректность внесения данных
  
-- Шаг 5. Создайте таблицу cafe.sales 
CREATE TABLE IF NOT EXISTS cafe.sales (
       date date NOT NULL,
       restaurant_uuid uuid NOT NULL,
       avg_check numeric(7,2),
       
       CONSTRAINT primary_key_sales PRIMARY KEY (date, restaurant_uuid),
       CONSTRAINT foreign_key_restaurant FOREIGN KEY (restaurant_uuid) REFERENCES cafe.restaurants);

-- Наполним таблицу
INSERT INTO cafe.sales (date, restaurant_uuid, avg_check)
       SELECT s.report_date,
       r.restaurant_uuid,
       s.avg_check
  FROM raw_data.sales s
  LEFT JOIN cafe.restaurants r on s.cafe_name = r.name
    ON CONFLICT (date, restaurant_uuid) DO NOTHING;  -- Пропустить дубликаты;

/* Этап 2. Создание представлений и написание аналитических запросов */

-- Задание 1
-- Чтобы выдать премию менеджерам, нужно понять, у каких заведений самый высокий средний чек. 
-- Создайте представление, которое покажет топ-3 заведений внутри каждого типа заведения по среднему чеку за все даты. 
-- Столбец со средним чеком округлите до второго знака после запятой
CREATE VIEW cafe.top_by_avg_check AS
  WITH cte AS (
SELECT r.name,
       r.type,
       avg(avg_check)::numeric(6,2) AS avg_check,
       ROW_NUMBER() OVER (PARTITION BY r.type ORDER BY avg(avg_check) DESC) AS rank
  FROM cafe.sales s
  LEFT JOIN cafe.restaurants r ON s.restaurant_uuid = r.restaurant_uuid
 GROUP BY r.name, r.type)
 
SELECT name AS "Название заведения",
       type AS "Тип заведения",
       avg_check AS "Средний чек"
  from cte
where rank <= 3;

SELECT * 
  FROM cafe.top_by_avg_check;
  
-- Задание 2
-- Создайте материализованное представление, которое покажет, как изменяется средний чек для каждого заведения от года к году за все года за исключением 2023 года. 
-- Все столбцы со средним чеком округлите до второго знака после запятой.
CREATE MATERIALIZED VIEW cafe.change_avg_check_by_year AS 
  WITH cte_1 AS (
       SELECT restaurant_uuid,
              EXTRACT(YEAR FROM date) AS year,
              AVG(avg_check) AS average_by_year
         FROM cafe.sales
        WHERE EXTRACT(YEAR FROM date) != 2023
        GROUP BY restaurant_uuid, EXTRACT(YEAR FROM date)),
    
       cte_2 AS (
       SELECT cte_1.year,
              r.name,
              r.type,
              ROUND(cte_1.average_by_year, 2) AS average_by_pres_year
         FROM cte_1 
         LEFT JOIN cafe.restaurants r USING (restaurant_uuid))
    
SELECT YEAR AS "Год",
       name AS "Название заведения",
       TYPE AS "Тип заведения",
       average_by_pres_year "Средний чек в этом году",
       LAG(average_by_pres_year) OVER (PARTITION BY name ORDER BY year) AS "Средний чек в предыдущем году",
       CASE 
           WHEN LAG(average_by_pres_year) OVER (PARTITION BY name ORDER BY year) IS NULL THEN NULL
           ELSE ROUND(((average_by_pres_year - LAG(average_by_pres_year) OVER (PARTITION BY name ORDER BY year)) / LAG(average_by_pres_year) OVER (PARTITION BY name ORDER BY year)) * 100, 2)
       END AS "Изменение среднего чека в %"
  FROM cte_2
 ORDER BY name, year;

SELECT * 
  FROM cafe.change_avg_check_by_year;
  
-- Задание 3
-- Найдите топ-3 заведения, где чаще всего менялся менеджер за весь период.
SELECT r.name AS "Название заведения",
       count(rm.manager_uuid) AS "Сколько раз менялся менеджер"
  FROM cafe.restaurant_manager_work_dates AS rm
  JOIN cafe.restaurants AS r ON rm.restaurant_uuid = r.restaurant_uuid
 GROUP BY r.name
 ORDER BY "Количество изменений" desc
 LIMIT 3;
 
-- Задание 4
-- Найдите пиццерию с самым большим количеством пицц в меню. Если таких пиццерий несколько, выведите все.
  WITH cte AS (
SELECT name,
       jsonb_each(menu -> 'Пицца') as pizza
  FROM cafe.restaurants
 WHERE type = 'pizzeria'),

cte_rank as (
SELECT name,
       count(pizza) as pizza_cnt,
       dense_rank() over(order by count(pizza) desc) as rank
  FROM cte
 GROUP BY name)
 
SELECT name AS "Название заведения",
       pizza_cnt AS "Количество пицц в меню"
  FROM cte_rank
 WHERE rank = 1
 ORDER BY "Количество пицц в меню" DESC;
 
 -- Задание 5
 -- Найдите самую дорогую пиццу для каждой пиццерии.
  WITH cte AS (
SELECT restaurant_uuid,
       name AS pizzeria,
       menu -> 'Пицца' AS pizza_menu
  FROM cafe.restaurants
 WHERE type = 'pizzeria' AND menu ? 'Пицца'),

       cte_price AS (
SELECT cte.restaurant_uuid,
       cte.pizzeria,
       'Пицца' AS dish_type,
       pizza_name AS pizza,
       (cte.pizza_menu ->> pizza_name)::numeric(7,2) AS price
  FROM cte, jsonb_object_keys(cte.pizza_menu) AS pizza_name),

       cte_rank AS (
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY pizzeria ORDER BY price DESC) AS rank
  FROM cte_price)

SELECT pizzeria AS "Название заведения",
       dish_type AS "Тип блюда",
       pizza AS "Название пиццы",
       price AS "Цена"
  FROM cte_rank
WHERE rank = 1;

 -- Задание 6
 -- Найдите два самых близких друг к другу заведения одного типа.
  WITH cte AS (
SELECT a.name AS rest_1,
       b.name AS rest_2,
       a.type AS type,
       ST_Distance(a.loc::geography, b.loc::geography) AS distance
  FROM cafe.restaurants a
  JOIN cafe.restaurants b ON a.type = b.type AND a.name <> b.name)

SELECT rest_1 AS "Название Заведения 1",
       rest_2 AS "Название Заведения 2",
       type AS "Тип заведения",
       distance AS "Расстояние"
  FROM cte
 ORDER BY distance
 LIMIT 1;
 
 -- ЗАДАНИЕ 7
 -- Найдите район с самым большим количеством заведений и район с самым маленьким количеством заведений. 
 -- Первой строчкой выведите район с самым большим количеством заведений, второй — с самым маленьким. 
  WITH cte AS (
SELECT d.district_name,
       COUNT(r.name) AS cnt
  FROM cafe.districts d
  LEFT JOIN cafe.restaurants r ON ST_Covers(d.district_geom, r.loc)
 GROUP BY d.district_name),

       cte_max AS (
SELECT district_name,
       cnt
  FROM cte
 ORDER BY cnt DESC
 LIMIT 1),

       cte_min AS (
SELECT district_name,
       cnt 
  FROM cte
 WHERE cnt > 0
 ORDER BY cnt
 LIMIT 1)

SELECT district_name AS "Название района",
       cnt AS "Количество заведений"
  FROM cte_max

UNION ALL

SELECT district_name,
       cnt
  FROM cte_min
 ORDER BY "Количество заведений" DESC;