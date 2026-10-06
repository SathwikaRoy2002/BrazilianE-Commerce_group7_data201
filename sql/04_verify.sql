-- =====================================================================
-- 04_verify.sql
-- Step 4 of 4: evidence that the load is complete and consistent.
-- =====================================================================
USE olist;

-- V1. Row counts per normalized table
SELECT 'zip_code' AS table_name, COUNT(*) AS row_count FROM zip_code
UNION ALL SELECT 'customer',     COUNT(*) FROM customer
UNION ALL SELECT 'seller',       COUNT(*) FROM seller
UNION ALL SELECT 'category',     COUNT(*) FROM category
UNION ALL SELECT 'product',      COUNT(*) FROM product
UNION ALL SELECT 'orders',       COUNT(*) FROM orders
UNION ALL SELECT 'shipment',     COUNT(*) FROM shipment
UNION ALL SELECT 'order_item',   COUNT(*) FROM order_item
UNION ALL SELECT 'payment',      COUNT(*) FROM payment
UNION ALL SELECT 'review',       COUNT(*) FROM review
UNION ALL SELECT 'order_review', COUNT(*) FROM order_review;

-- V2. Lossless checks: normalized tables reproduce the raw files
SELECT 'order_item units = raw item rows' AS check_name,
       (SELECT SUM(quantity) FROM order_item) AS normalized,
       (SELECT COUNT(*) FROM stg_order_items)  AS raw_source
UNION ALL
SELECT 'item revenue (price) preserved',
       (SELECT SUM(quantity * unit_price) FROM order_item),
       (SELECT SUM(CAST(price AS DECIMAL(10,2))) FROM stg_order_items)
UNION ALL
SELECT 'review-order links = raw review rows',
       (SELECT COUNT(*) FROM order_review),
       (SELECT COUNT(*) FROM stg_reviews)
UNION ALL
SELECT 'distinct reviews',
       (SELECT COUNT(*) FROM review),
       (SELECT COUNT(DISTINCT review_id) FROM stg_reviews);

-- V3. Referential integrity: orphan child rows (all must be 0)
SELECT 'customer -> zip_code' AS fk, COUNT(*) AS orphans
  FROM customer c LEFT JOIN zip_code z ON z.zip_code_prefix = c.zip_code_prefix WHERE z.zip_code_prefix IS NULL
UNION ALL SELECT 'seller -> zip_code', COUNT(*)
  FROM seller s LEFT JOIN zip_code z ON z.zip_code_prefix = s.zip_code_prefix WHERE z.zip_code_prefix IS NULL
UNION ALL SELECT 'product -> category', COUNT(*)
  FROM product p LEFT JOIN category c ON c.category_name = p.category_name
  WHERE p.category_name IS NOT NULL AND c.category_name IS NULL
UNION ALL SELECT 'orders -> customer', COUNT(*)
  FROM orders o LEFT JOIN customer c ON c.customer_id = o.customer_id WHERE c.customer_id IS NULL
UNION ALL SELECT 'order_item -> shipment', COUNT(*)
  FROM order_item i LEFT JOIN shipment s ON s.order_id = i.order_id AND s.seller_id = i.seller_id WHERE s.order_id IS NULL
UNION ALL SELECT 'order_item -> product', COUNT(*)
  FROM order_item i LEFT JOIN product p ON p.product_id = i.product_id WHERE p.product_id IS NULL
UNION ALL SELECT 'payment -> orders', COUNT(*)
  FROM payment p LEFT JOIN orders o ON o.order_id = p.order_id WHERE o.order_id IS NULL
UNION ALL SELECT 'order_review -> review', COUNT(*)
  FROM order_review r LEFT JOIN review v ON v.review_id = r.review_id WHERE v.review_id IS NULL;

-- V4. Declared foreign keys (from the data dictionary)
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'olist'
ORDER BY TABLE_NAME;

-- V5. Data-quality flags kept (not deleted) for analysis
SELECT 'orders with no items (mostly canceled/unavailable)' AS flag,
       COUNT(*) AS n FROM orders o
       WHERE NOT EXISTS (SELECT 1 FROM order_item i WHERE i.order_id = o.order_id)
UNION ALL SELECT 'delivered orders missing delivery date',
       COUNT(*) FROM orders WHERE order_status = 'delivered' AND delivered_customer_ts IS NULL
UNION ALL SELECT 'handed to carrier before purchase (bad timestamp)',
       COUNT(*) FROM orders WHERE delivered_carrier_ts < purchase_ts
UNION ALL SELECT 'products without category',
       COUNT(*) FROM product WHERE category_name IS NULL
UNION ALL SELECT 'zips with no coordinates',
       COUNT(*) FROM zip_code WHERE latitude IS NULL;

-- V6. Sample join across 6 tables (proves the schema is queryable end-to-end)
SELECT o.order_id, z.state, c.city, cat.category_name_en,
       i.quantity, i.unit_price, o.order_status, DATE(o.purchase_ts) AS purchased
FROM orders o
JOIN customer c     ON c.customer_id = o.customer_id
JOIN zip_code z     ON z.zip_code_prefix = c.zip_code_prefix
JOIN order_item i   ON i.order_id = o.order_id
JOIN product p      ON p.product_id = i.product_id
JOIN category cat   ON cat.category_name = p.category_name
ORDER BY o.purchase_ts
LIMIT 5;
