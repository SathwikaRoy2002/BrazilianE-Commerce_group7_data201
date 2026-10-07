-- =====================================================================
-- joins.sql - basic and advanced join queries (Drumil)
-- Fixed to match our schema in 02_schema.sql. 
-- =====================================================================
USE olist;


-- ---------------------------------------------------------------------
-- 1. INNER JOIN - each order with the customer who placed it
-- ---------------------------------------------------------------------
SELECT   o.order_id,
         o.purchase_ts,
         c.customer_unique_id,
         c.city
FROM     orders o
INNER JOIN customer c
         ON o.customer_id = c.customer_id
ORDER BY o.purchase_ts
LIMIT    20;

-- This query combines the orders and customer tables to show each order along with the customer who placed it.
-- INNER JOIN returns only rows that match in both tables.
-- FROM orders o starts with the orders table, INNER JOIN customer c brings in the customer table,
-- and ON o.customer_id = c.customer_id pairs each order with the customer that has the same ID.
-- Our customer table has no name column, so customer_unique_id and city identify the customer.


-- ---------------------------------------------------------------------
-- 2. LEFT JOIN - every order and its review, including orders with no review
-- ---------------------------------------------------------------------
SELECT   o.order_id,
         o.order_status,
         orv.review_id
FROM     orders o
LEFT JOIN order_review orv
         ON o.order_id = orv.order_id
WHERE    orv.review_id IS NULL;

-- LEFT JOIN keeps every row from the left table (orders) even when there is no matching review.
-- For orders without a review the review_id column comes back as NULL, and the WHERE keeps only those rows.
-- (customer LEFT JOIN orders would never show a NULL here, because Olist gives every order its own customer_id.)


-- ---------------------------------------------------------------------
-- 3. ADVANCED - multiple joins with GROUP BY and HAVING
-- Customers who spent more than 500 in total, highest spender first
-- ---------------------------------------------------------------------
select c.customer_unique_id,
         count(distinct o.order_id) as orders_placed,
         sum(oi.quantity * oi.unit_price) as total_spent
         from customer c
         join orders o on c.customer_id = o.customer_id
         join order_item oi on o.order_id = oi.order_id
         group by c.customer_unique_id
         order by total_spent desc;

-- This query joins customer, orders and order_item to calculate the total amount each customer spent.
-- The price is stored in order_item (unit_price), so the products table is not needed here.
-- 1. the joins give one row per item bought
-- 2. GROUP BY puts the rows of each customer together and SUM adds up quantity * unit_price
-- 3. HAVING SUM > 500 keeps only the customers whose total is above 500
-- customer_unique_id is used because one person gets a new customer_id for every order.


-- ---------------------------------------------------------------------
-- 4. ADVANCED - join with a subquery (most recent order per customer)
-- ---------------------------------------------------------------------
select c.customer_unique_id,
         o.order_id,
         o.purchase_ts
FROM     customer c
JOIN     orders o
         on c.customer_id = o.customer_id
join (select c2.customer_unique_id,
                   MAX(o2.purchase_ts) AS last_date
          FROM     customer c2
          join orders o2 on c2.customer_id = o2.customer_id
          GROUP BY c2.customer_unique_id) lo
         ON  c.customer_unique_id = lo.customer_unique_id
         AND o.purchase_ts        = lo.last_date
ORDER BY o.purchase_ts DESC
LIMIT    20;

-- This query finds the most recent order placed by each customer.
-- The subquery first finds the latest purchase date for every customer (a temporary table named lo, latest order),
-- and the main query joins it back to orders on both the customer and the date to get the matching order.
