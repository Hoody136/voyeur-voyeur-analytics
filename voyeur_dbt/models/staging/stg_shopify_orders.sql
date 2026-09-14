-- 1. IMPORT CTE
WITH source AS (
    SELECT * FROM {{ source('voyeur_raw', 'raw_orders_table') }}
),

-- 2. CLEAN CTE: PII Firewall Applied
renamed AS (
    SELECT
        -- Identifiers
        SAFE_CAST(`Name` AS STRING) AS order_id,
        SAFE_CAST(`Name` AS STRING) AS order_number,
        SAFE_CAST(`Id` AS STRING) AS shopify_internal_id,
        
        -- PII FIREWALL: Hashed Customer Identity
        TO_HEX(MD5(LOWER(TRIM(`Email`)))) AS customer_hash_id,
        SAFE_CAST(`Device ID` AS STRING) AS device_id,
        
        -- Timestamps
        SAFE_CAST(`Created at` AS TIMESTAMP) AS created_at,
        SAFE_CAST(`Paid at` AS TIMESTAMP) AS paid_at,
        SAFE_CAST(`Fulfilled at` AS TIMESTAMP) AS fulfilled_at,
        SAFE_CAST(`Cancelled at` AS TIMESTAMP) AS cancelled_at,
        
        -- Statuses
        SAFE_CAST(`Financial Status` AS STRING) AS financial_status,
        SAFE_CAST(`Fulfillment Status` AS STRING) AS fulfillment_status,
        
        -- Financials
        SAFE_CAST(`Currency` AS STRING) AS currency,
        SAFE_CAST(`Subtotal` AS FLOAT64) AS subtotal,
        SAFE_CAST(`Shipping` AS FLOAT64) AS shipping,
        SAFE_CAST(`Taxes` AS FLOAT64) AS taxes,
        SAFE_CAST(`Total` AS FLOAT64) AS total,
        SAFE_CAST(`Discount Code` AS STRING) AS discount_code,
        SAFE_CAST(`Discount Amount` AS FLOAT64) AS discount_amount,
        SAFE_CAST(`Refunded Amount` AS FLOAT64) AS refunded_amount,
        SAFE_CAST(`Outstanding Balance` AS FLOAT64) AS outstanding_balance,
        
        -- Line Item Details
        COALESCE(SAFE_CAST(`Lineitem sku` AS STRING), 'NO-SKU-ASSIGNED') AS lineitem_sku,
        SAFE_CAST(`Lineitem name` AS STRING) AS product_name,
        SAFE_CAST(`Lineitem quantity` AS INT64) AS lineitem_quantity,
        SAFE_CAST(`Lineitem price` AS FLOAT64) AS lineitem_price,
        SAFE_CAST(`Lineitem compare at price` AS FLOAT64) AS lineitem_compare_at_price,
        SAFE_CAST(`Lineitem discount` AS FLOAT64) AS lineitem_discount,
        SAFE_CAST(`Lineitem fulfillment status` AS STRING) AS lineitem_fulfillment_status,

        -- Injected Execution Cost
        0.0 AS execution_cost_gbp

    FROM source
    WHERE `Name` IS NOT NULL
)

-- 3. FINAL OUTPUT
SELECT * FROM renamed