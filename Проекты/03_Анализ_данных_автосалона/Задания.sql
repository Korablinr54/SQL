
----------[Этап 1. Создание и заполнение БД]----------
-- Шаг 1. Создайте БД с именем sprint_1
CREATE DATABASE sprint_1; 

-- Шаг 2. Создайте схему raw_data и таблицу sales

CREATE SCHEMA IF NOT EXISTS raw_data;

-- типы данныъх и ограничения пока не определяю, сначала загружу сырые данные для анализа
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

-- Шаг 3. Скачайте и проанализируйте исходный csv-файл. 

-- Шаг 4. Заполните таблицу sales данными, используя команду COPY 

-- в psql выполняем и получаем ответ "COPY 1000" 
COPY raw_data.sales (id, auto, gasoline_consumption, price, date, person_name, phone, discount, brand_origin)
FROM '.../data/cars.csv'
CSV HEADER
NULL 'null'; 

-- првоеряем, что данные загружены в таблицу 
SELECT * 
  FROM raw_data.sales 
 LIMIT 5;

-- Шаг 5. Проанализируйте сырые данные
 
 /* 5.1
поле: auto
описание: убеждаемся, что цвет всегда отделен запятой и находится в конце строки. Разделить на brand, model, color
наличие null: нет
ограничения: нет
тип данных: brand varchar(16), максимальная длинна строки в данных 7, поставим 16 с запасом
            model varchar(16), максимальная длинна строки в данных 8, поставим 16 с запасом
            color varchar(16) в базовом наборе цветов максимальное количество символов это 6, поставим с запасом 16
 */
 SELECT DISTINCT auto
   FROM raw_data.sales
  ORDER BY auto;
 
-- выделяем brand и находим максимальную длинну строки
 SELECT DISTINCT TRIM(SPLIT_PART(auto, ' ', 1)) AS brand,
        LENGTH(SPLIT_PART(auto, ' ', 1)) AS cnt_sym
   FROM raw_data.sales
  ORDER BY cnt_sym DESC;
  
  -- выделяем model и находим максимальную длинну строки. Видим странную модель 'model' это явно Tesla, доработаем обработку
 SELECT DISTINCT TRIM(REPLACE(SPLIT_PART(auto, ' ', 2), ',', '')) AS model,
        LENGTH(SPLIT_PART(auto, ' ', 2)) AS cnt_sym
   FROM raw_data.sales
  ORDER BY cnt_sym DESC;
  
 SELECT DISTINCT
        TRIM(CASE 
                 WHEN TRIM(LOWER(SPLIT_PART(auto, ' ', 1))) = 'tesla' THEN REPLACE(SPLIT_PART(auto, ' ', 2) || ' ' || SPLIT_PART(auto, ' ', 3), ',', '')
                 ELSE REPLACE(SPLIT_PART(auto, ' ', 2), ',', '') 
              END) AS model,
        LENGTH(SPLIT_PART(auto, ' ', 2)) AS cnt_sym
   FROM raw_data.sales
  ORDER BY cnt_sym DESC; 

-- выделим color
 SELECT DISTINCT TRIM(REPLACE(SPLIT_PART(auto, ',', 2), ',', '')) AS color,
        LENGTH(TRIM(REPLACE(SPLIT_PART(auto, ',', 2), ',', ''))) AS cnt_sym
   FROM raw_data.sales
  ORDER BY cnt_sym DESC;

 /* 5.2
поле: gasoline_consumption
описание:нет
наличие null: да
ограничения: не потребуются
тип данных: Пододйет тип данных numeric(3.1) т.к. есть двухзначные значения, например 12, теоретически возможны 12,1 и тд 
 */

 SELECT DISTINCT gasoline_consumption
   FROM raw_data.sales
  ORDER BY gasoline_consumption DESC;

/* 5.3
поле: price
описание: нет
наличие null: нет
ограничения: CHECK(price > 0)
тип данных: numeriс(9,2)
 */

 SELECT DISTINCT price
   FROM raw_data.sales
  ORDER BY price DESC;

/* 5.4
поле: date
описание: нет
наличие null: нет
ограничения: нет
тип данных: date
 */  

 SELECT DISTINCT date
   FROM raw_data.sales
  ORDER BY date DESC;

