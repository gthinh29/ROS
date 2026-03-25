import io
import uuid
from typing import List

import qrcode
from sqlalchemy.orm import Session

from core.enums import TableStatus
from modules.tables.models import Table
from modules.tables.schemas import TableCreate


def create_table(db: Session, table_in: TableCreate) -> Table:
    # Generate unique QR token based on UUID
    qr_token = str(uuid.uuid4())
    
    db_table = Table(
        id=uuid.uuid4(),
        restaurant_id=table_in.restaurant_id,
        zone=table_in.zone,
        number=table_in.number,
        qr_token=qr_token,
        status=TableStatus.EMPTY,
    )
    db.add(db_table)
    db.commit()
    db.refresh(db_table)
    return db_table


def get_tables(db: Session) -> List[Table]:
    return db.query(Table).order_by(Table.zone, Table.number).all()


def get_table(db: Session, table_id: uuid.UUID) -> Table | None:
    return db.query(Table).filter(Table.id == table_id).first()


def generate_qr_code_png(qr_token: str) -> bytes:
    """Generate a PNG image as bytes from the qr_token."""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    
    # Giả lập URL mà khách hàng sẽ truy cập khi quét mã
    # Trong thực tế URL sẽ trỏ về Frontend (Customer Web), ví dụ: https://ros.vn/table/token
    frontend_table_url = f"https://ros.app/table/{qr_token}"
    
    qr.add_data(frontend_table_url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save to bytes buffer
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()
