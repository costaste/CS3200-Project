CREATE DATABASE IF NOT EXISTS CryptoTracker;
USE CryptoTracker;

-- TABLES ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS currencies (
    abbrev VARCHAR(10) PRIMARY KEY,
    name   VARCHAR(64)
);

CREATE TABLE IF NOT EXISTS exchanges (
    name VARCHAR(256) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS bexes (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(256),
    search_url VARCHAR(256)
);

CREATE TABLE IF NOT EXISTS price_history (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    price_date DATE NOT NULL,
    base       VARCHAR(10) NOT NULL,
    target     VARCHAR(10) NOT NULL,
    high       INT NOT NULL,
    low        INT NOT NULL,
    day_open   INT NOT NULL,
    day_close  INT NOT NULL,
    data_source   VARCHAR(256),
    CONSTRAINT history_base_fk FOREIGN KEY (base) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT history_target_fk FOREIGN KEY (target) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT history_exchange_fk FOREIGN KEY (data_source) REFERENCES exchanges (name) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS users (
    id   INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(256)
);

CREATE TABLE IF NOT EXISTS price_watch (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    watcher_id      INT NOT NULL,
    base_currency   VARCHAR(10) NOT NULL DEFAULT 'USD',
    target_currency VARCHAR(10) NOT NULL,
    base_amount     INT NOT NULL,
    criteria_met    TINYINT(1) DEFAULT 0,
    CONSTRAINT pwatch_user_fk FOREIGN KEY (watcher_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT pwatch_base_fk FOREIGN KEY (base_currency) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT pwatch_target_fk FOREIGN KEY (target_currency) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS whale_watch (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    watcher_id   INT NOT NULL,
    currency     VARCHAR(10) NOT NULL,
    alert_amount INT NOT NULL,
    criteria_met TINYINT(1) DEFAULT 0,
    CONSTRAINT wwatch_user_fk FOREIGN KEY (watcher_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT wwatch_curr_fk FOREIGN KEY (currency) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS trade (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    buyer_id        INT NOT NULL,
    seller_id       INT NOT NULL,
    base_currency   VARCHAR(10) NOT NULL DEFAULT 'USD',
    target_currency VARCHAR(10) NOT NULL,
    base_amount     INT NOT NULL,
    target_amount   INT NOT NULL,
    CONSTRAINT trade_buyer_fk FOREIGN KEY (buyer_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT trade_seller_fk FOREIGN KEY (seller_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT trade_base_fk FOREIGN KEY (base_currency) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT trade_target_fk FOREIGN KEY (target_currency) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE
);

-- DATA -----------------------------------------------------------------------

-- Insert some starting currencies
INSERT INTO currencies (abbrev, name) VALUES
    ('USD', 'United States Dollar'),
    ('EUR', 'Euro'),
    ('GBP', 'Great British Pound'),
    ('BTC', 'Bitcoin'),
    ('ETH', 'Ethereum'),
    ('XRP', 'Ripple'),
    ('LTC', 'Litecoin'),
    ('XMR', 'Monero');

INSERT INTO bexes (name, search_url) VALUES
    ('Blockchain', 'https://www.blockchain.com/search?search=');

-- PROCEDURES/FUNCTIONS/TRIGGERS ----------------------------------------------

DELIMITER //
CREATE PROCEDURE write_price_history(
    IN price_date DATE,
    IN base       VARCHAR(10),
    IN target     VARCHAR(10),
    IN high       INT,
    IN low        INT,
    IN day_open   INT,
    IN day_close  INT,
    IN data_source     VARCHAR(30)
)
BEGIN
    INSERT INTO `price_history` (
        `price_date`,
        `base`,
        `target`,
        `high`,
        `low`,
        `day_open`,
        `day_close`,
        `data_source`
    ) VALUES (
        price_date,
        base,
        target,
        high,
        low,
        day_open,
        day_close,
        data_source
    );
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE add_exchange(
    IN exchange_name VARCHAR(256)
)
BEGIN
    DECLARE found VARCHAR(256);
    SELECT `name` INTO found FROM `exchanges` WHERE `name` = exchange_name;
    IF found IS NULL THEN
        INSERT INTO `exchanges` (
            `name`
        ) VALUES (
            exchange_name
        );
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE clear_price_history()
BEGIN
    TRUNCATE TABLE `price_history`;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_currencies()
BEGIN
    SELECT * FROM `currencies`;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_bexes()
BEGIN
    SELECT `id`, `name` FROM `bexes`;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_bex_search_url(
    IN bex_id INT
)
BEGIN
    SELECT `search_url` FROM `bexes` WHERE `id` = bex_id;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION get_user_id(
    user_name VARCHAR(256)
)
RETURNS INT
DETERMINISTIC CONTAINS SQL
BEGIN
    DECLARE user_id INT;

    SELECT `id` INTO user_id FROM `users` WHERE `name` = user_name;

    IF user_id IS NULL THEN
        -- create a new user if they don't already exist
        INSERT INTO `users` (`name`) VALUES (user_name);
        SELECT `id` INTO user_id FROM `users` WHERE `name` = user_name;
    END IF;

    return user_id;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE create_price_watch(
    IN user_id       INT,
    IN base          VARCHAR(10),
    IN target        VARCHAR(10),
    IN base_amount   INT
)
BEGIN
    DECLARE met TINYINT;

    SELECT check_price_watch_criteria(base, target, base_amount) INTO met;

    INSERT INTO `price_watch` (
        `watcher_id`,
        `base_currency`,
        `target_currency`,
        `base_amount`,
        `criteria_met`
    ) VALUES (
        user_id,
        base,
        target,
        base_amount,
        met
    );
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE create_whale_watch(
    IN user_id      INT,
    IN currency     VARCHAR(10),
    IN alert_amount INT
)
BEGIN
    INSERT INTO `whale_watch` (
        `watcher_id`,
        `currency`,
        `alert_amount`,
        `criteria_met`
    ) VALUES (
        user_id,
        currency,
        alert_amount,
        0
    );
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE update_price_watch(
    IN watch_id      INT,
    IN base          VARCHAR(10),
    IN target        VARCHAR(10),
    IN base_amount   INT
)
BEGIN
    DECLARE met TINYINT;

    SELECT check_price_watch_criteria(base, target, base_amount) INTO met;

    UPDATE `price_watch`
    SET
        `base_currency` = base,
        `target_currency` = target,
        `base_amount` = base_amount,
        `criteria_met` = met
    WHERE `id` = watch_id;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE update_whale_watch(
    IN watch_id     INT,
    IN currency     VARCHAR(10),
    IN alert_amount INT
)
BEGIN
    UPDATE `whale_watch`
    SET
        `currency` = currency,
        `alert_amount` = alert_amount
    WHERE `id` = watch_id;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION check_price_watch_criteria(
    base       VARCHAR(10),
    target     VARCHAR(10),
    base_amt   INT
)
RETURNS TINYINT
DETERMINISTIC CONTAINS SQL
BEGIN
    DECLARE history_id INT;

    SELECT MIN(`id`)
    INTO history_id
    FROM `price_history`
    WHERE `base` = base AND `target` = target AND `high` >= base_amt AND `low` <= base_amt;

    IF history_id IS NULL THEN
        return 0;
    ELSE
        return 1;
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_activated_price_watches(
    IN watcher_id INT
)
BEGIN
    SELECT `base_currency`, `base_amount`, `target_currency`
    FROM `price_watch`
    WHERE `watcher_id` = watcher_id AND `criteria_met` = 1;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_activated_whale_watches(
    IN watcher_id INT
)
BEGIN
    SELECT `currency`, `alert_amount`
    FROM `whale_watch`
    WHERE `watcher_id` = watcher_id AND `criteria_met` = 1;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_price_watches(
    IN watcher_id INT
)
BEGIN
    SELECT `id`, `base_currency`, `base_amount`, `target_currency`
    FROM `price_watch`
    WHERE `watcher_id` = watcher_id;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_whale_watches(
    IN watcher_id INT
)
BEGIN
    SELECT `id`, `currency`, `alert_amount`
    FROM `whale_watch`
    WHERE `watcher_id` = watcher_id;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_price_watches_for_user(
    IN watcher_id INT
)
BEGIN
    SELECT `id`, `base_currency`, `base_amount`, `target_currency`
    FROM `price_watch`
    WHERE `watcher_id` = watcher_id;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE get_whale_watches_for_user(
    IN watcher_id INT
)
BEGIN
    SELECT `id`, `currency`, `alert_amount`
    FROM `whale_watch`
    WHERE `watcher_id` = watcher_id;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE delete_watches(
    IN id INT,
    IN table_name VARCHAR(64),
    IN id_type VARCHAR(64)
)
BEGIN
    SET @sql_text = CONCAT('DELETE FROM ', table_name, ' WHERE ', id_type, ' = ', id);

    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE check_prices(
    IN curr1 VARCHAR(10),
    IN curr2 VARCHAR(10),
    IN data_from VARCHAR(30)
)
BEGIN
    SELECT `price_date`, `base`, `target`, `high`, `low`, `day_open`, `day_close`, `data_source`
    FROM `price_history`
    WHERE `base` = curr1 AND `target` = curr2 and `data_source` = data_from
    ORDER BY `price_date` DESC
    LIMIT 10;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE check_prices_all(
    IN curr1 VARCHAR(10),
    IN curr2 VARCHAR(10)
)
BEGIN
    SELECT `price_date`, `base`, `target`, `high`, `low`, `day_open`, `day_close`, `data_source`
    FROM `price_history`
    WHERE `base` = curr1 AND `target` = curr2
    ORDER BY `price_date` DESC
    LIMIT 10;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE check_prices_avg(
    IN curr1 VARCHAR(10),
    IN curr2 VARCHAR(10)
)
BEGIN
    SELECT `price_date` AS 'Date', `base` AS 'Base', `target` AS 'Target',
    avg(`high`) as 'Average High', avg(`low`) AS 'Average Low', avg(`day_open`) AS 'Average Open', avg(`day_close`) as 'Average Close'
    FROM `price_history`
    WHERE `base` = curr1 AND `target` = curr2
    GROUP BY `price_date`
    ORDER BY `price_date` DESC
    LIMIT 10;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE create_trade(
    IN buyer_id        INT,
    IN seller_id       INT,
    IN base_currency   VARCHAR(10),
    IN target_currency VARCHAR(10),
    IN base_amount     INT,
    IN target_amount   INT
)
BEGIN
    INSERT INTO `trade` (
        `buyer_id`,
        `seller_id`,
        `base_currency`,
        `target_currency`,
        `base_amount`,
        `target_amount`
    ) VALUES (
        buyer_id,
        seller_id,
        base_currency,
        target_currency,
        base_amount,
        target_amount
    );
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_trade_meets_watch AFTER INSERT
ON trade
FOR EACH ROW
BEGIN
    DECLARE currency_watched VARCHAR(10);
    DECLARE watch_id INT;
    DECLARE amount_watched INT;
    DECLARE row_not_found TINYINT DEFAULT FALSE;
    DECLARE watches_cursor CURSOR FOR
        SELECT id, currency, alert_amount
        FROM whale_watch
        WHERE currency = NEW.base_currency OR currency = NEW.target_currency;
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET row_not_found = TRUE;
    OPEN watches_cursor;

    WHILE row_not_found = FALSE DO
        FETCH watches_cursor INTO watch_id, currency_watched, amount_watched;
        IF (currency_watched = NEW.base_currency) AND (NEW.base_amount >= amount_watched) THEN
                UPDATE whale_watch
                SET criteria_met = 1
                WHERE id = watch_id;
        ELSEIF (currency_watched = NEW.target_currency) AND (NEW.target_amount >= amount_watched) THEN
                UPDATE whale_watch
                SET criteria_met = 1
                WHERE id = watch_id;
        END IF;
    END WHILE;
    CLOSE watches_cursor;
END //
DELIMITER ;
