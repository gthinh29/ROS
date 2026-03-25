import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/billing.dart';
import '../../core/api_client.dart';

class CurrentBillNotifier extends Notifier<BillModel?> {
  @override
  BillModel? build() => null;
  void setBill(BillModel? bill) => state = bill;
}
final currentBillProvider = NotifierProvider<CurrentBillNotifier, BillModel?>(CurrentBillNotifier.new);

class BillingErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setError(String? err) => state = err;
}
final billingErrorProvider = NotifierProvider<BillingErrorNotifier, String?>(BillingErrorNotifier.new);


class BillingNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> fetchBillForTable(String tableId) async {
    ref.read(billingErrorProvider.notifier).setError(null);
    ref.read(currentBillProvider.notifier).setBill(null);
    try {
      // 1. Get active orders for this table
      final orderRes = await apiClient.get('/orders?table_id=$tableId');
      final List<dynamic> orders = orderRes.data['data'] ?? [];
      
      if (orders.isEmpty) {
        ref.read(billingErrorProvider.notifier).setError('Bàn này đang trống, không có đơn hàng.');
        return;
      }
      
      // Get the first active order
      final orderId = orders.first['id'];

      // 2. Create or fetch the bill for the order
      final billRes = await apiClient.post('/billing/create', data: {
        'order_id': orderId
      });
      
      final billData = billRes.data['data'] ?? billRes.data;
      ref.read(currentBillProvider.notifier).setBill(BillModel.fromJson(billData));

    } catch (e) {
      ref.read(billingErrorProvider.notifier).setError(e.toString());
    }
  }

  Future<bool> checkout(String billId, String paymentMethod, {double? paidAmount}) async {
    try {
      final Map<String, dynamic> payload = {
        'bill_id': billId,
        'payment_method': paymentMethod, // Expected: CASH, VIETQR, CARD
      };
      if (paidAmount != null) {
        payload['paid_amount'] = paidAmount;
      }
      
      await apiClient.post('/billing/checkout', data: payload);
      ref.read(currentBillProvider.notifier).setBill(null);
      return true;
    } catch (e) {
      ref.read(billingErrorProvider.notifier).setError(e.toString());
      return false;
    }
  }

  Future<SplitBillResponse?> splitBill(String billId, int splitCount) async {
    try {
      final res = await apiClient.post('/billing/split', data: {
        'bill_id': billId,
        'split_count': splitCount,
      });
      final data = res.data['data'] ?? res.data;
      return SplitBillResponse.fromJson(data);
    } catch (e) {
      ref.read(billingErrorProvider.notifier).setError(e.toString());
      return null;
    }
  }
}

final billingProvider = NotifierProvider<BillingNotifier, void>(BillingNotifier.new);
