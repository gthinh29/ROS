

from typing import Sequence, Union



from alembic import op

import sqlalchemy as sa







revision: str = 'a1ae2ad8a292'

down_revision: Union[str, Sequence[str], None] = 'b571287c8884'

branch_labels: Union[str, Sequence[str], None] = None

depends_on: Union[str, Sequence[str], None] = None





def upgrade() -> None:

    

    

    op.drop_constraint(op.f('tables_qr_token_key'), 'tables', type_='unique')

    op.drop_column('tables', 'qr_token')

    





def downgrade() -> None:

    

    

    op.add_column('tables', sa.Column('qr_token', sa.TEXT(), autoincrement=False, nullable=True))

    op.create_unique_constraint(op.f('tables_qr_token_key'), 'tables', ['qr_token'], postgresql_nulls_not_distinct=False)

    

