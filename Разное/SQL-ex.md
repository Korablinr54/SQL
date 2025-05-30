Задание: 1   
Найдите номер модели, скорость и размер жесткого диска для всех ПК стоимостью менее 500 дол. Вывести: model, speed и hd
```SQL
SELECT model, 
       speed, 
       hd 
  FROM PC
 WHERE price < 500;
```
<br/>  

Задание: 2  
Найдите производителей принтеров. Вывести: maker
```SQL
SELECT DISTINCT maker
  FROM Product
 WHERE type = 'printer';
```
<br/>  

Задание: 3  
Найдите номер модели, объем памяти и размеры экранов ПК-блокнотов, цена которых превышает 1000 дол
```SQL
SELECT model,
       ram,
       screen
  FROM Laptop
 WHERE price > 1000;
```
<br/>  

Задание: 4  
Найдите все записи таблицы Printer для цветных принтеров
```SQL
SELECT *
  FROM Printer
 WHERE color = 'y';
```
<br/>  

Задание: 5  
Найдите номер модели, скорость и размер жесткого диска ПК, имеющих 12x или 24x CD и цену менее 600 дол.
```SQL
SELECT model,
       speed,
       hd
  FROM PC
 WHERE (cd = '12x' OR cd = '24x') AND price < 600;
```
<br/>  

Задание: 6  
Для каждого производителя, выпускающего ПК-блокноты c объёмом жесткого диска не менее 10 Гбайт, найти скорости таких ПК-блокнотов. Вывод: производитель, скорость
```SQL
SELECT distinct p.maker, 
       l.speed
  FROM Product AS p
  LEFT JOIN Laptop AS l ON p.model = l.model
 WHERE l.hd >= 10;
```
<br/>  

Задание: 7  
Найдите номера моделей и цены всех имеющихся в продаже продуктов (любого типа) производителя B (латинская буква)
```SQL
SELECT a.model, price 
  FROM (SELECT model,
               price 
          FROM PC 
 UNION
        SELECT model,
               price 
          FROM Laptop
 UNION
        SELECT model,
               price 
          FROM Printer) AS a
  JOIN Product p ON a.model = p.model
 WHERE p.maker = 'B'
```
<br/>  

Задание: 8  
Найдите производителя, выпускающего ПК, но не ПК-блокноты
```SQL
SELECT distinct maker
  FROM product 
 WHERE type = 'PC'

EXCEPT

SELECT DISTINCT maker
  FROM product
 WHERE type = 'Laptop'
```
<br/>  

Задание: 9  
Найдите производителей ПК с процессором не менее 450 Мгц. Вывести: Maker
```SQL
SELECT DISTINCT p.maker
  FROM Product p
  LEFT JOIN pc ON p.model = pc.model
 WHERE speed >= 450
```
<br/>  

Задание: 10  
Найдите модели принтеров, имеющих самую высокую цену. Вывести: model, price
```SQL
SELECT model,
       price
  FROM printer
 WHERE price = (SELECT MAX(price) 
                  FROM printer)
```
<br/>  

Задание: 11  
Найдите среднюю скорость ПК
```SQL
SELECT AVG(speed)
  FROM pc
```
<br/>  

Задание: 12  
Найдите среднюю скорость ПК-блокнотов, цена которых превышает 1000 дол.
```SQL
SELECT AVG(speed)
  FROM Laptop
 WHERE price > 1000
```
<br/>  

Задание: 13  
Найдите среднюю скорость ПК, выпущенных производителем A
```SQL
SELECT AVG(speed)
  FROM Pc
  JOIN Product AS p ON p.model = Pc.model AND p.maker = 'A'
```
<br/>  

Задание: 14  
Найдите класс, имя и страну для кораблей из таблицы Ships, имеющих не менее 10 орудий  
```SQL
SELECT s.class,
       s.name,
       c.country
  FROM Ships AS s
  LEFT JOIN Classes AS c ON s.class = c.class
 WHERE c.numGuns >= 10;
 ```
 <br/>  

Задание: 15  
Найдите размеры жестких дисков, совпадающих у двух и более PC. Вывести: HD  
```SQL
SELECT HD
  FROM (SELECT HD, COUNT(*) as cnt
          FROM PC
         GROUP BY HD
        HAVING COUNT(*) > 1) as t;
```
<br/>  

