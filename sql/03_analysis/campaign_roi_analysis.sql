SELECT 
    promo_id,
    promo_name,
    promo_type,
    discount_percentage,
    
    -- Volume Metrics
    COUNT(DISTINCT sales_code) AS total_orders,
    SUM(sales_quantity) AS total_units_sold,
    
    -- Financial Metrics
    CAST(ROUND(SUM(revenue), 2) AS NUMERIC) AS total_revenue,

    -- % Revenue Contribution among Promo Sales
    ROUND(
        (SUM(revenue) * 100.0) / SUM(SUM(revenue)) OVER(), 2
    ) AS promo_revenue_share_pct,

    -- Basket Metric
    ROUND(SUM(revenue) / COUNT(DISTINCT sales_code), 2) AS avg_order_value

FROM `sales_summary`
WHERE sales_type = 'Promo Sales'
GROUP BY promo_id, promo_name, promo_type, discount_percentage
ORDER BY total_revenue DESC;