/* 5.5
поле: person_name
описание: количество уникальных имен меньше количества строк, значит есть клиенты совершивши покупку повторно
наличие null: нет
ограничения: нет
тип данных: TEXT тк нет явноо паатерна, позволяющего определить максимальное количество знаков в имени
 */    
  
 SELECT DISTINCT person_name
   FROM raw_data.sales
  ORDER BY person_name DESC;
  
 SELECT COUNT(*) - (COUNT(*) - COUNT(DISTINCT person_name)) AS "Уникальных покупателей"
   FROM raw_data.sales;

/* 5.6
поле: phone
описание: количество уникальных имен меньше количества строк, значит есть клиенты совершивши покупку повторно. Стоит также проверить, что у одного клиента указан только один номер телефона
наличие null: нет
ограничения: нет
тип данных: TEXT т.к. нет явного паттерна длинны или типа данных здесь нет, установим тип данных TEXT
 */     
   
 SELECT DISTINCT phone
   FROM raw_data.sales
  ORDER BY phone DESC;

-- количество униикальных покупателей и уникальных номеров телефона совпадает.
 SELECT COUNT(*) - (COUNT(*) - COUNT(DISTINCT person_name)) AS "Уникальных покупателей",
        COUNT(*) - (COUNT(*) - COUNT(DISTINCT phone)) AS "Уникальных номеров телефона"
   FROM raw_data.sales;
   
-- Проверим, что у одного опльзователя только один номер телеофна
SELECT person_name, 
       COUNT(DISTINCT phone) AS cnt_of_uniq_number
  FROM raw_data.sales
 GROUP BY person_name
 ORDER BY cnt_of_uniq_number DESC; -- при сортировке по убыванию видим, что на 1 местре значение равное 1, значит у одного пользователя только один номер

 /* 5.7
поле: discount
описание:Данные в порядке, при наличии null следовало бы добавить NOT NULL DEFAULT 0 во избежание ошибок при выполнении расчетов
наличие null: нет
ограничения: нет
тип данных: несмотря на то, что все значения хранятся в int, это не значит, что не может появиться размера скидки в 6,5%. Установлю тип данных numeric(3,1)
 */ 

 SELECT DISTINCT discount
   FROM raw_data.sales
  ORDER BY discount DESC;

 /* 5.8
поле: brand_origin
описание:Данные в порядке, при наличии null следовало бы добавить NOT NULL DEFAULT 0 во избежание ошибок при выполнении расчетов
наличие null: да
ограничения: NOT NULL DEFAULT 'unknown'
тип данных: максимальное число символов 11, установим типа данных varchar(16)
 */ 
  
  SELECT DISTINCT brand_origin, length(brand_origin) AS cnt_of_symbols
   FROM raw_data.sales
  ORDER BY cnt_of_symbols DESC; 
  
 -- создаем новую таблицу для дальнейшй работы 
   DROP TABLE IF EXISTS raw_data.sales_processed;
 CREATE TABLE IF NOT EXISTS raw_data.sales_processed(
        id INT PRIMARY KEY,
        brand varchar(16),
        model varchar(16), 
        color varchar(16), 
        gasoline_consumption numeric(3,1),
        price numeric(9,2) NOT NULL DEFAULT 0 CHECK(price >= 0),
        date DATE,
        person_name TEXT,
        phone TEXT,
        discount numeric(3,1),
        brand_origin TEXT DEFAULT 'unknown'); 
 
 -- наполняем таблицу 
 DELETE FROM raw_data.sales_processed;
 INSERT INTO raw_data.sales_processed(id, brand, model, color, gasoline_consumption, price, date, person_name, phone, discount, brand_origin)
 SELECT id,
        TRIM(SPLIT_PART(auto, ' ', 1)),
        TRIM(CASE 
                 WHEN TRIM(LOWER(SPLIT_PART(auto, ' ', 1))) = 'tesla' THEN REPLACE(SPLIT_PART(auto, ' ', 2) || ' ' || SPLIT_PART(auto, ' ', 3), ',', '')
                 ELSE REPLACE(SPLIT_PART(auto, ' ', 2), ',', '') 
              END),
        TRIM(REPLACE(SPLIT_PART(auto, ',', 2), ',', '')),
        gasoline_consumption,
        price,
        date,
        person_name,
        phone,
        discount,
        COALESCE(brand_origin, 'unknown')
   FROM raw_data.sales
   
