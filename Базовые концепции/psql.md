# Список команд
| Команда | Описание |
|--------|--------|
| `\l` или `\l+` | Показать список всех баз данных |
| `\x on / off` | Отключить расширеный вывод |
| `CREATE DATABASE name` | Создать базу данных |
| `DROP DATABASE name` | Удалить базу данных |
| `\c <имя_бд>` | Подключиться к указанной базе данных |
| `\dn` или `\dn+` | Показать список всех схем в текущей базе данных |
| `\dt` или `\dt+` | Показать таблицы в текущей схеме (обычно `public`) |
| `\dt <схема>.*` | Показать таблицы в указанной схеме (например, `\dt myschema.*`) |
| `\dt *.*` | Показать все таблицы во всех схемах |
| `\d <схема>.<таблица>` | Показать структуру таблицы в конкретной схеме (например, `\d myschema.users`) |
| `\d+ <схема>.<таблица>` | Подробная информация о таблице из указанной схемы |
| `\dv <схема>.*` | Показать представления в указанной схеме |
| `\df <схема>.*` | Показать функции в указанной схеме |
| `\du` или `\du+` | Показать список пользователей (ролей) |
| `\x` | Включить/выключить расширенный режим отображения |
| `\timing` | Включить/выключить замер времени выполнения запросов |
| `\conninfo` | Показать информацию о текущем подключении |
| `\password <имя_роли>` | Установить пароль для указанной роли |
| `\e` | Открыть редактор для редактирования текущего SQL-запроса |
| `\i <файл.sql>` | Выполнить SQL-скрипт из файла |
| `\o <файл.txt>` | Перенаправить вывод следующей команды в файл |
| `\?` | Показать справку по командам `psql` |
| `\h` | Показать справку по SQL-командам (например, `\h INSERT`) |
| `\h <команда>` | Показать синтаксис конкретной SQL-команды (например, `\h CREATE TABLE`) |
| `\q` | Выйти из `psql` |
| `\echo <текст>` | Вывести текст (полезно в скриптах) |
| `\set <имя> <значение>` | Установить переменную в `psql` |
| `\get <имя>` | Получить значение переменной (выводит значение) |
| `\unset <имя>` | Удалить переменную |
| `\pset format <format>` | Установить формат вывода: `aligned`, `csv`, `html`, `latex` и др. |
| `\pset border <0/1/2>` | Стиль рамки: 0 — нет, 1 — минимальный, 2 — полный |
| `\pset tuples_only` | Включить/выключить вывод только данных (без заголовков и рамок) |

# Примеры использования

## Создание БД

Для начала проверим список существующих баз данных:  
```sql
Текущая кодовая страница: 1251
Password for user postgres:

psql (18.0)
Type "help" for help.

postgres=# \l
                                                             List of databases
   Name    |  Owner   | Encoding | Locale Provider |       Collate       |        Ctype        | Locale | ICU Rules |   Access privileges
-----------+----------+----------+-----------------+---------------------+---------------------+--------+-----------+-----------------------
 postgres  | postgres | UTF8     | libc            | Russian_Russia.1251 | Russian_Russia.1251 |        |           |
 template0 | postgres | UTF8     | libc            | Russian_Russia.1251 | Russian_Russia.1251 |        |           | =c/postgres          +
           |          |          |                 |                     |                     |        |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | Russian_Russia.1251 | Russian_Russia.1251 |        |           | =c/postgres          +
           |          |          |                 |                     |                     |        |           | postgres=CTc/postgres
(3 rows)
```

А теперь создадим новую базу и посмотрим как изменится вывод команды `\l`.  
```sql
postgres=# CREATE DATABASE practicum; -- создаем новую БД
CREATE DATABASE -- сообщение о том, что база создана

postgres=# \l -- проверяем список БД
                                                             List of databases
   Name    |  Owner   | Encoding | Locale Provider |       Collate       |        Ctype        | Locale | ICU Rules |   Access privileges
-----------+----------+----------+-----------------+---------------------+---------------------+--------+-----------+-----------------------
 postgres  | postgres | UTF8     | libc            | Russian_Russia.1251 | Russian_Russia.1251 |        |           |
 practicum | postgres | UTF8     | libc            | Russian_Russia.1251 | Russian_Russia.1251 |        |           |
 template0 | postgres | UTF8     | libc            | Russian_Russia.1251 | Russian_Russia.1251 |        |           | =c/postgres          +
           |          |          |                 |                     |                     |        |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | Russian_Russia.1251 | Russian_Russia.1251 |        |           | =c/postgres          +
           |          |          |                 |                     |                     |        |           | postgres=CTc/postgres
(4 rows)
```

## Подсключение к БД

В выводе теперь видим, что мы создали базу данных `practicum`.  
Но приглашение по прежнему сообщает, что мы подключены к БД `postgres`.
```sql
postgres=# -- подключены к бд postgres
```

Теперь переключимся на другую бд используя команду `\c`.  
```sql
postgres=# \c practicum -- переключаемся 
You are now connected to database "practicum" as user "postgres".
-- получаем уведомление о том, что мы переключились с "postgres" на "practicum"

practicum=# -- строка приглашения указывает на то, что мы успешно переключились
```

Мы уже видели как отображается вывод команды `\l`. Выглядит не слишком удобно. Можно включить подробный вывод командой `\x` или `\x off / on`.  

```sql
practicum=# \x -- режим включен
Expanded display is on.

practicum=# \l -- снова выводим список БД
List of databases
-[ RECORD 1 ]-----+----------------------
Name              | postgres
Owner             | postgres
Encoding          | UTF8
Locale Provider   | libc
Collate           | Russian_Russia.1251
Ctype             | Russian_Russia.1251
Locale            |
ICU Rules         |
Access privileges |
-[ RECORD 2 ]-----+----------------------
Name              | practicum
Owner             | postgres
Encoding          | UTF8
Locale Provider   | libc
Collate           | Russian_Russia.1251
Ctype             | Russian_Russia.1251
Locale            |
ICU Rules         |
Access privileges |
... 
```