-- =====================================================================
-- URBANMART: CUSTOMER LIFETIME VALUE (CLV) & REPEAT PURCHASE CADENCE
-- Window Functions (RANK, ROW_NUMBER, LAG) & RFM Segmentation
-- Prepared by: Anand Bhujbal
-- =====================================================================

USE urbanmart_retail;

-- 1. CUSTOMER ORDER CADENCE (Inter-Purchase Days using LAG)
WITH customer_orders_seq AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
    FROM orders
),
purchase_intervals AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        prev_order_date,
        DATEDIFF(order_date, prev_order_date) AS days_between_orders
    FROM customer_orders_seq
    WHERE prev_order_date IS NOT NULL
)
SELECT 
    customer_id,
    COUNT(order_id) AS repeat_orders_count,
    ROUND(AVG(days_between_orders), 1) AS avg_days_between_purchases
FROM purchase_intervals
GROUP BY customer_id
ORDER BY repeat_orders_count DESC
LIMIT 20;

-- 2. CUSTOMER LIFETIME VALUE (CLV) & RFM VALUE TIERS
WITH customer_aggregates AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.region,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.total_revenue) AS total_spend,
        ROUND(AVG(oi.total_revenue), 2) AS average_order_value,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date)) AS recency_days
    FROM customers c
    INNER JOIN orders o ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, c.customer_name, c.region
),
ranked_customers AS (
    SELECT 
        customer_id,
        customer_name,
        region,
        total_orders,
        total_spend,
        average_order_value,
        recency_days,
        RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
        PERCENT_RANK() OVER (ORDER BY total_spend) AS spend_percentile
    FROM customer_aggregates
)
SELECT 
    customer_id,
    customer_name,
    region,
    total_orders,
    total_spend,
    average_order_value,
    recency_days,
    CASE 
        WHEN spend_percentile >= 0.90 THEN 'Tier 1: Platinum VIP'
        WHEN spend_percentile >= 0.70 THEN 'Tier 2: Gold Loyal'
        WHEN spend_percentile >= 0.40 THEN 'Tier 3: Silver Core'
        ELSE 'Tier 4: Bronze Standard'
    END AS customer_tier
FROM ranked_customers
ORDER BY total_spend DESC;
