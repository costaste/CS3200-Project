CREATE DATABASE IF NOT EXISTS CryptoTracker;
USE CryptoTracker;

CREATE TABLE IF NOT EXISTS price_history (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    price_date DATE NOT NULL,
    high       INT NOT NULL,
    low        INT NOT NULL,
    day_open   INT NOT NULL,
    day_close  INT NOT NULL
);

