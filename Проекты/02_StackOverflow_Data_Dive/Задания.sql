/*
Часть - 1 

1) Найдите количество вопросов, которые набрали больше 300 очков или 
как минимум 100 раз были добавлены в «Закладки».
*/
SELECT COUNT(DISTINCT p.id) AS cnt
  FROM stackoverflow.posts AS p
  JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id AND pt.type = 'Question'  
 WHERE p.score > 300
    OR p.favorites_count >= 100;

/*
2) Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? 
Результат округлите до целого числа.
*/
  WITH cte AS (
SELECT COUNT(DISTINCT p.id) AS cnt,
       DATE_TRUNC('day', p.creation_date)::date AS date
  FROM stackoverflow.posts AS p
  JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id AND pt.type = 'Question'  
 WHERE EXTRACT(year FROM p.creation_date) = 2008
   AND DATE_TRUNC('day', p.creation_date) BETWEEN '2008-11-01' AND '2008-11-18'
 GROUP BY DATE_TRUNC('day', p.creation_date)::date)
 
 SELECT ROUND(AVG(cnt))
   FROM cte;

/*
3) Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
*/
SELECT COUNT(DISTINCT u.id) AS cnt 
  FROM stackoverflow.users AS u
  LEFT JOIN stackoverflow.badges AS b ON u.id = b.user_id
 WHERE u.creation_date::date = b.creation_date::date;

/*
4) Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
*/
SELECT COUNT(DISTINCT p.id) AS cnt
  FROM stackoverflow.posts AS p
  JOIN stackoverflow.users AS u ON u.id = p.user_id
  JOIN stackoverflow.votes AS v ON v.post_id = p.id
 WHERE p.score >= 1 
   AND u.display_name = 'Joel Coehoorn';

/*
5) Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. 
Таблица должна быть отсортирована по полю id.
*/
SELECT *, RANK () OVER (ORDER BY id DESC) AS Rank
  FROM stackoverflow.vote_types
 ORDER BY id;

/*
6) Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
*/
SELECT u.id, COUNT(v.post_id) AS cnt
  FROM stackoverflow.users AS u
  JOIN stackoverflow.votes AS v ON u.id = v.user_id AND v.vote_type_id = (SELECT DISTINCT id 
                                                                            FROM stackoverflow.vote_types 
                                                                           WHERE name = 'Close')
 GROUP BY u.id
 ORDER BY cnt DESC, u.id DESC
 LIMIT 10;

/*
7) Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
*/
  WITH cte AS (
SELECT u.id, COUNT(b.id) AS cnt
  FROM stackoverflow.users AS u
  JOIN stackoverflow.badges AS b ON u.id = b.user_id AND b.creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
 GROUP BY u.id)
 
 SELECT id, 
        cnt,
        DENSE_RANK() OVER (ORDER BY cnt DESC) AS rank
   FROM cte
  ORDER BY cnt DESC, id
  LIMIT 10;

/*
8) Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
*/
SELECT p.title,
       p.user_id,
       p.score,
       ROUND(AVG(p.score) OVER (partition by p.user_id)) AS avg
  FROM stackoverflow.posts AS p
 WHERE p.title IS NOT NULL
   AND p.score <> 0
 ORDER BY p.user_id;

/*
9) Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список.
*/
  WITH cte_b AS (
SELECT count(b.id) AS cnt, 
       b.user_id
  FROM stackoverflow.badges AS b
 GROUP BY b.user_id
HAVING count(b.id) > 1000)

SELECT p.title
  FROM stackoverflow.posts AS p
 WHERE p.user_id IN (SELECT user_id FROM cte_b)
   AND p.title IS NOT NULL;

/*
10) Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.
*/
SELECT u.id,
       u.views,
       CASE 
            WHEN u.views >= 350 THEN 1
            WHEN u.views BETWEEN 100 AND 349 THEN 2
            WHEN u.views < 100 THEN 3
       END AS Group
  FROM stackoverflow.users AS u
 WHERE u.location ~* 'Canada'
   AND u.views <> 0;

/*
11) Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
*/
  WITH cte AS (
SELECT u.id,  
       u.views,  
       CASE   
            WHEN u.views >= 350 THEN 1  
            WHEN u.views BETWEEN 100 AND 349 THEN 2  
            WHEN u.views < 100 THEN 3  
       END AS Group,
       RANK () OVER (PARTITION BY CASE   
                                      WHEN u.views >= 350 THEN 1  
                                      WHEN u.views BETWEEN 100 AND 349 THEN 2  
                                      WHEN u.views < 100 THEN 3  
                                  END ORDER BY u.views DESC)
  FROM stackoverflow.users AS u  
 WHERE u.location ~* 'Canada'  
   AND u.views <> 0)
   
 SELECT c.id, c.views, c.group
   FROM cte AS c
  WHERE rank = 1
  ORDER BY c.views DESC, 
           c.id;

