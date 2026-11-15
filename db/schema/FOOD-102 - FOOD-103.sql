-- FOOD-102. Генератор тестовых данных
CREATE OR REPLACE PROCEDURE isakov_food.insert_test_data(p_value INT)
LANGUAGE plpgsql
AS $$
DECLARE
    i INT;
    j INT;

    v_client_id UUID;
    v_login VARCHAR(100);
    v_courier_id UUID;
    v_category_id UUID;
    
    v_restaurant_id UUID;
    v_address_id UUID;
    v_product_id UUID;
    v_order_id UUID;
    v_review_id UUID;

    v_clients UUID[] := ARRAY[]::UUID[];
    v_couriers UUID[] := ARRAY[]::UUID[];
    v_categories UUID[] := ARRAY[]::UUID[];
    v_restaurants UUID[] := ARRAY[]::UUID[];
    v_products UUID[] := ARRAY[]::UUID[];

    v_order_statuses isakov_food.order_status[];
    v_product_statuses isakov_food.product_status[];
    v_restaurant_statuses isakov_food.restaurant_status[];
    v_courier_statuses isakov_food.courier_status[];
    v_payment_types isakov_food.payment_type[];
    v_payment_statuses isakov_food.payment_status[];
    v_order_pay_statuses isakov_food.order_pay_status[];
    v_review_types isakov_food.review_entity_type[];

    v_order_status isakov_food.order_status;
    v_review_type isakov_food.review_entity_type;

    v_order_time TIMESTAMP;
    v_delivery_time TIMESTAMP;
    v_first_month TIMESTAMP;
    v_month TIMESTAMP;

    v_coefficient NUMERIC(2,1);
    v_new_coefficient NUMERIC(2,1);
    v_delivered_count INT;
    v_commission_sum NUMERIC;
    v_letters TEXT[] := ARRAY[
        'а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н',
        'о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь',
        'э','ю','я'
    ];
BEGIN
    IF p_value IS NULL OR p_value <= 0 THEN
        RAISE EXCEPTION 'Параметр value должен быть положительным числом';
    END IF;

    -- Получаем значения ENUM через enum_range()
       -- Предварительное выделение массивов UUID
    v_order_statuses := enum_range(NULL::isakov_food.order_status);
    v_product_statuses := enum_range(NULL::isakov_food.product_status);
    v_restaurant_statuses := enum_range(NULL::isakov_food.restaurant_status);
    v_courier_statuses := enum_range(NULL::isakov_food.courier_status);
    v_payment_types := enum_range(NULL::isakov_food.payment_type);
    v_payment_statuses := enum_range(NULL::isakov_food.payment_status);
    v_order_pay_statuses := enum_range(NULL::isakov_food.order_pay_status);
    v_review_types := enum_range(NULL::isakov_food.review_entity_type);

    v_first_month :=
        date_trunc('month', current_date) - INTERVAL '5 months';

    -- 1. Клиенты, курьеры и категории
    FOR i IN 1..p_value LOOP

        v_client_id := exts.uuid_generate_v4();
       LOOP
    SELECT string_agg(
        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
        '' ORDER BY gs.n
    )
    INTO v_login
    FROM generate_series(
        1, 1 + floor(random() * 100)::INT
    ) AS gs(n);

    EXIT WHEN NOT EXISTS (
        SELECT 1
        FROM isakov_food.client
        WHERE login = v_login
    );
