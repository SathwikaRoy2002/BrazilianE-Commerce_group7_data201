-- ----------------------------------------------------------------------
-- 01_load.sql
-- Step 1 of 4: load the 9 raw Olist CSV files into load tables
-- Run from the repository root (so the relative data/ paths resolve):
--   mysql --local-infile=1 -u root -p < sql/01_load.sql
-- Server must allow it once:  SET GLOBAL local_infile = 1;
-- ----------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS olist
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

DROP TABLE IF EXISTS stg_customers, stg_geolocation, stg_order_items,
  stg_payments, stg_reviews, stg_orders, stg_products, stg_sellers,
  stg_category_translation;

CREATE TABLE stg_customers (
  customer_id              VARCHAR(35),
  customer_unique_id       VARCHAR(40),
  customer_zip_code_prefix VARCHAR(10),
  customer_city            VARCHAR(100),
  customer_state           VARCHAR(50)
);

CREATE TABLE stg_geolocation (
  geolocation_zip_code_prefix VARCHAR(10),
  geolocation_lat             VARCHAR(40),
  geolocation_lng             VARCHAR(40),
  geolocation_city            VARCHAR(100),
  geolocation_state           VARCHAR(50)
);

CREATE TABLE stg_order_items (
  order_id            VARCHAR(35),
  order_item_id       VARCHAR(6),
  product_id          VARCHAR(40),
  seller_id           VARCHAR(40),
  shipping_limit_date VARCHAR(30),
  price               VARCHAR(25),
  freight_value       VARCHAR(25)
);

CREATE TABLE stg_payments (
  order_id             VARCHAR(35),
  payment_sequential   VARCHAR(6),
  payment_type         VARCHAR(25),
  payment_installments VARCHAR(6),
  payment_value        VARCHAR(25)
);

CREATE TABLE stg_reviews (
  review_id               VARCHAR(35),
  order_id                VARCHAR(35),
  review_score            VARCHAR(6),
  review_comment_title    TEXT,
  review_comment_message  TEXT,
  review_creation_date    VARCHAR(30),
  review_answer_timestamp VARCHAR(30)
);

CREATE TABLE stg_orders (
  order_id                      VARCHAR(35),
  customer_id                   VARCHAR(35),
  order_status                  VARCHAR(30),
  order_purchase_timestamp      VARCHAR(35),
  order_approved_at             VARCHAR(35),
  order_delivered_carrier_date  VARCHAR(35),
  order_delivered_customer_date VARCHAR(35),
  order_estimated_delivery_date VARCHAR(35)
);

CREATE TABLE stg_products (
  product_id                 VARCHAR(35),
  product_category_name      VARCHAR(150),
  product_name_lenght        VARCHAR(20),   -- typo is in the source file
  product_description_lenght VARCHAR(20),
  product_photos_qty         VARCHAR(20),
  product_weight_g           VARCHAR(20),
  product_length_cm          VARCHAR(20),
  product_height_cm          VARCHAR(20),
  product_width_cm           VARCHAR(20)
);

CREATE TABLE stg_sellers (
  seller_id              VARCHAR(35),
  seller_zip_code_prefix VARCHAR(15),
  seller_city            VARCHAR(100),
  seller_state           VARCHAR(50)
);

CREATE TABLE stg_category_translation (
  product_category_name         VARCHAR(150),
  product_category_name_english VARCHAR(150)
);

-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'data/olist_customers_dataset.csv' INTO TABLE stg_customers
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_geolocation_dataset.csv' INTO TABLE stg_geolocation
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_order_items_dataset.csv' INTO TABLE stg_order_items
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_order_payments_dataset.csv' INTO TABLE stg_payments
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_order_reviews_dataset.csv' INTO TABLE stg_reviews
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_orders_dataset.csv' INTO TABLE stg_orders
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_products_dataset.csv' INTO TABLE stg_products
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/olist_sellers_dataset.csv' INTO TABLE stg_sellers
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/product_category_name_translation.csv' INTO TABLE stg_category_translation
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
  LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

-- Raw row counts (expected: 99441, 1000163, 112650, 103886, 99224,
-- 99441, 32951, 3095, 71  => 1,550,922 rows in total)
SELECT 'stg_customers' AS tbl, COUNT(*) AS n FROM stg_customers
UNION ALL SELECT 'stg_geolocation', COUNT(*) FROM stg_geolocation
UNION ALL SELECT 'stg_order_items', COUNT(*) FROM stg_order_items
UNION ALL SELECT 'stg_payments', COUNT(*) FROM stg_payments
UNION ALL SELECT 'stg_reviews', COUNT(*) FROM stg_reviews
UNION ALL SELECT 'stg_orders', COUNT(*) FROM stg_orders
UNION ALL SELECT 'stg_products', COUNT(*) FROM stg_products
UNION ALL SELECT 'stg_sellers', COUNT(*) FROM stg_sellers
UNION ALL SELECT 'stg_category_translation', COUNT(*) FROM stg_category_translation;
