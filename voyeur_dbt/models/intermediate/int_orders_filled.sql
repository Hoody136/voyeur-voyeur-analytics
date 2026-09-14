-- 1. IMPORT CTE: Grabbing the fully stacked Shopify & Sample Sale orders
WITH unioned_orders AS (
    SELECT * FROM {{ ref('int_orders_unioned') }}
),

-- 2. TRANSACTION HEADERS: Cart-Level Percentage Math
order_headers AS (
    -- DISTINCT is crucial here to prevent cartesian fan-outs when joining back to lines
    SELECT DISTINCT
        order_number,
        SAFE_DIVIDE(
            COALESCE(discount_amount, 0),
            (COALESCE(subtotal, 0) + COALESCE(discount_amount, 0))
        ) AS cart_discount_percentage
    FROM unioned_orders
    WHERE financial_status IS NOT NULL
),

-- 3. GLUE & POPULATE MISSING DISCOUNTS
base_lines AS (
    SELECT
        lines.* EXCEPT(lineitem_discount),
        
        -- THE DISCOUNT FIX: Injecting the synthetic discount if Shopify left it blank
        CASE
            WHEN COALESCE(lines.discount_amount, 0) > 0 AND COALESCE(lines.lineitem_discount, 0) = 0 THEN
                (lines.lineitem_price * headers.cart_discount_percentage) * lines.lineitem_quantity
            ELSE COALESCE(lines.lineitem_discount, 0)
        END AS lineitem_discount
        
    FROM unioned_orders AS lines
    LEFT JOIN order_headers AS headers
        ON lines.order_number = headers.order_number
),

-- 4. CORE SALES METRICS (Gross and Net)
sales_calculations AS (
    SELECT
        *,
        -- Gross Sales (Original Price * Qty)
        (lineitem_price * lineitem_quantity) AS lineitem_gross_sales_before_discount,

        -- Net Sales (Gross Sales minus the True Lineitem Discount)
        ((lineitem_price * lineitem_quantity) - lineitem_discount) AS lineitem_netsales_afterdiscount_before_returns,

        -- Actual Selling Price Per Unit
        SAFE_DIVIDE(
            ((lineitem_price * lineitem_quantity) - lineitem_discount), 
            lineitem_quantity
        ) AS lineitem_selling_price
    FROM base_lines
),

-- 5. COST ALLOCATIONS (The Shipping Fix & Taxes)
cost_allocations AS (
    SELECT
        *,
        -- THE SHIPPING FIX: Uses actual shipping value instead of reverse-engineering the Total
        SAFE_DIVIDE(COALESCE(shipping, 0), subtotal) * lineitem_netsales_afterdiscount_before_returns AS lineitem_shipping,
        
        -- Pro-rata Tax allocation
        SAFE_DIVIDE(COALESCE(taxes, 0), subtotal) * lineitem_netsales_afterdiscount_before_returns AS lineitem_tax
    FROM sales_calculations
),

-- 6. REFUND ALLOCATIONS
final_output AS (
    SELECT
        *,
        SAFE_DIVIDE(COALESCE(refunded_amount, 0), total) * (lineitem_netsales_afterdiscount_before_returns + COALESCE(lineitem_shipping, 0)) AS lineitem_refund
    FROM cost_allocations
)

SELECT * FROM final_output