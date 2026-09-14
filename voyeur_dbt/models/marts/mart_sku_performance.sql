-- 1. IMPORT CTEs
WITH products AS (
    SELECT * FROM {{ ref('dim_products') }}
),

inventory AS (
    -- Aggregating inventory by SKU just in case there are multiple bins/locations
    SELECT
        sku,
        SUM(on_hand_current) AS current_stock
    FROM {{ ref('fct_inventory') }}
    GROUP BY sku
),

sales AS (
    SELECT * FROM {{ ref('int_sku_sales_rolling') }}
)

-- 2. FINAL JOINS & KPIS
SELECT
    -- 1. ALL Product Attributes & Aliased Buy Data
    p.* EXCEPT (qty_on_order, qty_received, variant_live_price),
    SAFE_CAST(p.qty_on_order AS INT64) AS ordered_units,
    SAFE_CAST(p.qty_received AS INT64) AS received_units,
    SAFE_CAST(p.variant_live_price AS FLOAT64) AS current_price,

    -- 2. Live Inventory
    COALESCE(i.current_stock, 0) AS stock_on_hand,

    -------------------------------------------------------------------------
    -- 3. EXTENDED INVENTORY & ORDER VALUES
    -------------------------------------------------------------------------
    (SAFE_CAST(p.qty_on_order AS INT64) * SAFE_CAST(p.unit_cost_gbp AS FLOAT64)) AS ordered_value_at_cost_gbp,
    (SAFE_CAST(p.qty_on_order AS INT64) * SAFE_CAST(p.gbp_rrp AS FLOAT64)) AS ordered_value_at_rrp_gbp,
    (COALESCE(i.current_stock, 0) * SAFE_CAST(p.unit_cost_gbp AS FLOAT64)) AS stock_value_at_cost_gbp,
    (COALESCE(i.current_stock, 0) * SAFE_CAST(p.variant_live_price AS FLOAT64)) AS stock_value_at_live_price_gbp,
    (COALESCE(i.current_stock, 0) * SAFE_CAST(p.gbp_rrp AS FLOAT64)) AS stock_value_at_rrp_gbp,

    -------------------------------------------------------------------------
    -- 4. LIFETIME METRICS (No Timeframe)
    -------------------------------------------------------------------------
    COALESCE(s.lifetime_sales_units, 0) AS lifetime_sales_units,
    COALESCE(s.lifetime_gross_sales_if_at_rrp_gbp, 0) AS lifetime_gross_sales_if_at_rrp_gbp,
    COALESCE(s.lifetime_gross_sales_before_discount_gbp, 0) AS lifetime_gross_sales_before_discount_gbp,
    COALESCE(s.lifetime_full_price_gross_sales_gbp, 0) AS lifetime_full_price_gross_sales_gbp,
    COALESCE(s.lifetime_net_sales_gbp, 0) AS lifetime_net_sales_gbp,
    COALESCE(s.lifetime_refund_amount_gbp, 0) AS lifetime_refund_amount_gbp,
    COALESCE(s.lifetime_sales_at_cost_gbp, 0) AS lifetime_sales_at_cost_gbp,
    COALESCE(s.lifetime_checkout_discount_gbp, 0) AS lifetime_checkout_discount_gbp,
    COALESCE(s.lifetime_apportioned_tax_gbp, 0) AS lifetime_apportioned_tax_gbp,
    COALESCE(s.lifetime_apportioned_shipping_gbp, 0) AS lifetime_apportioned_shipping_gbp,
    COALESCE(s.lifetime_execution_cost_gbp, 0) AS lifetime_execution_cost_gbp,

    -- NEW: True Commercial Profitability (Net Revenue - COGS - Liquidation OPEX)
    (
        COALESCE(s.lifetime_net_sales_gbp, 0)
        - COALESCE(s.lifetime_sales_at_cost_gbp, 0)
        - COALESCE(s.lifetime_execution_cost_gbp, 0)
    ) AS lifetime_true_gross_profit,

    -------------------------------------------------------------------------
    -- 5. PREVIOUS WEEK (PW)
    -------------------------------------------------------------------------
    COALESCE(s.pw_sales_units, 0) AS pw_sales_units,
    COALESCE(s.pw_gross_sales_if_at_rrp_gbp, 0) AS pw_gross_sales_if_at_rrp_gbp,
    COALESCE(s.pw_gross_sales_before_discount_gbp, 0) AS pw_gross_sales_before_discount_gbp,
    COALESCE(s.pw_full_price_gross_sales_gbp, 0) AS pw_full_price_gross_sales_gbp,
    COALESCE(s.pw_net_sales_gbp, 0) AS pw_net_sales_gbp,
    COALESCE(s.pw_refund_amount_gbp, 0) AS pw_refund_amount_gbp,
    COALESCE(s.pw_sales_at_cost_gbp, 0) AS pw_sales_at_cost_gbp,
    COALESCE(s.pw_checkout_discount_gbp, 0) AS pw_checkout_discount_gbp,
    COALESCE(s.pw_apportioned_tax_gbp, 0) AS pw_apportioned_tax_gbp,
    COALESCE(s.pw_apportioned_shipping_gbp, 0) AS pw_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 6. PREVIOUS WEEK -1 (PW-1)
    -------------------------------------------------------------------------
    COALESCE(s.pw_minus_1_sales_units, 0) AS pw_minus_1_sales_units,
    COALESCE(s.pw_minus_1_gross_sales_if_at_rrp_gbp, 0) AS pw_minus_1_gross_sales_if_at_rrp_gbp,
    COALESCE(s.pw_minus_1_gross_sales_before_discount_gbp, 0) AS pw_minus_1_gross_sales_before_discount_gbp,
    COALESCE(s.pw_minus_1_full_price_gross_sales_gbp, 0) AS pw_minus_1_full_price_gross_sales_gbp,
    COALESCE(s.pw_minus_1_net_sales_gbp, 0) AS pw_minus_1_net_sales_gbp,
    COALESCE(s.pw_minus_1_refund_amount_gbp, 0) AS pw_minus_1_refund_amount_gbp,
    COALESCE(s.pw_minus_1_sales_at_cost_gbp, 0) AS pw_minus_1_sales_at_cost_gbp,
    COALESCE(s.pw_minus_1_checkout_discount_gbp, 0) AS pw_minus_1_checkout_discount_gbp,
    COALESCE(s.pw_minus_1_apportioned_tax_gbp, 0) AS pw_minus_1_apportioned_tax_gbp,
    COALESCE(s.pw_minus_1_apportioned_shipping_gbp, 0) AS pw_minus_1_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 7. PREVIOUS WEEK LY (PWLY)
    -------------------------------------------------------------------------
    COALESCE(s.pwly_sales_units, 0) AS pwly_sales_units,
    COALESCE(s.pwly_gross_sales_if_at_rrp_gbp, 0) AS pwly_gross_sales_if_at_rrp_gbp,
    COALESCE(s.pwly_gross_sales_before_discount_gbp, 0) AS pwly_gross_sales_before_discount_gbp,
    COALESCE(s.pwly_full_price_gross_sales_gbp, 0) AS pwly_full_price_gross_sales_gbp,
    COALESCE(s.pwly_net_sales_gbp, 0) AS pwly_net_sales_gbp,
    COALESCE(s.pwly_refund_amount_gbp, 0) AS pwly_refund_amount_gbp,
    COALESCE(s.pwly_sales_at_cost_gbp, 0) AS pwly_sales_at_cost_gbp,
    COALESCE(s.pwly_checkout_discount_gbp, 0) AS pwly_checkout_discount_gbp,
    COALESCE(s.pwly_apportioned_tax_gbp, 0) AS pwly_apportioned_tax_gbp,
    COALESCE(s.pwly_apportioned_shipping_gbp, 0) AS pwly_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 8. PREVIOUS 4 WEEKS (P-4W)
    -------------------------------------------------------------------------
    COALESCE(s.p_4w_sales_units, 0) AS p_4w_sales_units,
    COALESCE(s.p_4w_gross_sales_if_at_rrp_gbp, 0) AS p_4w_gross_sales_if_at_rrp_gbp,
    COALESCE(s.p_4w_gross_sales_before_discount_gbp, 0) AS p_4w_gross_sales_before_discount_gbp,
    COALESCE(s.p_4w_full_price_gross_sales_gbp, 0) AS p_4w_full_price_gross_sales_gbp,
    COALESCE(s.p_4w_net_sales_gbp, 0) AS p_4w_net_sales_gbp,
    COALESCE(s.p_4w_refund_amount_gbp, 0) AS p_4w_refund_amount_gbp,
    COALESCE(s.p_4w_sales_at_cost_gbp, 0) AS p_4w_sales_at_cost_gbp,
    COALESCE(s.p_4w_checkout_discount_gbp, 0) AS p_4w_checkout_discount_gbp,
    COALESCE(s.p_4w_apportioned_tax_gbp, 0) AS p_4w_apportioned_tax_gbp,
    COALESCE(s.p_4w_apportioned_shipping_gbp, 0) AS p_4w_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 9. PREVIOUS 4 WEEKS LY (P-4W LY)
    -------------------------------------------------------------------------
    COALESCE(s.p_4w_ly_sales_units, 0) AS p_4w_ly_sales_units,
    COALESCE(s.p_4w_ly_gross_sales_if_at_rrp_gbp, 0) AS p_4w_ly_gross_sales_if_at_rrp_gbp,
    COALESCE(s.p_4w_ly_gross_sales_before_discount_gbp, 0) AS p_4w_ly_gross_sales_before_discount_gbp,
    COALESCE(s.p_4w_ly_full_price_gross_sales_gbp, 0) AS p_4w_ly_full_price_gross_sales_gbp,
    COALESCE(s.p_4w_ly_net_sales_gbp, 0) AS p_4w_ly_net_sales_gbp,
    COALESCE(s.p_4w_ly_refund_amount_gbp, 0) AS p_4w_ly_refund_amount_gbp,
    COALESCE(s.p_4w_ly_sales_at_cost_gbp, 0) AS p_4w_ly_sales_at_cost_gbp,
    COALESCE(s.p_4w_ly_checkout_discount_gbp, 0) AS p_4w_ly_checkout_discount_gbp,
    COALESCE(s.p_4w_ly_apportioned_tax_gbp, 0) AS p_4w_ly_apportioned_tax_gbp,
    COALESCE(s.p_4w_ly_apportioned_shipping_gbp, 0) AS p_4w_ly_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 10. PREVIOUS WEEKS -5-8 (P-5-8W)
    -------------------------------------------------------------------------
    COALESCE(s.p_5_8w_sales_units, 0) AS p_5_8w_sales_units,
    COALESCE(s.p_5_8w_gross_sales_if_at_rrp_gbp, 0) AS p_5_8w_gross_sales_if_at_rrp_gbp,
    COALESCE(s.p_5_8w_gross_sales_before_discount_gbp, 0) AS p_5_8w_gross_sales_before_discount_gbp,
    COALESCE(s.p_5_8w_full_price_gross_sales_gbp, 0) AS p_5_8w_full_price_gross_sales_gbp,
    COALESCE(s.p_5_8w_net_sales_gbp, 0) AS p_5_8w_net_sales_gbp,
    COALESCE(s.p_5_8w_refund_amount_gbp, 0) AS p_5_8w_refund_amount_gbp,
    COALESCE(s.p_5_8w_sales_at_cost_gbp, 0) AS p_5_8w_sales_at_cost_gbp,
    COALESCE(s.p_5_8w_checkout_discount_gbp, 0) AS p_5_8w_checkout_discount_gbp,
    COALESCE(s.p_5_8w_apportioned_tax_gbp, 0) AS p_5_8w_apportioned_tax_gbp,
    COALESCE(s.p_5_8w_apportioned_shipping_gbp, 0) AS p_5_8w_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 11. YTD TY
    -------------------------------------------------------------------------
    COALESCE(s.ytd_sales_units, 0) AS ytd_sales_units,
    COALESCE(s.ytd_gross_sales_if_at_rrp_gbp, 0) AS ytd_gross_sales_if_at_rrp_gbp,
    COALESCE(s.ytd_gross_sales_before_discount_gbp, 0) AS ytd_gross_sales_before_discount_gbp,
    COALESCE(s.ytd_full_price_gross_sales_gbp, 0) AS ytd_full_price_gross_sales_gbp,
    COALESCE(s.ytd_net_sales_gbp, 0) AS ytd_net_sales_gbp,
    COALESCE(s.ytd_refund_amount_gbp, 0) AS ytd_refund_amount_gbp,
    COALESCE(s.ytd_sales_at_cost_gbp, 0) AS ytd_sales_at_cost_gbp,
    COALESCE(s.ytd_checkout_discount_gbp, 0) AS ytd_checkout_discount_gbp,
    COALESCE(s.ytd_apportioned_tax_gbp, 0) AS ytd_apportioned_tax_gbp,
    COALESCE(s.ytd_apportioned_shipping_gbp, 0) AS ytd_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 12. YTD LY
    -------------------------------------------------------------------------
    COALESCE(s.ytdly_sales_units, 0) AS ytdly_sales_units,
    COALESCE(s.ytdly_gross_sales_if_at_rrp_gbp, 0) AS ytdly_gross_sales_if_at_rrp_gbp,
    COALESCE(s.ytdly_gross_sales_before_discount_gbp, 0) AS ytdly_gross_sales_before_discount_gbp,
    COALESCE(s.ytdly_full_price_gross_sales_gbp, 0) AS ytdly_full_price_gross_sales_gbp,
    COALESCE(s.ytdly_net_sales_gbp, 0) AS ytdly_net_sales_gbp,
    COALESCE(s.ytdly_refund_amount_gbp, 0) AS ytdly_refund_amount_gbp,
    COALESCE(s.ytdly_sales_at_cost_gbp, 0) AS ytdly_sales_at_cost_gbp,
    COALESCE(s.ytdly_checkout_discount_gbp, 0) AS ytdly_checkout_discount_gbp,
    COALESCE(s.ytdly_apportioned_tax_gbp, 0) AS ytdly_apportioned_tax_gbp,
    COALESCE(s.ytdly_apportioned_shipping_gbp, 0) AS ytdly_apportioned_shipping_gbp,

    -------------------------------------------------------------------------
    -- 13. INVENTORY & MERCHANDISING KPIS
    -------------------------------------------------------------------------
    -- Stock Weeks Cover (Current Stock / Previous Week's Sales Velocity)
    SAFE_DIVIDE(COALESCE(i.current_stock, 0), s.pw_sales_units) AS stock_weeks_cover,
   
    -- Sell-Through Rate (Lifetime Units Sold / (Lifetime Units Sold + Current Stock))
    SAFE_DIVIDE(
        COALESCE(s.lifetime_sales_units, 0),
        (COALESCE(s.lifetime_sales_units, 0) + COALESCE(i.current_stock, 0))
    ) AS sell_through_rate

FROM products p
LEFT JOIN inventory i
    ON p.vv_sku = i.sku
LEFT JOIN sales s
    ON p.vv_sku = s.lineitem_sku