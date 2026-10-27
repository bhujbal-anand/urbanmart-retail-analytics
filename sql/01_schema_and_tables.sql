-- =====================================================================
-- URBANMART RETAIL ANALYTICS & INVENTORY OPTIMIZATION
-- Schema Architecture & Relational Tables (MySQL 8.0)
-- Prepared by: Anand Bhujbal
-- =====================================================================

DROP DATABASE IF EXISTS urbanmart_retail;
CREATE DATABASE urbanmart_retail;
USE urbanmart_retail;

-- 1. PRODUCTS (SKU Master)
CREATE TABLE products (
    sku_id             VARCHAR(20)    PRIMARY KEY,
    product_name       VARCHAR(150)   NOT NULL,
    category           VARCHAR(50)    NOT NULL,
    subcategory        VARCHAR(50)    NOT NULL,
    unit_cost          DECIMAL(10,2)  NOT NULL,
    retail_price       DECIMAL(10,2)  NOT NULL,
    reorder_level      INT            NOT NULL DEFAULT 50,
    target_weeks_supply INT           NOT NULL DEFAULT 8
);

-- 2. CUSTOMERS
CREATE TABLE customers (
    customer_id        VARCHAR(20)    PRIMARY KEY,
    customer_name      VARCHAR(100)   NOT NULL,
    email              VARCHAR(100),
    city               VARCHAR(50)    NOT NULL,
    region             VARCHAR(50)    NOT NULL,
    customer_segment   VARCHAR(30)    DEFAULT 'Standard'
);

-- 3. ORDERS
CREATE TABLE orders (
    order_id           VARCHAR(20)    PRIMARY KEY,
    customer_id        VARCHAR(20)    NOT NULL,
    order_date         DATE           NOT NULL,
    sales_channel      VARCHAR(30)    NOT NULL,
    payment_mode       VARCHAR(30)    NOT NULL,
    shipping_region    VARCHAR(50)    NOT NULL,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 4. ORDER ITEMS (Transactions)
CREATE TABLE order_items (
    item_id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id           VARCHAR(20)    NOT NULL,
    sku_id             VARCHAR(20)    NOT NULL,
    quantity           INT            NOT NULL,
    unit_price         DECIMAL(10,2)  NOT NULL,
    discount_pct       DECIMAL(5,2)   DEFAULT 0.00,
    total_revenue      DECIMAL(12,2)  NOT NULL,
    cost_of_goods      DECIMAL(12,2)  NOT NULL,
    profit             DECIMAL(12,2)  NOT NULL,
    CONSTRAINT fk_item_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_item_product FOREIGN KEY (sku_id) REFERENCES products(sku_id)
);

-- 5. INVENTORY SNAPSHOTS (Weekly Stock Health)
CREATE TABLE inventory_snapshots (
    snapshot_id        BIGINT AUTO_INCREMENT PRIMARY KEY,
    snapshot_date      DATE           NOT NULL,
    sku_id             VARCHAR(20)    NOT NULL,
    current_stock      INT            NOT NULL,
    weekly_sales_rate  DECIMAL(8,2)   NOT NULL,
    weeks_of_supply    DECIMAL(8,2)   NOT NULL,
    inventory_value    DECIMAL(14,2)  NOT NULL,
    CONSTRAINT fk_inv_product FOREIGN KEY (sku_id) REFERENCES products(sku_id)
);

-- Strategic Indexes
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_sku ON order_items(sku_id);
CREATE INDEX idx_inv_snapshot ON inventory_snapshots(snapshot_date, sku_id);
