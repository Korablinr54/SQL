# Проект: Анализ продаж автомобилей

## Описание проекта
Проект представляет собой анализ данных о продажах автомобилей, включая создание нормализованной базы данных и выполнение аналитических запросов. Проект выполнен с использованием Docker и DBeaver.

---

## 🛠 Технологии
<div align="center">
  <table>
    <tr>
      <td align="center" width="150">
        <img src="https://img.icons8.com/color/48/000000/postgreesql.png" width="48" height="48" alt="PostgreSQL"/><br>
        PostgreSQL
      </td>
      <td align="center" width="150">
        <img src="https://img.icons8.com/color/48/000000/docker.png" width="48" height="48" alt="Docker"/><br>
        Docker
      </td>
      <td align="center" width="150">
        <img src="https://img.icons8.com/ios-filled/50/000000/database.png" width="48" height="48" alt="DBeaver"/><br>
        DBeaver
      </td>
    </tr>
  </table>
</div>

---

## ⚙️ Установка и настройка

### Запуск контейнера PostgreSQL
```bash
docker run --name postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_DB=sprint_1 \
  -d -p 5432:5432 \
  -v D:/project_1:/mnt/data \
  postgres
```
## Структура базы данных

### Схемы

- **raw_data** - исходные необработанные данные
- **car_shop** - нормализованная структура данных

![image](https://github.com/user-attachments/assets/599e024f-5665-4570-b7b8-9a78ca20ea05)

### Таблицы

#### Схема raw_data
- `sales` - исходные данные продаж
- `sales_processed` - обработанные данные

#### Схема car_shop
- `countries` - справочник стран
- `brands` - автомобильные бренды
- `colors` - цвета автомобилей
- `models` - модели автомобилей
- `cars` - конкретные автомобили (модель + цвет)
- `persons` - покупатели
- `sales_normalized` - информация о продажах

## Особенности реализации

- Нормализованная структура данных
- Обработка NULL-значений
- Проверки целостности данных
- Оптимальные типы данных для каждого поля

## Дополнительно
Проект выполнен в рамках учебного задания курса SQL для разработки (Яндекс Практикум).