END LOOP;

        INSERT INTO isakov_food.client
            (client_id, login, password, phone_number)
        VALUES
            (
                v_client_id,
                v_login,
                md5(random()::TEXT),
                substring(replace(v_client_id::TEXT, '-', ''), 1, 20)
            );

        v_clients := array_append(v_clients, v_client_id);
		
        v_courier_id := exts.uuid_generate_v4();

        INSERT INTO isakov_food.courier
            (courier_id, fio, phone_number, status,
             hire_date, dismissal_date, coefficient)
        VALUES
            (
                v_courier_id,
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ),
                replace(v_courier_id::TEXT, '-', ''),
                v_courier_statuses[
    				1 + floor(random() * 3)::INT
				],
				v_first_month::DATE,
				NULL,
				0.1
            );

        v_couriers := array_append(v_couriers, v_courier_id);
        
        v_category_id := exts.uuid_generate_v4();

        INSERT INTO isakov_food.product_category
            (product_category_id, product_category_name)
        VALUES
            (v_category_id, (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ));

        v_categories := array_append(v_categories, v_category_id);
        

    END LOOP;

    -- 2. Адреса ресторанов и рестораны
    FOR i IN 1..p_value LOOP

        v_address_id := exts.uuid_generate_v4();

        INSERT INTO isakov_food.address
            (address_id, street, house_number, apartment_office)
        VALUES
            (v_address_id, (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ), i::TEXT, NULL);

        v_restaurant_id := exts.uuid_generate_v4();

        INSERT INTO isakov_food.restaurant
            (restaurant_id, restaurant_name, address_id, description,
             work_start, work_end, company_details, rating, status)
        VALUES
            (
                v_restaurant_id,
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ),
                v_address_id,
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ),
                TIME '09:00',
                TIME '22:00',
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ),
                NULL,
                v_restaurant_statuses[
                    1 + floor(
                        random() * cardinality(v_restaurant_statuses)
                    )::INT
                ]
            );

        v_restaurants := array_append(v_restaurants, v_restaurant_id);
		
    END LOOP;

    -- 3. Четыре адреса для каждого клиента
    FOR i IN 1..p_value LOOP
        FOR j IN 1..4 LOOP

            v_address_id := exts.uuid_generate_v4();

            INSERT INTO isakov_food.address
                (address_id, street, house_number, apartment_office)
            VALUES
                (
                    v_address_id,
                    (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ),
                    j::TEXT,
                    NULL
                );

            INSERT INTO isakov_food.client_address
                (client_id, address_id)
            VALUES
                (v_clients[i], v_address_id);

        END LOOP;
    END LOOP;

    -- 4. Пять блюд на каждый ресторан
    FOR i IN 1..(p_value * 5) LOOP

        v_product_id := exts.uuid_generate_v4();

        INSERT INTO isakov_food.product
            (product_id, product_name, product_category_id, price,
             restaurant_id, photo_url, rating, status, description)
        VALUES
            (
                v_product_id,
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ),
                v_categories[1 + ((i - 1) % p_value)],
                1000,
                v_restaurants[1 + ((i - 1) % p_value)],
                NULL,
                NULL,
                v_product_statuses[
                    1 + floor(
                        random() * cardinality(v_product_statuses)
                    )::INT
                ],
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                )
            );

        v_products := array_append(v_products, v_product_id);
        

    END LOOP;

    -- 5. Заказы, позиции, оплаты и отзывы
    FOR i IN 1..(p_value * 5) LOOP

        v_order_id := exts.uuid_generate_v4();

        -- Дата заказа в пределах последних шести календарных месяцев
        v_order_time :=
            v_first_month
            + random() * (
                localtimestamp
                - INTERVAL '1 day'
                - v_first_month
            );

        v_order_status := v_order_statuses[
            1 + floor(
                random() * cardinality(v_order_statuses)
            )::INT
        ];

        IF v_order_status = 'доставлен' THEN
            v_delivery_time := v_order_time + INTERVAL '30 minutes';
        ELSE
            v_delivery_time := NULL;
        END IF;

        INSERT INTO isakov_food."order"
            (
                order_id, courier_id, client_id, address_id,
                restaurant_id, order_timestamp, delivery_timestamp,
                order_amount, status, pay_status, description
            )
        VALUES
            (
                v_order_id,
                v_couriers[1 + ((i - 1) % p_value)],
                v_clients[1 + ((i - 1) % p_value)],
                (
                    SELECT ca.address_id
                    FROM isakov_food.client_address ca
                    WHERE ca.client_id =
                        v_clients[1 + ((i - 1) % p_value)]
                    ORDER BY ca.address_id
                    OFFSET (((i - 1) / p_value) % 4)
                    LIMIT 1
                ),
                v_restaurants[1 + ((i - 1) % p_value)],
                v_order_time,
                v_delivery_time,
                1000,
                v_order_status,
                v_order_pay_statuses[1],
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                )
            );

        -- Одна позиция из того же ресторана
        v_product_id := v_products[
    		1 + ((i - 1) % p_value)
      		+ floor(random() * 5)::INT * p_value
		];

		INSERT INTO isakov_food.order_structure
    		(order_id, product_id, quantity)
		VALUES
    		(v_order_id, v_product_id, 1);

        -- Одна успешная попытка оплаты
        INSERT INTO isakov_food.payment
            (
                payment_id, order_id, payment_type, amount,
                transaction_id, transaction_timestamp, status
            )
        VALUES
            (
                exts.uuid_generate_v4(),
                v_order_id,
                v_payment_types[
                    1 + floor(
                        random() * cardinality(v_payment_types)
                    )::INT
                ],
                1100,
                exts.uuid_generate_v4()::TEXT,
                v_order_time + INTERVAL '5 minutes',
                v_payment_statuses[1]
            );

        -- Один отзыв на заказ
        v_review_type := v_review_types[
            1 + floor(
                random() * cardinality(v_review_types)
            )::INT
        ];

        IF v_review_type = 'блюдо' THEN
            v_address_id := NULL;
        ELSIF v_review_type = 'ресторан' THEN
            v_product_id := v_restaurants[
                1 + ((i - 1) % p_value)
            ];
        ELSE
            v_product_id := v_order_id;
        END IF;

        v_review_id := exts.uuid_generate_v4();

        INSERT INTO isakov_food.review
            (
                review_id, review_timestamp, entity_id,
                entity_type, order_id, description, photo_url, rating
            )
        VALUES
            (
                v_review_id,
                v_order_time + INTERVAL '1 hour',
                v_product_id,
                v_review_type,
                v_order_id,
                (
                    SELECT string_agg(
                        v_letters[1 + floor(random() * cardinality(v_letters))::INT],
                        '' ORDER BY gs.n
                    )
                    FROM generate_series(
                        1, 3 + floor(random() * 38)::INT
                    ) AS gs(n)
                ),
                NULL,
                1 + floor(random() * 5)::INT
            );

        INSERT INTO isakov_food.review_client
            (review_id, client_id)
        VALUES
            (
                v_review_id,
                v_clients[1 + ((i - 1) % p_value)]
            );

    END LOOP;

    -- 6. Пересчёт рейтингов по созданным отзывам
    UPDATE isakov_food.product p
    SET rating = (
        SELECT AVG(r.rating)
        FROM isakov_food.review r
        WHERE r.entity_type = 'блюдо'
          AND r.entity_id = p.product_id
    )
    WHERE p.product_id = ANY(v_products);

    UPDATE isakov_food.restaurant r
    SET rating = (
        SELECT AVG(rv.rating)
        FROM isakov_food.review rv
        WHERE rv.entity_type = 'ресторан'
          AND rv.entity_id = r.restaurant_id
    )
    WHERE r.restaurant_id = ANY(v_restaurants);

    -- 7. История выплат за шесть месяцев
    FOR i IN 1..p_value LOOP

        v_coefficient := 0.1;
	    

        -- От самого раннего месяца к текущему
        FOR j IN REVERSE 5..0 LOOP

            v_month :=
                date_trunc('month', current_date)
                - make_interval(months => j);

            SELECT
                COUNT(*)::INT,
                COALESCE(SUM(o.commission), 0)
            INTO
                v_delivered_count,
                v_commission_sum
            FROM isakov_food."order" o
            WHERE o.courier_id = v_couriers[i]
              AND o.status = 'доставлен'
              AND o.order_timestamp >= v_month
              AND o.order_timestamp < v_month + INTERVAL '1 month';

            INSERT INTO isakov_food.courier_pay
                (year, month, courier_id, amount, coefficient_used)
            VALUES
                (
                    EXTRACT(YEAR FROM v_month)::INT,
                    EXTRACT(MONTH FROM v_month)::INT,
                    v_couriers[i],
                    v_coefficient * v_commission_sum,
                    v_coefficient
                );

            -- Коэффициент для следующего месяца
            v_new_coefficient :=
                CASE
                    WHEN v_delivered_count <= 150 THEN 0.1
                    WHEN v_delivered_count <= 250 THEN 0.2
                    WHEN v_delivered_count <= 500 THEN 0.3
                    ELSE 0.5
                END;

            v_coefficient := v_new_coefficient;

        END LOOP;

        -- Коэффициент на следующий месяц
        UPDATE isakov_food.courier
        SET coefficient = v_coefficient
        WHERE courier_id = v_couriers[i];
        

    END LOOP;

