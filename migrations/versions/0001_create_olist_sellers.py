"""create olist sellers"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "olist_sellers",
        sa.Column("seller_id", sa.CHAR(32), primary_key=True),
        sa.Column("seller_zip_code_prefix", sa.CHAR(5), nullable=False),
        sa.Column("seller_city", sa.String(100)),
        sa.Column("seller_state", sa.CHAR(2)),
    )


def downgrade():
    op.drop_table("olist_sellers")