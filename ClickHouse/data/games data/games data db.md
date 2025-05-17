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

# Описание данных  
`Name` — название игры.  
`Platform` — платформа.  
`Year_of_Release` — год выпуска.  
`Genre` — жанр игры.  
`NA_sales` — продажи в Северной Америке (миллионы проданных копий).  
`EU_sales` — продажи в Европе (миллионы проданных копий).  
`JP_sales` — продажи в Японии (миллионы проданных копий).  
`Other_sales` — продажи в других странах (миллионы проданных копий).  
`Critic_Score` — оценка критиков (максимум 100).  
`User_Score` — оценка пользователей (максимум 10).  
`Rating` — рейтинг от организации ESRB (англ. Entertainment Software Rating Board). Эта ассоциация определяет рейтинг компьютерных игр и присваивает им подходящую возрастную категорию.  