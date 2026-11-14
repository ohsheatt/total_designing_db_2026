-- DROP SCHEMA isakov_food;

CREATE SCHEMA isakov_food AUTHORIZATION postgres;

-- DROP TYPE isakov_food.courier_status;

CREATE TYPE isakov_food.courier_status AS ENUM (
	'свободен',
	'занят',
	'на_доставке',
	'уволен');

-- DROP TYPE isakov_food.order_pay_status;

CREATE TYPE isakov_food.order_pay_status AS ENUM (
	'ожидает',
	'оплачен',
	'ошибка');

-- DROP TYPE isakov_food.order_status;

CREATE TYPE isakov_food.order_status AS ENUM (
	'создан',
	'готовится',
	'в_доставке',
	'доставлен',
	'отменён');

-- DROP TYPE isakov_food.payment_status;

CREATE TYPE isakov_food.payment_status AS ENUM (
	'успех',
	'ошибка',
	'в_обработке');

-- DROP TYPE isakov_food."payment_type";

CREATE TYPE isakov_food."payment_type" AS ENUM (
	'карта',
	'наличные',
	'безнал');

-- DROP TYPE isakov_food.product_status;

CREATE TYPE isakov_food.product_status AS ENUM (
	'доступно',
	'нет_в_наличии',
	'архив');

-- DROP TYPE isakov_food.restaurant_status;

CREATE TYPE isakov_food.restaurant_status AS ENUM (
	'активен',
	'неактивен');

-- DROP TYPE isakov_food.review_entity_type;

CREATE TYPE isakov_food.review_entity_type AS ENUM (
	'блюдо',
	'ресторан',
	'заказ');
-- isakov_food.address определение

-- Drop table

-- DROP TABLE isakov_food.address;

CREATE TABLE isakov_food.address (
	address_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	street text NOT NULL,
	house_number text NOT NULL,
	apartment_office text NULL,
	CONSTRAINT address_pkey PRIMARY KEY (address_id)
);


-- isakov_food.client определение

-- Drop table

-- DROP TABLE isakov_food.client;

CREATE TABLE isakov_food.client (
	client_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	login varchar(100) NOT NULL,
	"password" bpchar(32) NOT NULL,
	phone_number bpchar(20) NOT NULL,
	CONSTRAINT client_login_key UNIQUE (login),
	CONSTRAINT client_phone_number_key UNIQUE (phone_number),
	CONSTRAINT client_pkey PRIMARY KEY (client_id)
);


-- isakov_food.courier определение

-- Drop table

-- DROP TABLE isakov_food.courier;

CREATE TABLE isakov_food.courier (
	courier_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	fio text NOT NULL,
	phone_number text NOT NULL,
	status isakov_food.courier_status NOT NULL,
	hire_date date NOT NULL,
	dismissal_date date NULL,
	coefficient numeric(2, 1) DEFAULT 0.1 NOT NULL,
	CONSTRAINT courier_check CHECK (((status <> 'уволен'::isakov_food.courier_status) OR (dismissal_date IS NOT NULL))),
	CONSTRAINT courier_coefficient_check CHECK (((coefficient >= 0.1) AND (coefficient <= 0.5))),
	CONSTRAINT courier_pkey PRIMARY KEY (courier_id)
);


-- isakov_food.product_category определение

-- Drop table

-- DROP TABLE isakov_food.product_category;

CREATE TABLE isakov_food.product_category (
	product_category_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	product_category_name varchar(255) NOT NULL,
	CONSTRAINT product_category_pkey PRIMARY KEY (product_category_id)
);


-- isakov_food.client_address определение

-- Drop table

-- DROP TABLE isakov_food.client_address;

CREATE TABLE isakov_food.client_address (
	client_id uuid NOT NULL,
	address_id uuid NOT NULL,
	CONSTRAINT client_address_pkey PRIMARY KEY (client_id, address_id),
	CONSTRAINT client_address_address_id_fkey FOREIGN KEY (address_id) REFERENCES isakov_food.address(address_id),
	CONSTRAINT client_address_client_id_fkey FOREIGN KEY (client_id) REFERENCES isakov_food.client(client_id)
);


-- isakov_food.courier_pay определение

-- Drop table

-- DROP TABLE isakov_food.courier_pay;

CREATE TABLE isakov_food.courier_pay (
	"year" int4 NOT NULL,
	"month" int4 NOT NULL,
	courier_id uuid NOT NULL,
	amount numeric NOT NULL,
	coefficient_used numeric NOT NULL,
	CONSTRAINT courier_pay_amount_check CHECK ((amount >= (0)::numeric)),
	CONSTRAINT courier_pay_pkey PRIMARY KEY (year, month, courier_id),
	CONSTRAINT courier_pay_courier_id_fkey FOREIGN KEY (courier_id) REFERENCES isakov_food.courier(courier_id)
);


