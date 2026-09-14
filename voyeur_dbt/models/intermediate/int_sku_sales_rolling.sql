-- 1. IMPORT CTEs
WITH order_lines AS (
    SELECT * FROM {{ ref('fct_order_lines') }}
),

-- 2. TIME ANCHOR: Lock the rolling window to the completed previous week
time_anchor AS (
    SELECT
        EXTRACT(ISOYEAR FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 WEEK)) AS anchor_year,
        EXTRACT(ISOWEEK FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 WEEK)) AS anchor_week
),

-- 3. APPLY ISO DATES TO ORDERS
orders_with_iso AS (
    SELECT
        o.*,
        EXTRACT(ISOYEAR FROM SAFE_CAST(o.created_at AS TIMESTAMP)) AS tx_iso_year,
        EXTRACT(ISOWEEK FROM SAFE_CAST(o.created_at AS TIMESTAMP)) AS tx_iso_week
    FROM order_lines o
),

-- 4. SKU AGGREGATIONS
sku_aggregations AS (
    SELECT
        o.lineitem_sku,
       
        -------------------------------------------------------------------------
        -- 1. LIFETIME METRICS (No Timeframe)
        -------------------------------------------------------------------------
        SUM(o.sales_units) AS lifetime_sales_units,
        SUM(o.gross_sales_if_at_rrp_gbp) AS lifetime_gross_sales_if_at_rrp_gbp,
        SUM(o.gross_sales_before_discount_gbp) AS lifetime_gross_sales_before_discount_gbp,
        SUM(o.full_price_gross_sales_gbp) AS lifetime_full_price_gross_sales_gbp,
        SUM(o.net_sales_gbp) AS lifetime_net_sales_gbp,
        SUM(o.refund_amount_gbp) AS lifetime_refund_amount_gbp,
        SUM(o.sales_at_cost_gbp) AS lifetime_sales_at_cost_gbp,
        SUM(o.checkout_discount_gbp) AS lifetime_checkout_discount_gbp,
        SUM(o.apportioned_tax_gbp) AS lifetime_apportioned_tax_gbp,
        SUM(o.apportioned_shipping_gbp) AS lifetime_apportioned_shipping_gbp,
        SUM(COALESCE(o.execution_cost_gbp, 0)) AS lifetime_execution_cost_gbp,

        -------------------------------------------------------------------------
        -- 2. PREVIOUS WEEK (PW)
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.sales_units ELSE 0 END) AS pw_sales_units,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS pw_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS pw_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.full_price_gross_sales_gbp ELSE 0 END) AS pw_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.net_sales_gbp ELSE 0 END) AS pw_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.refund_amount_gbp ELSE 0 END) AS pw_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.sales_at_cost_gbp ELSE 0 END) AS pw_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.checkout_discount_gbp ELSE 0 END) AS pw_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.apportioned_tax_gbp ELSE 0 END) AS pw_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = a.anchor_week THEN o.apportioned_shipping_gbp ELSE 0 END) AS pw_apportioned_shipping_gbp,

        -------------------------------------------------------------------------
        -- 3. PREVIOUS WEEK -1 (PW-1)
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.sales_units ELSE 0 END) AS pw_minus_1_sales_units,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS pw_minus_1_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS pw_minus_1_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.full_price_gross_sales_gbp ELSE 0 END) AS pw_minus_1_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.net_sales_gbp ELSE 0 END) AS pw_minus_1_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.refund_amount_gbp ELSE 0 END) AS pw_minus_1_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.sales_at_cost_gbp ELSE 0 END) AS pw_minus_1_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.checkout_discount_gbp ELSE 0 END) AS pw_minus_1_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.apportioned_tax_gbp ELSE 0 END) AS pw_minus_1_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week = (a.anchor_week - 1) THEN o.apportioned_shipping_gbp ELSE 0 END) AS pw_minus_1_apportioned_shipping_gbp,

        -------------------------------------------------------------------------
        -- 4. PREVIOUS WEEK LY (PWLY)
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.sales_units ELSE 0 END) AS pwly_sales_units,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS pwly_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS pwly_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.full_price_gross_sales_gbp ELSE 0 END) AS pwly_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.net_sales_gbp ELSE 0 END) AS pwly_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.refund_amount_gbp ELSE 0 END) AS pwly_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.sales_at_cost_gbp ELSE 0 END) AS pwly_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.checkout_discount_gbp ELSE 0 END) AS pwly_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.apportioned_tax_gbp ELSE 0 END) AS pwly_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week = a.anchor_week THEN o.apportioned_shipping_gbp ELSE 0 END) AS pwly_apportioned_shipping_gbp,

        -------------------------------------------------------------------------
        -- 5. PREVIOUS 4 WEEKS (P-4W)
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.sales_units ELSE 0 END) AS p_4w_sales_units,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS p_4w_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS p_4w_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.full_price_gross_sales_gbp ELSE 0 END) AS p_4w_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.net_sales_gbp ELSE 0 END) AS p_4w_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.refund_amount_gbp ELSE 0 END) AS p_4w_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.sales_at_cost_gbp ELSE 0 END) AS p_4w_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.checkout_discount_gbp ELSE 0 END) AS p_4w_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.apportioned_tax_gbp ELSE 0 END) AS p_4w_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.apportioned_shipping_gbp ELSE 0 END) AS p_4w_apportioned_shipping_gbp,

        -------------------------------------------------------------------------
        -- 6. PREVIOUS 4 WEEKS LY (P-4W LY)
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.sales_units ELSE 0 END) AS p_4w_ly_sales_units,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS p_4w_ly_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS p_4w_ly_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.full_price_gross_sales_gbp ELSE 0 END) AS p_4w_ly_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.net_sales_gbp ELSE 0 END) AS p_4w_ly_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.refund_amount_gbp ELSE 0 END) AS p_4w_ly_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.sales_at_cost_gbp ELSE 0 END) AS p_4w_ly_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.checkout_discount_gbp ELSE 0 END) AS p_4w_ly_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.apportioned_tax_gbp ELSE 0 END) AS p_4w_ly_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week BETWEEN (a.anchor_week - 3) AND a.anchor_week THEN o.apportioned_shipping_gbp ELSE 0 END) AS p_4w_ly_apportioned_shipping_gbp,

        -------------------------------------------------------------------------
        -- 7. PREVIOUS WEEKS -5-8 (P-5-8W)
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.sales_units ELSE 0 END) AS p_5_8w_sales_units,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS p_5_8w_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS p_5_8w_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.full_price_gross_sales_gbp ELSE 0 END) AS p_5_8w_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.net_sales_gbp ELSE 0 END) AS p_5_8w_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.refund_amount_gbp ELSE 0 END) AS p_5_8w_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.sales_at_cost_gbp ELSE 0 END) AS p_5_8w_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.checkout_discount_gbp ELSE 0 END) AS p_5_8w_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.apportioned_tax_gbp ELSE 0 END) AS p_5_8w_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week BETWEEN (a.anchor_week - 7) AND (a.anchor_week - 4) THEN o.apportioned_shipping_gbp ELSE 0 END) AS p_5_8w_apportioned_shipping_gbp,

        -------------------------------------------------------------------------
        -- 8. YTD TY
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.sales_units ELSE 0 END) AS ytd_sales_units,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS ytd_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS ytd_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.full_price_gross_sales_gbp ELSE 0 END) AS ytd_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.net_sales_gbp ELSE 0 END) AS ytd_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.refund_amount_gbp ELSE 0 END) AS ytd_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.sales_at_cost_gbp ELSE 0 END) AS ytd_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.checkout_discount_gbp ELSE 0 END) AS ytd_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.apportioned_tax_gbp ELSE 0 END) AS ytd_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = a.anchor_year AND o.tx_iso_week <= a.anchor_week THEN o.apportioned_shipping_gbp ELSE 0 END) AS ytd_apportioned_shipping_gbp,

        -------------------------------------------------------------------------
        -- 9. YTD LY
        -------------------------------------------------------------------------
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.sales_units ELSE 0 END) AS ytdly_sales_units,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.gross_sales_if_at_rrp_gbp ELSE 0 END) AS ytdly_gross_sales_if_at_rrp_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.gross_sales_before_discount_gbp ELSE 0 END) AS ytdly_gross_sales_before_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.full_price_gross_sales_gbp ELSE 0 END) AS ytdly_full_price_gross_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.net_sales_gbp ELSE 0 END) AS ytdly_net_sales_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.refund_amount_gbp ELSE 0 END) AS ytdly_refund_amount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.sales_at_cost_gbp ELSE 0 END) AS ytdly_sales_at_cost_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.checkout_discount_gbp ELSE 0 END) AS ytdly_checkout_discount_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.apportioned_tax_gbp ELSE 0 END) AS ytdly_apportioned_tax_gbp,
        SUM(CASE WHEN o.tx_iso_year = (a.anchor_year - 1) AND o.tx_iso_week <= a.anchor_week THEN o.apportioned_shipping_gbp ELSE 0 END) AS ytdly_apportioned_shipping_gbp

    FROM orders_with_iso o
    CROSS JOIN time_anchor a
    GROUP BY
        o.lineitem_sku
)

SELECT * FROM sku_aggregations