-- смотрим на данные в доработанной таблице
SELECT *
  FROM raw_data.sales_processed;

-- Шаг 6. Создайте схему car_shop. реши лвообще пересоздать все таблицы чем допиливать прошлые
CREATE SCHEMA IF NOT EXISTS car_shop;

-- Шаг 7. Типы данных определил выше, причины выбора тех или иных типов прописал на шаге 5, на этапе анализа сырых данных
-- Шаг 8. Заполните все таблицы данными, c помощью команд  

-- 8.1 Создаем таблицы
CREATE TABLE car_shop.countries (
       country_id SERIAL PRIMARY KEY,
       country_name TEXT UNIQUE NOT NULL); -- т.к. таблица ялвляется справочником, добавляем ограничение на уникальность

CREATE TABLE car_shop.brands (
       brand_id SERIAL PRIMARY KEY,
       brand_name VARCHAR(16) UNIQUE NOT NULL,
       country_id INT NOT NULL,
       
       CONSTRAINT fk_brands_countries 
          FOREIGN KEY (country_id) 
          REFERENCES car_shop.countries(country_id));

CREATE TABLE car_shop.colors (
       color_id SERIAL PRIMARY KEY,
       color_name VARCHAR(16) UNIQUE NOT NULL);

CREATE TABLE car_shop.models (
       model_id SERIAL PRIMARY KEY,
       model_name VARCHAR(16) NOT NULL,
       brand_id INT NOT NULL,
       gasoline_consumption NUMERIC(3,1),
    
       CONSTRAINT unique_model_brand UNIQUE (model_name, brand_id), -- добавляем комбинированное ограничение по уникальности
       
       CONSTRAINT fk_models_brands 
          FOREIGN KEY (brand_id) 
          REFERENCES car_shop.brands(brand_id));

CREATE TABLE car_shop.cars(
       car_id SERIAL PRIMARY KEY,
       model_id INT NOT NULL,
       color_id INT NOT NULL,
    
       CONSTRAINT unique_car_model_color UNIQUE (model_id, color_id),
       
       CONSTRAINT fk_cars_models 
          FOREIGN KEY (model_id) 
          REFERENCES car_shop.models(model_id),
          
       CONSTRAINT fk_cars_colors 
         FOREIGN KEY (color_id) 
         REFERENCES car_shop.colors(color_id));


CREATE TABLE car_shop.persons(
       person_id SERIAL PRIMARY KEY,
       person_name TEXT NOT NULL,
       phone TEXT NOT NULL,
    
       CONSTRAINT unique_person_phone UNIQUE (person_name, phone)
);

-- Наполняем таблицы данными 
-- 1. Страны
INSERT INTO car_shop.countries (country_name)
SELECT DISTINCT TRIM(INITCAP(brand_origin))
  FROM raw_data.sales_processed
 WHERE brand_origin IS NOT NULL
    ON CONFLICT (country_name) DO NOTHING;

-- 2. Бренды
INSERT INTO car_shop.brands (brand_name, country_id)
SELECT DISTINCT sp.brand,
       c.country_id
  FROM raw_data.sales_processed sp
  JOIN car_shop.countries c ON TRIM(INITCAP(sp.brand_origin)) = c.country_name
    ON CONFLICT (brand_name) DO NOTHING;

-- 3. Цвета
INSERT INTO car_shop.colors (color_name)
SELECT DISTINCT color
  FROM raw_data.sales_processed
    ON CONFLICT (color_name) DO NOTHING;

-- 4. Модели (с расходом топлива) -- сте дальше по плану обучения но нужны уже сейчас
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

-- 5. Автомобили
INSERT INTO car_shop.cars (model_id, color_id)
SELECT DISTINCT m.model_id,
       c.color_id
 FROM raw_data.sales_processed sp
 JOIN car_shop.brands b ON sp.brand = b.brand_name
 JOIN car_shop.models m ON sp.model = m.model_name AND b.brand_id = m.brand_id
 JOIN car_shop.colors c ON sp.color = c.color_name
   ON CONFLICT ON CONSTRAINT unique_car_model_color DO NOTHING;

