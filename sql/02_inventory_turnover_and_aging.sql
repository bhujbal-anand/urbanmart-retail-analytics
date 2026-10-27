-- =====================================================================
-- URBANMART: INVENTORY HEALTH & STOCK TURNOVER OPTIMIZATION
-- CTEs, Stock Aging Matrix, and Stagnant Inventory Identification
-- Prepared by: Anand Bhujbal
-- =====================================================================

USE urbanmart_retail;

-- 1. IDENTIFY SLOW-MOVING & STAGNANT INVENTORY (Weeks of Supply > 18)
WITH latest_snapshot AS (
    SELECT 
        i.sku_id,
        p.product_name,
        p.category,
        i.current_stock,
        i.weekly_sales_rate,
        i.weeks_of_supply,
        i.inventory_value,
        CASE 
            WHEN i.weeks_of_supply < 10 THEN 'Healthy (<10 wks)'
            WHEN i.weeks_of_supply BETWEEN 10 AND 18 THEN 'Moderate (10-18 wks)'
            ELSE 'High Risk / Stagnant (>18 wks)'
        END AS inventory_status_tier
    FROM inventory_snapshots i
    INNER JOIN products p ON p.sku_id = i.sku_id
    WHERE i.snapshot_date = (SELECT MAX(snapshot_date) FROM inventory_snapshots)
)
SELECT 
    category,
    inventory_status_tier,
    COUNT(sku_id) AS total_skus,
    SUM(current_stock) AS total_units_in_stock,
    SUM(inventory_value) AS tied_up_capital_usd
FROM latest_snapshot
GROUP BY category, inventory_status_tier
ORDER BY category, tied_up_capital_usd DESC;

-- 2. ANNUAL INVENTORY TURNOVER RATIO BY CATEGORY
WITH category_cogs AS (
    SELECT 
        p.category,
        SUM(oi.cost_of_goods) AS annual_cogs
    FROM order_items oi
    INNER JOIN products p ON p.sku_id = oi.sku_id
    INNER JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY p.category
),
category_avg_inv AS (
    SELECT 
        p.category,
        AVG(i.inventory_value) AS avg_inventory_value
    FROM inventory_snapshots i
    INNER JOIN products p ON p.sku_id = i.sku_id
    WHERE i.snapshot_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY p.category
)
SELECT 
    c.category,
    ROUND(c.annual_cogs, 2) AS annual_cogs_usd,
    ROUND(a.avg_inventory_value, 2) AS avg_inventory_usd,
    ROUND(c.annual_cogs / NULLIF(a.avg_inventory_value, 0), 2) AS inventory_turnover_ratio,
    ROUND(365 / NULLIF(c.annual_cogs / NULLIF(a.avg_inventory_value, 0), 0), 1) AS days_sales_of_inventory
FROM category_cogs c
INNER JOIN category_avg_inv a ON a.category = c.category
ORDER BY inventory_turnover_ratio DESC;
