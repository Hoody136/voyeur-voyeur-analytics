-- 1. IMPORT CTE
WITH source AS (
    SELECT * FROM {{ source('raw_shopify', 'raw_products_table') }}
),

-- 2. CLEAN CTE: Enforcing data types for the pricing engine
renamed AS (
    SELECT
        -- Identifiers: Always cast SKUs to STRING
        SAFE_CAST(`Variant SKU` AS STRING) AS variant_sku,
        
        -- Financials: Cast to FLOAT64 for accurate downstream margin/discount math
        SAFE_CAST(`Variant Price` AS FLOAT64) AS variant_live_price

    FROM source
)

-- 3. FINAL OUTPUT
SELECT * FROM renamed