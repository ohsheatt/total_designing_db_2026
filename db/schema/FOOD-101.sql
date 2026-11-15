-- FOOD-101. Спроектировать и создать физическую схему
CREATE SCHEMA IF NOT EXISTS exts;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA exts;

CREATE SCHEMA IF NOT EXISTS isakov_food;

CREATE TYPE isakov_food.restaurant_status AS ENUM (
    'активен',
    'неактивен'
);

CREATE TYPE isakov_food.product_status AS ENUM (
    'доступно',
    'нет_в_наличии',
    'архив'
);

CREATE TYPE isakov_food.courier_status AS ENUM (
    'свободен',
    'занят',
    'на_доставке',
    'уволен'
);

CREATE TYPE isakov_food.order_status AS ENUM (
    'создан',
    'готовится',
    'в_доставке',
    'доставлен',
    'отменён'
);

CREATE TYPE isakov_food.order_pay_status AS ENUM (
    'ожидает',
    'оплачен',
    'ошибка'
);

CREATE TYPE isakov_food.payment_status AS ENUM (
    'успех',
    'ошибка',
    'в_обработке'
);

CREATE TYPE isakov_food.payment_type AS ENUM (
    'карта',
    'наличные',
    'безнал'
);

CREATE TYPE isakov_food.review_entity_type AS ENUM (
    'блюдо',
    'ресторан',
    'заказ'
);


CREATE TABLE isakov_food.client (
    client_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),

    login VARCHAR(100) NOT NULL UNIQUE,

    password CHAR(32) NOT NULL,

    phone_number CHAR(20) NOT NULL UNIQUE
);

CREATE TABLE isakov_food.address (
    address_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),
    street TEXT NOT NULL,
    house_number TEXT NOT NULL,
    apartment_office TEXT
);

CREATE TABLE isakov_food.client_address (
    client_id UUID NOT NULL,
    address_id UUID NOT NULL,

    PRIMARY KEY (client_id, address_id),

    FOREIGN KEY (client_id)
        REFERENCES isakov_food.client(client_id),

    FOREIGN KEY (address_id)
        REFERENCES isakov_food.address(address_id)
);

CREATE TABLE isakov_food.restaurant (
    restaurant_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),
    restaurant_name TEXT NOT NULL,
    address_id UUID NOT NULL UNIQUE,
    description TEXT NOT NULL,
    work_start TIME NOT NULL,
    work_end TIME NOT NULL,
    company_details TEXT NOT NULL,
    rating NUMERIC(3,2),
    status isakov_food.restaurant_status NOT NULL,

    FOREIGN KEY (address_id)
        REFERENCES isakov_food.address(address_id),

    CHECK (rating BETWEEN 0 AND 5),
    CHECK (work_end > work_start)
);

CREATE TABLE isakov_food.courier (
    courier_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),
    fio TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    status isakov_food.courier_status NOT NULL,
    hire_date DATE NOT NULL,
    dismissal_date DATE,
    coefficient NUMERIC(2,1) NOT NULL DEFAULT 0.1,

    CHECK (coefficient BETWEEN 0.1 AND 0.5),
    CHECK (status <> 'уволен' OR dismissal_date IS NOT NULL),
    CHECK (dismissal_date IS NULL OR dismissal_date >= hire_date)
);

CREATE TABLE isakov_food.courier_pay (
    year INT NOT NULL,
    month INT NOT NULL,
    courier_id UUID NOT NULL,
    amount NUMERIC NOT NULL,
    coefficient_used NUMERIC NOT NULL,

    PRIMARY KEY (year, month, courier_id),

    FOREIGN KEY (courier_id)
        REFERENCES isakov_food.courier(courier_id),

    CHECK (amount >= 0)
);

CREATE TABLE isakov_food.product_category (
    product_category_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),
    product_category_name VARCHAR(255) NOT NULL
);

CREATE TABLE isakov_food.product (
    product_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),
    product_name VARCHAR(255) NOT NULL,
    product_category_id UUID NOT NULL,
    price NUMERIC NOT NULL,
    restaurant_id UUID NOT NULL,
    photo_url TEXT,
    rating NUMERIC,
    status isakov_food.product_status NOT NULL,
    description TEXT NOT NULL,

    FOREIGN KEY (product_category_id)
        REFERENCES isakov_food.product_category(product_category_id),

    FOREIGN KEY (restaurant_id)
        REFERENCES isakov_food.restaurant(restaurant_id),

    CHECK (price >= 0),
    CHECK (rating BETWEEN 0 AND 5)
);

