import os
import sys
from logging.config import fileConfig

# Make 'backend/' importable when alembic is invoked from the backend/ dir
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import engine_from_config, pool  # noqa: E402

from alembic import context  # noqa: E402
from core.config import settings  # noqa: E402
from core.database import Base  # noqa: E402

# Import all models so Alembic autogenerate can detect them
import modules.user.models  # noqa: E402, F401
import modules.auth.models  # noqa: E402, F401
import modules.tables.models  # noqa: E402, F401
import modules.menu.models  # noqa: E402, F401
import modules.inventory.models  # noqa: E402, F401
import modules.orders.models  # noqa: E402, F401
import modules.billing.models  # noqa: E402, F401
import modules.reservations.models  # noqa: E402, F401

# Alembic Config object — gives access to values in .ini file
config = context.config

# Wire DATABASE_URL from our pydantic settings (overrides alembic.ini value)
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

# Set up Python logging from alembic.ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Autogenerate support — point to all model metadata
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (no live DB connection required)."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode (connects to DB)."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