END;
$$;


-- FOOD-103. Удаление тестовых данных
CREATE OR REPLACE PROCEDURE isakov_food.erase_test_data()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM isakov_food.payment;
    DELETE FROM isakov_food.review_client;
    DELETE FROM isakov_food.review;
    DELETE FROM isakov_food.order_structure;
    DELETE FROM isakov_food.courier_pay;
    DELETE FROM isakov_food."order";
    DELETE FROM isakov_food.client_address;
    DELETE FROM isakov_food.product;
    DELETE FROM isakov_food.restaurant;
    DELETE FROM isakov_food.courier;
    DELETE FROM isakov_food.product_category;
    DELETE FROM isakov_food.client;
    DELETE FROM isakov_food.address;
END;
$$;


CALL isakov_food.insert_test_data(100);

SELECT
    p.product_id,
    p.product_name,
    COUNT(r.review_id) AS review_count,
    AVG(r.rating) AS average_rating,
    p.rating AS saved_rating
FROM isakov_food.product p
LEFT JOIN isakov_food.review r
    ON r.entity_id = p.product_id
   AND r.entity_type = 'блюдо'
GROUP BY p.product_id, p.product_name, p.rating
ORDER BY review_count DESC;


SELECT COUNT(*) AS products_without_reviews
FROM isakov_food.product p
WHERE NOT EXISTS (
    SELECT 1
    FROM isakov_food.review r
    WHERE r.entity_id = p.product_id
      AND r.entity_type = 'блюдо'
);

SELECT COUNT(*) AS products_without_reviews_with_rating
FROM isakov_food.product p
WHERE NOT EXISTS (
    SELECT 1
    FROM isakov_food.review r
    WHERE r.entity_id = p.product_id
      AND r.entity_type = 'блюдо'
)
AND p.rating IS NOT NULL;
