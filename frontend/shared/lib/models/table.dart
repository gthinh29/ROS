enum TableStatus { empty, occupied, reserved, cleaning }

class TableModel {
  final String id;
  final String zone;
  final int number;
  final String qrToken;
  final TableStatus status;

  TableModel({
    required this.id,
    required this.zone,
    required this.number,
    required this.qrToken,
    required this.status,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as String,
      zone: json['zone'] as String,
      number: json['number'] as int,
      qrToken: json['qr_token'] as String? ?? '',
      status: TableStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String).toUpperCase(),
        orElse: () => TableStatus.empty,
      ),
    );
  }

  TableModel copyWith({
    String? id,
    String? zone,
    int? number,
    String? qrToken,
    TableStatus? status,
  }) {
    return TableModel(
      id: id ?? this.id,
      zone: zone ?? this.zone,
      number: number ?? this.number,
      qrToken: qrToken ?? this.qrToken,
      status: status ?? this.status,
    );
  }
}
