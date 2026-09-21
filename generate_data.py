import os
import csv
import random
from datetime import datetime, timedelta

data_dir = 'd:/Resume/Projects/e-commerce-dw/data/sample_data'

# Rename existing files to plural
if os.path.exists(f'{data_dir}/customer.csv'):
    os.rename(f'{data_dir}/customer.csv', f'{data_dir}/customers.csv')
if os.path.exists(f'{data_dir}/product.csv'):
    os.rename(f'{data_dir}/product.csv', f'{data_dir}/products.csv')

def write_csv(filepath, data):
    if not data: return
    keys = data[0].keys()
    with open(filepath, 'w', newline='') as f:
        dict_writer = csv.DictWriter(f, keys)
        dict_writer.writeheader()
        dict_writer.writerows(data)

# Generate Sales
sales_data = []
for i in range(1, 101):
    quantity = random.randint(1, 5)
    unit_price = round(random.uniform(10.0, 500.0), 2)
    discount_percent = round(random.uniform(0, 20), 2)
    total_amount = round(quantity * unit_price * (1 - discount_percent/100), 2)
    
    sales_data.append({
        'sale_id': i,
        'customer_id': random.randint(1, 10),
        'product_id': random.randint(1, 10),
        'salesperson_id': random.randint(1, 5),
        'order_date': (datetime.now() - timedelta(days=random.randint(1, 365))).strftime('%Y-%m-%d'),
        'delivery_date': (datetime.now() - timedelta(days=random.randint(1, 360))).strftime('%Y-%m-%d'),
        'quantity': quantity,
        'unit_price': unit_price,
        'discount_percent': discount_percent,
        'total_amount': total_amount,
        'profit': round(random.uniform(2.0, 50.0), 2),
        'city': 'New York',
        'state': 'NY',
        'country': 'USA'
    })
write_csv(f'{data_dir}/sales.csv', sales_data)

# Generate Inventory
inventory_data = []
for i in range(1, 21):
    q_on_hand = random.randint(50, 500)
    q_reserved = random.randint(0, 50)
    inventory_data.append({
        'inventory_id': i,
        'product_id': random.randint(1, 10),
        'warehouse_id': f'WH-{random.randint(1,3)}',
        'quantity_on_hand': q_on_hand,
        'quantity_reserved': q_reserved,
        'quantity_available': q_on_hand - q_reserved,
        'reorder_point': 100,
        'last_stock_date': '2025-01-01'
    })
write_csv(f'{data_dir}/inventory.csv', inventory_data)

# Generate Salesperson
salesperson_data = []
for i in range(1, 6):
    salesperson_data.append({
        'salesperson_id': i,
        'salesperson_name': f'Salesperson {i}',
        'email': f'sp{i}@email.com',
        'phone': f'+1-555-020{i}',
        'department': 'Sales',
        'region': 'North America',
        'manager_id': 1 if i > 1 else None,
        'hire_date': '2023-01-01'
    })
write_csv(f'{data_dir}/salesperson.csv', salesperson_data)

print("Data generation complete.")
