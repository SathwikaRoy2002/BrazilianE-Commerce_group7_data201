-- ============================================================================
-- joins.sql
-- five meaningful MySQL queries for the normalized Olist database
--
-- Run this file after:
--   01_load.sql
--   02_schema.sql
--   03_Cleaning.sql
--
-- Query split:
--   Basic 1-2    SELECT, filtering, joins, GROUP BY, and aggregation
--   Advanced 1-2 Joins, aggregation, derived-table subqueries
-- ============================================================================

USE olist;

-- ============================================================================
-- BASIC QUERY 1: Categories with the most products
-- Business question: Which product categories contain the most products?
-- Tables used: category, product
-- Concepts: LEFT JOIN, COUNT, GROUP BY, ORDER BY, LIMIT
-- The LEFT JOIN also keeps categories that currently have zero products.
-- ============================================================================

SELECT
    c.category_name_en AS category,
    COUNT(p.product_id) AS product_count
FROM category AS c
LEFT JOIN product AS p
       ON p.category_name = c.category_name
GROUP BY c.category_name, c.category_name_en
ORDER BY product_count DESC, category
LIMIT 10;


-- ============================================================================
-- BASIC QUERY 2: Delivered orders by customer state
-- Business question: Which Brazilian states have the most delivered orders?
-- Tables used: orders, customer, zip_code
-- Concepts: INNER JOIN, WHERE filtering, COUNT, GROUP BY
-- ============================================================================

SELECT
    z.state,
    COUNT(*) AS delivered_order_count
FROM orders AS o
INNER JOIN customer AS c
        ON c.customer_id = o.customer_id
INNER JOIN zip_code AS z
        ON z.zip_code_prefix = c.zip_code_prefix
WHERE o.order_status = 'delivered'
GROUP BY z.state
ORDER BY delivered_order_count DESC, z.state;


-- ============================================================================
-- ADVANCED QUERY 1: Delivered orders with a five-star review
-- Concepts used: JOINs and a subquery
-- The EXISTS subquery checks whether each order has a five-star review.
-- ============================================================================

SELECT
    c.customer_id,
    c.city,
    o.order_id,
    o.order_status
FROM customer AS c
INNER JOIN orders AS o
        ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND EXISTS (
      SELECT 1
      FROM order_review AS orv
      INNER JOIN review AS r
              ON r.review_id = orv.review_id
      WHERE orv.order_id = o.order_id
        AND r.score = 5
  )
ORDER BY o.order_id;

-- ============================================================================
-- ADVANCED QUERY 2: Items priced above the overall average
-- Concepts used: a JOIN and a simple aggregate subquery
-- The subquery finds the average item price, and the main query returns
-- seller and product details for items priced higher than that average.
-- ============================================================================

SELECT
    s.seller_id,
    s.city AS seller_city,
    i.product_id,
    i.unit_price
FROM seller AS s
INNER JOIN order_item AS i
        ON i.seller_id = s.seller_id
WHERE i.unit_price > (
    SELECT AVG(unit_price)
    FROM order_item
)
ORDER BY i.unit_price DESC;