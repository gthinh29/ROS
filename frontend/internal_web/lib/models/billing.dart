enum BillStatus { pending, paid, cancelled }

class BillModel {
  final String id;
  final String orderId;
  final double subtotal;
  final double tax;
  final double serviceFee;
  final double discount;
  final double total;
  final String? paymentMethod;
  final double? paidAmount;
  final double? changeAmount;
  final BillStatus status;

  BillModel({
    required this.id,
    required this.orderId,
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
    required this.discount,
    required this.total,
    this.paymentMethod,
    this.paidAmount,
    this.changeAmount,
    required this.status,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      serviceFee: (json['service_fee'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      paidAmount: json['paid_amount']?.toDouble(),
      changeAmount: json['change_amount']?.toDouble(),
      status: BillStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status']?.toString().toUpperCase()),
        orElse: () => BillStatus.pending,
      ),
    );
  }
}

class SplitBillPart {
  final int partIndex;
  final double amount;
  SplitBillPart({required this.partIndex, required this.amount});
  factory SplitBillPart.fromJson(Map<String, dynamic> json) {
    return SplitBillPart(
      partIndex: json['part_index'] as int,
      amount: (json['amount'] ?? 0.0).toDouble(),
    );
  }
}

class SplitBillResponse {
  final String billId;
  final int splitCount;
  final double total;
  final List<SplitBillPart> parts;
  SplitBillResponse({required this.billId, required this.splitCount, required this.total, required this.parts});
  factory SplitBillResponse.fromJson(Map<String, dynamic> json) {
    return SplitBillResponse(
      billId: json['bill_id'] as String,
      splitCount: json['split_count'] as int,
      total: (json['total'] ?? 0.0).toDouble(),
      parts: (json['parts'] as List<dynamic>?)?.map((e) => SplitBillPart.fromJson(e)).toList() ?? [],
    );
  }
}
