

from typing import Sequence, Union



from alembic import op

import sqlalchemy as sa







revision: str = '1fcd66aaefa1'

down_revision: Union[str, Sequence[str], None] = '4fee1dc9926a'

branch_labels: Union[str, Sequence[str], None] = None

depends_on: Union[str, Sequence[str], None] = None





def upgrade() -> None:

    

    

    op.add_column('tables', sa.Column('capacity', sa.Integer(), server_default='4', nullable=False))

    op.add_column('tables', sa.Column('x_pos', sa.Float(), server_default='0', nullable=False))

    op.add_column('tables', sa.Column('y_pos', sa.Float(), server_default='0', nullable=False))

    





def downgrade() -> None:

    

    

    op.drop_column('tables', 'y_pos')

    op.drop_column('tables', 'x_pos')

    op.drop_column('tables', 'capacity')

    

