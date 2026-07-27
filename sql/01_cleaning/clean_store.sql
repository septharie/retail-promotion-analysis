-- Step 1 : Profiling 
-- Check NULL values across all attributes
SELECT 
    COUNT(*) AS total_rows,
    COUNTIF(store_id IS NULL) AS null_store_id,
    COUNTIF(store_code IS NULL) AS null_store_code,
    COUNTIF(store_name IS NULL) AS null_store_name,
    COUNTIF(city IS NULL) AS null_city,
    COUNTIF(province IS NULL) AS null_province,
    COUNTIF(address IS NULL) AS null_address
FROM `raw_store`;

-- Check variation in city name
SELECT 
    city, 
    COUNT(*) AS num_city
FROM `raw_store`
GROUP BY city
ORDER BY num_city ASC
LIMIT 20;

-- Check variation in province name
SELECT 
    province, 
    COUNT(*) AS num_province
FROM `raw_store`
GROUP BY province
ORDER BY num_province ASC
LIMIT 20;

-- Check for duplicate store codes
SELECT 
    store_code, 
    COUNT(*) AS num_duplicate
FROM `raw_store`
GROUP BY store_code
HAVING COUNT(*) > 1;


-- Step 2 : Cleaning & Transformation
 -- Create clean table
CREATE OR REPLACE TABLE `clean_store` AS

-- Deduplicate records keeping the earliest store code
WITH deduplication AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(
            PARTITION BY store_code 
            ORDER BY store_code ASC
        ) AS row_num
    FROM `raw_store`
)

SELECT 
    store_id,
    store_code,
    store_name,

    -- 1. Standardize city name
    CASE 
        WHEN LOWER(city) IN ('jakarta') THEN 'Jakarta'
        WHEN LOWER(city) IN ('surabaya') THEN 'Surabaya'
        WHEN LOWER(city) IN ('medan') THEN 'Medan'
        WHEN LOWER(city) IN ('makasar', 'makassar') THEN 'Makassar'
        ELSE INITCAP(TRIM(city))
    END AS clean_city,

    -- 2. Standardize province name
    CASE 
        WHEN LOWER(province) IN ('di yogya', 'yogya', 'yogyakarta', 'd.i. yogyakarta') THEN 'DI Yogyakarta'
        ELSE INITCAP(TRIM(province))
    END AS clean_province,
    
    -- 3. Filling NULL with 'Not Available'
    COALESCE(INITCAP(address), 'Not Available') AS clean_address

FROM deduplication
WHERE row_num = 1; 

-- Step 3 : Data Validation 
-- Inspect cleaned sample output
SELECT * 
FROM `clean_store` 
LIMIT 10;