/*
12) Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением.
*/
  WITH CTE AS (
SELECT EXTRACT(day FROM creation_Date::date) AS date_of_creation,
       COUNT(DISTINCT id) AS cnt
  FROM stackoverflow.users AS u
 WHERE 1 = 1
   AND EXTRACT(year FROM creation_Date::date) = 2008
   AND EXTRACT(month FROM creation_Date::date) = 11
 GROUP BY date_of_creation)
 
 SELECT *, SUM(cnt) OVER (ORDER BY date_of_creation ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
   FROM cte
  ORDER BY date_of_creation;

/*
13) Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.
*/

SELECT DISTINCT u.id,
       MIN(p.creation_date) OVER (PARTITION BY p.user_id) - u.creation_date AS diff
  FROM stackoverflow.users AS u 
  JOIN stackoverflow.posts AS p ON u.id = p.user_id
 ORDER BY u.id;

/*
Часть - 2

14) Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. 
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
Результат отсортируйте по убыванию общего количества просмотров.
*/
SELECT DATE_TRUNC('month', p.creation_date)::date AS mnth, 
       SUM(views_count) AS sum
  FROM stackoverflow.posts AS p
 WHERE p.creation_date::date BETWEEN '2008-01-01' AND '2008-12-31'
 GROUP BY mnth
 ORDER BY sum DESC;

/*
15) Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. 
Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке.
*/
SELECT u.display_name,
       COUNT(DISTINCT p.user_id) AS cnt
  FROM stackoverflow.users AS u 
  JOIN stackoverflow.posts AS p ON u.id = p.user_id
  JOIN stackoverflow.post_types AS t ON p.post_type_id = t.id
 WHERE 1 = 1
   AND DATE_TRUNC('day', p.creation_date) <= DATE_TRUNC('day', u.creation_date) + INTERVAL '1 month'
   AND p.post_type_id = 2 
 GROUP BY display_name
HAVING COUNT(p.id) > 100;

/*
16) Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
Отсортируйте таблицу по значению месяца по убыванию.
*/
SELECT DATE_TRUNC('month', p.creation_date)::date AS month,
       COUNT(p.id) AS cnt
 FROM stackoverflow.posts p
 JOIN stackoverflow.users u ON p.user_id = u.id
WHERE DATE_TRUNC('month', u.creation_date)::date = '2008-09-01'  
  AND DATE_TRUNC('month', p.creation_date)::date = '2008-12-01'  
GROUP BY month
ORDER BY month DESC;

/*
17) Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
*/
SELECT user_id, 
       creation_date, 
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
  FROM stackoverflow.posts 
 ORDER BY user_id, creation_date;

/*
18) Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
Нужно получить одно целое число — не забудьте округлить результат.
*/
  WITH cte AS (
SELECT p.user_id, 
       COUNT(distinct p.creation_date::date)
  FROM stackoverflow.posts AS p
 WHERE CAST(creation_date AS date) BETWEEN '2008-12-1' AND '2008-12-7' 
 GROUP BY p.user_id
HAVING COUNT(p.id)>=1)

SELECT ROUND(AVG(count))
  FROM cte

/*
19) На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? 
Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
*/
  WITH cte AS (
SELECT EXTRACT(month FROM creation_date) AS num_of_mnth, 
       COUNT(id) AS cnt
  FROM stackoverflow.posts AS p
 WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
 GROUP BY num_of_mnth)

SELECT num_of_mnth, 
       cnt, 
       ROUND(((cnt::numeric/LAG(cnt) OVER (ORDER BY num_of_mnth))-1)*100,2)
  FROM cte;

/*
20) Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. 
Выведите данные его активности за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.
*/

  WITH cte AS (
SELECT user_id
  FROM stackoverflow.posts
 GROUP BY user_id 
 ORDER BY COUNT(id) DESC
 LIMIT 1) 

SELECT EXTRACT(WEEK FROM p.creation_date) AS week,
       MAX(p.creation_date) AS date
  FROM stackoverflow.posts p
  JOIN cte m ON m.user_id = p.user_id
 WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01'
 GROUP BY EXTRACT(WEEK FROM p.creation_date);