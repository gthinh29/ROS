"""add_cancelled_to_order_item_status

Revision ID: db697d1fb976
Revises: 918047c9da95
Create Date: 2026-03-26 13:06:32.378915

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'db697d1fb976'
down_revision: Union[str, Sequence[str], None] = '918047c9da95'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Thêm CANCELLED vào enum orderitemstatus."""
    op.execute("ALTER TYPE orderitemstatus ADD VALUE IF NOT EXISTS 'CANCELLED'")


def downgrade() -> None:
    """PostgreSQL không hỗ trợ xóa enum value, bỏ qua downgrade."""
    pass
