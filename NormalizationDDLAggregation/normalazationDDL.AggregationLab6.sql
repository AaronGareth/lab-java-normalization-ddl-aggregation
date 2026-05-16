-- ============================================================
-- DATABASE NORMALIZATION LAB
-- Exercises 1, 2, and 3
-- ============================================================


-- ============================================================
-- EXERCISE 1: Blog Database (3NF)
-- ============================================================
CREATE DATABASE IF NOT EXISTS normalizationDDLAggregation_lab;

USE normalizationDDLAggregation_lab;

-- Drop tables if re-running (order matters due to FK constraints)
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS authors;

-- Authors table: stores each author exactly once.
-- Eliminates the redundancy of repeating author names across posts.
CREATE TABLE authors (
                         id   INT          PRIMARY KEY AUTO_INCREMENT,
                         name VARCHAR(100) NOT NULL UNIQUE  -- each author name must be unique
);

-- Posts table: references authors via FK.
-- word_count and views depend only on the post (id), not on the author.
CREATE TABLE posts (
                       id          INT          PRIMARY KEY AUTO_INCREMENT,
                       author_id   INT          NOT NULL,
                       title       VARCHAR(255) NOT NULL UNIQUE,                   -- post titles are unique
                       word_count  INT          NOT NULL CHECK (word_count > 0),   -- must be a positive number
                       views       INT          NOT NULL DEFAULT 0
                           CHECK (views >= 0),                -- cannot be negative
                       FOREIGN KEY (author_id) REFERENCES authors(id)
);

-- Index: speeds up lookups like "all posts by a given author"
CREATE INDEX idx_posts_author ON posts(author_id);


-- ------------------------------------------------------------
-- Exercise 1: INSERT sample data
-- ------------------------------------------------------------

INSERT INTO authors (name) VALUES
                               ('Maria Charlotte'),
                               ('Juan Perez'),
                               ('Gemma Alcocer');

-- author_id references: 1=Maria Charlotte, 2=Juan Perez, 3=Gemma Alcocer
INSERT INTO posts (author_id, title, word_count, views) VALUES
                                                            (1, 'Best Paint Colors',           814,  14),
                                                            (2, 'Small Space Decorating Tips', 1146, 221),
                                                            (1, 'Hot Accessories',             986,  105),
                                                            (1, 'Mixing Textures',             765,  22),
                                                            (2, 'Kitchen Refresh',             1242, 307),
                                                            (1, 'Homemade Art Hacks',          1002, 193),
                                                            (3, 'Refinishing Wood Floors',     1571, 7542);


-- ============================================================
-- EXERCISE 2: Airline Database (3NF)
-- ============================================================

-- Drop tables if re-running (order matters due to FK constraints)
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS flights;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS aircrafts;

-- Aircraft models: seat count is a property of the aircraft type,
-- not of any individual flight. Removing it from flights eliminates
-- a transitive dependency (flight_number → aircraft → total_seats).
CREATE TABLE aircrafts (
                           id          INT          PRIMARY KEY AUTO_INCREMENT,
                           name        VARCHAR(100) NOT NULL UNIQUE,                    -- e.g. "Boeing 747"
                           total_seats INT          NOT NULL CHECK (total_seats > 0)    -- must have at least one seat
);

-- Customers: status and total mileage are properties of the customer,
-- not of any booking or flight. Isolating them here removes the
-- massive row duplication seen in the raw dataset.
CREATE TABLE customers (
                           id            INT          PRIMARY KEY AUTO_INCREMENT,
                           name          VARCHAR(100) NOT NULL UNIQUE,
                           status        VARCHAR(20)  NOT NULL DEFAULT 'None'
                               CHECK (status IN ('None', 'Silver', 'Gold')), -- enforces valid tiers
                           total_mileage INT          NOT NULL DEFAULT 0
                               CHECK (total_mileage >= 0)                    -- cannot be negative
);

