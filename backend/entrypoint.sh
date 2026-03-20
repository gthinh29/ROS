#!/bin/sh
set -e

echo "═══════════════════════════════════════"
echo "  🚀 Starting Restaurant API"
echo "═══════════════════════════════════════"

# ── 1. Run Alembic migrations ─────────────────────────────────────────────────
echo "⏳ Running database migrations..."
alembic upgrade head
echo "✅ Migrations complete"

# ── 2. Seed (idempotent — only runs if DB is empty) ───────────────────────────
echo "⏳ Checking if seed is needed..."
SEED_CHECK=$(python - <<'EOF'
from core.database import SessionLocal
from modules.user.models import User
db = SessionLocal()
count = db.query(User).count()
db.close()
print(count)
EOF
)

if [ "$SEED_CHECK" = "0" ]; then
    echo "⏳ Seeding database with demo data..."
    python seed.py
else
    echo "⏭️  Seed skipped — database already has data (${SEED_CHECK} users found)"
fi

# ── 3. Start FastAPI server ────────────────────────────────────────────────────
echo "🌐 Starting Uvicorn..."
exec uvicorn main:app --host 0.0.0.0 --port 8000 --reload