CREATE TABLE isakov_food."order" (
    order_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),

    courier_id UUID NOT NULL,
    client_id UUID NOT NULL,
    address_id UUID NOT NULL,
    restaurant_id UUID NOT NULL,

    order_timestamp TIMESTAMP NOT NULL,
    delivery_timestamp TIMESTAMP,

    order_amount NUMERIC NOT NULL,
    commission NUMERIC
        GENERATED ALWAYS AS (order_amount * 0.10) STORED,
    total_amount NUMERIC
        GENERATED ALWAYS AS (order_amount * 1.10) STORED,

    status isakov_food.order_status NOT NULL,
    pay_status isakov_food.order_pay_status NOT NULL,
    description TEXT NOT NULL,

    FOREIGN KEY (courier_id)
        REFERENCES isakov_food.courier(courier_id),

    FOREIGN KEY (client_id)
        REFERENCES isakov_food.client(client_id),

    FOREIGN KEY (restaurant_id)
        REFERENCES isakov_food.restaurant(restaurant_id),

    FOREIGN KEY (client_id, address_id)
        REFERENCES isakov_food.client_address(client_id, address_id),

    CHECK (total_amount >= 1000),

    CHECK (
        (status = 'доставлен' AND delivery_timestamp IS NOT NULL)
        OR
        (status <> 'доставлен' AND delivery_timestamp IS NULL)
    ),

    CHECK (
        delivery_timestamp IS NULL
        OR delivery_timestamp >= order_timestamp
    )
);

CREATE TABLE isakov_food.payment (
    payment_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),
    order_id UUID NOT NULL,
    payment_type isakov_food.payment_type NOT NULL,
    amount NUMERIC NOT NULL,
    transaction_id TEXT NOT NULL UNIQUE,
    transaction_timestamp TIMESTAMP NOT NULL,
    status isakov_food.payment_status NOT NULL,

    FOREIGN KEY (order_id)
        REFERENCES isakov_food."order"(order_id)
);

CREATE TABLE isakov_food.order_structure (
    order_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity NUMERIC NOT NULL,

    PRIMARY KEY (order_id, product_id),

    FOREIGN KEY (order_id)
        REFERENCES isakov_food."order"(order_id),

    FOREIGN KEY (product_id)
        REFERENCES isakov_food.product(product_id),

    CHECK (quantity > 0)
);

