import uuid
import datetime
from typing import List

from sqlalchemy.orm import Session

from core.enums import TableStatus, ReservationStatus
from modules.tables.models import Table
from modules.tables.schemas import TableCreate, TableUpdate
from modules.reservations.models import Reservation


def create_table(db: Session, table_in: TableCreate) -> Table:
    db_table = Table(
        id=uuid.uuid4(),
        restaurant_id=table_in.restaurant_id,
        zone=table_in.zone,
        number=table_in.number,
        status=TableStatus.EMPTY,
        capacity=table_in.capacity,
        x_pos=table_in.x_pos,
        y_pos=table_in.y_pos,
    )
    db.add(db_table)
    db.commit()
    db.refresh(db_table)
    return db_table

def update_table(db: Session, table_id: uuid.UUID, data: TableUpdate) -> Table:
    table = get_table(db, table_id)
    if not table:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Table not found")
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(table, key, value)
        
    db.commit()
    db.refresh(table)
    return table


def get_tables(db: Session) -> List[Table]:
    all_tables = db.query(Table).order_by(Table.zone, Table.number).all()

    now_vn = datetime.datetime.now() + datetime.timedelta(hours=7)
    one_hour_later = now_vn + datetime.timedelta(hours=1)

    
    upcoming_res = db.query(Reservation).filter(
        Reservation.table_id.isnot(None),
        Reservation.status.in_([ReservationStatus.PENDING, ReservationStatus.CONFIRMED]),
        Reservation.reserved_at >= now_vn,
        Reservation.reserved_at <= one_hour_later
    ).all()

    
    res_map = {r.table_id: r.reserved_at for r in upcoming_res}

    for t in all_tables:
        db.expunge(t)
        
        t.upcoming_reservation_time = res_map.get(t.id)

    return all_tables


def get_table(db: Session, table_id: uuid.UUID) -> Table | None:
    return db.query(Table).filter(Table.id == table_id).first()

def get_available_tables(db: Session, target_date: datetime.date, target_time: datetime.time) -> List[Table]:
    target_dt = datetime.datetime.combine(target_date, target_time)
    
    
    start_dt = target_dt - datetime.timedelta(hours=2)
    end_dt = target_dt + datetime.timedelta(hours=2)
    
    blocked_table_ids = db.query(Reservation.table_id).filter(
        Reservation.table_id.isnot(None),
        Reservation.status.in_([ReservationStatus.PENDING, ReservationStatus.CONFIRMED, ReservationStatus.CHECKED_IN]),
        Reservation.reserved_at > start_dt,
        Reservation.reserved_at < end_dt
    ).all()
    
    blocked_ids = set([r[0] for r in blocked_table_ids])
    
    all_tables = db.query(Table).order_by(Table.zone, Table.number).all()

    now_vn = datetime.datetime.now() + datetime.timedelta(hours=7)
    is_immediate = target_dt < now_vn + datetime.timedelta(hours=2)

    for t in all_tables:
        db.expunge(t)
        if t.id in blocked_ids:
            t.status = TableStatus.RESERVED
        elif is_immediate and t.status != TableStatus.EMPTY:
            pass 
        else:
            t.status = TableStatus.EMPTY

    return all_tables
