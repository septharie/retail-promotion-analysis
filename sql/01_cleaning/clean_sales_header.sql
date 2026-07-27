-- Step 1 : Profiling 
-- Check NULL values across all attributes
SELECT 
    COUNT(*) AS total_rows,
    COUNTIF(sales_code IS NULL) AS null_store_code,
    COUNTIF(member_id IS NULL) AS null_member_id,
    COUNTIF(store_id IS NULL) AS null_store_id,
    COUNTIF(sales_date IS NULL) AS null_sales_date,
    COUNTIF(sales_time IS NULL) AS null_sales_time,
    COUNTIF(payment_method IS NULL) AS null_payment_method
FROM `raw_sales_header`;

-- Check variation in date formats
SELECT 
    sales_date, 
    COUNT(*) AS num_date
FROM `raw_sales_header`
GROUP BY sales_date
ORDER BY num_date DESC
LIMIT 20;

-- Check variation in time formats
SELECT 
    sales_time, 
    COUNT(*) AS num_time
FROM `raw_sales_header`
GROUP BY sales_time
ORDER BY num_time DESC
LIMIT 20;

-- Check for duplicate store codes
SELECT 
    store_code, 
    COUNT(*) AS num_duplicate
FROM `raw_sales_header`
GROUP BY store_code
HAVING COUNT(*) > 1;


-- Step 2 : Cleaning & Transformation
 -- Create clean table
CREATE OR REPLACE TABLE `clean_sales_header` AS

-- Deduplicate records keeping the earliest sales_code
WITH deduplication AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(
            PARTITION BY sales_code 
            ORDER BY sales_code ASC
        ) AS row_num
    FROM `raw_sales_header`
)

SELECT 
    sales_code,

    -- 1. change type from float to interger and if NULL then fill with 0
    COALESCE(SAFE_CAST(member_id AS INT64), 0) AS member_id,

    store_id,

    -- 2. Standardize date format
    COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', TRIM(sales_date)),
        SAFE.PARSE_DATE('%Y-%m-%d', REPLACE(TRIM(sales_date), '.', '-')),
        SAFE.PARSE_DATE('%d/%m/%Y', TRIM(sales_date)),
        SAFE.PARSE_DATE('%d-%m-%Y', REPLACE(TRIM(sales_date), '/', '-')),
        SAFE.PARSE_DATE('%d %b %Y', TRIM(sales_date)),
        SAFE.PARSE_DATE('%m/%d/%Y', TRIM(sales_date))
    ) AS clean_sales_date,

    -- 3. Standardize time format
    COALESCE(
        SAFE.PARSE_TIME('%I:%M %p', TRIM(sales_time)),
        SAFE.PARSE_TIME('%I:%M:%S %p', TRIM(sales_time)),
        SAFE.PARSE_TIME('%H:%M:%S', REPLACE(TRIM(sales_time), '.', ':')),
        SAFE.PARSE_TIME('%H:%M', REPLACE(TRIM(sales_time), '.', ':'))
    ) AS clean_sales_time,
    
    -- 4. Filling NULL with 'Unknown'
    COALESCE(TRIM(payment_method), 'Unknown') AS clean_payment_method

FROM deduplication
WHERE row_num = 1; 

-- Step 3 : Data Validation 
-- Inspect cleaned sample output
SELECT * 
FROM `clean_sales_header` 
LIMIT 10;
