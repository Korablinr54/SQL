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

```SQL

```
