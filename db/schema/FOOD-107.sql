-- FOOD-107. Зарплата курьеров
CREATE OR REPLACE PROCEDURE isakov_food.courier_salary()
LANGUAGE plpgsql
AS $$
DECLARE
    v_month DATE := DATE_TRUNC('month', CURRENT_DATE)::DATE;
    v_courier RECORD;

    v_delivered_count INT;
    v_commission_sum NUMERIC;
    v_new_coefficient NUMERIC(2,1);
    v_salary NUMERIC;
BEGIN
    FOR v_courier IN
        SELECT
            courier_id,
            status,
            coefficient
        FROM isakov_food.courier
    LOOP
        -- Количество доставленных заказов и сумма комиссий за текущий месяц
        SELECT
            COUNT(*)::INT,
            COALESCE(SUM(o.commission), 0)
        INTO
            v_delivered_count,
            v_commission_sum
        FROM isakov_food."order" o
        WHERE o.courier_id = v_courier.courier_id
          AND o.status = 'доставлен'
          AND o.order_timestamp >= v_month
          AND o.order_timestamp < v_month + INTERVAL '1 month';

        -- Зарплата рассчитывается по коэффициенту текущего месяца
        v_salary := v_courier.coefficient * v_commission_sum;

        -- Запись или обновление выплаты за текущий месяц
        INSERT INTO isakov_food.courier_pay
            (year, month, courier_id, amount, coefficient_used)
        VALUES
            (
                EXTRACT(YEAR FROM v_month)::INT,
                EXTRACT(MONTH FROM v_month)::INT,
                v_courier.courier_id,
                v_salary,
                v_courier.coefficient
            )
        ON CONFLICT (year, month, courier_id)
        DO UPDATE SET
            amount = EXCLUDED.amount,
            coefficient_used = EXCLUDED.coefficient_used;

        -- Определение коэффициента на следующий месяц
        v_new_coefficient :=
            CASE
                WHEN v_delivered_count <= 150 THEN 0.1
                WHEN v_delivered_count <= 250 THEN 0.2
                WHEN v_delivered_count <= 500 THEN 0.3
                ELSE 0.5
            END;

        -- Обновление коэффициента только работающего курьера
        IF v_courier.status <> 'уволен' THEN
            UPDATE isakov_food.courier
            SET coefficient = v_new_coefficient
            WHERE courier_id = v_courier.courier_id;
        END IF;
    END LOOP;
END;
$$;