CREATE TABLE isakov_food.review (
    review_id UUID PRIMARY KEY
        DEFAULT exts.uuid_generate_v4(),
    review_timestamp TIMESTAMP NOT NULL,
    entity_id UUID NOT NULL,
    entity_type isakov_food.review_entity_type NOT NULL,
    order_id UUID NOT NULL,
    description TEXT NOT NULL,
    photo_url TEXT,
    rating NUMERIC NOT NULL,

    FOREIGN KEY (order_id)
        REFERENCES isakov_food."order"(order_id),

    UNIQUE (order_id, entity_type, entity_id),

    CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE isakov_food.review_client (
    review_id UUID PRIMARY KEY,
    client_id UUID NOT NULL,

    FOREIGN KEY (review_id)
        REFERENCES isakov_food.review(review_id),

    FOREIGN KEY (client_id)
        REFERENCES isakov_food.client(client_id)
);


CREATE OR REPLACE FUNCTION isakov_food.check_order_product_restaurant()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_restaurant UUID;
    v_product_restaurant UUID;
BEGIN
    SELECT restaurant_id
    INTO v_order_restaurant
    FROM isakov_food."order"
    WHERE order_id = NEW.order_id;

    SELECT restaurant_id
    INTO v_product_restaurant
    FROM isakov_food.product
    WHERE product_id = NEW.product_id;

    IF v_order_restaurant IS DISTINCT FROM v_product_restaurant THEN
        RAISE EXCEPTION
            'Блюдо должно принадлежать ресторану заказа';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_order_product_restaurant
BEFORE INSERT OR UPDATE
ON isakov_food.order_structure
FOR EACH ROW
EXECUTE FUNCTION isakov_food.check_order_product_restaurant();


CREATE OR REPLACE FUNCTION isakov_food.check_order_has_position()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id UUID;
BEGIN
    IF TG_TABLE_NAME = 'order' THEN
        v_order_id := NEW.order_id;

        IF EXISTS (
            SELECT 1
            FROM isakov_food."order"
            WHERE order_id = v_order_id
        )
        AND NOT EXISTS (
            SELECT 1
            FROM isakov_food.order_structure
            WHERE order_id = v_order_id
        ) THEN
            RAISE EXCEPTION
                'Заказ должен содержать хотя бы одну позицию';
        END IF;

    ELSIF TG_OP = 'INSERT' THEN
        v_order_id := NEW.order_id;

        IF NOT EXISTS (
            SELECT 1
            FROM isakov_food.order_structure
            WHERE order_id = v_order_id
        ) THEN
            RAISE EXCEPTION
                'Заказ должен содержать хотя бы одну позицию';
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        v_order_id := OLD.order_id;

        IF EXISTS (
            SELECT 1
            FROM isakov_food."order"
            WHERE order_id = v_order_id
        )
        AND NOT EXISTS (
            SELECT 1
            FROM isakov_food.order_structure
            WHERE order_id = v_order_id
        ) THEN
            RAISE EXCEPTION
                'Заказ должен содержать хотя бы одну позицию';
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.order_id IS DISTINCT FROM NEW.order_id THEN
            IF EXISTS (
                SELECT 1
                FROM isakov_food."order"
                WHERE order_id = OLD.order_id
            )
            AND NOT EXISTS (
                SELECT 1
                FROM isakov_food.order_structure
                WHERE order_id = OLD.order_id
            ) THEN
                RAISE EXCEPTION
                    'Заказ должен содержать хотя бы одну позицию';
            END IF;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM isakov_food."order"
            WHERE order_id = NEW.order_id
        )
        AND NOT EXISTS (
            SELECT 1
            FROM isakov_food.order_structure
            WHERE order_id = NEW.order_id
        ) THEN
            RAISE EXCEPTION
                'Заказ должен содержать хотя бы одну позицию';
        END IF;
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_order_has_position
AFTER INSERT OR UPDATE
ON isakov_food."order"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION isakov_food.check_order_has_position();

CREATE CONSTRAINT TRIGGER trg_order_structure_has_position
AFTER INSERT OR UPDATE OR DELETE
ON isakov_food.order_structure
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION isakov_food.check_order_has_position();



CREATE OR REPLACE FUNCTION isakov_food.check_payment_amount()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_TABLE_NAME = 'payment' THEN
        IF NEW.amount IS DISTINCT FROM (
            SELECT total_amount
            FROM isakov_food."order"
            WHERE order_id = NEW.order_id
        ) THEN
            RAISE EXCEPTION
                'Сумма оплаты должна равняться общей сумме заказа';
        END IF;

    ELSIF TG_TABLE_NAME = 'order' THEN
        IF EXISTS (
            SELECT 1
            FROM isakov_food.payment
            WHERE order_id = NEW.order_id
              AND amount IS DISTINCT FROM NEW.total_amount
        ) THEN
            RAISE EXCEPTION
                'Сумма оплаты должна равняться общей сумме заказа';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_payment_amount
BEFORE INSERT OR UPDATE
ON isakov_food.payment
FOR EACH ROW
EXECUTE FUNCTION isakov_food.check_payment_amount();


CREATE TRIGGER trg_check_order_payment_amount
AFTER UPDATE OF order_amount
ON isakov_food."order"
FOR EACH ROW
EXECUTE FUNCTION isakov_food.check_payment_amount();