-- Flights: a flight number maps to exactly one aircraft and one distance.
-- flight_number is the natural key (e.g. "DL143") — no surrogate needed.
CREATE TABLE flights (
                         flight_number VARCHAR(10)  PRIMARY KEY,
                         aircraft_id   INT          NOT NULL,
                         mileage       INT          NOT NULL CHECK (mileage > 0),     -- must be a positive distance
                         FOREIGN KEY (aircraft_id) REFERENCES aircrafts(id)
);

-- Bookings: junction table linking customers to flights.
-- The composite PK (customer_id, flight_number) naturally prevents
-- a customer from being booked on the same flight more than once.
CREATE TABLE bookings (
                          customer_id   INT         NOT NULL,
                          flight_number VARCHAR(10) NOT NULL,
                          PRIMARY KEY (customer_id, flight_number),                    -- composite PK = uniqueness constraint
                          FOREIGN KEY (customer_id)   REFERENCES customers(id),
                          FOREIGN KEY (flight_number) REFERENCES flights(flight_number)
);

-- Indexes: support the most common query patterns
-- "All bookings for a given customer" (used in mileage queries)
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
-- "All customers on a given flight" (used in load/manifest queries)
CREATE INDEX idx_bookings_flight   ON bookings(flight_number);
-- "All flights operated by a given aircraft type"
CREATE INDEX idx_flights_aircraft  ON flights(aircraft_id);


-- ------------------------------------------------------------
-- Exercise 2: INSERT sample data
-- ------------------------------------------------------------

-- aircraft_id auto-assigned: 1=Boeing 747, 2=Airbus A330, 3=Boeing 777
INSERT INTO aircrafts (name, total_seats) VALUES
                                              ('Boeing 747',  400),
                                              ('Airbus A330', 236),
                                              ('Boeing 777',  264);

-- customer_id auto-assigned: 1=Agustine, 2=Alaina, 3=Tom, 4=Sam,
--                             5=Jessica, 6=Ana, 7=Jennifer, 8=Christian
INSERT INTO customers (name, status, total_mileage) VALUES
                                                        ('Agustine Riviera', 'Silver', 115235),
                                                        ('Alaina Sepulvida', 'None',     6008),
                                                        ('Tom Jones',        'Gold',   205767),
                                                        ('Sam Rio',          'None',     2653),
                                                        ('Jessica James',    'Silver', 127656),
                                                        ('Ana Janco',        'Silver', 136773),
                                                        ('Jennifer Cortez',  'Gold',   300582),
                                                        ('Christian Janco',  'Silver',  14642);

-- aircraft_id references: 1=Boeing 747, 2=Airbus A330, 3=Boeing 777
INSERT INTO flights (flight_number, aircraft_id, mileage) VALUES
                                                              ('DL143', 1, 135),
                                                              ('DL122', 2, 4370),
                                                              ('DL53',  3, 2078),
                                                              ('DL222', 3, 1765),
                                                              ('DL37',  1, 531);

-- Bookings deduped from the raw dataset.
-- Each unique (customer, flight) pair appears exactly once.
INSERT INTO bookings (customer_id, flight_number) VALUES
                                                      (1, 'DL143'),  -- Agustine Riviera on DL143
                                                      (1, 'DL122'),  -- Agustine Riviera on DL122
                                                      (2, 'DL122'),  -- Alaina Sepulvida on DL122
                                                      (3, 'DL122'),  -- Tom Jones on DL122
                                                      (3, 'DL53'),   -- Tom Jones on DL53
                                                      (3, 'DL222'),  -- Tom Jones on DL222
                                                      (4, 'DL143'),  -- Sam Rio on DL143
                                                      (4, 'DL37'),   -- Sam Rio on DL37
                                                      (5, 'DL143'),  -- Jessica James on DL143
                                                      (5, 'DL122'),  -- Jessica James on DL122
                                                      (6, 'DL222'),  -- Ana Janco on DL222
                                                      (7, 'DL222'),  -- Jennifer Cortez on DL222
                                                      (8, 'DL222');  -- Christian Janco on DL222


