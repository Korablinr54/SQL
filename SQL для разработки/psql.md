# Команды psql

## Запуск
Запускаем PostgreSQL в docker
```bash
docker run --name my-postgres `  -- запусукаем контейнер с именем my-postgres
  -e POSTGRES_PASSWORD=your_password `   -- указываем пароль
  -d -p 5432:5432 `   -- -в в фоновом режиме. проброс порта 5432 
  postgres:latest   -- последняя версия образа
```

Проверяем запущен ли образ  
```bash
PS C:\Users\user> docker ps
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

