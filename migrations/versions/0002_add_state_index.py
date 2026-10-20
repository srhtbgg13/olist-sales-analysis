"""add state index"""
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index("ix_olist_sellers_state", "olist_sellers", ["seller_state"])


def downgrade():
    op.drop_index("ix_olist_sellers_state", table_name="olist_sellers")