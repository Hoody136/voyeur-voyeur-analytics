-- 1. IMPORT CTE
WITH source AS (
    SELECT * FROM {{ source('raw_shopify', 'raw_inventory_table') }}
),

-- 2. CLEAN CTE: Enforce standard naming and data types
renamed AS (
    SELECT
        -- Identifiers & Product Attributes
        SAFE_CAST(`Handle` AS STRING) AS handle,
        SAFE_CAST(`Title` AS STRING) AS title,
        SAFE_CAST(`Option1 Name` AS STRING) AS option1_name,
        SAFE_CAST(`Option1 Value` AS STRING) AS option1_value,
        SAFE_CAST(`Option2 Name` AS STRING) AS option2_name,
        SAFE_CAST(`Option2 Value` AS STRING) AS option2_value,
        SAFE_CAST(`Option3 Name` AS STRING) AS option3_name,
        SAFE_CAST(`Option3 Value` AS STRING) AS option3_value,
        SAFE_CAST(`SKU` AS STRING) AS sku,
        
        -- Compliance & Location Info
        SAFE_CAST(`HS Code` AS STRING) AS hs_code,
        SAFE_CAST(`COO` AS STRING) AS coo,
        SAFE_CAST(`Location` AS STRING) AS location, 
        SAFE_CAST(`Bin name` AS STRING) AS bin_name,
        
        -- Inventory Metrics: Strictly cast to INT64 for aggregate math
        SAFE_CAST(`Incoming _not editable_` AS INT64) AS incoming,
        SAFE_CAST(`Unavailable _not editable_` AS INT64) AS unavailable,
        SAFE_CAST(`Committed _not editable_` AS INT64) AS committed,
        SAFE_CAST(`Available _not editable_` AS INT64) AS available,
        SAFE_CAST(`On hand _current_` AS INT64) AS on_hand_current,
        SAFE_CAST(`On hand _new_` AS INT64) AS on_hand_new

    FROM source
)

-- 3. FINAL OUTPUT
SELECT * FROM renamed