

from typing import Sequence, Union



from alembic import op

import sqlalchemy as sa







revision: str = '4fee1dc9926a'

down_revision: Union[str, Sequence[str], None] = 'a1ae2ad8a292'

branch_labels: Union[str, Sequence[str], None] = None

depends_on: Union[str, Sequence[str], None] = None





def upgrade() -> None:

    

    

    op.add_column('menu_items', sa.Column('is_featured', sa.Boolean(), server_default='false', nullable=False))

    





def downgrade() -> None:

    

    

    op.drop_column('menu_items', 'is_featured')

    

