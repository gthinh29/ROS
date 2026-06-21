

from typing import Sequence, Union



import sqlalchemy as sa

from alembic import op

from sqlalchemy.dialects import postgresql





revision: str = 'a1b2c3d4e5f6'

down_revision: Union[str, Sequence[str], None] = 'db697d1fb976'

branch_labels: Union[str, Sequence[str], None] = None

depends_on: Union[str, Sequence[str], None] = None





def upgrade() -> None:

    

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

    

    op.drop_index('ix_reservation_items_reservation_id', table_name='reservation_items')

    op.drop_table('reservation_items')

