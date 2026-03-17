from fastapi import APIRouter

router = APIRouter(prefix="/billing", tags=["Billing"])

# TODO (TV1): Implement VAT, Voucher, Split Bill (item-based & evenly), checkout