Задание: 16  
Найдите пары моделей PC, имеющих одинаковые скорость и RAM. В результате каждая пара указывается только один раз, т.е. (i,j), но не (j,i), Порядок вывода: модель с большим номером, модель с меньшим номером, скорость и RAM
```SQL
SELECT DISTINCT 
       pc_1.model, 
       pc_2.model, 
       pc_1.speed, 
       pc_1.ram
  FROM PC as pc_1, PC as pc_2
 WHERE pc_1.speed = pc_2.speed
   AND pc_1.ram = pc_2.ram
   AND pc_1.model > pc_2.model;
```
<br/>  

Задание: 17  
Найдите модели ПК-блокнотов, скорость которых меньше скорости каждого из ПК. Вывести: type, model, speed
```SQL
SELECT DISTINCT
       p.type,
       p.model,
       l.speed
  FROM product AS p
  JOIN Laptop as l ON p.model = l.model
 WHERE l.speed < ANY (SELECT DISTINCT speed
                        FROM pc);
```
<br/>  

Задание: 18  
Найдите производителей самых дешевых цветных принтеров. Вывести: maker, price  
```SQL
SELECT DISTINCT pt.maker, pr.price
  FROM (SELECT model, price 
          FROM Printer 
         WHERE color = 'y') as pr
  JOIN Product as pt ON pr.model = pt.model
 WHERE price = (SELECT min(price) 
                  FROM Printer 
                 WHERE color = 'y');
```
<br/>  

Задание: 19  
Для каждого производителя, имеющего модели в таблице Laptop, найдите средний размер экрана выпускаемых им ПК-блокнотов  
```SQL
SELECT p.maker, AVG(screen) AS Avg_screen
  FROM Product AS p
  JOIN Laptop AS l ON p.model = l.model
 GROUP BY p.maker;
```
<br/>  

Задание: 20  
Найдите производителей, выпускающих по меньшей мере три различных модели ПК. Вывести: Maker, число моделей ПК  
```SQL
SELECT maker, 
       count(distinct model) AS count_model
  FROM Product
 WHERE type = 'PC'
 GROUP BY maker
HAVING count(distinct model) >= 3;
```
<br/>  

Задание: 21  
Найдите максимальную цену ПК, выпускаемых каждым производителем, у которого есть модели в таблице PC  
```SQL
SELECT maker, 
       MAX(price)
  FROM Product
  JOIN PC USING (model) 
 GROUP BY maker;
```
<br/>  

Задание: 22    
Для каждого значения скорости ПК, превышающего 600 МГц, определите среднюю цену ПК с такой же скоростью. Вывести: speed, средняя цена
```SQL
SELECT speed,
       AVG(price) AS Avg_price
  FROM PC
 WHERE speed > 600
 GROUP BY speed;

```
<br/>  

Задание: 23      
Найдите производителей, которые производили бы как ПК со скоростью не менее 750 МГц, так и ПК-блокноты со скоростью не менее 750 МГц
```SQL
SELECT distinct p.maker
  FROM Product AS p
  JOIN PC AS pc USING (model) WHERE pc.speed >= 750

UNION 

SELECT distinct p.maker
  FROM Product AS p
  JOIN Laptop AS l USING (model) WHERE l.speed >= 750
```
<br/>  

Задание: 24      
Перечислите номера моделей любых типов, имеющих самую высокую цену по всей имеющейся в базе данных продукции
```SQL
WITH cte AS(

SELECT DISTINCT model, price
  FROM PC

UNION

SELECT DISTINCT model, price
  FROM Laptop

UNION 

SELECT DISTINCT model, price
  FROM Printer)

SELECT model
  FROM cte
 WHERE price = (SELECT MAX(price) FROM cte);
```
<br/>  