-- isakov_food.restaurant определение

-- Drop table

-- DROP TABLE isakov_food.restaurant;

CREATE TABLE isakov_food.restaurant (
	restaurant_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	restaurant_name text NOT NULL,
	address_id uuid NOT NULL,
	description text NOT NULL,
	work_start time NOT NULL,
	work_end time NOT NULL,
	company_details text NOT NULL,
	rating numeric(3, 2) NULL,
	status isakov_food.restaurant_status NOT NULL,
	CONSTRAINT restaurant_address_id_key UNIQUE (address_id),
	CONSTRAINT restaurant_check CHECK ((work_end > work_start)),
	CONSTRAINT restaurant_pkey PRIMARY KEY (restaurant_id),
	CONSTRAINT restaurant_rating_check CHECK (((rating >= (0)::numeric) AND (rating <= (5)::numeric))),
	CONSTRAINT restaurant_address_id_fkey FOREIGN KEY (address_id) REFERENCES isakov_food.address(address_id)
);


-- isakov_food."order" определение

-- Drop table

-- DROP TABLE isakov_food."order";

CREATE TABLE isakov_food."order" (
	order_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	courier_id uuid NOT NULL,
	client_id uuid NOT NULL,
	address_id uuid NOT NULL,
	restaurant_id uuid NOT NULL,
	order_timestamp timestamp NOT NULL,
	delivery_timestamp timestamp NULL,
	order_amount numeric NOT NULL,
	commission numeric GENERATED ALWAYS AS (order_amount * 0.10) STORED NULL,
	total_amount numeric GENERATED ALWAYS AS (order_amount * 1.10) STORED NULL,
	status isakov_food.order_status NOT NULL,
	pay_status isakov_food.order_pay_status NOT NULL,
	description text NOT NULL,
	CONSTRAINT order_check CHECK ((((status = 'доставлен'::isakov_food.order_status) AND (delivery_timestamp IS NOT NULL)) OR ((status <> 'доставлен'::isakov_food.order_status) AND (delivery_timestamp IS NULL)))),
	CONSTRAINT order_check1 CHECK (((delivery_timestamp IS NULL) OR (delivery_timestamp >= order_timestamp))),
	CONSTRAINT order_pkey PRIMARY KEY (order_id),
	CONSTRAINT order_total_amount_check CHECK ((total_amount >= (1000)::numeric)),
	CONSTRAINT trg_order_has_position TRIGGER DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT order_client_id_address_id_fkey FOREIGN KEY (client_id,address_id) REFERENCES isakov_food.client_address(client_id,address_id),
	CONSTRAINT order_client_id_fkey FOREIGN KEY (client_id) REFERENCES isakov_food.client(client_id),
	CONSTRAINT order_courier_id_fkey FOREIGN KEY (courier_id) REFERENCES isakov_food.courier(courier_id),
	CONSTRAINT order_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES isakov_food.restaurant(restaurant_id)
);

-- Table Triggers

create constraint trigger trg_order_has_position after
insert
    or
update
    on
    isakov_food."order" deferrable initially deferred for each row execute function isakov_food.check_order_has_position();
create trigger trg_check_order_payment_amount after
update
    of order_amount on
    isakov_food."order" for each row execute function isakov_food.check_payment_amount();


-- isakov_food.payment определение

-- Drop table

-- DROP TABLE isakov_food.payment;

CREATE TABLE isakov_food.payment (
	payment_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	order_id uuid NOT NULL,
	"payment_type" isakov_food."payment_type" NOT NULL,
	amount numeric NOT NULL,
	transaction_id text NOT NULL,
	transaction_timestamp timestamp NOT NULL,
	status isakov_food.payment_status NOT NULL,
	CONSTRAINT payment_pkey PRIMARY KEY (payment_id),
	CONSTRAINT payment_transaction_id_key UNIQUE (transaction_id),
	CONSTRAINT payment_order_id_fkey FOREIGN KEY (order_id) REFERENCES isakov_food."order"(order_id)
);
CREATE UNIQUE INDEX payment_one_success_per_order ON isakov_food.payment USING btree (order_id) WHERE (status = 'успех'::isakov_food.payment_status);

-- Table Triggers

create trigger trg_check_payment_amount before
insert
    or
update
    on
    isakov_food.payment for each row execute function isakov_food.check_payment_amount();
create trigger trg_update_order_pay_status after
insert
    or
delete
    or
update
    on
    isakov_food.payment for each row execute function isakov_food.update_order_pay_status();


-- isakov_food.product определение

-- Drop table

-- DROP TABLE isakov_food.product;

