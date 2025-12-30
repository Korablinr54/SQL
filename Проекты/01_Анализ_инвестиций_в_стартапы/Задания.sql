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
11) Отобразите имя и фамилию всех сотрудников стартапов. 
Добавьте поле с названием учебного заведения, которое окончил или в котором учится сотрудник, 
если эта информация известна.
*/
SELECT p.first_name,
       p.last_name,
       e.instituition
  FROM people p
  LEFT JOIN education e ON e.person_id = p.id;

/*
12) Для каждой компании найдите количество учебных заведений, которые окончили или в которых учатся сотрудники. 
Выведите название компании и число уникальных названий учебных заведений. 
Составьте топ-5 компаний по количеству университетов.
*/
SELECT c.name,
       COUNT(DISTINCT e.instituition) AS cnt
  FROM company c
 INNER JOIN people p ON c.id = p.company_id
 INNER JOIN education e ON p.id = e.person_id
 GROUP BY c.name
 ORDER BY COUNT(DISTINCT e.instituition) DESC
 LIMIT 5;

/*
13) Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним.
*/
SELECT DISTINCT name
  FROM company
 WHERE id IN (SELECT c.id
                FROM company c
                JOIN funding_round f ON f.company_id = c.id
               WHERE is_first_round = 1
                 AND is_last_round = 1
                 AND c.status = 'closed');

/*
14) Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.
*/
  WITH cte_1 AS (
SELECT DISTINCT id
  FROM company
 WHERE id IN (SELECT c.id
                FROM company c
                JOIN funding_round f ON f.company_id = c.id
               WHERE is_first_round = 1
                 AND is_last_round = 1
                 AND c.status = 'closed')) 

SELECT DISTINCT p.id
  FROM people p
  JOIN cte_1 ON p.company_id = cte_1.id; 

/*
15) Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, 
в котором обучался сотрудник.
*/
  WITH cte_1 AS (
SELECT DISTINCT id
  FROM company
 WHERE id IN (SELECT c.id
                FROM company c
                JOIN funding_round f ON f.company_id = c.id
               WHERE is_first_round = 1
                 AND is_last_round = 1
                 AND c.status = 'closed')) 

SELECT DISTINCT 
       p.id, 
       education.instituition
  FROM people p
  JOIN cte_1 ON p.company_id = cte_1.id
  JOIN education ON p.id = education.person_id;

/*
16) Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания.
*/
  WITH cte_1 AS (
SELECT DISTINCT id
  FROM company
 WHERE id IN (SELECT c.id
                FROM company c
                JOIN funding_round f ON f.company_id = c.id
               WHERE is_first_round = 1
                 AND is_last_round = 1
                 AND c.status = 'closed')) 

SELECT DISTINCT 
       p.id, 
       COUNT(education.instituition) AS cnt
  FROM people p
  JOIN cte_1 ON p.company_id = cte_1.id
  JOIN education ON p.id = education.person_id
 GROUP BY p.id;

/*
17) Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), 
в которых обучались сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится.
*/
  WITH cte_1 AS (
SELECT DISTINCT id
  FROM company
 WHERE id IN (SELECT c.id
                FROM company c
                JOIN funding_round f ON f.company_id = c.id
               WHERE is_first_round = 1
                 AND is_last_round = 1
                 AND c.status = 'closed')) 

SELECT AVG(cnt) as avg_cnt
  FROM (SELECT DISTINCT p.id, 
               COUNT(education.instituition) AS cnt
          FROM people p
          JOIN cte_1 ON p.company_id = cte_1.id
          JOIN education ON p.id = education.person_id
         GROUP BY p.id) as t;

/*
18) Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), 
в которых обучались сотрудники Socialnet.
*/
  WITH cte_1 AS (
SELECT DISTINCT id
  FROM company
 WHERE id IN (SELECT c.id
                FROM company c
               WHERE c.name = 'Socialnet')) 

SELECT AVG(cnt)
  FROM (SELECT DISTINCT p.id, 
               COUNT(education.instituition) AS cnt
          FROM people p
          JOIN cte_1 ON p.company_id = cte_1.id
          JOIN education ON p.id = education.person_id
         GROUP BY p.id) as t;

/*
19) Составьте таблицу из полей:
name_of_fund — название фонда;
name_of_company — название компании;
amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, 
а раунды финансирования проходили с 2012 по 2013 год включительно.
*/
SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount
  FROM fund f
  JOIN investment i ON f.id = i.fund_id 
  JOIN company c ON i.company_id = c.id
  JOIN funding_round fr ON i.funding_round_id = fr.id
 WHERE c.milestones > 6
   AND EXTRACT(year FROM funded_at::timestamp) = ANY (ARRAY[2012, 2013]);

