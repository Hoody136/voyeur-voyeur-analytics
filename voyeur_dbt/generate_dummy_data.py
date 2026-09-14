import pandas as pd
import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker('en_GB')

# 1. THE MASTER CATALOG (Relational Integrity)
catalog = [
    {"sku": "25M1501P-FW25P-43-BLACK", "name": "Mens Jaya Evo Mules - Black", "cost": 45.00, "rrp": 155.00, "brand": "Vibram"},
    {"sku": "V-SS26P-26W2102PNAN-BEG", "name": "Womens Performa Jane Evo - Beige", "cost": 40.00, "rrp": 150.00, "brand": "Vibram"},
    {"sku": "RU02E1623-FW25P-50-BOSCO", "name": "Oversized Longsleeve Hoodie - Grey", "cost": 95.00, "rrp": 365.00, "brand": "Rick Owens"},
    {"sku": "RU02E1262-FW25P-50-WASHE", "name": "Hollywood Banana Longsleeve Tee", "cost": 65.00, "rrp": 235.00, "brand": "Rick Owens"},
    {"sku": "SPORT-SKIRT-BLK-M", "name": "Sport Uniform Skirt - Black", "cost": 70.00, "rrp": 250.00, "brand": "Voyeur"},
    {"sku": "CANDLE-MARM-175", "name": "Marmalade Candle - 175g", "cost": 15.00, "rrp": 60.00, "brand": "Voyeur"}
]

# ---------------------------------------------------------
# 2. GENERATE RANGE SHEET & PRODUCTS
# ---------------------------------------------------------
range_sheet_data = []
products_data = []

for item in catalog:
    # Master Range Sheet
    range_sheet_data.append({
        "VV SKU _Internal_": item["sku"],
        "PRODUCT NAME": item["name"],
        "BRAND": item["brand"],
        "GBP RRP": item["rrp"],
        "UNIT COST - GBP": item["cost"],
        "QTY ON ORDER": random.randint(50, 200),
        "QTY RECEIVED": random.randint(20, 100)
    })
    
    # Shopify Products Export (Live Prices)
    products_data.append({
        "Variant SKU": item["sku"],
        "Variant Price": item["rrp"] # Assuming full price on site
    })

pd.DataFrame(range_sheet_data).to_csv("dummy_master_range_sheet.csv", index=False)
pd.DataFrame(products_data).to_csv("dummy_raw_products_table.csv", index=False)

# ---------------------------------------------------------
# 3. GENERATE INVENTORY
# ---------------------------------------------------------
inventory_data = []
for item in catalog:
    current_stock = random.randint(0, 50)
    inventory_data.append({
        "SKU": item["sku"],
        "Title": item["name"],
        "Available _not editable_": current_stock,
        "On hand _current_": current_stock,
        "Location": "London Flagship"
    })
pd.DataFrame(inventory_data).to_csv("dummy_raw_inventory_table.csv", index=False)

# ---------------------------------------------------------
# 4. GENERATE SHOPIFY ORDERS
# ---------------------------------------------------------
order_data = []
start_date = datetime(2025, 1, 1)

for i in range(500): # Generates 500 orders
    order_id = f"#{1000 + i}"
    created_at = start_date + timedelta(days=random.randint(0, 365), hours=random.randint(8, 22))
    
    email = fake.email()
    num_items = random.randint(1, 3)
    cart_items = random.sample(catalog, num_items)
    
    subtotal = 0
    discount_amount = random.choice([0, 0, 50.00]) # Occasional cart discount
    
    for idx, item in enumerate(cart_items):
        qty = random.randint(1, 2)
        line_price = item["rrp"]
        line_total = line_price * qty
        subtotal += line_total
        
        row = {
            "Name": order_id,
            "Email": email if idx == 0 else None,
            "Financial Status": "paid" if idx == 0 else None,
            "Created at": created_at.strftime("%Y-%m-%d %H:%M:%S +0000"),
            "Paid at": created_at.strftime("%Y-%m-%d %H:%M:%S +0000"),
            "Lineitem quantity": qty,
            "Lineitem name": item["name"],
            "Lineitem price": line_price,
            "Lineitem sku": item["sku"],
            "Lineitem discount": 0,
            "Lineitem fulfillment status": "fulfilled",
            "Subtotal": subtotal - discount_amount if idx == 0 else None,
            "Shipping": 10.00 if idx == 0 else None,
            "Taxes": round((subtotal - discount_amount) * 0.20, 2) if idx == 0 else None,
            "Total": (subtotal - discount_amount) + 10.00 + round((subtotal - discount_amount) * 0.20, 2) if idx == 0 else None,
            "Discount Amount": discount_amount if idx == 0 else None,
            "Refunded Amount": 0 if idx == 0 else None
        }
        order_data.append(row)

pd.DataFrame(order_data).to_csv("dummy_raw_orders_table.csv", index=False)

# ---------------------------------------------------------
# 5. GENERATE SAMPLE SALES
# ---------------------------------------------------------
sample_sale_data = []
for i in range(50): # 50 Sample Sale offline transactions
    order_id = f"SS-{2000 + i}"
    item = random.choice(catalog)
    qty = 1
    liquidation_price = round(item["rrp"] * 0.30, 2) # 70% off for sample sale!
    
    sample_sale_data.append({
        "Name": order_id,
        "Email": fake.email(),
        "Paid at": (start_date + timedelta(days=random.randint(100, 105))).strftime("%Y-%m-%d %H:%M:%S +0000"), # Clustered over 5 days
        "Financial Status": "paid",
        "Lineitem sku": item["sku"],
        "Lineitem quantity": qty,
        "Subtotal": liquidation_price,
        "Taxes": round(liquidation_price * 0.20, 2),
        "Total": liquidation_price + round(liquidation_price * 0.20, 2),
        "Lineitem Additional Sample Sale Execution Costs": round(liquidation_price * 0.05, 2) # 5% venue cut
    })

pd.DataFrame(sample_sale_data).to_csv("dummy_raw_samplesale_table.csv", index=False)

print("🚀 Complete Dummy Ecosystem Generated! (5 CSV files)")