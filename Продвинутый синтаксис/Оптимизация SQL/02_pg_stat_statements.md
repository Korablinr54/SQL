# pg_stat_statements

Это стандртный для PostgreSQL модуль, который используется для получения статистики о запросах:
* скорость построения плана запроса  
* скорость выполнения запроса  
* минимальной и максимальной скорости выполнения запроса  
* сколько раз выполнялся запрос  
* сколько записей вернул и многое другое  

## Подключение pg_stat_statements

Для активации `pg_stat_statements` нужно изменить файл настроек сервера PostgreSQL `postgresql.conf`. Найти файл можно с помощью SQL-команды:  
```sql
SHOW config_file;
```

вывод:  
```
D:/Program Files/Postgres 18/data/postgresql.conf
```

Дальше нужно открыть файл и найти в нем строку `shared_preload_libraries`. 
```sql
# - Shared Library Preloading -

#local_preload_libraries = ''
#session_preload_libraries = ''
#shared_preload_libraries = ''		# (change requires restart) -- интересующее нас место
#jit_provider = 'llvmjit'		# JIT library to use

# - Other Defaults -
```

Добавляем в кавычках значение `pg_stat_statements` напротив `shared_preload_libraries` и убираем `#` в самом начале строки  
```sql
# - Shared Library Preloading -

#local_preload_libraries = ''
#session_preload_libraries = ''
shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)
#jit_provider = 'llvmjit'		# JIT library to use

# - Other Defaults -
```

Далее сохраняем файл и перезагружаем БД.

### windows

1) `win + r`  
2) `services.msc`  
3) найти процесс `postgresql-%`  
4) ПКМ - перезапустить  
5) готово

### linux

1) `sudo systemctl restart postgresql.service`

### mac

1) `sudo brew services restart postgresql`

## Инструменты pg_stat_statements

После активация модуль начинает работать в фоновом режиме, он не требует много ресурсов.  

Есть несколько инструментов, мы разберем два:
1) представление `pg_stat_statements`  
2) функция `pg_stat_statements_reset`  

Изначально они недоступны но их можно установить:  
```sql
CREATE EXTENSION pg_stat_statements;
```

В представление много параметров, но понадобятся нам не все:  
| Поле (столбец)         | Тип данных          | Назначение и содержание                                                                                  |
|------------------------|---------------------|----------------------------------------------------------------------------------------------------------|
| **dbid**               | oid                 | Уникальный идентификатор (OID) базы данных, в контексте которой был исполнен оператор SQL.                |
| **query**              | text                | Полный текст выполненного SQL-запроса.                                                                   |
| **calls**              | bigint              | Общее количество запусков данного запроса.                                                               |
| **total_exec_time**    | double precision    | Суммарное время (в миллисекундах), потраченное на все выполнения этого запроса.                           |
| **min_exec_time**      | double precision    | Наименьшая длительность (в миллисекундах) одного выполнения запроса.                                      |
| **max_exec_time**      | double precision    | Наибольшая длительность (в миллисекундах) одного выполнения запроса.                                      |
| **mean_exec_time**     | double precision    | Среднее арифметическое время (в миллисекундах), затрачиваемое на одно выполнение запроса.                 |
| **rows**               | bigint              | Суммарное количество строк, которое было возвращено или модифицировано (вставлено, обновлено, удалено) в результате всех выполнений запроса. |

`pg_stat_statements` собирает информацию по всем базам, для начала стоит определиться по какой мы будем смотреть статистику. Найдем id интересующей нас базы:  
```sql
 SELECT oid, 
        datname 
   FROM pg_database;
```

вывод:
```sql
oid  |datname  |
-----+---------+
    5|postgres |
16384|practicum|
    1|template1|
    4|template0|
16385|shop     |
```

### пример работы 
Зная идентификатор БД мы можем проанализировать запросы в этой БД:  
```sql
 CREATE EXTENSION pg_stat_statements; -- подключаем модуль

 SELECT oid, -- находим id интересующей базы
        datname 
   FROM pg_database;

 SELECT query, -- текст, а точнее шаблон текста запроса
        calls, -- количество вызовов
        total_exec_time, -- общее время выполнения запроса 
        min_exec_time, -- минимальное время выполнения запроса 
        max_exec_time, -- максимальное время выполнения запроса 
        mean_exec_time, -- среднее время выполнения запроса 
        ROWS -- количество возвращаемых строк
   FROM pg_stat_statements 
  WHERE dbid = 16384
  ORDER BY total_exec_time DESC;
  ```

  вывод:  
  ```
query                                                                                                                                                                                                                                                          |calls|total_exec_time     |min_exec_time|max_exec_time      |mean_exec_time       |rows|
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----+--------------------+-------------+-------------------+---------------------+----+
SELECT query, ¶    calls,¶    total_exec_time,¶    min_exec_time, ¶    max_exec_time, ¶    mean_exec_time,¶    rows¶FROM pg_stat_statements ¶WHERE dbid = $1 ORDER BY total_exec_time DESC                                                                     |    7|              5.6823|       0.5218|             1.0906|   0.8117571428571428|  48|
  ```