/*
20) Выгрузите таблицу, в которой будут такие поля:
название компании-покупателя;
сумма сделки;
название компании, которую купили;
сумма инвестиций, вложенных в купленную компанию;
доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, 
округлённая до ближайшего целого числа.
Не учитывайте те сделки, в которых сумма покупки равна нулю. 
Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. 
Ограничьте таблицу первыми десятью записями.
*/
  WITH buyer_cte AS (
SELECT c.name AS buyer,
       a.price_amount AS amount,
       a.id
  FROM company c
  JOIN acquisition a ON a.acquiring_company_id = c.id
 WHERE a.price_amount > 0),

       acquired_cte AS (
SELECT c.name AS acquired_company,
       a.price_amount AS amount,
       c.funding_total AS investment,
       a.id
  FROM company c
  JOIN acquisition a ON a.acquired_company_id = c.id
 WHERE c.funding_total > 0)

SELECT b.buyer,
       b.amount,
       a.acquired_company,
       a.investment,
       ROUND(b.amount / a.investment) AS roi_ratio
  FROM buyer_cte AS b
  JOIN acquired_cte AS a ON b.id = a.id
 ORDER BY b.amount DESC, a.acquired_company
 LIMIT 10;

/*
21) Выгрузите таблицу, в которую войдут названия компаний из категории social, 
получившие финансирование с 2010 по 2013 год включительно. 
Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, 
в котором проходил раунд финансирования.
*/
SELECT c.name, 
       EXTRACT(month FROM fr.funded_at::timestamp) AS "month"
  FROM company c
  JOIN funding_round fr ON c.id = fr.company_id
 WHERE c.category_code = 'social'
   AND fr.raised_amount <> 0
   AND EXTRACT(year FROM fr.funded_at::timestamp) BETWEEN 2010 AND 2013;

/*
22) Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. 
Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
номер месяца, в котором проходили раунды;
количество уникальных названий фондов из США, которые инвестировали в этом месяце;
количество компаний, купленных за этот месяц;
общая сумма сделок по покупкам в этом месяце.
*/
  WITH monthly_funds AS (
SELECT EXTRACT(MONTH FROM fr.funded_at::timestamp) AS month_num,
       COUNT(DISTINCT f.id) AS total_funds
  FROM fund f
 LEFT JOIN investment AS inv ON f.id = inv.fund_id
 LEFT JOIN funding_round AS fr ON inv.funding_round_id = fr.id
WHERE f.country_code = 'USA'
  AND EXTRACT(YEAR FROM fr.funded_at::timestamp) BETWEEN 2010 AND 2013
GROUP BY month_num),

       monthly_acquisitions AS (
SELECT EXTRACT(MONTH FROM acquired_at::timestamp) AS month_num,
       COUNT(acquired_company_id) AS companies_bought,
       SUM(price_amount) AS total_amount
  FROM acquisition 
 WHERE EXTRACT(YEAR FROM acquired_at::timestamp) BETWEEN 2010 AND 2013
 GROUP BY month_num)

SELECT mf.month_num, 
       mf.total_funds, 
       ma.companies_bought,
       ma.total_amount
  FROM monthly_funds mf
  LEFT JOIN monthly_acquisitions ma ON mf.month_num = ma.month_num;

/*
23) Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, 
в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. 
Данные за каждый год должны быть в отдельном поле. 
Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.
*/

  WITH avg_2011 AS (
SELECT country_code,
       AVG(funding_total) AS avg_2011
  FROM company 
 WHERE EXTRACT(YEAR FROM founded_at::timestamp) = 2011
 GROUP BY country_code),

       avg_2012 AS (
SELECT country_code,
       AVG(funding_total) AS avg_2012
  FROM company 
 WHERE EXTRACT(YEAR FROM founded_at::timestamp) = 2012
 GROUP BY country_code),

       avg_2013 AS (
SELECT country_code,
       AVG(funding_total) AS avg_2013
  FROM company 
 WHERE EXTRACT(YEAR FROM founded_at::timestamp) = 2013
 GROUP BY country_code)

SELECT a1.country_code,
       a1.avg_2011,
       a2.avg_2012,
       a3.avg_2013
  FROM avg_2011 a1
 INNER JOIN avg_2012 a2 ON a1.country_code = a2.country_code
 INNER JOIN avg_2013 a3 ON a2.country_code = a3.country_code
 ORDER BY a1.avg_2011 DESC;
