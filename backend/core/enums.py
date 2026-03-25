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
    RESERVED = "RESERVED"
    CLEANING = "CLEANING"


class ReservationStatus(str, enum.Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    CHECKED_IN = "CHECKED_IN"
    CANCELLED = "CANCELLED"


class OrderType(str, enum.Enum):
    DINE_IN = "DINE_IN"
    PRE_ORDER = "PRE_ORDER"


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
    VIETQR = "VIETQR"
    CARD = "CARD"


class BillStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