Давайте выполним несколько запросов, чтобы поулчить какую-то статистику для анализа:
```sql
SELECT o.*, p.* 
  FROM online_store.orders o 
  JOIN online_store.profiles p ON (o.user_id = p.user_id);

SELECT *, 
       ROUND(AVG(revenue) OVER (PARTITION BY event_dt), 2) AS avg_rev
  FROM online_store.orders;

SELECT *, AVG(revenue) OVER (PARTITION BY event_dt) AS avg_rev 
  FROM online_store.orders;

SELECT *, COUNT(*) OVER (PARTITION BY user_id) AS orders_cnt 
  FROM online_store.orders; 
```

Давайте найдем топ-5 самыйх медленных запросов:  
```sql
SELECT query, 
       ROUND(total_exec_time::numeric,2) AS total_exec_time,
       ROUND(mean_exec_time::numeric,2) AS mean_exec_time,                
       ROUND(min_exec_time::numeric,2) AS min_exec_time, 
       ROUND(max_exec_time::numeric,2) AS max_exec_time,
       calls,
       rows                          
  FROM pg_stat_statements
 WHERE dbid = 16432 
 ORDER BY mean_exec_time DESC
 LIMIT 5;
```

вывод:  
```
query                                                                                                       |total_exec_time|mean_exec_time|min_exec_time|max_exec_time|calls|rows|
------------------------------------------------------------------------------------------------------------+---------------+--------------+-------------+-------------+-----+----+
SELECT o.*, p.* ¶  FROM online_store.orders o ¶  JOIN online_store.profiles p ON (o.user_id = p.user_id)    |          24.34|         24.34|        24.34|        24.34|    1| 200|
SELECT *, COUNT(*) OVER (PARTITION BY user_id) AS orders_cnt ¶  FROM online_store.orders                    |           5.62|          5.62|         5.62|         5.62|    1| 200|
SELECT *, AVG(revenue) OVER (PARTITION BY event_dt) AS avg_rev ¶  FROM online_store.orders                  |           5.03|          5.03|         5.03|         5.03|    1| 200|
SELECT *, ¶       ROUND(AVG(revenue) OVER (PARTITION BY event_dt), $1) AS avg_rev¶  FROM online_store.orders|           3.56|          3.56|         3.56|         3.56|    1| 200|
SELECT COUNT(*) FROM (SELECT * FROM  online_store.orders¶) dbvrcnt                                          |           1.23|          1.23|         1.23|         1.23|    1|   1|
```

Это топ-5 самых медленных запросов, критерий - максимальное среднее время выполнения запроса (хотя у нас всего их 5 :) но для учебных целей сгодится)

Изменим запрос, чтобы видеть долю относительно других:  
```sql
SELECT query,
       ROUND(mean_exec_time::NUMERIC,2) AS mean,
       ROUND(total_exec_time::NUMERIC,2) AS total,
       ROUND(min_exec_time::NUMERIC,2) AS min, 
       ROUND(max_exec_time::NUMERIC,2) AS max,
       calls,
       rows,
    -- вычисление % времени, потраченного на запрос, относительно других запросов                          
       ROUND((100 * total_exec_time / sum(total_exec_time) OVER())::NUMERIC, 2) AS percent
FROM pg_stat_statements
WHERE dbid = 16432 ORDER BY mean_exec_time DESC
LIMIT 5;
```

Вывод:
```sql
query                                                                                                                   |mean |total |min  |max  |calls|rows|percent|
------------------------------------------------------------------------------------------------------------------------+-----+------+-----+-----+-----+----+-------+
SELECT o.*, p.* ¶  FROM online_store.orders o ¶  JOIN online_store.profiles p ON (o.user_id = p.user_id)                |22.88|114.38|16.98|30.98|    5|1000|  52.13|
SELECT *, COUNT(*) OVER (PARTITION BY user_id) AS orders_cnt ¶  FROM online_store.orders                                | 6.50| 52.00| 4.22|10.66|    8|1600|  23.70|
SELECT *, ¶       ROUND(AVG(revenue) OVER (PARTITION BY event_dt), $1) AS avg_rev¶  FROM online_store.orders            | 4.51| 31.55| 3.38| 8.04|    7|1400|  14.38|
SELECT *, AVG(revenue) OVER (PARTITION BY event_dt) AS avg_rev ¶  FROM online_store.orders                              | 4.04| 12.11| 2.28| 5.03|    3| 600|   5.52|
SELECT COUNT(*) FROM (SELECT *, COUNT(*) OVER (PARTITION BY user_id) AS orders_cnt ¶  FROM online_store.orders¶) dbvrcnt| 2.46|  2.46| 2.46| 2.46|    1|   1|   1.12|
```