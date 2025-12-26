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
SELECT SUM(price_amount) AS price_amount
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
5) Выведите на экран всю информацию о людях, у которых названия аккаунтов 
в поле network_username содержат подстроку 'money', а фамилия начинается на 'K'.
*/
SELECT *
  FROM people 
 WHERE network_username ILIKE '%money%'
   AND last_name ILIKE 'k%';


/*
6) Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, 
зарегистрированные в этой стране. Страну, в которой зарегистрирована компания, 
можно определить по коду страны. Отсортируйте данные по убыванию суммы.
*/
SELECT country_code,
       SUM(funding_total) AS funding_total
  FROM company
 GROUP BY country_code
 ORDER BY SUM(funding_total) DESC;


/*
7) Составьте таблицу, в которую войдёт дата проведения раунда, 
а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций 
не равно нулю и не равно максимальному значению.
*/
SELECT funded_at,
       MIN(raised_amount) AS min_raised_amount,
       MAX(raised_amount) AS max_raised_amount
  FROM funding_round
 GROUP BY funded_at
HAVING MIN(raised_amount) <> 0
   AND MIN(raised_amount) <> MAX(raised_amount);


/*
8) Создайте поле с категориями:
Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
Отобразите все поля таблицы fund и новое поле с категориями.
*/
SELECT *, 
       CASE
           WHEN invested_companies >= 100 THEN 'high_activity'
           WHEN invested_companies BETWEEN 20 AND 99 THEN 'middle_activity'
           WHEN invested_companies < 20 THEN 'low_activity'
       END AS activity
  FROM fund;

/*
9) Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа 
среднее количество инвестиционных раундов, в которых фонд принимал участие. 
Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего.
*/
 WITH cte_1 AS (
SELECT *,
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity
FROM fund)

SELECT activity,
       ROUND(AVG(investment_rounds)) as avg_investment_rounds
  FROM cte_1
 GROUP BY activity
 ORDER BY AVG(investment_rounds);


/*
10) Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, 
в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно. 
Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
Выгрузите десять самых активных стран-инвесторов: 
отсортируйте таблицу по среднему количеству компаний от большего к меньшему. 
Затем добавьте сортировку по коду страны в лексикографическом порядке.
*/
SELECT country_code,
       MIN(invested_companies) AS min_invested_companies,
       MAX(invested_companies) AS max_invested_companies,
       AVG(invested_companies) AS avg_invested_companies
  FROM fund
 WHERE EXTRACT(year FROM founded_at::timestamp) = ANY (ARRAY[2010, 2011, 2012]) 
 GROUP BY country_code
HAVING MIN(invested_companies) > 0
 ORDER BY AVG(invested_companies) DESC,
          country_code
 LIMIT 10;


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
