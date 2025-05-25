# Команды psql

Служебные команды `psql` начинаются с `\`  

## Запуск

### Запускаем контейнер
Запускаем PostgreSQL в docker
```bash
docker run --name my-postgres \'  -- запусукаем контейнер с именем my-postgres
  -e POSTGRES_PASSWORD=your_password \'   -- указываем пароль
  -d -p 5432:5432 \'   -- -d в фоновом режиме. проброс порта 5432 
  postgres:latest   -- последняя версия образа
```

### Проверяем запущен ли образ  
```bash
docker ps
```  
| Колонка         | Описание                                                                 |
|----------------|--------------------------------------------------------------------------|
| CONTAINER ID   | Уникальный идентификатор контейнера — `db8bc5e725a4`                      |
| IMAGE          | Используемый образ — `postgres:latest` (последняя версия PostgreSQL)     |
| COMMAND        | Команда, которую запустил Docker — `docker-entrypoint.sh`               |
| CREATED        | Когда контейнер был создан — `6 seconds ago`                            |
| STATUS         | Состояние контейнера — `Up 5 seconds` (работает уже 5 секунд)            |
| PORTS          | Проброшенные порты — `0.0.0.0:5432->5432/tcp` (порт 5432 доступен извне) |
| NAMES          | Имя контейнера — `my-postgres`                                           |

### подключаемся к бд в psql
```bash
docker exec -it my-postgres psql -U postgres
```
| Часть команды                                 | Описание                                                                 |
|----------------------------------------------|--------------------------------------------------------------------------|
| `docker exec`                                | Команда Docker для выполнения команд внутри запущенного контейнера.      |
| `-it`                                        | Флаги для интерактивного режима: `-i` (интерактивный), `-t` (терминал). |
| `my-postgres`                                | Имя контейнера, в котором будет выполнена команда.                      |
| `psql`                                       | Утилита PostgreSQL для взаимодействия с базой данных.                   |
| `-U postgres`                                | Указывает пользователя `postgres`, который будет использоваться для подключения. |

## Создание базы данных

Для начала проверим, какие БД у нас уже существуют.  
```bash
\l   -- возвращает список всех БД
```
| Name    |  Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | Locale | ICU Rules |   Access privileges       |
|---------|----------|----------|-----------------|------------|------------|--------|-----------|---------------------------|
| postgres  | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           |                           |
| template0 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +    |
|         |          |          |                 |            |            |        |           | postgres=CTc/postgres     |
| template1 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +    |
|         |          |          |                 |            |            |        |           | postgres=CTc/postgres     |

| Столбец             | Описание                                                                 |
|---------------------|--------------------------------------------------------------------------|
| `Name`              | Имя базы данных.                                                         |
| `Owner`             | Владелец базы данных.                                                    |
| `Encoding`          | Кодировка базы данных (например, `UTF8`).                               |
| `Locale Provider`   | Провайдер локали (`libc` — стандартный в Linux/Unix-системах).          |
| `Collate`           | Настройка сортировки по умолчанию.                                       |
| `Ctype`             | Тип кодировки для сортировки и сравнения.                                |
| `Locale`            | Локаль, используемая для сортировки и форматирования.                    |
| `ICU Rules`         | Используемые правила для сортировки и форматирования текста.             |
| `Access privileges` | Права доступа к базе данных.                                             |  

Теперь создадим базу данных используя команду `CREATE DATABASE` 
```bash
CREATE DATABASE MyDB;
```

Убеждаемся в том, что БД создана используя команду `\list` или просто `\l`
```bash
\l
```  
| Name    |  Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | Locale | ICU Rules |   Access privileges       |
|---------|----------|----------|-----------------|------------|------------|--------|-----------|---------------------------|
| MyBD    | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           |                           |
| template0 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +    |
|         |          |          |                 |            |            |        |           | postgres=CTc/postgres     |
| template1 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +    |
|         |          |          |                 |            |            |        |           | postgres=CTc/postgres     |  

База данных успешно создана.  

### Переключаемся между БД
для того, чтобы переключиться между БД необходимо использовать команду `\c` - connect
```bash
\l -- првоеряем списко БД
\c <database_name> -- без скобок указываем имя бд
\conninfo -- првоеряем, куда мы подключены
```
                                  List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
-----------+----------+----------+------------+------------+-----------------------
 MyDB      | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(4 rows)

You are now connected to database "MyDB" as user "postgres".

