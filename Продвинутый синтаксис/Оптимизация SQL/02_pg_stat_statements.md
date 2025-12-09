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

Добавляем в кавычках значение `pg_stat_statements` напротив `shared_preload_libraries`  
```sql
# - Shared Library Preloading -

#local_preload_libraries = ''
#session_preload_libraries = ''
#shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)
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

