-- FOOD-108. Отчет "сколько денег"
CREATE OR REPLACE VIEW isakov_food.how_much_money AS
WITH RECURSIVE months AS (
    SELECT
        DATE_TRUNC('month', MIN(order_timestamp))::DATE AS month_start,
        DATE_TRUNC('month', MAX(order_timestamp))::DATE AS last_month
    FROM isakov_food."order"
    WHERE status = 'доставлен'

    UNION ALL

    SELECT
        (month_start + INTERVAL '1 month')::DATE,
        last_month
    FROM months
    WHERE month_start < last_month
),
orders_by_month AS (
    SELECT
        DATE_TRUNC('month', order_timestamp)::DATE AS month_start,
        SUM(order_amount) AS sum_no_commission,
        SUM(total_amount) AS sum_with_commission
    FROM isakov_food."order"
    WHERE status = 'доставлен'
    GROUP BY DATE_TRUNC('month', order_timestamp)
),
payments_by_month AS (
    SELECT
        MAKE_DATE(year, month, 1) AS month_start,
        SUM(amount) AS courier_pay
    FROM isakov_food.courier_pay
    GROUP BY year, month
),
monthly_totals AS (
    SELECT
        m.month_start,
        COALESCE(o.sum_no_commission, 0::NUMERIC) AS sum_no_commission,
        COALESCE(o.sum_with_commission, 0::NUMERIC) AS sum_with_commission,
        COALESCE(o.sum_with_commission, 0::NUMERIC)
            - COALESCE(o.sum_no_commission, 0::NUMERIC) AS commission,
        COALESCE(p.courier_pay, 0::NUMERIC) AS courier_pay
    FROM months m
    LEFT JOIN orders_by_month o
        ON o.month_start = m.month_start
    LEFT JOIN payments_by_month p
        ON p.month_start = m.month_start
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM') AS year_month,
    sum_no_commission,
    sum_with_commission,
    commission,
    LAG(commission) OVER (ORDER BY month_start) AS prev_commission,
    commission - LAG(commission) OVER (ORDER BY month_start) AS commission_diff,
    courier_pay,
    commission - courier_pay AS net_profit
FROM monthly_totals;

