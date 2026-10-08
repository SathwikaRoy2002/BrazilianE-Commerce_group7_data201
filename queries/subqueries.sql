-- =====================================================================
-- subqueries.sql - 2 basic and 2 advanced subquery queries (Aimaan Khan)
-- Run after 01_load, 02_schema and 03_Cleaning.
-- Uses only what we have covered: SELECT, WHERE, aggregates, GROUP BY,
-- HAVING, joins with aliases, and subqueries (scalar, IN, in FROM, EXISTS).
-- =====================================================================
USE olist;


-- ---------------------------------------------------------------------
-- BASIC 1 - scalar subquery in WHERE
-- Which payments are bigger than the average payment? (top 10)
-- ---------------------------------------------------------------------
SELECT   order_id,
         payment_type,
         installments,
         payment_value
FROM     payment
WHERE    payment_value > (SELECT AVG(payment_value) FROM payment)   -- inner query returns one number (~154.10)
ORDER BY payment_value DESC
LIMIT    10;
-- The inner query runs first and gives the average, the outer query keeps rows above it.
-- 31,012 of the 103,886 payments are above average; the largest is 13,664.08 by credit card.


-- ---------------------------------------------------------------------
-- BASIC 2 - nested IN subqueries
-- Which states have the most customers who gave a 1-star review?
-- ---------------------------------------------------------------------
SELECT   z.state,
         COUNT(DISTINCT c.customer_unique_id) AS unhappy_customers
FROM     customer c
JOIN     zip_code z ON z.zip_code_prefix = c.zip_code_prefix
WHERE    c.customer_id IN (
            SELECT o.customer_id
            FROM   orders o
            WHERE  o.order_id IN (
                     SELECT orv.order_id
                     FROM   order_review orv
                     WHERE  orv.review_id IN (SELECT review_id FROM review WHERE score = 1)))
GROUP BY z.state
ORDER BY unhappy_customers DESC;
-- Works from the inside out: 1-star reviews -> their orders -> the customers who placed them.
-- customer_unique_id is counted so a person with several orders is counted once. SP (3,965) and RJ (2,128) lead.


-- ---------------------------------------------------------------------
-- ADVANCED 1 - subquery in FROM (derived table) + nested scalar subquery
-- Which sellers earn more than the average seller? (top 10 by revenue)
-- ---------------------------------------------------------------------
SELECT   s.seller_id,
         s.city,
         z.state,
         t.orders_sold,
         t.revenue
FROM     (SELECT   seller_id,
                   COUNT(DISTINCT order_id)  AS orders_sold,
                   SUM(quantity * unit_price) AS revenue
          FROM     order_item
          GROUP BY seller_id) t                          -- derived table: one row per seller
JOIN     seller s   ON s.seller_id = t.seller_id
JOIN     zip_code z ON z.zip_code_prefix = s.zip_code_prefix
WHERE    t.revenue > (SELECT AVG(seller_rev)
                      FROM  (SELECT   SUM(quantity * unit_price) AS seller_rev
                             FROM     order_item
                             GROUP BY seller_id) x)      -- average of the per-seller totals
ORDER BY t.revenue DESC
LIMIT    10;
-- AVG(SUM(...)) is not allowed in SQL, so the per-seller totals are built in a subquery first
-- and then averaged. Only 628 of 3,095 sellers beat the average; the top one is in Guariba, SP.


-- ---------------------------------------------------------------------
-- ADVANCED 2 - IN with GROUP BY/HAVING + correlated NOT EXISTS
-- Which loyal customers (3+ orders) never gave a review below 4 stars?
-- ---------------------------------------------------------------------
SELECT   c.customer_unique_id,
         z.state,
         COUNT(*) AS orders_placed                       -- each customer_id row is one order
FROM     customer c
JOIN     zip_code z ON z.zip_code_prefix = c.zip_code_prefix
WHERE    c.customer_unique_id IN (
            SELECT   customer_unique_id
            FROM     customer
            GROUP BY customer_unique_id
            HAVING   COUNT(*) >= 3)                      -- people with 3 or more orders
  AND    NOT EXISTS (
            SELECT 1
            FROM   customer c2
            JOIN   orders o         ON o.customer_id = c2.customer_id
            JOIN   order_review orv ON orv.order_id  = o.order_id
            JOIN   review r         ON r.review_id   = orv.review_id
            WHERE  c2.customer_unique_id = c.customer_unique_id   -- correlated: links to the outer row
              AND  r.score < 4)
GROUP BY c.customer_unique_id, z.state
ORDER BY orders_placed DESC;
-- The NOT EXISTS subquery re-runs for each outer customer and drops anyone with a review under 4.
-- Olist gives a new customer_id per order, so customer_unique_id is what identifies a repeat buyer.
