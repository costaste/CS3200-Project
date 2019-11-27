CREATE DATABASE IF NOT EXISTS CryptoTracker;
USE CryptoTracker;


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
    target_amount   INT NOT NULL DEFAULT 1,
    CONSTRAINT watch_user_fk FOREIGN KEY (watcher_id) REFERENCES users (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT watch_base_fk FOREIGN KEY (base_currency) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT watch_target_fk FOREIGN KEY (target_currency) REFERENCES currencies (abbrev) ON UPDATE CASCADE ON DELETE CASCADE
);

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
