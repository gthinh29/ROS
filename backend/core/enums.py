"""Shared enums used across multiple modules."""

import enum


class UserRole(str, enum.Enum):
    ADMIN = "ADMIN"
    CASHIER = "CASHIER"
    WAITER = "WAITER"
    KITCHEN = "KITCHEN"


class TableStatus(str, enum.Enum):
    EMPTY = "EMPTY"
    OCCUPIED = "OCCUPIED"
    WAITING = "WAITING"
    CLEANING = "CLEANING"


class OrderType(str, enum.Enum):
    DINE_IN = "DINE_IN"
    TAKEAWAY = "TAKEAWAY"


class OrderStatus(str, enum.Enum):
    PENDING = "PENDING"
    PREPARING = "PREPARING"
    READY = "READY"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class OrderItemStatus(str, enum.Enum):
    PENDING = "PENDING"
    PREPARING = "PREPARING"
    READY = "READY"
    SERVED = "SERVED"


class PaymentMethod(str, enum.Enum):
    CASH = "CASH"
    QR = "QR"
    CARD = "CARD"


class BillStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    CANCELLED = "CANCELLED"