-- ============================================================
-- EXERCISE 3: SQL Queries on the Airline Database
-- ============================================================

-- ------------------------------------------------------------
-- Query 1: Total number of distinct flights
-- ------------------------------------------------------------
SELECT COUNT(DISTINCT flight_number) AS total_flights
FROM flights;
-- Expected result: 5


-- ------------------------------------------------------------
-- Query 2: Average flight distance across all flights
-- ------------------------------------------------------------
SELECT AVG(mileage) AS avg_flight_distance
FROM flights;
-- Expected result: (135 + 4370 + 2078 + 1765 + 531) / 5 = 1775.8


-- ------------------------------------------------------------
-- Query 3: Average number of seats per aircraft type
-- ------------------------------------------------------------
SELECT AVG(total_seats) AS avg_seats_per_aircraft
FROM aircrafts;
-- Expected result: (400 + 236 + 264) / 3 = 300


-- ------------------------------------------------------------
-- Query 4: Average total customer mileage, grouped by status
-- Useful for understanding how engaged each loyalty tier is.
-- ------------------------------------------------------------
SELECT   status,
         AVG(total_mileage) AS avg_mileage
FROM     customers
GROUP BY status;


-- ------------------------------------------------------------
-- Query 5: Max total customer mileage, grouped by status
-- Identifies the highest-mileage customer in each tier.
-- ------------------------------------------------------------
SELECT   status,
         MAX(total_mileage) AS max_mileage
FROM     customers
GROUP BY status;


-- ------------------------------------------------------------
-- Query 6: Count of aircraft whose name contains "Boeing"
-- LIKE with % wildcard matches any string containing "Boeing".
-- ------------------------------------------------------------
SELECT COUNT(*) AS boeing_count
FROM   aircrafts
WHERE  name LIKE '%Boeing%';
-- Expected result: 2 (Boeing 747, Boeing 777)


-- ------------------------------------------------------------
-- Query 7: Flights with distance between 300 and 2000 miles
-- BETWEEN is inclusive on both ends (300 ≤ mileage ≤ 2000).
-- ------------------------------------------------------------
SELECT *
FROM   flights
WHERE  mileage BETWEEN 300 AND 2000;
-- Expected result: DL222 (1765 mi), DL37 (531 mi)
-- Excluded: DL143 (135), DL122 (4370), DL53 (2078)


-- ------------------------------------------------------------
-- Query 8: Average booked flight distance, grouped by customer status
-- Joins bookings → customers (for status) and bookings → flights (for mileage).
-- Shows whether premium-status customers tend to fly longer routes.
-- ------------------------------------------------------------
SELECT   c.status,
         AVG(f.mileage) AS avg_booked_distance
FROM     bookings  b
             JOIN     customers c ON b.customer_id   = c.id
             JOIN     flights   f ON b.flight_number = f.flight_number
GROUP BY c.status;


-- ------------------------------------------------------------
-- Query 9: Most booked aircraft among Gold status customers
-- Traverses: bookings → customers (filter Gold)
--                     → flights → aircrafts
-- GROUP BY aircraft name, order descending, take the top result.
-- ------------------------------------------------------------
SELECT   a.name,
         COUNT(*) AS total_bookings
FROM     bookings  b
             JOIN     customers c ON b.customer_id   = c.id
             JOIN     flights   f ON b.flight_number = f.flight_number
             JOIN     aircrafts a ON f.aircraft_id   = a.id
WHERE    c.status = 'Gold'
GROUP BY a.name
ORDER BY total_bookings DESC
LIMIT    1;
-- Gold customers: Tom Jones → DL122 (A330), DL53 (777), DL222 (777)
--                Jennifer Cortez → DL222 (777)
-- Boeing 777 gets 3 bookings → most booked among Gold status