CREATE OR REPLACE FUNCTION isakov_food.check_review_target()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_restaurant UUID;
BEGIN
    SELECT restaurant_id
    INTO v_order_restaurant
    FROM isakov_food."order"
    WHERE order_id = NEW.order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заказ для отзыва не существует';
    END IF;

    IF NEW.entity_type = 'блюдо' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM isakov_food.order_structure os
            WHERE os.order_id = NEW.order_id
              AND os.product_id = NEW.entity_id
        ) THEN
            RAISE EXCEPTION 'Нельзя оставить отзыв на блюдо, которого нет в заказе';
        END IF;

    ELSIF NEW.entity_type = 'ресторан' THEN
        IF NEW.entity_id IS DISTINCT FROM v_order_restaurant THEN
            RAISE EXCEPTION 'Отзыв должен относиться к ресторану заказа';
        END IF;

    ELSIF NEW.entity_type = 'заказ' THEN
        IF NEW.entity_id IS DISTINCT FROM NEW.order_id THEN
            RAISE EXCEPTION 'Отзыв на заказ должен ссылаться на этот заказ';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_review_target
BEFORE INSERT OR UPDATE
ON isakov_food.review
FOR EACH ROW
EXECUTE FUNCTION isakov_food.check_review_target();


CREATE OR REPLACE FUNCTION isakov_food.check_review_client()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_client UUID;
BEGIN
    SELECT o.client_id
    INTO v_order_client
    FROM isakov_food.review r
    JOIN isakov_food."order" o
        ON o.order_id = r.order_id
    WHERE r.review_id = NEW.review_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заказ для отзыва не найден';
    END IF;

    IF NEW.client_id IS DISTINCT FROM v_order_client THEN
        RAISE EXCEPTION
            'Клиент отзыва должен совпадать с клиентом заказа';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_check_review_client
BEFORE INSERT OR UPDATE
ON isakov_food.review_client
FOR EACH ROW
EXECUTE FUNCTION isakov_food.check_review_client();




-- BR-8.1: не более одной успешной попытки оплаты на заказ
CREATE UNIQUE INDEX IF NOT EXISTS payment_one_success_per_order
ON isakov_food.payment (order_id)
WHERE status = 'успех';



-- Пересчёт агрегированного статуса оплаты заказа по BR-8.7
CREATE OR REPLACE FUNCTION isakov_food.recalculate_order_pay_status(
    p_order_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_pay_status isakov_food.order_pay_status;
BEGIN
    -- Если есть успешная попытка
    IF EXISTS (
        SELECT 1
        FROM isakov_food.payment
        WHERE order_id = p_order_id
          AND status = 'успех'
    ) THEN
        v_pay_status := 'оплачен';

    -- Если все попытки завершились ошибкой
    ELSIF EXISTS (
        SELECT 1
        FROM isakov_food.payment
        WHERE order_id = p_order_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM isakov_food.payment
        WHERE order_id = p_order_id
          AND status <> 'ошибка'
    ) THEN
        v_pay_status := 'ошибка';

    -- Если есть попытка в обработке и нет успешных
    ELSIF EXISTS (
        SELECT 1
        FROM isakov_food.payment
        WHERE order_id = p_order_id
          AND status = 'в_обработке'
    ) THEN
        v_pay_status := 'ожидает';

    ELSE
        -- Для заказа без попыток статус не меняем
        RETURN;
    END IF;

    UPDATE isakov_food."order"
    SET pay_status = v_pay_status
    WHERE order_id = p_order_id;
END;
$$;


-- Триггерная функция для INSERT, UPDATE и DELETE
CREATE OR REPLACE FUNCTION isakov_food.update_order_pay_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM isakov_food.recalculate_order_pay_status(OLD.order_id);
        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.order_id IS DISTINCT FROM NEW.order_id THEN
            PERFORM isakov_food.recalculate_order_pay_status(OLD.order_id);
        END IF;

        PERFORM isakov_food.recalculate_order_pay_status(NEW.order_id);
        RETURN NEW;

    ELSE
        PERFORM isakov_food.recalculate_order_pay_status(NEW.order_id);
        RETURN NEW;
    END IF;
END;
$$;


-- Подключение триггера к таблице payment
DROP TRIGGER IF EXISTS trg_update_order_pay_status
ON isakov_food.payment;

CREATE TRIGGER trg_update_order_pay_status
AFTER INSERT OR UPDATE OR DELETE
ON isakov_food.payment
FOR EACH ROW
EXECUTE FUNCTION isakov_food.update_order_pay_status();

