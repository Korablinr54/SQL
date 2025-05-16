# Создаём базу данных:
```SQL 
CREATE DATABASE games_data;
```

# Создаём таблицу
```SQL
CREATE TABLE games_data.games
(Uid Int32,
Name String, 
Platform String,
Year_of_Release Float32,
Genre String,
NA_sales Float32,
EU_sales Float32,
JP_sales Float32,
Other_sales Float32,
Critic_Score Float32,
User_Score String,
Rating String
)
ENGINE = MergeTree()
ORDER BY intHash32(Uid)
SAMPLE BY intHash32(Uid);
```
**Движок** `ENGINE = MergeTree()`
**Ключ сортировки** `ORDER BY intHash32(Uid)`
