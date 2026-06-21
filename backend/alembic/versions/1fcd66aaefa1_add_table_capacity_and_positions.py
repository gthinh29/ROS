"""add_table_capacity_and_positions

Revision ID: 1fcd66aaefa1
Revises: 4fee1dc9926a
Create Date: 2026-06-20 10:24:22.319190

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa



revision: str = '1fcd66aaefa1'
down_revision: Union[str, Sequence[str], None] = '4fee1dc9926a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    
    op.add_column('tables', sa.Column('capacity', sa.Integer(), server_default='4', nullable=False))
    op.add_column('tables', sa.Column('x_pos', sa.Float(), server_default='0', nullable=False))
    op.add_column('tables', sa.Column('y_pos', sa.Float(), server_default='0', nullable=False))
    


def downgrade() -> None:
    """Downgrade schema."""
    
    op.drop_column('tables', 'y_pos')
    op.drop_column('tables', 'x_pos')
    op.drop_column('tables', 'capacity')
    
