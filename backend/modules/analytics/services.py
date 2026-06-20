import datetime
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import func

from core.enums import OrderStatus, TableStatus
from modules.orders.models import Order, OrderItem
from modules.tables.models import Table
from modules.menu.models import MenuItem
from modules.analytics.schemas import DailyOverview, RevenuePoint, TopItem

def get_daily_overview(db: Session) -> DailyOverview:
    now_vn = datetime.datetime.now() + datetime.timedelta(hours=7)
    start_of_day = now_vn.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = start_of_day + datetime.timedelta(days=1)

    # Lấy các đơn hàng trong ngày (chỉ tính COMPLETED)
    orders = db.query(Order).filter(
        Order.status == OrderStatus.COMPLETED,
        Order.created_at >= start_of_day,
        Order.created_at < end_of_day
    ).all()

    total_revenue = float(sum((o.total or 0.0) for o in orders)) # type: ignore
    order_count = len(orders)

    # Đếm số bàn đang hoạt động (OCCUPIED)
    active_tables = db.query(Table).filter(Table.status == TableStatus.OCCUPIED).count()

    return DailyOverview(
        total_revenue=total_revenue,
        order_count=order_count,
        active_tables=active_tables
    )

def get_revenue_chart(db: Session) -> List[RevenuePoint]:
    now_vn = datetime.datetime.now() + datetime.timedelta(hours=7)
    start_of_today = now_vn.replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Lấy 7 ngày qua
    start_date = start_of_today - datetime.timedelta(days=6)

    # Gom nhóm theo ngày
    results = db.query(
        func.date_trunc('day', Order.created_at).label('date'),
        func.sum(Order.total).label('revenue')
    ).filter(
        Order.status == OrderStatus.COMPLETED,
        Order.created_at >= start_date
    ).group_by('date').order_by('date').all()

    # Tạo map dữ liệu để fill vào 7 ngày
    data_map = {row.date.strftime('%Y-%m-%d') if hasattr(row.date, 'strftime') else str(row.date)[:10]: float(row.revenue or 0) for row in results}

    chart_data = []
    for i in range(7):
        current_date = start_date + datetime.timedelta(days=i)
        date_str = current_date.strftime('%Y-%m-%d')
        chart_data.append(RevenuePoint(
            date=date_str,
            revenue=data_map.get(date_str, 0.0)
        ))

    return chart_data

def get_top_items(db: Session, limit: int = 5) -> List[TopItem]:
    now_vn = datetime.datetime.now() + datetime.timedelta(hours=7)
    start_of_today = now_vn.replace(hour=0, minute=0, second=0, microsecond=0)

    # Đếm số lượng món trong ngày
    results = db.query(
        MenuItem.name,
        func.sum(OrderItem.qty).label('quantity')
    ).join(OrderItem, OrderItem.menu_item_id == MenuItem.id)\
     .join(Order, Order.id == OrderItem.order_id)\
     .filter(
         Order.status == OrderStatus.COMPLETED,
         Order.created_at >= start_of_today
     ).group_by(MenuItem.name)\
     .order_by(func.sum(OrderItem.qty).desc())\
     .limit(limit).all()

    return [TopItem(name=r.name, quantity=int(r.quantity)) for r in results]
