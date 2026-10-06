-- 2 basic queries by DRUMIL

-- 1. this query combines orders and customer tables to show each order along with the name of customer who placed it
--  uses an INNER JOIN so only rows matched in both tables are returned
-- customer without any order are not shown


select o.order_ird, o.order_date, c.name
from orders o 
inner join customer c 
  on o.customer_id = c.customer_id
-- -- -- -- -- -- -- -- ---- -- --  -- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- --
-- 1. this query combines orders and customer tables to show each order along with the name of customer who placed it
--  uses an INNER JOIN so only rows matched in both tables are returned
-- customer without any order are not shown

--  from order o starts with orders table
--  inner join customer c bring in customer table
--  on on o.customer_id = c.customer_id it matches the order to customer with same ID 
--  eg = order 101 has customer_id 1 so its paired 


-- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- --

-- 2. left join

select c.name, o.order_id, o.order_date
from customer c
left join order o
  on customer_id = o.customer_id;


-- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- --
-- 2. this query lists all the customer along with any orders they have placed
-- ituses left join which keeps everything row from the customer table even if there is no match order 
--  for customer who have not placed any order column shows null

-- from customer c makes the customer left table writtenn first 
-- left join order okeeps every row from left table its matches it or not in order
--  if a customer has no matching sql order it still returns customer's row with order filled with columns as NULL


-- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- --


-- 3. Advance queries

select c.name,
  sum(oi.quantity * p.price) as total_spent
from customers c
join order o 
  on c.customer_id = o.customer_id
join order items oi
  on o.order_id = oi.order_id
join products p 
  on oi.product_id = p.product_id
group by c.customer_id, c.name
having sum(oi.quantity * p.price) > 500
order by total_spent desc;

-- multiple joins with group by and having 
--  this query joins four tables (customer orders, order_itens, and products) to calculate total amount each customer has spent.
--  it multiplies quantity by price for every item adds total for each customer using group by and sum 
--  and then by using having to show only customers who spent more than 500 
-- result are sorted from highest to lowest spending

--  its purpose is to find out how much each customer has spent in total and show only customer who spent more than 500, highest spender first

-- we need 4 tables because no single table holds everything 
--  customer name in customer , order placed in orders. what was each orders is in order_items and price in products
-- 1. joins just give all rows 
-- 2. group by pulls customer rows and then sum add ups the total
-- 3. having sum > 500 keeps the group whos total is above 500 

-- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- -- -- -- -- -- -- -- -- -- ---- -- --

select c.name, o.order_id, o.order_date
from customer c
join orders o
  on c.customer_id = o.customer_id
join (
    select customer_id, MAX(order_date) as last_date
    from orders
    group by customer_id
) lo
  on o.customer_id = lo.customer_id
AND o.order_date = lo.last_date;

-- this query finds most recent order placed by each customer. a subquery first finds latest order date for every customer and main query 
 -- then joins this reults back to orders table on both customer ID and date get the matching order. 
-- finally it joins customers table to display customer name

-- the subquery produces a temporary table named as lo (latest order)
-- 
