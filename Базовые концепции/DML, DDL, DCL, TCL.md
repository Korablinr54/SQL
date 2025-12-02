# Типы SQL апросов
| Категория | Полное название          | Назначение                                          | Основные команды                           |
|-----------|--------------------------|-----------------------------------------------------|--------------------------------------------|
| **DDL**   | Data Definition Language | Определение и изменение структуры объектов БД       | `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `RENAME` |
| **DML**   | Data Manipulation Language | Манипуляция данными (CRUD-операции)                | `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `MERGE` |
| **DCL**   | Data Control Language    | Управление правами доступа                         | `GRANT`, `REVOKE`                          |
| **TCL**   | Transaction Control Language | Управление транзакциями                           | `COMMIT`, `ROLLBACK`, `SAVEPOINT`          |

# DDL
## CREATE

Для создания любого объекта в базе испольщуется оператор `CREATE`.  
```sql
CREATE <ТИП ОБЪЕКТА> <имя объекта> <ПАРАМЕТРЫ>;
```

Создадим БД **shop** и переключимся на нее  
```sql
CREATE DATABASE shop -- создаем базу
CREATE DATABASE -- база успешно создана

postgres=# \c shop -- переключаемся на новую базу
You are now connected to database "shop" as user "postgres". -- переключение прошло успешно
```

Проверим схемы в выбранной базе:
```sql
shop=# \dn -- проверяем существующие в базе схемы

      List of schemas
  Name  |       Owner
--------+-------------------
 public | pg_database_owner
(1 row)
```