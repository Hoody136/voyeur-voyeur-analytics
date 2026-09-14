# Voyeur Voyeur Analytics: dbt Core Architecture

This repository contains the dbt Core data architecture for Voyeur Voyeur. It ingests raw operational data from Shopify and offline Sample Sales via BigQuery, transforms it applying robust commercial business logic, and outputs pristine, BI-ready tables for Looker Studio.

## 🏗️ Architecture Design (The Medallion Approach)

The project is structured into three distinct layers to ensure data integrity and modularity:

1. **Staging (`models/staging/`):** The "Loading Bay." This layer connects directly to the raw BigQuery tables. It standardizes column naming, enforces strict data types, and applies critical security measures.
2. **Intermediate (`models/intermediate/`):** The "Assembly Line." This layer unions the online and offline sales channels into a single pipeline and executes the heavy computational business logic (e.g., resolving missing discount data, allocating costs, and calculating rolling time-window metrics).
3. **Marts (`models/marts/`):** The "Storefront." The final consumption layer. These are the flat, highly optimized tables (`fct_order_lines`, `mart_sku_performance`) that connect directly to Looker Studio to power the trading and merchandising dashboards.

## 🔒 Security: The PII Firewall
To maintain strict compliance with data privacy standards (GDPR/CCPA), a PII (Personally Identifiable Information) firewall is implemented at the Staging layer. Customer email addresses from raw orders are immediately converted using a one-way cryptographic hash (`MD5`). The downstream warehouse retains a unique customer identifier for lifetime value (LTV) tracking, without ever exposing raw contact details.

## 🧮 Commercial Logic & Caveats

### 1. Synthetic Discount Apportionment
**The Challenge:** When a cart-level promo code is used, the raw Shopify export logs the total discount in the transaction header but leaves the line-item discount values blank. 
**The Solution:** The `int_orders_filled` model dynamically calculates the discount percentage of the total cart and pro-ratas that discount down to the individual line items. This ensures accurate net revenue calculations at the SKU level.

### 2. Refund "Smear Allocation" (Known Limitation)
**The Challenge:** The standard Shopify Orders CSV export logs the total `Refunded Amount` at the top-level transaction header. If a customer buys three items but only returns one, the raw data does not specify *which* item was returned.
**The Solution:** To ensure the financial ledger balances (Gross Profit and Net Sales remain financially accurate), the architecture uses a "Smear Allocation." The total refunded amount is calculated as a percentage of the overall basket, and that percentage is subtracted across every item in the cart.
*   **Impact:** Financial totals are 100% accurate. However, SKU-level return *unit rates* are mathematically smeared. 
*   **Future Roadmap:** To achieve true atomic return rates, the business must eventually migrate away from flat CSV exports and utilize a direct API pipeline (e.g., Fivetran) that tracks returns at the line-item grain natively.
