-- Step 1 : Profiling 
-- Check NULL values across all attributes
SELECT
    COUNT(*) AS total_rows,
    COUNTIF(sales_detail_id IS NULL) AS null_sales_detail_id,
    COUNTIF(sales_code IS NULL) AS null_sales_code,
    COUNTIF(product_id IS NULL) AS null_product_id,
    COUNTIF(promo_id IS NULL) AS null_promo_id,
    COUNTIF(sales_quantity IS NULL) AS null_sales_quantity,
    COUNTIF(sales_price IS NULL) AS null_sales_price
FROM `raw_sales_detail`;

-- Check for duplicate sales codes
SELECT 
    sales_code,
    product_id,
    sales_price,
    COUNT(*) AS num_duplicate
FROM `raw_sales_detail`
GROUP BY
    sales_code, 
    product_id, 
    sales_price
HAVING COUNT(*) > 1;


-- Step 2 : Cleaning & Transformation
 -- Create clean table
CREATE OR REPLACE TABLE `clean_sales_detail` AS

-- Deduplicate records keeping the earliest sales_detail_id
WITH deduplication AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(
            PARTITION BY sales_code, product_id
            ORDER BY sales_detail_id ASC
        ) AS row_num
    FROM `raw_sales_detail`
)

SELECT 
    sales_detail_id,
    sales_code,
    d.product_id,
    d.promo_id,

    -- 1. Change data type and if NULL then fill with 1
    COALESCE(SAFE_CAST(d.sales_quantity AS INT64), 1) AS clean_sales_quantity,

    -- 2. Change data type and if NULL then fill with (product_price * sales_quantity - diskon_percentage)
    COALESCE(
        SAFE_CAST(d.sales_price AS NUMERIC),
        -- If sales_price NULL, count automatic from product & promo table 
        -- (Sales Price = Product Price * (1 - Discount Percentage) * Sales Quantity)
       ROUND(
            SAFE_CAST(p.price AS NUMERIC) 
            * (1 - (IFNULL(SAFE_CAST(pr.discount_percentage AS NUMERIC), 0) / 100)) 
            * COALESCE(SAFE_CAST(d.sales_quantity AS INT64), 1),
            2
        )
    ) AS clean_sales_price

FROM deduplication d
LEFT JOIN `clean_product` p 
    ON d.product_id = p.product_id
LEFT JOIN `clean_promo` pr 
    ON d.promo_id = pr.promo_id
WHERE d.row_num = 1
    AND p.product_id IS NOT NULL;

-- Step 3 : Data Validation 
-- Inspect cleaned sample output
SELECT * 
FROM `clean_sales_detail` 
LIMIT 10;