Задание: 25      
Найдите производителей принтеров, которые производят ПК с наименьшим объемом RAM и с самым быстрым процессором среди всех ПК, имеющих наименьший объем RAM
```SQL
SELECT DISTINCT p.maker
  FROM Product p
  JOIN PC ON p.model = PC.model
 WHERE PC.ram = (SELECT MIN(ram) FROM PC)
   AND PC.speed = (SELECT MAX(speed)
                     FROM PC
                    WHERE ram = (SELECT MIN(ram) FROM PC) 
  )
   AND p.maker IN (SELECT maker
                     FROM Product
                    WHERE type = 'Printer'
  );
```
<br/>  

Задание: 26      
Найдите среднюю цену ПК и ПК-блокнотов, выпущенных производителем A
```SQL
SELECT AVG(Price)
  FROM (SELECT Price
          FROM Product
          JOIN PC USING(model)
         WHERE maker = 'A'

         UNION ALL

         SELECT Price
           FROM Product
           JOIN Laptop USING(model)
          WHERE maker = 'A') as t1;
```
<br/>  

Задание: 27      
Найдите средний размер диска ПК каждого из тех производителей, которые выпускают и принтеры. Вывести: maker, средний размер HD
```SQL
SELECT p.maker, 
       AVG(pc.hd) AS Avg_hd
  FROM Product AS p
  JOIN PC AS pc ON p.model = pc.model
 WHERE p.maker IN (SELECT p.maker
                     FROM Product AS p
                    WHERE p.type = 'Printer')                   
 GROUP BY p.maker;
```
<br/>  

Задание: 28      
Используя таблицу Product, определить количество производителей, выпускающих по одной модели
```SQL
  WITH cte AS (
SELECT maker, count(model) as qty
  FROM Product
 GROUP BY maker
)

SELECT COUNT(maker)
  FROM cte
 WHERE qty = 1;
```
<br/>  

Задание: 29      
В предположении, что приход и расход денег на каждом пункте приема фиксируется не чаще одного раза в день [т.е. первичный ключ (пункт, дата)], написать запрос с выходными данными (пункт, дата, приход, расход)
```SQL
 SELECT t.point,
        t.date,
        SUM(t.inc),
        sum(t.out) 
  FROM (SELECT point,
               date,
               inc,
               NULL AS out
          FROM Income_o 
    UNION 
        SELECT point,
               date,
               NULL AS inc,
               Outcome_o.out
          FROM Outcome_o) AS t 
  GROUP BY t.point, t.date;
```
<br/>  

Задание: 30        
В предположении, что приход и расход денег на каждом пункте приема фиксируется произвольное число раз (первичным ключом в таблицах является столбец code), требуется получить таблицу, в которой каждому пункту за каждую дату выполнения операций будет соответствовать одна строка
```SQL
SELECT point,
       date,
       SUM(sum_out),
       SUM(sum_inc)
  FROM (SELECT point, date, SUM(inc) AS sum_inc, null AS sum_out
          FROM Income
         GROUP BY point, date
 UNION
        SELECT point, date, null AS sum_inc, SUM(out) AS sum_out
          FROM Outcome
         GROUP BY point, date) AS t1
GROUP BY point, date
ORDER BY point;
```
<br/>  

Задание: 31        
Для классов кораблей, калибр орудий которых не менее 16 дюймов, укажите класс и страну
```SQL
select class, country 
  FROM Classes 
 WHERE bore >= 16;
```
<br/>  

Задание: 32        
Одной из характеристик корабля является половина куба калибра его главных орудий (mw). С точностью до 2 десятичных знаков определите среднее значение mw для кораблей каждой страны, у которой есть корабли в базе данных
```SQL
  WITH combined_data AS (
SELECT c.country,
       c.class,
       c.bore,
       s.name
  FROM classes c
  LEFT JOIN ships s ON c.class = s.class

 UNION ALL

SELECT DISTINCT c.country,
       c.class,
       c.bore,
       o.ship AS name
  FROM classes c
  LEFT JOIN outcomes o ON c.class = o.ship
 WHERE o.ship = c.class AND o.ship NOT IN (SELECT name FROM ships))

SELECT country,
       CAST(AVG((POWER(bore, 3) / 2)) AS NUMERIC(6, 2)) AS weight
  FROM combined_data
 WHERE name IS NOT NULL
 GROUP BY country;
```
<br/>  

Задание: 33        

```SQL

```
