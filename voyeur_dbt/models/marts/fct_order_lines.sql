-- 1. IMPORT CTEs
WITH orders AS (
    SELECT * FROM {{ ref('int_orders_filled') }}
),

products AS (
    -- Exclude product_name to prevent column duplication with the orders table
    SELECT * EXCEPT (product_name)
    FROM {{ ref('dim_products') }}
),

dates AS (
    SELECT * FROM {{ ref('stg_dim_date') }}
)

-- 2. THE ATOMIC JOIN & KPI GENERATION
SELECT
    -- Base Data
    o.*,
    p.*,
    d.*,
   
    -- ----------------------------------------------------------------------------------
    -- REVENUE KPIS
    -- ----------------------------------------------------------------------------------
    
    -- Gross Sales if sold at RRP (Baseline revenue if sold at RRP).
    CASE
        WHEN o.financial_status = 'paid' THEN (SAFE_CAST(p.gbp_rrp AS FLOAT64) * o.lineitem_quantity)
        ELSE 0
    END AS gross_sales_if_at_rrp_gbp,
    
    -- True Gross Sales Before Discount (Accounts for True RRP and Markdowns)
    CASE
        WHEN o.financial_status = 'paid' THEN o.lineitem_gross_sales_before_discount
        ELSE 0
    END AS gross_sales_before_discount_gbp,
    
    -- Net Sales (Revenue after checkout discounts, before returns)
    CASE
        WHEN o.financial_status = 'paid' THEN o.lineitem_netsales_afterdiscount_before_returns
        ELSE 0
    END AS net_sales_gbp,
    
    -- ----------------------------------------------------------------------------------
    -- DISCOUNT & MARKDOWN KPIS
    -- ----------------------------------------------------------------------------------
    
    -- Total Discount (Physical Markdowns + Cart Promo Codes)
    CASE
        WHEN o.financial_status = 'paid' THEN COALESCE(o.lineitem_discount, 0)
        ELSE 0
    END AS checkout_discount_gbp,
   
    -- RRP Markdown (Total monetary difference between RRP and final paid price)
    CASE
        WHEN o.financial_status = 'paid' THEN
            ((SAFE_CAST(p.gbp_rrp AS FLOAT64) * o.lineitem_quantity) - o.lineitem_netsales_afterdiscount_before_returns)
        ELSE 0
    END AS rrp_markdown_gbp,
    
    -- Sales Type Flag (Full Price vs Discount)
    CASE
        WHEN COALESCE(o.lineitem_discount, 0) > 0 THEN 'Discount'
        ELSE 'Full Price'
    END AS sales_type,

    -- Full-Price Gross Sales
    CASE
        WHEN COALESCE(o.lineitem_discount, 0) = 0 AND o.financial_status = 'paid' THEN o.lineitem_gross_sales_before_discount
        ELSE 0
    END AS full_price_gross_sales_gbp,

    -- Discounted Gross Sales
    CASE
        WHEN COALESCE(o.lineitem_discount, 0) > 0 AND o.financial_status = 'paid' THEN o.lineitem_gross_sales_before_discount
        ELSE 0
    END AS discounted_gross_sales_gbp,

    -- ----------------------------------------------------------------------------------
    -- PROFITABILITY KPIS
    -- ----------------------------------------------------------------------------------
    
    -- Sales @ Cost (COGS)
    CASE
        WHEN o.financial_status = 'paid' THEN (SAFE_CAST(p.unit_cost_gbp AS FLOAT64) * o.lineitem_quantity)
        WHEN o.financial_status = 'partially_refunded' AND o.lineitem_fulfillment_status = 'fulfilled' THEN (SAFE_CAST(p.unit_cost_gbp AS FLOAT64) * o.lineitem_quantity)
        ELSE 0
    END AS sales_at_cost_gbp,

    -- Gross Profit
    CASE
        WHEN o.financial_status = 'paid' THEN
            (o.lineitem_netsales_afterdiscount_before_returns - (SAFE_CAST(p.unit_cost_gbp AS FLOAT64) * o.lineitem_quantity))
        ELSE 0
    END AS gross_profit_gbp,
   
    -- ----------------------------------------------------------------------------------
    -- VOLUME & RETURN KPIS
    -- ----------------------------------------------------------------------------------
    
    -- Sales Units
    CASE
        WHEN o.financial_status = 'paid' THEN o.lineitem_quantity
        ELSE 0
    END AS sales_units,
    
    -- Return Flag
    CASE
        WHEN o.financial_status = 'refunded' THEN 1
        WHEN o.financial_status = 'partially_refunded' AND o.lineitem_fulfillment_status != 'fulfilled' THEN 1
        ELSE 0
    END AS is_returned,
    
    -- Returned Quantity
    CASE
        WHEN o.financial_status = 'refunded' THEN o.lineitem_quantity
        WHEN o.financial_status = 'partially_refunded' AND o.lineitem_fulfillment_status != 'fulfilled' THEN o.lineitem_quantity
        ELSE 0
    END AS return_quantity,
    
    -- Returned Amount / Value
    COALESCE(o.lineitem_refund, 0) AS refund_amount_gbp,

    -- ----------------------------------------------------------------------------------
    -- BI PASS-THROUGH METRICS
    -- ----------------------------------------------------------------------------------
    COALESCE(o.lineitem_shipping, 0) AS apportioned_shipping_gbp,
    COALESCE(o.lineitem_tax, 0) AS apportioned_tax_gbp,
    EXTRACT(HOUR FROM SAFE_CAST(o.created_at AS TIMESTAMP)) AS transaction_hour

FROM orders o
LEFT JOIN products p
    ON o.lineitem_sku = p.vv_sku
LEFT JOIN dates d
    ON DATE(SAFE_CAST(o.created_at AS TIMESTAMP)) = d.date