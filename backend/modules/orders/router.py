from fastapi import APIRouter

router = APIRouter(prefix="/orders", tags=["Orders"])

# TODO (TV1): Implement Order creation (ACID), state machine, KDS integration
