-- Step 1 : Profiling 
-- Check NULL values across all attributes
SELECT 
    COUNT(*) AS total_rows,
    COUNTIF(promo_id IS NULL) AS null_promo_id,
    COUNTIF(promo_code IS NULL) AS null_promo_code,
    COUNTIF(promo_name IS NULL) AS null_promo_name,
    COUNTIF(promo_type IS NULL) AS null_promo_type,
    COUNTIF(discount_percentage IS NULL) AS discount_percentage,
    COUNTIF(start_date IS NULL) AS null_start_date,
    COUNTIF(end_date IS NULL) AS null_end_date
FROM `raw_promo`;

-- Check variation in date formats
SELECT 
    start_date, 
    COUNT(*) AS num_date
FROM `raw_promo`
GROUP BY start_date
ORDER BY num_date DESC
LIMIT 20;

-- Check for duplicate promo codes
SELECT 
    promo_code, 
    COUNT(*) AS num_duplicate
FROM `raw_promo`
GROUP BY promo_code
HAVING COUNT(*) > 1;

-- Step 2 : Cleaning & Transformation
 -- Create clean table
CREATE OR REPLACE TABLE `clean_promo` AS

SELECT 
    promo_id,
    promo_code,

    -- 1. Standardize text formatting (remove spaces & format capital)
    INITCAP(TRIM(promo_name)) AS clean_promo_name,
    INITCAP(TRIM(promo_type)) AS clean_promo_type,

    discount_percentage,
    
   -- 2. Parse and standardize heterogeneous date formats into DATE type
    COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', start_date),
        SAFE.PARSE_DATE('%Y-%m-%d', REPLACE(start_date, '.', '-')),
        SAFE.PARSE_DATE('%d/%m/%Y', start_date),
        SAFE.PARSE_DATE('%d-%m-%Y', REPLACE(start_date, '/', '-')),
        SAFE.PARSE_DATE('%d %b %Y', start_date),
        SAFE.PARSE_DATE('%m/%d/%Y', start_date)
    ) AS clean_start_date,

    -- 3. Parse and standardize heterogeneous date formats into DATE type + Filling NULL with Far-Future Date (2099-12-31)
    COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', end_date),
        SAFE.PARSE_DATE('%Y-%m-%d', REPLACE(end_date, '.', '-')),
        SAFE.PARSE_DATE('%d/%m/%Y', end_date),
        SAFE.PARSE_DATE('%d-%m-%Y', REPLACE(end_date, '/', '-')),
        SAFE.PARSE_DATE('%d %b %Y', end_date),
        SAFE.PARSE_DATE('%m/%d/%Y', end_date),
        
        -- If end_date is NULL then put this below date
        DATE '2099-12-31'
    ) AS clean_end_date

FROM `raw_promo`;

-- Step 3 : Data Validation 
-- Inspect cleaned sample output
SELECT * 
FROM `clean_promo` 
LIMIT 10;
