--FOOD-106. Статистика по ресторанам
CREATE OR REPLACE FUNCTION isakov_food.get_statistic()
RETURNS TABLE (
    restaurant_name TEXT,
    best_product_name VARCHAR(255),
    total_amount NUMERIC,
    avg_amount NUMERIC,
    best_user VARCHAR(100)
)
LANGUAGE sql
AS $$
    WITH delivered_orders AS (
        SELECT
            o.order_id,
            o.restaurant_id,
            o.client_id,
            o.total_amount
        FROM isakov_food."order" o
        WHERE o.status = 'доставлен'
    ),

    restaurant_amounts AS (
        SELECT
            restaurant_id,
            SUM(total_amount) AS total_amount,
            AVG(total_amount) AS avg_amount
        FROM delivered_orders
        GROUP BY restaurant_id
    ),

    product_totals AS (
        SELECT
            d.restaurant_id,
            p.product_name,
            SUM(os.quantity) AS total_quantity
        FROM delivered_orders d
        JOIN isakov_food.order_structure os
            ON os.order_id = d.order_id
        JOIN isakov_food.product p
            ON p.product_id = os.product_id
        GROUP BY d.restaurant_id, p.product_id, p.product_name
    ),

    best_products AS (
        SELECT DISTINCT ON (restaurant_id)
            restaurant_id,
            product_name
        FROM product_totals
        ORDER BY restaurant_id, total_quantity DESC, random()
    ),

    user_totals AS (
        SELECT
            d.restaurant_id,
            c.login,
            COUNT(*) AS order_count
        FROM delivered_orders d
        JOIN isakov_food.client c
            ON c.client_id = d.client_id
        GROUP BY d.restaurant_id, c.client_id, c.login
    ),

    best_users AS (
        SELECT DISTINCT ON (restaurant_id)
            restaurant_id,
            login
        FROM user_totals
        ORDER BY restaurant_id, order_count DESC, random()
    )

    SELECT
        r.restaurant_name,
        bp.product_name,
        ra.total_amount,
        ra.avg_amount,
        bu.login
    FROM isakov_food.restaurant r
    LEFT JOIN restaurant_amounts ra
        ON ra.restaurant_id = r.restaurant_id
    LEFT JOIN best_products bp
        ON bp.restaurant_id = r.restaurant_id
    LEFT JOIN best_users bu
        ON bu.restaurant_id = r.restaurant_id;
$$;
