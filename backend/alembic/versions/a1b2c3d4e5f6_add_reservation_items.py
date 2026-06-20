"""add reservation_items table

Revision ID: a1b2c3d4e5f6
Revises: db697d1fb976
Create Date: 2026-04-30 06:11:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = 'db697d1fb976'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Tạo bảng reservation_items để lưu pre-order gắn với reservation."""
    op.create_table(
        'reservation_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            'reservation_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('reservations.id', ondelete='CASCADE'),
            nullable=False,
        ),
        sa.Column(
            'menu_item_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('menu_items.id'),
            nullable=False,
        ),
        sa.Column(
            'variant_id',
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey('variants.id'),
            nullable=True,
        ),
        # Comma-separated modifier UUIDs — simple approach, no extra join table
        sa.Column('modifier_ids', sa.Text(), nullable=True),
        sa.Column('qty', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('note', sa.Text(), nullable=True),
    )

    op.create_index(
        'ix_reservation_items_reservation_id',
        'reservation_items',
        ['reservation_id'],
    )


def downgrade() -> None:
    """Xóa bảng reservation_items."""
    op.drop_index('ix_reservation_items_reservation_id', table_name='reservation_items')
    op.drop_table('reservation_items')
