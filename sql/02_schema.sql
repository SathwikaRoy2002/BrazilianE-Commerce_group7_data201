-- ===========================================================================================
-- 02_schema.sql
-- Step 2 of 4: normalize schema with primary keys, foreign keys and check constraints
-- ===========================================================================================

USE olist;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS order_review,
review,
payment,
order_item,
shipment,
orders,
product,
category,
seller,
customer,
zip_code;

SET FOREIGN_KEY_CHECKS = 1;

-- LOCATION

CREATE TABLE zip_code (
    zip_code_prefix CHAR(5) NOT NULL,
    state CHAR(2) NOT NULL,
    latitude DECIMAL(10, 7) NULL,
    longitude DECIMAL(10, 7) NULL,
    geo_points INT NOT NULL DEFAULT 0,
    PRIMARY KEY (zip_code_prefix) CONSTRAINT chk_zip_lat CHECK (
        latitude IS NULL
        OR latitude BETWEEN -34 AND 6
    ),
    CONSTRAINT chk_zip_lon CHECK (
        longitude IS NULL
        OR longitude BETWEEN -74 AND -34
    )
);

-- PARTIES

CREATE TABLE customer (
    customer_id CHAR(36) NOT NULL,
    customer_unique_id CHAR(36) NOT NULL,
    zip_code_prefix CHAR(5) NOT NULL,
    city VARCHAR(100) NOT NULL,
    PRIMARY KEY (customer_id),
    KEY idx_customer_unique_id (customer_unique_id),
    CONSTRAINT fk_customer_zip FOREIGN KEY (zip_code_prefix) REFERENCES zip_code (zip_code_prefix)
);

CREATE TABLE seller (
    seller_id CHAR(36) NOT NULL,
    zip_code_prefix CHAR(5) NOT NULL,
    city VARCHAR(100) NOT NULL,
    PRIMARY KEY (seller_id),
    CONSTRAINT fk_seller_zip FOREIGN KEY (zip_code_prefix) REFERENCES zip_code (zip_code_prefix)
);

-- SOMETHING

CREATE TABLE category (
    category_name_en VARCHAR(100) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (category_name),
    UNIQUE KEY uq_category_name_en (category_name_en)
);

CREATE TABLE product (
    product_id CHAR(32) NOT NULL,
    category_name VARCHAR(60) NULL,
    name_length SMALLINT NULL,
    description_length SMALLINT NULL,
    photos_qty TINYINT NULL,
    weight_g INT NULL,
    length_cm SMALLINT NULL,
    height_cm SMALLINT NULL,
    width_cm SMALLINT NULL,
    PRIMARY KEY (product_id),
    CONSTRAINT fk_product_category FOREIGN KEY (category_name) REFERENCES category (category_name),
    CONSTRAINT chk_product_weight CHECK (
        weight_g IS NULL
        OR weight_g > 0
    )
);

-- ORDERSSSS

CREATE TABLE orders (
    order_id CHAR(32) NOT NULL,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(12) NOT NULL,
    purchase_ts DATETIME NOT NULL,
    approved_ts DATETIME NULL,
    delivered_carrier_ts DATETIME NULL,
    delivered_customer_ts DATETIME NULL,
    estimated_delivery_date DATE NOT NULL,
    PRIMARY KEY (order_id),
    UNIQUE KEY uq_orders_customer (customer_id),
    KEY idx_orders_purchase (purchase_ts),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
    CONSTRAINT chk_order_status CHECK (
        order_status IN (
            'created',
            'approved',
            'invoiced',
            'processing',
            'shipped',
            'delivered',
            'canceled',
            'unavailable'
        )
    )
);

CREATE TABLE shipment (
    order_id CHAR(32) NOT NULL,
    seller_id CHAR(32) NOT NULL,
    shipping_limit_ts DATETIME NOT NULL,
    PRIMARY KEY (order_id, seller_id),
    KEY idx_shipment_seller (seller_id),
    CONSTRAINT fk_shipment_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_shipment_seller FOREIGN KEY (seller_id) REFERENCES seller (seller_id)
);

CREATE TABLE order_item (
    order_id CHAR(32) NOT NULL,
    product_id CHAR(32) NOT NULL,
    seller_id CHAR(32) NOT NULL,
    quantity TINYINT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    unit_freight DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    KEY idx_item_product (product_id),
    CONSTRAINT fk_item_shipment FOREIGN KEY (order_id, seller_id) REFERENCES shipment (order_id, seller_id),
    CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES product (product_id),
    CONSTRAINT chk_item_qty CHECK (quantity >= 1),
    CONSTRAINT chk_item_price CHECK (
        unit_price > 0
        AND unit_freight >= 0
    )
);

CREATE TABLE payment (
    order_id CHAR(32) NOT NULL,
    payment_sequential TINYINT NOT NULL,
    payment_type VARCHAR(12) NOT NULL,
    installments TINYINT NOT NULL,
    payment_value DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT chk_payment_type CHECK (
        payment_type IN (
            'credit_card',
            'boleto',
            'voucher',
            'debit_card',
            'not_defined'
        )
    ),
    CONSTRAINT chk_payment_value CHECK (payment_value >= 0)
);

-- REVIEWS

CREATE TABLE review (
    review_id CHAR(32) NOT NULL,
    score TINYINT NOT NULL,
    comment_title VARCHAR(100) NULL,
    comment_message TEXT NULL,
    creation_date DATE NOT NULL,
    answer_ts DATETIME NOT NULL,
    PRIMARY KEY (review_id),
    CONSTRAINT chk_review_score CHECK (score BETWEEN 1 AND 5)
);

CREATE TABLE order_review (
    order_id CHAR(32) NOT NULL,
    review_id CHAR(32) NOT NULL,
    PRIMARY KEY (order_id, review_id),
    KEY idx_order_review_review (review_id),
    CONSTRAINT fk_or_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_or_review FOREIGN KEY (review_id) REFERENCES review (review_id)
);