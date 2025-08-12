# SQL-скрипт проекта "Анализ продаж автомобилей"

```sql
/*
 * Проект: Анализ продаж автомобилей
 * Описание:
 * Скрипт создает нормализованную структуру БД для анализа продаж автомобилей,
 * выполняет ETL-процесс из сырых данных в нормализованную схему,
 * содержит аналитические запросы для бизнес-анализа.
 * 
 * Инструменты:
 * - PostgreSQL 14+
 * - Docker
 * - DBeaver
 */
 
-- =============================================
-- ЭТАП 1: СОЗДАНИЕ И НАПОЛНЕНИЕ БАЗЫ ДАННЫХ
-- =============================================

-- Запуск контейнера PostgreSQL (для локальной разработки)
/*
docker run --name postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=sprint_1 \
  -d -p 5432:5432 \
  -v D:/project_1:/mnt/data \
  postgres
*/

-- 1.1 СОЗДАНИЕ СХЕМ И ТАБЛИЦ ДЛЯ СЫРЫХ ДАННЫХ
-------------------------------------------------

CREATE SCHEMA IF NOT EXISTS raw_data;

-- Таблица для импорта исходных данных
CREATE TABLE IF NOT EXISTS raw_data.sales(
       id INT,
       auto TEXT,
       gasoline_consumption NUMERIC,
       price NUMERIC,
       date DATE,
       person_name TEXT,
       phone TEXT,
       discount NUMERIC,
       brand_origin TEXT
);

-- 1.2 ИМПОРТ ДАННЫХ ИЗ CSV
-------------------------------
COPY raw_data.sales (id, auto, gasoline_consumption, price, date, person_name, phone, discount, brand_origin)
FROM '/mnt/data/cars.csv'
CSV HEADER
NULL 'null';

-- Проверка загруженных данных
SELECT * FROM raw_data.sales LIMIT 5;

-- 1.3 АНАЛИЗ И ПРЕОБРАЗОВАНИЕ ДАННЫХ
-----------------------------------------

-- Создаем обработанную версию таблицы с правильными типами данных
CREATE TABLE IF NOT EXISTS raw_data.sales_processed(
       id INT PRIMARY KEY,
       brand VARCHAR(16),
       model VARCHAR(16), 
       color VARCHAR(16), 
       gasoline_consumption NUMERIC(3,1),
       price NUMERIC(9,2) NOT NULL DEFAULT 0 CHECK(price >= 0),
       date DATE,
       person_name TEXT,
       phone TEXT,
       discount NUMERIC(3,1),
       brand_origin TEXT DEFAULT 'unknown'
);

-- Наполнение обработанной таблицы
INSERT INTO raw_data.sales_processed
SELECT id,
       TRIM(SPLIT_PART(auto, ' ', 1)) AS brand,
       TRIM(CASE 
                WHEN TRIM(LOWER(SPLIT_PART(auto, ' ', 1))) = 'tesla' 
                     THEN REPLACE(SPLIT_PART(auto, ' ', 2) || ' ' || SPLIT_PART(auto, ' ', 3), ',', '')
                ELSE REPLACE(SPLIT_PART(auto, ' ', 2), ',', '') 
            END) AS model,
      TRIM(REPLACE(SPLIT_PART(auto, ',', 2), ',', '')) AS color,
      gasoline_consumption,
      price,
      date,
      person_name,
      phone,
      discount,
      COALESCE(brand_origin, 'unknown') AS brand_origin
 FROM raw_data.sales;

-- =============================================
-- ЭТАП 2: СОЗДАНИЕ НОРМАЛИЗОВАННОЙ СХЕМЫ
-- =============================================

CREATE SCHEMA IF NOT EXISTS car_shop;

-- 2.1 ТАБЛИЦА СТРАН
CREATE TABLE car_shop.countries (
       country_id SERIAL PRIMARY KEY,
       country_name TEXT UNIQUE NOT NULL
);

-- 2.2 ТАБЛИЦА БРЕНДОВ
CREATE TABLE car_shop.brands (
       brand_id SERIAL PRIMARY KEY,
       brand_name VARCHAR(16) UNIQUE NOT NULL,
       country_id INT NOT NULL,

       CONSTRAINT fk_brands_countries FOREIGN KEY (country_id) 
       REFERENCES car_shop.countries(country_id)
);

-- 2.3 ТАБЛИЦА ЦВЕТОВ
CREATE TABLE car_shop.colors (
       color_id SERIAL PRIMARY KEY,
       color_name VARCHAR(16) UNIQUE NOT NULL
);

-- 2.4 ТАБЛИЦА МОДЕЛЕЙ
CREATE TABLE car_shop.models (
       model_id SERIAL PRIMARY KEY,
       model_name VARCHAR(16) NOT NULL,
       brand_id INT NOT NULL,
       gasoline_consumption NUMERIC(3,1),

       CONSTRAINT unique_model_brand UNIQUE (model_name, brand_id),

       CONSTRAINT fk_models_brands FOREIGN KEY (brand_id) 
       REFERENCES car_shop.brands(brand_id)
);

-- 2.5 ТАБЛИЦА АВТОМОБИЛЕЙ
CREATE TABLE car_shop.cars(
       car_id SERIAL PRIMARY KEY,
       model_id INT NOT NULL,
       color_id INT NOT NULL,

       CONSTRAINT unique_car_model_color UNIQUE (model_id, color_id),

       CONSTRAINT fk_cars_models FOREIGN KEY (model_id) 
       REFERENCES car_shop.models(model_id),

       CONSTRAINT fk_cars_colors FOREIGN KEY (color_id) 
       REFERENCES car_shop.colors(color_id)
);

-- 2.6 ТАБЛИЦА ПОКУПАТЕЛЕЙ
CREATE TABLE car_shop.persons(
       person_id SERIAL PRIMARY KEY,
       person_name TEXT NOT NULL,
       phone TEXT NOT NULL,

       CONSTRAINT unique_person_phone UNIQUE (person_name, phone)
);

-- 2.7 ТАБЛИЦА ПРОДАЖ
CREATE TABLE car_shop.sales_normalized(
       id SERIAL PRIMARY KEY,
       car_id INT NOT NULL,
       price NUMERIC(9,2) NOT NULL DEFAULT 0 CHECK(price >= 0),
       date DATE,
       person_id INT NOT NULL,
       discount NUMERIC(3,1),
       brand_id INT NOT NULL,

       CONSTRAINT fk_sales_cars FOREIGN KEY (car_id)
       REFERENCES car_shop.cars(car_id),

       CONSTRAINT fk_sales_persons FOREIGN KEY (person_id)
       REFERENCES car_shop.persons(person_id),

       CONSTRAINT fk_sales_brands FOREIGN KEY (brand_id)
       REFERENCES car_shop.brands(brand_id)
);

-- =============================================
-- ЭТАП 3: НАПОЛНЕНИЕ НОРМАЛИЗОВАННОЙ СХЕМЫ
-- =============================================

-- 3.1 Заполнение стран
INSERT INTO car_shop.countries (country_name)
SELECT DISTINCT TRIM(INITCAP(brand_origin))
  FROM raw_data.sales_processed
 WHERE brand_origin IS NOT NULL
    ON CONFLICT (country_name) DO NOTHING;

-- 3.2 Заполнение брендов
INSERT INTO car_shop.brands (brand_name, country_id)
SELECT DISTINCT sp.brand, c.country_id
  FROM raw_data.sales_processed sp
  JOIN car_shop.countries c ON TRIM(INITCAP(sp.brand_origin)) = c.country_name
    ON CONFLICT (brand_name) DO NOTHING;

-- 3.3 Заполнение цветов
INSERT INTO car_shop.colors (color_name)
SELECT DISTINCT color
  FROM raw_data.sales_processed
    ON CONFLICT (color_name) DO NOTHING;

-- 3.4 Заполнение моделей
INSERT INTO car_shop.models (model_name, brand_id, gasoline_consumption)
  WITH model_stats AS (
SELECT model,
       brand,
       AVG(gasoline_consumption) AS avg_consumption
  FROM raw_data.sales_processed
 GROUP BY model, brand)

SELECT ms.model,
       b.brand_id,
       ms.avg_consumption
  FROM model_stats ms
  JOIN car_shop.brands b ON ms.brand = b.brand_name
    ON CONFLICT ON CONSTRAINT unique_model_brand DO NOTHING;

-- 3.5 Заполнение автомобилей
INSERT INTO car_shop.cars (model_id, color_id)
SELECT DISTINCT m.model_id,
       c.color_id
  FROM raw_data.sales_processed sp
  JOIN car_shop.brands b ON sp.brand = b.brand_name
  JOIN car_shop.models m ON sp.model = m.model_name AND b.brand_id = m.brand_id
  JOIN car_shop.colors c  ON sp.color = c.color_name
    ON CONFLICT ON CONSTRAINT unique_car_model_color DO NOTHING;

-- 3.6 Заполнение покупателей
INSERT INTO car_shop.persons (person_name, phone)
SELECT DISTINCT person_name, phone
  FROM raw_data.sales_processed
    ON CONFLICT ON CONSTRAINT unique_person_phone DO NOTHING;

-- 3.7 Заполнение продаж
INSERT INTO car_shop.sales_normalized (car_id, price, date, person_id, discount, brand_id)
SELECT c.car_id,
       sp.price,
       sp.date,
       p.person_id,
       sp.discount,
       b.brand_id
  FROM raw_data.sales_processed sp
  JOIN car_shop.brands b ON sp.brand = b.brand_name
  JOIN car_shop.persons p ON sp.person_name = p.person_name AND sp.phone = p.phone
  JOIN car_shop.models m ON sp.model = m.model_name AND b.brand_id = m.brand_id
  JOIN car_shop.colors cl ON sp.color = cl.color_name
  JOIN car_shop.cars c ON m.model_id = c.model_id AND cl.color_id = c.color_id;

-- =============================================
-- ЭТАП 4: АНАЛИТИЧЕСКИЕ ЗАПРОСЫ
-- =============================================

-- 4.1 Процент моделей без данных о расходе топлива
SELECT ROUND((COUNT(*) - COUNT(gasoline_consumption))::numeric / COUNT(*) * 100, 2) AS nulls_percentage_gasoline_consumption
  FROM car_shop.models;

-- 4.2 Средняя цена по брендам и годам (со скидкой)
SELECT b.brand_name, 
       EXTRACT(YEAR FROM s.date) AS year,
       ROUND(AVG(s.price * (1 - s.discount/100)), 2) AS price_avg
  FROM car_shop.sales_normalized AS s
  JOIN car_shop.brands AS b ON s.brand_id = b.brand_id
 GROUP BY b.brand_name, year
 ORDER BY b.brand_name, year;

-- 4.3 Средняя цена по месяцам 2022 года (со скидкой)
SELECT EXTRACT(month FROM date) AS month,
       ROUND(AVG(price * (1 - discount/100)), 2) AS price_avg
  FROM car_shop.sales_normalized
 WHERE EXTRACT(YEAR FROM date) = 2022
 GROUP BY month
 ORDER BY month;

-- 4.4 Список купленных машин по покупателям
SELECT p.person_name,
       STRING_AGG(b.brand_name || ' ' || m.model_name, ', ') AS cars
  FROM car_shop.sales_normalized s
  JOIN car_shop.cars c ON s.car_id = c.car_id
  JOIN car_shop.models m ON c.model_id = m.model_id
  JOIN car_shop.brands b ON m.brand_id = b.brand_id
  JOIN car_shop.persons p  ON s.person_id = p.person_id
 GROUP BY p.person_name
 ORDER BY p.person_name;

-- 4.5 Макс/мин цена по странам (без скидки)
SELECT co.country_name,
       ROUND(MAX(s.price / (1 - s.discount/100)), 2) AS original_price_max,
       ROUND(MIN(s.price / (1 - s.discount/100)), 2) AS original_price_min
  FROM car_shop.sales_normalized s
  JOIN car_shop.brands b ON s.brand_id = b.brand_id
  JOIN car_shop.countries co ON b.country_id = co.country_id
 GROUP BY co.country_name
 ORDER BY co.country_name;

-- 4.6 🇺🇸 Количество покупателей из США
SELECT COUNT(*) AS persons_from_usa_count
  FROM car_shop.persons
 WHERE phone LIKE '+1%';
