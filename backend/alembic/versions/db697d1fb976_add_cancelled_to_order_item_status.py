

from typing import Sequence, Union



from alembic import op

import sqlalchemy as sa







revision: str = 'db697d1fb976'

down_revision: Union[str, Sequence[str], None] = '918047c9da95'

branch_labels: Union[str, Sequence[str], None] = None

depends_on: Union[str, Sequence[str], None] = None





def upgrade() -> None:

    

    op.execute("ALTER TYPE orderitemstatus ADD VALUE IF NOT EXISTS 'CANCELLED'")





def downgrade() -> None:

    

    pass

