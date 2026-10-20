
import csv
import os
import sys
import time
from pathlib import Path
from sqlalchemy import create_engine

DATA_DIR = Path("data")
def txt(c):
    return f"NULLIF(TRIM({c}), '')"

def upper(c):
    return f"UPPER(NULLIF(TRIM({c}), ''))"

def ts(c):
    return f"NULLIF(TRIM({c}), '')::timestamp"

def num(c):
    return f"NULLIF(TRIM({c}), '')::numeric"

def intg(c):
    return f"NULLIF(TRIM({c}), '')::numeric::integer"

def dbl(c):
    return f"NULLIF(TRIM({c}), '')::double precision"

TABLES = [
    dict(
        table="olist_sellers", file="olist_sellers_dataset.csv",
        conflict="(seller_id)",
        cols=[
            ("seller_id", txt("seller_id")),
            ("seller_zip_code_prefix", txt("seller_zip_code_prefix")),
            ("seller_city", txt("seller_city")),
            ("seller_state", upper("seller_state")),
        ],
    ),
    dict(
        table="olist_customers", file="olist_customers_dataset.csv",
        conflict="(customer_id)",
        cols=[
            ("customer_id", txt("customer_id")),
            ("customer_unique_id", txt("customer_unique_id")),
            ("customer_zip_code_prefix", txt("customer_zip_code_prefix")),
            ("customer_city", txt("customer_city")),
            ("customer_state", upper("customer_state")),
        ],
    ),
    dict(
        table="olist_products", file="olist_products_dataset.csv",
        conflict="(product_id)",
        cols=[
            ("product_id", txt("product_id")),
            ("product_category_name", txt("product_category_name")),
            ("product_name_length", intg("product_name_lenght")),
            ("product_description_length", intg("product_description_lenght")),
            ("product_photos_qty", intg("product_photos_qty")),
            ("product_weight_g", intg("product_weight_g")),
            ("product_length_cm", intg("product_length_cm")),
            ("product_height_cm", intg("product_height_cm")),
            ("product_width_cm", intg("product_width_cm")),
        ],
    ),
    dict(
        table="product_category_name_translation",
        file="product_category_name_translation.csv",
        conflict="(product_category_name)",
        cols=[
            ("product_category_name", txt("product_category_name")),
            ("product_category_name_english", txt("product_category_name_english")),
        ],
    ),
    dict(
        table="olist_orders", file="olist_orders_dataset.csv",
        conflict="(order_id)",
        cols=[
            ("order_id", txt("order_id")),
            ("customer_id", txt("customer_id")),
            ("order_status", txt("order_status")),
            ("order_purchase_timestamp", ts("order_purchase_timestamp")),
            ("order_approved_at", ts("order_approved_at")),
            ("order_delivered_carrier_date", ts("order_delivered_carrier_date")),
            ("order_delivered_customer_date", ts("order_delivered_customer_date")),
            ("order_estimated_delivery_date", ts("order_estimated_delivery_date")),
        ],
    ),
    dict(
        table="olist_order_items", file="olist_order_items_dataset.csv",
        conflict="(order_id, order_item_id)",
        cols=[
            ("order_id", txt("order_id")),
            ("order_item_id", intg("order_item_id")),
            ("product_id", txt("product_id")),
            ("seller_id", txt("seller_id")),
            ("shipping_limit_date", ts("shipping_limit_date")),
            ("price", num("price")),
            ("freight_value", num("freight_value")),
        ],
    ),
    dict(
        table="olist_order_payments", file="olist_order_payments_dataset.csv",
        conflict="(order_id, payment_sequential)",
        cols=[
            ("order_id", txt("order_id")),
            ("payment_sequential", intg("payment_sequential")),
            ("payment_type", txt("payment_type")),
            ("payment_installments", intg("payment_installments")),
            ("payment_value", num("payment_value")),
        ],
    ),
    dict(
        table="olist_order_reviews", file="olist_order_reviews_dataset.csv",
        truncate=True,
        cols=[
            ("review_id", txt("review_id")),
            ("order_id", txt("order_id")),
            ("review_score", intg("review_score")),
            ("review_comment_title", txt("review_comment_title")),
            ("review_comment_message", txt("review_comment_message")),
            ("review_creation_date", ts("review_creation_date")),
            ("review_answer_timestamp", ts("review_answer_timestamp")),
        ],
    ),
    dict(
        table="olist_geolocation", file="olist_geolocation_dataset.csv",
        truncate=True,
        cols=[
            ("geolocation_zip_code_prefix", txt("geolocation_zip_code_prefix")),
            ("geolocation_lat", dbl("geolocation_lat")),
            ("geolocation_lng", dbl("geolocation_lng")),
            ("geolocation_city", txt("geolocation_city")),
            ("geolocation_state", upper("geolocation_state")),
        ],
    ),
]

def load_table(raw, spec):
    path = DATA_DIR / spec["file"]
    if not path.exists():
        raise FileNotFoundError(f"File tidak ditemukan: {path}")
    
    with open(path, encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        n_csv = sum(1 for _ in reader)

    cur = raw.cursor()
    cols_ddl = ", ".join(f'"{h.strip()}" TEXT' for h in header)
    cur.execute(f"CREATE TEMP TABLE stg ({cols_ddl}) ON COMMIT DROP")

    with open(path, encoding="utf-8-sig") as f:
        cur.copy_expert("COPY stg FROM STDIN WITH (FORMAT csv, HEADER true)", f)

    if spec.get("truncate"):
        cur.execute(f"TRUNCATE {spec['table']} RESTART IDENTITY")

    target = ", ".join(c for c, _ in spec["cols"])
    select = ", ".join(e for _, e in spec["cols"])
    conflict = f"ON CONFLICT {spec['conflict']} DO NOTHING" if spec.get("conflict") else ""
    cur.execute(f"INSERT INTO {spec['table']} ({target}) SELECT {select} FROM stg {conflict}")

    cur.execute(f"SELECT COUNT(*) FROM {spec['table']}")
    n_db = cur.fetchone()[0]
    raw.commit()
    return n_csv, n_db

def main():
    if "DATABASE_URL" not in os.environ:
        sys.exit("DATABASE_URL belum diset di jendela PowerShell ini.")
    engine = create_engine(os.environ["DATABASE_URL"])
    raw = engine.raw_connection()
    mismatches = []
    print(f"{'Tabel':<36}{'Baris CSV':>12}{'Baris tabel':>13}  Status")
    print("-" * 70)
    for spec in TABLES:
        start = time.time()
        try:
            n_csv, n_db = load_table(raw, spec)
        except Exception as e:
            raw.rollback()
            print(f"{spec['table']:<36}GAGAL")
            print(f"\nError pada tabel {spec['table']}:\n{e}")
            sys.exit(1)
        ok = n_csv == n_db
        if not ok:
            mismatches.append(spec["table"])
        status = "OK" if ok else "BEDA"
        print(f"{spec['table']:<36}{n_csv:>12,}{n_db:>13,}  {status} ({time.time() - start:.1f} dtk)")

    raw.close()
    print("-" * 70)
    if mismatches:
        print("Jumlah baris berbeda di:", ", ".join(mismatches))
        sys.exit(1)
    print("Semua tabel berhasil dimuat dan jumlah barisnya cocok.")
if __name__ == "__main__":
    main()