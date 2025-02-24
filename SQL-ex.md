Задание: 1   
Найдите номер модели, скорость и размер жесткого диска для всех ПК стоимостью менее 500 дол. Вывести: model, speed и hd
```SQL
SELECT model, 
       speed, 
       hd 
  FROM PC
 WHERE price < 500
```