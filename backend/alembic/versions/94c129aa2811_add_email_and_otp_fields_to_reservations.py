"""Add email and otp fields to reservations

Revision ID: 94c129aa2811
Revises: a1b2c3d4e5f6
Create Date: 2026-06-20 08:24:36.380816

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa



revision: str = '94c129aa2811'
down_revision: Union[str, Sequence[str], None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    
    op.drop_index(op.f('ix_reservation_items_reservation_id'), table_name='reservation_items')
    op.add_column('reservations', sa.Column('email', sa.String(length=255), nullable=False))
    op.add_column('reservations', sa.Column('otp_code', sa.String(length=10), nullable=True))
    op.add_column('reservations', sa.Column('otp_expires_at', sa.DateTime(timezone=True), nullable=True))
    


def downgrade() -> None:
    """Downgrade schema."""
    
    op.drop_column('reservations', 'otp_expires_at')
    op.drop_column('reservations', 'otp_code')
    op.drop_column('reservations', 'email')
    op.create_index(op.f('ix_reservation_items_reservation_id'), 'reservation_items', ['reservation_id'], unique=False)
    
