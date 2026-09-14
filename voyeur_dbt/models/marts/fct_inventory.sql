-- 1. IMPORT CTEs
WITH inventory AS (
    SELECT * FROM {{ ref('stg_shopify_inventory') }}
),

products AS (
    SELECT * FROM {{ ref('dim_products') }}
)

-- 2. ENRICHMENT CTE
SELECT
    -- Pulls every column from your staging inventory table (stock levels, bins, etc.)
    i.*,
   
    -- Pulls all enriched product data, excluding the redundant join key to keep the BI layer clean
    p.* EXCEPT (vv_sku)

FROM inventory i
LEFT JOIN products p
    ON i.sku = p.vv_sku