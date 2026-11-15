-- FOOD-109. Пользователь inspector
CREATE ROLE inspector LOGIN PASSWORD 'NetoSQL2025';

-- Права на схему проекта
GRANT ALL PRIVILEGES ON SCHEMA isakov_food TO inspector;

-- Права на существующие таблицы и представления
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA isakov_food TO inspector;

-- Права на существующие последовательности
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA isakov_food TO inspector;

-- Права на функции
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA isakov_food TO inspector;

-- Права на процедуры
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA isakov_food TO inspector;

-- Доступ к системным схемам
GRANT USAGE ON SCHEMA information_schema TO inspector;
GRANT USAGE ON SCHEMA pg_catalog TO inspector;

-- Доступ к схеме расширений
GRANT USAGE ON SCHEMA exts TO inspector;
GRANT EXECUTE ON FUNCTION exts.uuid_generate_v4() TO inspector;

-- Доступ к финансовому представлению FOOD-108
GRANT SELECT ON isakov_food.how_much_money TO inspector;
