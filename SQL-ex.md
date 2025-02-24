Задание: 1   
Найдите номер модели, скорость и размер жесткого диска для всех ПК стоимостью менее 500 дол. Вывести: model, speed и hd
```SQL
SELECT model, 
       speed, 
       hd 
  FROM PC
 WHERE price < 500
```
<br/>  

Задание: 2  
Найдите производителей принтеров. Вывести: maker
```SQL
SELECT DISTINCT maker
  FROM Product
 WHERE type = 'printer'
```
<br/>  

Задание: 3  
Найдите номер модели, объем памяти и размеры экранов ПК-блокнотов, цена которых превышает 1000 дол
```SQL
SELECT model,
       ram,
       screen
  FROM Laptop
 WHERE price > 1000
```
<br/>  

Задание: 4
Найдите все записи таблицы Printer для цветных принтеров
```SQL
SELECT *
  FROM Printer
 WHERE color = 'y'
```
