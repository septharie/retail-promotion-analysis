-- Create Sales Summary Table
CREATE OR REPLACE TABLE `sales_summary` AS
SELECT 
    -- Sales & Transaction Header
    sd.sales_detail_id AS sales_summary_id,
    sd.sales_code,
    sh.clean_sales_date AS sales_date,
    sh.clean_sales_time AS sales_time,
    COALESCE(sh.clean_payment_method, 'Unknown') AS payment_method,
    
    -- Store Information
    sh.store_id,
    COALESCE(st.store_name, 'Unknown Store') AS store_name,
    COALESCE(st.clean_city, 'Unknown City') AS store_city,
    COALESCE(st.clean_province, 'Unknown Province') AS store_province,
    
    -- Member Information
    sh.member_id,
    COALESCE(m.clean_member_name, 'Non-Member') AS member_name,
    COALESCE(m.clean_gender, 'Non-Member') AS member_gender,

    -- Customer Segmentation Flag
    CASE 
        WHEN sh.member_id IS NULL OR sh.member_id = 0 THEN 'Non-Member'
        ELSE 'Member'
    END AS customer_type,
    
    -- Product Master Data
    sd.product_id,
    p.product_name,
    p.brand,
    p.clean_category AS category,
    p.price AS original_unit_price,
    
    -- Promotion Details
    sd.promo_id,
    COALESCE(pr.clean_promo_name, 'No Promo') AS promo_name,
    COALESCE(pr.clean_promo_type, 'Regular') AS promo_type,
    COALESCE(pr.discount_percentage, 0) AS discount_percentage,

    -- Promotional Sales Flag
    CASE 
        WHEN sd.promo_id IS NULL OR sd.promo_id = 0 THEN 'Regular Sales'
        ELSE 'Promo Sales'
    END AS sales_type,
    
    -- Sales Metrics
    sd.clean_sales_quantity AS sales_quantity,
    sd.clean_sales_price AS sales_price,
    
    -- Gross Revenue
    (p.price * sd.clean_sales_quantity) AS gross_revenue,

    -- Discount Amount 
    ROUND(
        	(p.price * sd.clean_sales_quantity) * (COALESCE(pr.discount_percentage, 0) / 100.0), 2
	) AS discount_amount,

    -- Net Revenue
    ROUND( 
        	(p.price * sd.clean_sales_quantity) * (1 - (COALESCE(pr.discount_percentage, 0) / 100.0)) , 2
	) AS revenue


FROM `clean_sales_detail` sd
JOIN `clean_sales_header` sh 
    ON sd.sales_code = sh.sales_code
JOIN `clean_product` p 
    ON sd.product_id = p.product_id
LEFT JOIN `clean_promo` pr 
    ON sd.promo_id = pr.promo_id
LEFT JOIN `clean_member` m 
    ON sh.member_id = m.member_id
LEFT JOIN `clean_store` st 
    ON sh.store_id = st.store_id;
