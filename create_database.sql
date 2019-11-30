CREATE DATABASE IF NOT EXISTS CryptoTracker;
USE CryptoTracker;

-- TABLES ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS currencies (
    abbrev VARCHAR(10) PRIMARY KEY,
    name   VARCHAR(64)
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
    CONSTRAINT history_base_fk FOREIGN KEY (base) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT history_target_fk FOREIGN KEY (target) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS exchanges (
    name    VARCHAR(256) PRIMARY KEY,
    website VARCHAR(256),
    country VARCHAR(256)
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

-- PROCEDURES/FUNCTIONS/TRIGGERS ----------------------------------------------

DELIMITER //
CREATE PROCEDURE write_price_history(
    IN price_date DATE,
    IN base       VARCHAR(10),
    IN target     VARCHAR(10),
    IN high       INT,
    IN low        INT,
    IN day_open   INT,
    IN day_close  INT
)
BEGIN
    INSERT INTO `price_history` (
        `price_date`,
        `base`,
        `target`,
        `high`,
        `low`,
        `day_open`,
        `day_close`
    ) VALUES (
        price_date,
        base,
        target,
        high,
        low,
        day_open,
        day_close
    );
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
        0
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
CREATE FUNCTION check_price_watch_criteria(
    pwid INT
)
RETURNS TINYINT
DETERMINISTIC CONTAINS SQL
BEGIN
    DECLARE base VARCHAR(10);
    DECLARE target VARCHAR(10);
    DECLARE base_amt INT;
    DECLARE history_id INT;

    SELECT `base_currency`, `target_currency`, `base_amount`
    INTO base, target, base_amt
    FROM `price_watch`
    WHERE `id` = pwid;

    SELECT `id`
    INTO history_id
    FROM `price_history`
    WHERE `base` = base AND `target` = target AND `high` >= base_amt AND `low` <= base_amt;

    IF history_id = NULL THEN
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