-- 6. Покупатели
INSERT INTO car_shop.persons (person_name, phone)
SELECT DISTINCT person_name, phone
  FROM raw_data.sales_processed
    ON CONFLICT ON CONSTRAINT unique_person_phone DO NOTHING;

-- 8.5 Создаем и наполняем таблицу продаж 
CREATE TABLE car_shop.sales_normalized(
       id SERIAL PRIMARY KEY,
       car_id INT NOT NULL,
       price NUMERIC(9,2) NOT NULL DEFAULT 0 CHECK(price >= 0),
       date DATE,
       person_id INT NOT NULL,
       discount NUMERIC(3,1),
       brand_id INT NOT NULL,
       
    CONSTRAINT fk_sales_cars
       FOREIGN KEY (car_id)
    REFERENCES car_shop.cars(car_id),
    
    CONSTRAINT fk_sales_persons
       FOREIGN KEY (person_id)
       REFERENCES car_shop.persons(person_id),
       
    CONSTRAINT fk_sales_brands
       FOREIGN KEY (brand_id)
       REFERENCES car_shop.brands(brand_id));

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

----------[Этап 2. Создание выборок]----------
-- Задание 1. Напишите запрос, который выведет процент моделей машин, у которых нет параметра gasoline_consumption.
SELECT ROUND((COUNT(*) - COUNT(gasoline_consumption))::numeric / COUNT(*) * 100, 2) AS nulls_percentage_gasoline_consumption
  FROM car_shop.models;

-- Задание 2. Напишите запрос, который покажет название бренда и среднюю цену его автомобилей 
-- в разбивке по всем годам с учётом скидки. Итоговый результат отсортируйте по названию бренда и году 
-- в восходящем порядке. Среднюю цену округлите до второго знака после запятой.
SELECT b.brand_name, 
       EXTRACT(YEAR FROM s.date) AS year,
       ROUND(AVG(s.price * (1 - s.discount/100)), 2) AS price_avg
  FROM car_shop.sales_normalized AS s
  JOIN car_shop.brands AS b ON s.brand_id = b.brand_id
 GROUP BY b.brand_name, year
 ORDER BY b.brand_name, year;

-- Задание 3. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки. 
-- Результат отсортируйте по месяцам в восходящем порядке. 
-- Среднюю цену округлите до второго знака после запятой.
SELECT EXTRACT(month FROM date) AS month,
       ROUND(AVG(price * (1 - discount/100)), 2) AS price_avg
  FROM car_shop.sales_normalized
 WHERE EXTRACT(YEAR FROM date) = 2022
 GROUP BY month
 ORDER BY month;

-- Задание 4. Используя функцию STRING_AGG, напишите запрос, который выведет список купленных машин у каждого пользователя через запятую. 
-- Пользователь может купить две одинаковые машины — это нормально. Название машины покажите полное, с названием бренда — например: Tesla Model 3. 
-- Отсортируйте по имени пользователя в восходящем порядке. Сортировка внутри самой строки с машинами не нужна.
SELECT p.person_name,
       STRING_AGG(b.brand_name || ' ' || m.model_name, ', ') AS cars
  FROM car_shop.sales_normalized s
  JOIN car_shop.cars c ON s.car_id = c.car_id
  JOIN car_shop.models m ON c.model_id = m.model_id
  JOIN car_shop.brands b ON m.brand_id = b.brand_id
  JOIN car_shop.persons p ON s.person_id = p.person_id
 GROUP BY p.person_name
 ORDER BY p.person_name;

-- Задание 5. Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки. 
-- Цена в колонке price дана с учётом скидки.
SELECT co.country_name,
       ROUND(MAX(s.price / (1 - s.discount/100)), 2) AS original_price_max,
       ROUND(MIN(s.price / (1 - s.discount/100)), 2) AS original_price_min
  FROM car_shop.sales_normalized s
  JOIN car_shop.brands b ON s.brand_id = b.brand_id
  JOIN car_shop.countries co ON b.country_id = co.country_id
 GROUP BY co.country_name
 ORDER BY co.country_name;

-- Задание 6. Напишите запрос, который покажет количество всех пользователей из США. 
-- Это пользователи, у которых номер телефона начинается на +1.
SELECT COUNT(*) AS persons_from_usa_count
  FROM car_shop.persons
 WHERE phone LIKE '+1%';