/*
1) Отобразите все записи из таблицы company по компаниям, которые закрылись.
*/
SELECT *
  FROM company
 WHERE status = 'closed';


/*
2) Отобразите количество привлечённых средств для новостных компаний США. 
Используйте данные из таблицы company. 
Отсортируйте таблицу по убыванию значений в поле funding_total.
*/
SELECT funding_total
  FROM company
 WHERE category_code = 'news'
   AND country_code = 'USA'
 ORDER BY funding_total DESC;


/*
3) Найдите общую сумму сделок по покупке одних компаний другими в долларах. 
Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.
*/
SELECT SUM(price_amount) as price_amount
  FROM acquisition
 WHERE EXTRACT(year FROM acquired_at::timestamp) = ANY (ARRAY[2011, 2012, 2013])
   AND term_code = 'cash';


/*
4) Отобразите имя, фамилию и названия аккаунтов людей в поле network_username, 
у которых названия аккаунтов начинаются на 'Silver'.
*/
SELECT first_name,
       last_name,
       network_username
  FROM people
 WHERE network_username ILIKE 'silver%';


/*
5) 
Выведите на экран всю информацию о людях, у которых названия аккаунтов 
в поле network_username содержат подстроку 'money', а фамилия начинается на 'K'.
*/
SELECT *
  FROM people 
 WHERE network_username ILIKE '%money%'
   AND last_name ILIKE 'k%';


/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/

/*

*/
