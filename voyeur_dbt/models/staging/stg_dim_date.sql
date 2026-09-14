-- 1. IMPORT CTE
WITH source AS (
    SELECT * FROM {{ source('raw_shopify', 'dim_date') }}
),

-- 2. CLEAN CTE: Applying the Retail 4-4-5 Calendar Logic
renamed AS (
    SELECT
        *, -- Pulls through date, iso_week, calendar_month, seasons natively
        
        -- RETAIL 4-4-5 ISO MONTH LOGIC (Includes 53-week safeguard)
        CASE
            WHEN iso_week BETWEEN 1 AND 4 THEN 'ISO_Month_01_Jan'
            WHEN iso_week BETWEEN 5 AND 8 THEN 'ISO_Month_02_Feb'
            WHEN iso_week BETWEEN 9 AND 13 THEN 'ISO_Month_03_Mar'
            WHEN iso_week BETWEEN 14 AND 17 THEN 'ISO_Month_04_Apr'
            WHEN iso_week BETWEEN 18 AND 21 THEN 'ISO_Month_05_May'
            WHEN iso_week BETWEEN 22 AND 26 THEN 'ISO_Month_06_Jun'
            WHEN iso_week BETWEEN 27 AND 30 THEN 'ISO_Month_07_Jul'
            WHEN iso_week BETWEEN 31 AND 34 THEN 'ISO_Month_08_Aug'
            WHEN iso_week BETWEEN 35 AND 39 THEN 'ISO_Month_09_Sep'
            WHEN iso_week BETWEEN 40 AND 43 THEN 'ISO_Month_10_Oct'
            WHEN iso_week BETWEEN 44 AND 47 THEN 'ISO_Month_11_Nov'
            WHEN iso_week >= 48 THEN 'ISO_Month_12_Dec'
        END AS iso_month

    FROM source
)

-- 3. FINAL OUTPUT
SELECT * FROM renamed