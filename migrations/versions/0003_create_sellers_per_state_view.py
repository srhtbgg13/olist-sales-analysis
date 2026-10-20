"""create sellers per state view"""
from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        CREATE VIEW v_sellers_per_state AS
        SELECT seller_state, COUNT(*) AS jumlah_seller
        FROM olist_sellers
        GROUP BY seller_state
    """)


def downgrade():
    op.execute("DROP VIEW v_sellers_per_state")