CREATE TABLE isakov_food.product (
	product_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	product_name varchar(255) NOT NULL,
	product_category_id uuid NOT NULL,
	price numeric NOT NULL,
	restaurant_id uuid NOT NULL,
	photo_url text NULL,
	rating numeric NULL,
	status isakov_food.product_status NOT NULL,
	description text NOT NULL,
	CONSTRAINT product_pkey PRIMARY KEY (product_id),
	CONSTRAINT product_price_check CHECK ((price >= (0)::numeric)),
	CONSTRAINT product_rating_check CHECK (((rating >= (0)::numeric) AND (rating <= (5)::numeric))),
	CONSTRAINT product_product_category_id_fkey FOREIGN KEY (product_category_id) REFERENCES isakov_food.product_category(product_category_id),
	CONSTRAINT product_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES isakov_food.restaurant(restaurant_id)
);


-- isakov_food.review определение

-- Drop table

-- DROP TABLE isakov_food.review;

CREATE TABLE isakov_food.review (
	review_id uuid DEFAULT exts.uuid_generate_v4() NOT NULL,
	review_timestamp timestamp NOT NULL,
	entity_id uuid NOT NULL,
	entity_type isakov_food.review_entity_type NOT NULL,
	order_id uuid NOT NULL,
	description text NOT NULL,
	photo_url text NULL,
	rating numeric NOT NULL,
	CONSTRAINT review_order_id_entity_type_entity_id_key UNIQUE (order_id, entity_type, entity_id),
	CONSTRAINT review_pkey PRIMARY KEY (review_id),
	CONSTRAINT review_rating_check CHECK (((rating >= (1)::numeric) AND (rating <= (5)::numeric))),
	CONSTRAINT review_order_id_fkey FOREIGN KEY (order_id) REFERENCES isakov_food."order"(order_id)
);

-- Table Triggers

create trigger trg_check_review_target before
insert
    or
update
    on
    isakov_food.review for each row execute function isakov_food.check_review_target();


-- isakov_food.review_client определение

-- Drop table

-- DROP TABLE isakov_food.review_client;

CREATE TABLE isakov_food.review_client (
	review_id uuid NOT NULL,
	client_id uuid NOT NULL,
	CONSTRAINT review_client_pkey PRIMARY KEY (review_id),
	CONSTRAINT review_client_client_id_fkey FOREIGN KEY (client_id) REFERENCES isakov_food.client(client_id),
	CONSTRAINT review_client_review_id_fkey FOREIGN KEY (review_id) REFERENCES isakov_food.review(review_id)
);

-- Table Triggers

create trigger trg_check_review_client before
insert
    or
update
    on
    isakov_food.review_client for each row execute function isakov_food.check_review_client();


-- isakov_food.order_structure определение

-- Drop table

-- DROP TABLE isakov_food.order_structure;

CREATE TABLE isakov_food.order_structure (
	order_id uuid NOT NULL,
	product_id uuid NOT NULL,
	quantity numeric NOT NULL,
	CONSTRAINT order_structure_pkey PRIMARY KEY (order_id, product_id),
	CONSTRAINT order_structure_quantity_check CHECK ((quantity > (0)::numeric)),
	CONSTRAINT trg_order_structure_has_position TRIGGER DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT order_structure_order_id_fkey FOREIGN KEY (order_id) REFERENCES isakov_food."order"(order_id),
	CONSTRAINT order_structure_product_id_fkey FOREIGN KEY (product_id) REFERENCES isakov_food.product(product_id)
);

-- Table Triggers

create trigger trg_check_order_product_restaurant before
insert
    or
update
    on
    isakov_food.order_structure for each row execute function isakov_food.check_order_product_restaurant();
create constraint trigger trg_order_structure_has_position after
insert
    or
delete
    or
update
    on
    isakov_food.order_structure deferrable initially deferred for each row execute function isakov_food.check_order_has_position();



-- DROP FUNCTION isakov_food.check_order_has_position();

CREATE OR REPLACE FUNCTION isakov_food.check_order_has_position()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- DROP FUNCTION isakov_food.check_order_product_restaurant();

CREATE OR REPLACE FUNCTION isakov_food.check_order_product_restaurant()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- DROP FUNCTION isakov_food.check_payment_amount();

CREATE OR REPLACE FUNCTION isakov_food.check_payment_amount()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- DROP FUNCTION isakov_food.check_review_client();

CREATE OR REPLACE FUNCTION isakov_food.check_review_client()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- DROP FUNCTION isakov_food.check_review_target();

CREATE OR REPLACE FUNCTION isakov_food.check_review_target()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- DROP FUNCTION isakov_food.recalculate_order_pay_status(uuid);

CREATE OR REPLACE FUNCTION isakov_food.recalculate_order_pay_status(p_order_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- DROP FUNCTION isakov_food.update_order_pay_status();

CREATE OR REPLACE FUNCTION isakov_food.update_order_pay_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;
