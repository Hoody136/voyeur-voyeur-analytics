-- 1. IMPORT CTE
WITH source AS (
    SELECT * FROM {{ source('voyeur_raw', 'master_range_sheet') }}
),

-- 2. CLEAN CTE: Standardizing column names and enforcing exact data types
renamed AS (
    SELECT
        -- Identifiers & Categorization
        SAFE_CAST(`NOTE` AS STRING) AS note,
        SAFE_CAST(`PO` AS STRING) AS po,
        SAFE_CAST(`VV SKU _Internal_` AS STRING) AS vv_sku,
        SAFE_CAST(`BRAND` AS STRING) AS brand,
        SAFE_CAST(`SEASON` AS STRING) AS season,
        SAFE_CAST(`PRE_MAIN` AS STRING) AS pre_main,
        SAFE_CAST(`CATEGORY` AS STRING) AS category,
        SAFE_CAST(`SUB CATEGORY` AS STRING) AS sub_category,
        
        -- Product Attributes
        SAFE_CAST(`STYLE CODES` AS STRING) AS style_codes,
        SAFE_CAST(`FABRIC CODE` AS STRING) AS fabric_code,
        SAFE_CAST(`COMPOSITION 1` AS STRING) AS composition_1,
        SAFE_CAST(`COMPOSITION 2` AS STRING) AS composition_2,
        SAFE_CAST(`COUNTRY OF ORIGIN` AS STRING) AS country_of_origin,
        SAFE_CAST(`PRODUCT NAME` AS STRING) AS product_name,
        SAFE_CAST(`BRAND COLOUR` AS STRING) AS brand_colour,
        SAFE_CAST(`VV COLOUR` AS STRING) AS vv_colour,
        SAFE_CAST(`GENDER` AS STRING) AS gender,
        SAFE_CAST(`SIZE` AS STRING) AS product_size,
        
        -- Barcodes
        SAFE_CAST(`BARCODES` AS STRING) AS barcodes,
        SAFE_CAST(`BRANDUPC_BARCODE` AS STRING) AS brand_upc_barcode,
        SAFE_CAST(`HS BARCODES` AS STRING) AS hs_barcodes,
        
        -- Financials & Pricing (Strictly FLOAT64 for math)
        SAFE_CAST(`GBP RRP` AS FLOAT64) AS gbp_rrp,
        SAFE_CAST(`EUR RRP` AS FLOAT64) AS eur_rrp,
        SAFE_CAST(`COST CURRENCY` AS STRING) AS cost_currency,
        SAFE_CAST(`UNIT COST _ORIGINAL_` AS FLOAT64) AS unit_cost_original,
        SAFE_CAST(`ORDER COST _ORIGINAL_` AS FLOAT64) AS order_cost_original,
        SAFE_CAST(`Live Price _` AS FLOAT64) AS live_price_do_not_use,
        SAFE_CAST(`UNIT COST - GBP` AS FLOAT64) AS unit_cost_gbp,
        
        -- FX Rates
        SAFE_CAST(`FX RATE: GBP to EURO` AS FLOAT64) AS fx_rate_gbp_to_euro,
        SAFE_CAST(`FX RATE: USD to EURO` AS FLOAT64) AS fx_rate_usd_to_euro,
        SAFE_CAST(`FX RATE: USD to GBP` AS FLOAT64) AS fx_rate_usd_to_gbp,
        
        -- Inventory Quantities (Strictly INT64)
        SAFE_CAST(`QTY ON ORDER` AS INT64) AS qty_on_order,
        SAFE_CAST(`QTY RECEIVED` AS INT64) AS qty_received,
        
        -- Dates & Logistics (Strictly DATE)
        SAFE_CAST(`DELIVERY PERIOD` AS DATE) AS delivery_period,
        SAFE_CAST(`DELIVERY DATE` AS DATE) AS delivery_date,
        SAFE_CAST(`TURNAROUND_DAYS` AS INT64) AS turnaround_days,
        SAFE_CAST(`LIVE DATE` AS DATE) AS live_date,
        SAFE_CAST(`DELIVERY WINDOW OPEN` AS DATE) AS delivery_window_open,
        SAFE_CAST(`DELIVERY WINDOW CLOSE` AS DATE) AS delivery_window_close

    FROM source
)

-- 3. FINAL OUTPUT
SELECT * FROM renamed