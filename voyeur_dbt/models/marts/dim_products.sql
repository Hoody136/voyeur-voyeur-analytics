-- 1. IMPORT CTEs
WITH shopify_products AS (
    SELECT * FROM {{ ref('stg_shopify_products') }}
),

range_sheet AS (
    SELECT * FROM {{ ref('stg_shopify_range_sheet') }}
),

-- 2. ENRICHMENT CTE
enriched_products AS (
    SELECT
        -- Pulling every core attribute from the merchandising master file
        r.*,
        
        -- Pulling the live price from the Shopify website
        -- SAFETY NET: If the item isn't on the website yet, default to the planned RRP
        COALESCE(p.variant_live_price, r.gbp_rrp) AS variant_live_price

    FROM range_sheet r
    LEFT JOIN shopify_products p
        ON r.vv_sku = p.variant_sku
)

-- 3. FINAL OUTPUT
SELECT * FROM enriched_products