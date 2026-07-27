-- Step 1 : Profiling 
-- Check NULL values across all attributes
SELECT
    COUNT(*) AS total_rows,
    COUNTIF(product_id IS NULL) AS null_product_id,
    COUNTIF(product_code IS NULL) AS null_porduct_code,
    COUNTIF(product_name IS NULL) AS null_product_name,
    COUNTIF(brand IS NULL) AS null_brand,
    COUNTIF(category IS NULL) AS null_category,
    COUNTIF(price IS NULL) AS null_price
FROM `raw_product`; 
-- Check variation in brand name
SELECT
    brand,
    COUNT(*) AS num_brand
FROM `raw_product`
GROUP BY brand
ORDER BY num_brand ASC
LIMIT 20; 
-- Check variation in category name
SELECT
    category,
    COUNT(*) AS num_category
FROM `raw_product`
GROUP BY category
ORDER BY num_category ASC
LIMIT 20;

-- Check for duplicate product codes
SELECT
    product_code,
    COUNT(*) AS num_duplicate
FROM `raw_product`
GROUP BY product_code
HAVING COUNT(*) > 1;
 
-- Step 2 : Cleaning & Transformation
 -- Create clean table
CREATE OR REPLACE TABLE `clean_product` AS

-- Deduplicate records keeping the earliest product code
WITH deduplication AS (
    SELECT
	*,
	ROW_NUMBER() OVER(
	PARTITION BY product_id
	ORDER BY product_code ASC
	) AS row_num
    FROM `raw_product`
)

SELECT
    product_id,
    product_code,
    product_name,
    brand,

    -- 1. Standardize category
    CASE
	WHEN category = 'Mebutuhan Rumah Tangga' THEN 'Kebutuhan Rumah Tangga'
	ELSE INITCAP(TRIM(category))
    END AS clean_category, 
    price

FROM deduplication
WHERE row_num = 1; 
-- Step 3 : Data Validation 
-- Inspect cleaned sample output
SELECT *
FROM `clean_product`
LIMIT 10;
