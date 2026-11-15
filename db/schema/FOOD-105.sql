-- FOOD-105. Триггер пересчета рейтинга
CREATE OR REPLACE FUNCTION isakov_food.rating_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Пересчёт рейтинга старой сущности при UPDATE или DELETE
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN

        IF OLD.entity_type = 'блюдо' THEN
            UPDATE isakov_food.product
            SET rating = (
                SELECT AVG(rating)
                FROM isakov_food.review
                WHERE entity_type = 'блюдо'
                  AND entity_id = OLD.entity_id
            )
            WHERE product_id = OLD.entity_id;

        ELSIF OLD.entity_type = 'ресторан' THEN
            UPDATE isakov_food.restaurant
            SET rating = (
                SELECT AVG(rating)
                FROM isakov_food.review
                WHERE entity_type = 'ресторан'
                  AND entity_id = OLD.entity_id
            )
            WHERE restaurant_id = OLD.entity_id;
        END IF;

    END IF;

    -- Пересчёт рейтинга новой сущности при INSERT или UPDATE
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN

        IF NEW.entity_type = 'блюдо' THEN
            UPDATE isakov_food.product
            SET rating = (
                SELECT AVG(rating)
                FROM isakov_food.review
                WHERE entity_type = 'блюдо'
                  AND entity_id = NEW.entity_id
            )
            WHERE product_id = NEW.entity_id;

        ELSIF NEW.entity_type = 'ресторан' THEN
            UPDATE isakov_food.restaurant
            SET rating = (
                SELECT AVG(rating)
                FROM isakov_food.review
                WHERE entity_type = 'ресторан'
                  AND entity_id = NEW.entity_id
            )
            WHERE restaurant_id = NEW.entity_id;
        END IF;

    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_rating_change
AFTER INSERT OR UPDATE OR DELETE
ON isakov_food.review
FOR EACH ROW
EXECUTE FUNCTION isakov_food.rating_change();
