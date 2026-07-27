-- Step 1 : Profiling 
-- Check NULL values across all attributes
SELECT 
    COUNT(*) AS total_rows,
    COUNTIF(member_id IS NULL) AS null_member_id,
    COUNTIF(member_code IS NULL) AS null_member_code,
    COUNTIF(member_name IS NULL) AS null_member_name,
    COUNTIF(gender IS NULL) AS null_gender,
    COUNTIF(city IS NULL) AS null_city,
    COUNTIF(join_date IS NULL) AS null_join_date
FROM `porfo-502707.promotion.raw_member`;

-- Check variation in date formats
SELECT 
    join_date, 
    COUNT(*) AS num_date
FROM `porfo-502707.promotion.raw_member`
GROUP BY join_date
ORDER BY num_date DESC
LIMIT 20;

-- Check for duplicate member codes
SELECT 
    member_code, 
    COUNT(*) AS num_duplicate
FROM `porfo-502707.promotion.raw_member`
GROUP BY member_code
HAVING COUNT(*) > 1;

-- Step 2 : Cleaning & Transformation
 -- Create clean table
CREATE OR REPLACE TABLE `porfo-502707.promotion.clean_member` AS

-- Deduplicate records keeping the earliest join date
WITH deduplication AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(
            PARTITION BY member_code 
            ORDER BY join_date ASC
        ) AS row_num
    FROM `porfo-502707.promotion.raw_member`
)

SELECT 
    member_id,
    member_code,

    -- 1. Standardize text formatting (remove spaces & format capital)
    INITCAP(TRIM(member_name)) AS clean_member_name,
    
    -- 2. Filling NULL with 'Unknown'
    COALESCE(INITCAP(gender), 'Unknown') AS clean_gender,
    COALESCE(INITCAP(city), 'Unknown') AS clean_city,
    
    -- 3. Parse and standardize heterogeneous date formats into DATE type
    COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', join_date),
        SAFE.PARSE_DATE('%Y-%m-%d', REPLACE(join_date, '.', '-')),
        SAFE.PARSE_DATE('%d-%m-%Y', REPLACE(join_date, '/', '-')),
        SAFE.PARSE_DATE('%d %b %Y', join_date),
        SAFE.PARSE_DATE('%m-%d-%Y', REPLACE(join_date, '/', '-'))
    ) AS clean_join_date

FROM deduplication
WHERE row_num = 1; 

-- Step 3 : Data Validation 
-- Inspect cleaned sample output
SELECT * 
FROM `porfo-502707.promotion.clean_member` 
LIMIT 10;
