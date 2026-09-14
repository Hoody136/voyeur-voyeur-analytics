-- 1. IMPORT CTEs: Pulling from our clean staging layer using ref()
WITH shopify_orders AS (
    SELECT 
        *, 
        'Shopify E-Com' AS source_platform 
    FROM {{ ref('stg_shopify_orders') }}
),

sample_sales AS (
    SELECT 
        *, 
        'Offline Sample Sale' AS source_platform 
    FROM {{ ref('stg_shopify_samplesale') }}
),

-- 2. LOGIC CTE: Stacking the tables vertically
unioned_orders AS (
    SELECT * FROM shopify_orders
    UNION ALL
    SELECT * FROM sample_sales
)

-- 3. FINAL OUTPUT
SELECT * FROM unioned_orders