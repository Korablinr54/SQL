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