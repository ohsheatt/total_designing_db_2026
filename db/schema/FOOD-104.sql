-- FOOD-104. Добавление блюда
CREATE OR REPLACE PROCEDURE isakov_food.add_product(
    IN p_restaurant_id UUID,
    IN p_product_category_id UUID,
    IN p_name VARCHAR(255),
    IN p_price NUMERIC,
    IN p_rating NUMERIC,
    IN p_status isakov_food.product_status,
    IN p_description TEXT,
    IN p_photo_url TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_constraint_name TEXT;
BEGIN
    -- Проверяем существование ресторана
    IF NOT EXISTS (
        SELECT 1
        FROM isakov_food.restaurant
        WHERE restaurant_id = p_restaurant_id
    ) THEN
        RAISE EXCEPTION
            'Ресторан с ID % не существует',
            p_restaurant_id;
    END IF;

    -- Проверяем существование категории
    IF NOT EXISTS (
        SELECT 1
        FROM isakov_food.product_category
        WHERE product_category_id = p_product_category_id
    ) THEN
        RAISE EXCEPTION
            'Категория с ID % не существует',
            p_product_category_id;
    END IF;

    -- Добавляем блюдо
    BEGIN
        INSERT INTO isakov_food.product (
            product_name,
            product_category_id,
            price,
            restaurant_id,
            photo_url,
            rating,
            status,
            description
        )
        VALUES (
            p_name,
            p_product_category_id,
            p_price,
            p_restaurant_id,
            p_photo_url,
            p_rating,
            p_status,
            p_description
        );

    EXCEPTION
        WHEN check_violation THEN
            GET STACKED DIAGNOSTICS
                v_constraint_name = CONSTRAINT_NAME;

            RAISE EXCEPTION
                'Нарушено ограничение таблицы product: %',
                v_constraint_name;
    END;
END;
$$;

