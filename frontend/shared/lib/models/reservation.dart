enum ReservationStatus { pending, confirmed, checked_in, cancelled }

class ReservationModel {
  final String id;
  final String customerName;
  final String phone;
  final String? email;
  final DateTime reservedAt;
  final int partySize;
  final ReservationStatus status;
  final String? tableId;
  final String? note;
  final List<dynamic> preOrderItems;

  ReservationModel({
    required this.id,
    required this.customerName,
    required this.phone,
    this.email,
    required this.reservedAt,
    required this.partySize,
    required this.status,
    this.tableId,
    this.note,
    this.preOrderItems = const [],
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      customerName: json['customer_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      reservedAt: DateTime.parse(json['reserved_at'] as String),
      partySize: json['party_size'] as int,
      status: ReservationStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String).toUpperCase(),
        orElse: () => ReservationStatus.pending,
      ),
      tableId: json['table_id'] as String?,
      note: json['note'] as String?,
      preOrderItems: json['pre_order_items'] as List<dynamic>? ?? [],
    );
  }
}
