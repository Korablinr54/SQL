/* 
Проект выполнялся с использованием Docker и DBeaver 
Полный цикл: от создания БД до аналитических запросов
*/

----------[Этап 1. Создание и заполнение БД]----------

-- Шаг 1. Запуск контейнера PostgreSQL
docker run --name postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=sprint_1 \
  -d -p 5432:5432 \
  -v D:/project_1:/mnt/data \
  postgres

-- Шаг 2. Создание схемы и таблицы для сырых данных
CREATE SCHEMA IF NOT EXISTS raw_data;

CREATE TABLE IF NOT EXISTS raw_data.sales(
       id INT,
       auto TEXT,
       gasoline_consumption NUMERIC,
       price NUMERIC,
       date DATE,
       person_name TEXT,
       phone TEXT,
       discount NUMERIC,
       brand_origin TEXT);

-- Шаг 3. Загрузка данных из CSV
COPY raw_data.sales (id, auto, gasoline_consumption, price, date, person_name, phone, discount, brand_origin)
FROM '/mnt/data/cars.csv'
CSV HEADER
NULL 'null';

-- Шаг 4. Создание нормализованной структуры
CREATE SCHEMA IF NOT EXISTS car_shop;

-- Таблица стран
CREATE TABLE car_shop.countries (
       country_id SERIAL PRIMARY KEY,
       country_name TEXT UNIQUE NOT NULL);

-- Таблица брендов
CREATE TABLE car_shop.brands (
       brand_id SERIAL PRIMARY KEY,
       brand_name VARCHAR(16) UNIQUE NOT NULL,
       country_id INT NOT NULL,
       CONSTRAINT fk_brands_countries FOREIGN KEY (country_id) 
       REFERENCES car_shop.countries(country_id));

-- Таблица цветов
CREATE TABLE car_shop.colors (
       color_id SERIAL PRIMARY KEY,
       color_name VARCHAR(16) UNIQUE NOT NULL);

-- Таблица моделей
CREATE TABLE car_shop.models (
       model_id SERIAL PRIMARY KEY,
       model_name VARCHAR(16) NOT NULL,
       brand_id INT NOT NULL,
       gasoline_consumption NUMERIC(3,1),
       CONSTRAINT unique_model_brand UNIQUE (model_name, brand_id),
       CONSTRAINT fk_models_brands FOREIGN KEY (brand_id) 
       REFERENCES car_shop.brands(brand_id));

-- Таблица автомобилей
CREATE TABLE car_shop.cars(
       car_id SERIAL PRIMARY KEY,
       model_id INT NOT NULL,
       color_id INT NOT NULL,
       CONSTRAINT unique_car_model_color UNIQUE (model_id, color_id),
       CONSTRAINT fk_cars_models FOREIGN KEY (model_id) 
       REFERENCES car_shop.models(model_id),
       CONSTRAINT fk_cars_colors FOREIGN KEY (color_id) 
       REFERENCES car_shop.colors(color_id));

-- Таблица покупателей
CREATE TABLE car_shop.persons(
       person_id SERIAL PRIMARY KEY,
       person_name TEXT NOT NULL,
       phone TEXT NOT NULL,
       CONSTRAINT unique_person_phone UNIQUE (person_name, phone));

-- Таблица продаж
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
       REFERENCES car_shop.brands(brand_id));

----------[Этап 2. Аналитические запросы]----------

-- 1. Процент моделей без данных о расходе топлива
SELECT ROUND((COUNT(*) - COUNT(gasoline_consumption))::numeric / COUNT(*) * 100, 2) 
AS nulls_percentage_gasoline_consumption
FROM car_shop.models;

-- 2. Средняя цена по брендам и годам с учетом скидки
SELECT b.brand_name, 
       EXTRACT(YEAR FROM s.date) AS year,
       ROUND(AVG(s.price * (1 - s.discount/100)), 2) AS price_avg
FROM car_shop.sales_normalized AS s
JOIN car_shop.brands AS b ON s.brand_id = b.brand_id
GROUP BY b.brand_name, year
ORDER BY b.brand_name, year;

-- 3. Динамика средних цен по месяцам 2022 года
SELECT EXTRACT(month FROM date) AS month,
       ROUND(AVG(price * (1 - discount/100)), 2) AS price_avg
FROM car_shop.sales_normalized
WHERE EXTRACT(YEAR FROM date) = 2022
GROUP BY month
ORDER BY month;

-- 4. Список покупок по клиентам
SELECT p.person_name,
       STRING_AGG(b.brand_name || ' ' || m.model_name, ', ') AS cars
FROM car_shop.sales_normalized s
JOIN car_shop.cars c ON s.car_id = c.car_id
JOIN car_shop.models m ON c.model_id = m.model_id
JOIN car_shop.brands b ON m.brand_id = b.brand_id
JOIN car_shop.persons p ON s.person_id = p.person_id
GROUP BY p.person_name
ORDER BY p.person_name;

-- 5. Максимальная и минимальная цена по странам (без учета скидки)
SELECT co.country_name,
       ROUND(MAX(s.price / (1 - s.discount/100)), 2) AS original_price_max,
       ROUND(MIN(s.price / (1 - s.discount/100)), 2) AS original_price_min
FROM car_shop.sales_normalized s
JOIN car_shop.brands b ON s.brand_id = b.brand_id
JOIN car_shop.countries co ON b.country_id = co.country_id
GROUP BY co.country_name
ORDER BY co.country_name;

-- 6. Количество покупателей из США (телефон +1)
SELECT COUNT(*) AS persons_from_usa_count
FROM car_shop.persons
WHERE phone LIKE '+1%';
