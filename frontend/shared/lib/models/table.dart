enum TableStatus { empty, occupied, reserved, cleaning }

class TableModel {
  final String id;
  final String zone;
  final int number;
  final TableStatus status;
  final int? capacity;
  final DateTime? upcomingReservationTime;

  TableModel({
    required this.id,
    required this.zone,
    required this.number,
    required this.status,
    this.capacity,
    this.upcomingReservationTime,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as String,
      zone: json['zone'] as String,
      number: json['number'] as int,
      status: TableStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String).toUpperCase(),
        orElse: () => TableStatus.empty,
      ),
      capacity: json['capacity'] as int?,
      upcomingReservationTime: json['upcoming_reservation_time'] != null
          ? DateTime.parse(json['upcoming_reservation_time'] as String)
          : null,
    );
  }

  TableModel copyWith({
    String? id,
    String? zone,
    int? number,
    TableStatus? status,
    int? capacity,
    DateTime? upcomingReservationTime,
  }) {
    return TableModel(
      id: id ?? this.id,
      zone: zone ?? this.zone,
      number: number ?? this.number,
      status: status ?? this.status,
      capacity: capacity ?? this.capacity,
      upcomingReservationTime: upcomingReservationTime ?? this.upcomingReservationTime,
    );
  }
}
