-- cleaning the dataset 


use olist;
set foreign_key_checks = 1;


--  1. category 
-- loading 71 categories from files. A couple of categories show up in product but never made it to file 
-- therefore the second insert picks up the part which is missing or else foreign key will fail\


INSERT INTO category (category_name, category_name_en)
SELECT TRIM(product_category_name), TRIM(product_category_name_english)
From stg_category_translation;



INSERT INTO category (category_name, category_name_en)
SELECT TRIM(product_category_name), TRIM(product_category_name)
from stg_products
where trim(product_category_name)  <> ''
    and trim(product_category_name) not in (SELECT category_name from category)
group by trim(product_category_name);



update category
set category_name_en = 'portable_kitchen_food_preparers'
where category_name = 'portateis_cozinha_e_preparadores_de_alimentos';


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- 2. zip code (one row per zip prefix)

-- zip is stored as numbers so the leading(starting zeros) got dropped for example (1037 should be 01037)

-- some of zip have more than 1 state attached example 04011 shows up in sao paulo and Acre
-- we count every geolocation customer and seller f=row for zip 

-- latitude and longitude is avg of distinct points for each zip
--  some zip are used by customer or seller but they arent in geolocation so we will keep them with null coordinates so the foreign key will work


insert into zip_code(zip_code_prefix,state, latitude, longitude, geo_points)
with all_states as (
    select LPAD(geolocation_zip_code_prefix,5,'0') as zip, geolocation_state as st from stg_geolocation
    union all 
    select LPAD(customer_zip_code_prefix,5,'0'), customer_state from stg_customers
    union all 
    select LPAD(seller_zip_code_prefix,5,'0'), seller_state from stg_sellers),

state_vote as (
    select zip, st,
                    ROW_NUMBER() OVER (PARTITION BY zip order by count(*) DESC, st) as rn
                    from all_states
                    group by zip, st
    
),

geo_points as (
    select distinct LPAD(geolocation_zip_code_prefix,5,'0') as zip,
        CAST(geolocation_lat as decimal(12,8)) as lat,
        CAST(geolocation_lng as decimal(12,8)) as lng
    from stg_geolocation
    where CAST(geolocation_lat as decimal(12,8)) between -33.75 and 5.27
        and CAST(geolocation_lng as decimal(12,8)) between -73.99 and -34.79


),

geo as (
    select zip, avg(lat) as lat, avg(lng) as lng, count(*) as n
    from geo_points
    group by zip
)

select v.zip, v.st,g.lat,g.lng, coalesce(g.n,0)
from state_vote v
LEFT JOIN geo g on g.zip = v.zip
where v.rn = 1;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 


--  3. customer 
-- state isnt stored here . we get it by joining zip code
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

insert into customer(customer_id, customer_unique_id, zip_code_prefix,city)
select customer_id, customer_unique_id,
        LPAD(customer_zip_code_prefix,5,'0'),
        LOWER (TRIM(customer_city))

from stg_customers;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- 4.seller

--  the city column is free text here there are mixed name of same name with different notation 
-- So we keep everything before the first '/', '\', ',' or ' - ' 
--  so we have to clean 
-- email and one zip code typed in city
-- spelling out abbreviations

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

insert into seller ( seller_id, zip_code_prefix,city)
with cleaned as (
    select seller_id,
            LPAD(seller_zip_code_prefix,5,'0') as zip,
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(
                REPLACE(REPLACE(REPLACE(LOWER(TRIM(seller_city)), '?', ''), 
                '’', ''''),
                '´', ''''),
                '/',1),
                 '\\',1),
                ',',1),
                ' - ',1)) as c
                from stg_sellers
)

select seller_id,zip,
    CASE
    -- EMAIL OR ZIP IN CITY FIELD
        WHEN c like '%@%' or c REGEXP '^[0-9]+$' THEN NULL 

        when c like '%-__' then TRIM(LEFT(c, CHAR_LENGTH(c) - 3))    -- 'andira-pr' - > 'andria'

        when c = 'sp' THEN 'sao paulo'
        when c = 'sbc' then 'sao bernardo do campo'
        else c
        end
from cleaned;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- 5. product
--  we will  now fix 'lentgh typo in column name 
--  turn empty string into null 
-- product have 0g weight which is incorrect so we will change that to mull value tpp


insert into product(product_id, category_name, name_length, description_length, photos_qty, weight_g, length_cm, height_cm, width_cm)

select product_id,
    NULLIF(TRIM(product_category_name),''),
    NULLIF(product_name_lenght,''),
    NULLIF(product_description_lenght,''),
    NULLIF(product_photos_qty, ''),
    NULLIF(NULLIF(product_weight_g,''),'0'),
    NULLIF(product_length_cm, ''),
    NULLIF(product_height_cm, ''),
    NULLIF(product_width_cm, '')
from stg_products;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- 6. orders
--  empty timestamp becomes null those values havent been approved shhipped or delivered yet

-- - - -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

insert into orders(order_id,  customer_id, order_status,purchase_ts, approved_ts, delivered_carrier_ts, delivered_customer_ts, estimated_delivery_date)
select order_id, customer_id, order_status,
    order_purchase_timestamp,
    NULLIF(order_approved_at, ''),
    NULLIF(order_delivered_carrier_date, ''),
    NULLIF(order_delivered_customer_date, ''),
    DATE(order_estimated_delivery_date)
from stg_orders;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- 7. shipment

-- one row per order and seller with seller shipping dealine

insert into shipment (order_id, seller_id, shipping_limit_ts)
select order_id, seller_id, MIN(shipping_limit_date)
from stg_order_items
group by order_id, seller_id;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- 8. order items
-- staging has one row per unit, so buying 3 of same product gives 3 rows
--  we therefore collapse those into single row with quantity = 3
-- seller, price, freight are same across rows therefore min just gets one value
-- 


insert into order_item(order_id, product_id,seller_id,quantity, unit_price, unit_freight)
select order_id, product_id, MIN(seller_id), count(*),
        MIN(CAST(price as decimal (10,2))), MIN(CAST(freight_value as decimal(10,2)))

from stg_order_items
group by order_id, product_id;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- 9. payment

-- nothing to clean 

insert into payment(order_id, payment_sequential, payment_type, installments, payment_value)
select order_id, payment_sequential, payment_type, payment_installments, payment_value
from stg_payments;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- 10. review + order review
-- same review can be linked to more than 1 order so we get theoir own table order_review connects the two (2nf split)

insert into review (review_id, score, comment_title, comment_message, creation_date, answer_ts)
select distinct review_id, review_score,
    NULLIF(TRIM(review_comment_title), ''),
    NULLIF(TRIM(review_comment_message), ''),
    DATE(review_creation_date),
    review_answer_timestamp
from stg_reviews;


insert into order_review(order_id, review_id)
select distinct order_id, review_id
from stg_reviews;