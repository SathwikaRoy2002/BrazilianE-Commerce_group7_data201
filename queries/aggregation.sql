-- =====================================================================

-- 2 basic + 2 advanced aggregation queries on the normalized Olist schema
-- =====================================================================

USE olist;

-- ---------------------------------------------------------------------
-- BASIC 1. Number of orders per order status
-- ---------------------------------------------------------------------
SELECT order_status,
       COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- ---------------------------------------------------------------------
-- BASIC 2. Total and average payment value per payment type
-- ---------------------------------------------------------------------
SELECT payment_type,
       COUNT(*)                     AS payment_count,
       ROUND(SUM(payment_value), 2) AS total_value,
       ROUND(AVG(payment_value), 2) AS avg_value
FROM payment
GROUP BY payment_type
ORDER BY total_value DESC;

-- ---------------------------------------------------------------------
-- ADVANCED 3. Product categories with at least 100,000 in revenue
-- ---------------------------------------------------------------------
SELECT c.category_name_en                          AS category,
       COUNT(DISTINCT o.order_id)                  AS order_count,
       SUM(oi.quantity)                            AS units_sold,
       ROUND(SUM(oi.quantity * oi.unit_price), 2)  AS revenue
FROM order_item oi
JOIN orders   o ON oi.order_id     = o.order_id
JOIN product  p ON oi.product_id   = p.product_id
JOIN category c ON p.category_name = c.category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.category_name, c.category_name_en
HAVING SUM(oi.quantity * oi.unit_price) >= 100000
ORDER BY revenue DESC;

-- ---------------------------------------------------------------------
-- ADVANCED 4. Sellers that ship late too often
-- ---------------------------------------------------------------------
SELECT s.seller_id,
       z.state,
       COUNT(*)                                                           AS shipments,
       SUM(o.delivered_carrier_ts > sh.shipping_limit_ts)                 AS late_shipments,
       ROUND(100 * AVG(o.delivered_carrier_ts > sh.shipping_limit_ts), 1) AS late_pct
FROM shipment sh
JOIN orders   o ON sh.order_id       = o.order_id
JOIN seller   s ON sh.seller_id      = s.seller_id
JOIN zip_code z ON s.zip_code_prefix = z.zip_code_prefix
WHERE o.order_status = 'delivered'
  AND o.delivered_carrier_ts IS NOT NULL
GROUP BY s.seller_id, z.state
HAVING COUNT(*) >= 30
   AND AVG(o.delivered_carrier_ts > sh.shipping_limit_ts) > 0.10
ORDER BY late_pct DESC
LIMIT 10;
