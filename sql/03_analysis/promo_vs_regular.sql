SELECT 
    sales_type,
    
    -- Order & Volume Metrics
    COUNT(DISTINCT sales_code) AS total_orders,
    SUM(sales_quantity) AS total_units_sold,
    
    -- Financial Metrics
    CAST(ROUND(SUM(revenue), 2) AS NUMERIC) AS total_revenue,

    -- Customer Basket Metrics
    ROUND(SUM(revenue) / COUNT(DISTINCT sales_code), 2) AS avg_order_value,
    ROUND(SUM(sales_quantity) / COUNT(DISTINCT sales_code), 2) AS avg_units_per_order

FROM `sales_summary`
GROUP BY sales_type
ORDER BY total_revenue DESC;
