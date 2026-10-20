"""create remaining olist tables (customers, products, orders, items, payments, reviews, geolocation)"""
from alembic import op
import sqlalchemy as sa

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "olist_customers",
        sa.Column("customer_id", sa.CHAR(32), primary_key=True),
        sa.Column("customer_unique_id", sa.CHAR(32), nullable=False),
        sa.Column("customer_zip_code_prefix", sa.CHAR(5)),
        sa.Column("customer_city", sa.String(100)),
        sa.Column("customer_state", sa.CHAR(2)),
    )
    op.create_index("ix_olist_customers_unique_id", "olist_customers", ["customer_unique_id"])

    op.create_table(
        "olist_products",
        sa.Column("product_id", sa.CHAR(32), primary_key=True),
        sa.Column("product_category_name", sa.String(100)),
        sa.Column("product_name_length", sa.Integer),
        sa.Column("product_description_length", sa.Integer),
        sa.Column("product_photos_qty", sa.Integer),
        sa.Column("product_weight_g", sa.Integer),
        sa.Column("product_length_cm", sa.Integer),
        sa.Column("product_height_cm", sa.Integer),
        sa.Column("product_width_cm", sa.Integer),
    )

    op.create_table(
        "product_category_name_translation",
        sa.Column("product_category_name", sa.String(100), primary_key=True),
        sa.Column("product_category_name_english", sa.String(100)),
    )

    op.create_table(
        "olist_geolocation",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("geolocation_zip_code_prefix", sa.CHAR(5), nullable=False),
        sa.Column("geolocation_lat", sa.Float),
        sa.Column("geolocation_lng", sa.Float),
        sa.Column("geolocation_city", sa.String(100)),
        sa.Column("geolocation_state", sa.CHAR(2)),
    )
    op.create_index("ix_olist_geolocation_zip", "olist_geolocation", ["geolocation_zip_code_prefix"])

    op.create_table(
        "olist_orders",
        sa.Column("order_id", sa.CHAR(32), primary_key=True),
        sa.Column("customer_id", sa.CHAR(32),
                  sa.ForeignKey("olist_customers.customer_id"), nullable=False),
        sa.Column("order_status", sa.String(20)),
        sa.Column("order_purchase_timestamp", sa.DateTime),
        sa.Column("order_approved_at", sa.DateTime),
        sa.Column("order_delivered_carrier_date", sa.DateTime),
        sa.Column("order_delivered_customer_date", sa.DateTime),
        sa.Column("order_estimated_delivery_date", sa.DateTime),
    )
    op.create_index("ix_olist_orders_customer", "olist_orders", ["customer_id"])
    op.create_index("ix_olist_orders_purchase", "olist_orders", ["order_purchase_timestamp"])

    op.create_table(
        "olist_order_items",
        sa.Column("order_id", sa.CHAR(32), sa.ForeignKey("olist_orders.order_id"), nullable=False),
        sa.Column("order_item_id", sa.Integer, nullable=False),
        sa.Column("product_id", sa.CHAR(32), sa.ForeignKey("olist_products.product_id"), nullable=False),
        sa.Column("seller_id", sa.CHAR(32), sa.ForeignKey("olist_sellers.seller_id"), nullable=False),
        sa.Column("shipping_limit_date", sa.DateTime),
        sa.Column("price", sa.Numeric(12, 2)),
        sa.Column("freight_value", sa.Numeric(12, 2)),
        sa.PrimaryKeyConstraint("order_id", "order_item_id"),
    )
    op.create_index("ix_olist_order_items_product", "olist_order_items", ["product_id"])
    op.create_index("ix_olist_order_items_seller", "olist_order_items", ["seller_id"])

    op.create_table(
        "olist_order_payments",
        sa.Column("order_id", sa.CHAR(32), sa.ForeignKey("olist_orders.order_id"), nullable=False),
        sa.Column("payment_sequential", sa.Integer, nullable=False),
        sa.Column("payment_type", sa.String(20)),
        sa.Column("payment_installments", sa.Integer),
        sa.Column("payment_value", sa.Numeric(12, 2)),
        sa.PrimaryKeyConstraint("order_id", "payment_sequential"),
    )

    op.create_table(
        "olist_order_reviews",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column("review_id", sa.CHAR(32), nullable=False),
        sa.Column("order_id", sa.CHAR(32), sa.ForeignKey("olist_orders.order_id"), nullable=False),
        sa.Column("review_score", sa.Integer),
        sa.Column("review_comment_title", sa.Text),
        sa.Column("review_comment_message", sa.Text),
        sa.Column("review_creation_date", sa.DateTime),
        sa.Column("review_answer_timestamp", sa.DateTime),
    )
    op.create_index("ix_olist_order_reviews_order", "olist_order_reviews", ["order_id"])


def downgrade():
    op.drop_table("olist_order_reviews")
    op.drop_table("olist_order_payments")
    op.drop_table("olist_order_items")
    op.drop_table("olist_orders")
    op.drop_table("olist_geolocation")
    op.drop_table("product_category_name_translation")
    op.drop_table("olist_products")
    op.drop_table("olist_customers")