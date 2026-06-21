"""add_is_featured_to_menu_item

Revision ID: 4fee1dc9926a
Revises: a1ae2ad8a292
Create Date: 2026-06-20 10:21:44.462236

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa



revision: str = '4fee1dc9926a'
down_revision: Union[str, Sequence[str], None] = 'a1ae2ad8a292'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    
    op.add_column('menu_items', sa.Column('is_featured', sa.Boolean(), server_default='false', nullable=False))
    


def downgrade() -> None:
    """Downgrade schema."""
    
    op.drop_column('menu_items', 'is_featured')
    
