

from typing import Sequence, Union



from alembic import op

import sqlalchemy as sa







revision: str = 'b571287c8884'

down_revision: Union[str, Sequence[str], None] = '94c129aa2811'

branch_labels: Union[str, Sequence[str], None] = None

depends_on: Union[str, Sequence[str], None] = None





def upgrade() -> None:

    

    

    op.drop_table('reservation_items')

    





def downgrade() -> None:

    

    

    op.create_table('reservation_items',

    sa.Column('id', sa.UUID(), autoincrement=False, nullable=False),

    sa.Column('reservation_id', sa.UUID(), autoincrement=False, nullable=False),

    sa.Column('menu_item_id', sa.UUID(), autoincrement=False, nullable=False),

    sa.Column('variant_id', sa.UUID(), autoincrement=False, nullable=True),

    sa.Column('modifier_ids', sa.TEXT(), autoincrement=False, nullable=True),

    sa.Column('qty', sa.INTEGER(), server_default=sa.text('1'), autoincrement=False, nullable=False),

    sa.Column('note', sa.TEXT(), autoincrement=False, nullable=True),

    sa.ForeignKeyConstraint(['menu_item_id'], ['menu_items.id'], name=op.f('reservation_items_menu_item_id_fkey')),

    sa.ForeignKeyConstraint(['reservation_id'], ['reservations.id'], name=op.f('reservation_items_reservation_id_fkey'), ondelete='CASCADE'),

    sa.ForeignKeyConstraint(['variant_id'], ['variants.id'], name=op.f('reservation_items_variant_id_fkey')),

    sa.PrimaryKeyConstraint('id', name=op.f('reservation_items_pkey'))

    )

    

