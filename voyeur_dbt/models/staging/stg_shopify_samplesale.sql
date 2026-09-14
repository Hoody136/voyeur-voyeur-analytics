-- 1. IMPORT CTE
WITH source AS (
    SELECT * FROM {{ source('raw_shopify', 'raw_samplesale_table') }}
),

-- 2. CLEAN CTE: Aligning to standard orders + PII Firewall
renamed AS (
    SELECT
        -- Identifiers: Auto-generate UUID if blank to prevent primary key failures
        COALESCE(SAFE_CAST(`Id` AS STRING), CONCAT('SS-', CAST(GENERATE_UUID() AS STRING))) AS order_id,
        COALESCE(`Name`, CONCAT('SS-', CAST(GENERATE_UUID() AS STRING))) AS order_number,
        
        -- PII FIREWALL: Hashed Customer Identity
        TO_HEX(MD5(LOWER(TRIM(`Email`)))) AS customer_hash_id,
        
        SAFE_CAST(`Device ID` AS STRING) AS device_id,
        
        -- Timestamps (Uses 'Paid at' if 'Created at' is blank in the CSV)
        COALESCE(SAFE_CAST(`Created at` AS TIMESTAMP), SAFE_CAST(`Paid at` AS TIMESTAMP)) AS created_at,
        SAFE_CAST(`Paid at` AS TIMESTAMP) AS paid_at,
        SAFE_CAST(`Fulfilled at` AS TIMESTAMP) AS fulfilled_at,
        SAFE_CAST(`Cancelled at` AS TIMESTAMP) AS cancelled_at,
        
        -- Statuses
        `Financial Status` AS financial_status,
        `Fulfillment Status` AS fulfillment_status,
        
        -- Financials
        `Currency` AS currency,
        SAFE_CAST(`Subtotal` AS FLOAT64) AS subtotal,
        SAFE_CAST(`Shipping` AS FLOAT64) AS shipping,
        SAFE_CAST(`Taxes` AS FLOAT64) AS taxes,
        SAFE_CAST(`Total` AS FLOAT64) AS total,
        `Discount Code` AS discount_code,
        SAFE_CAST(`Discount Amount` AS FLOAT64) AS discount_amount,
        SAFE_CAST(`Refunded Amount` AS FLOAT64) AS refunded_amount,
        SAFE_CAST(`Outstanding Balance` AS FLOAT64) AS outstanding_balance,
        
        -- Line Item Details
        `Lineitem sku` AS lineitem_sku,
        `Lineitem name` AS product_name,
        SAFE_CAST(`Lineitem quantity` AS INT64) AS lineitem_quantity,
        SAFE_CAST(`Lineitem price` AS FLOAT64) AS lineitem_price,
        SAFE_CAST(`Lineitem compare at price` AS FLOAT64) AS lineitem_compare_at_price,
        SAFE_CAST(`Lineitem discount` AS FLOAT64) AS lineitem_discount,
        SAFE_CAST(`Lineitem fulfillment status` AS STRING) AS lineitem_fulfillment_status,
        
        -- Injected Execution Cost (Specifically pulling the Sample Sale OPEX)
        SAFE_CAST(`Lineitem Additional Sample Sale Execution Costs` AS FLOAT64) AS execution_cost_gbp

    FROM source
)

-- 3. FINAL OUTPUT
SELECT * FROM renamed