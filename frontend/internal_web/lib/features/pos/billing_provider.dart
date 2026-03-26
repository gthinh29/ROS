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
      // 1. Lấy đơn hàng đang hoạt động của bàn này
      final orderRes = await apiClient.get('/orders?table_id=$tableId');
      final List<dynamic> orders = orderRes.data['data'] ?? [];

      if (orders.isEmpty) {
        ref.read(billingErrorProvider.notifier).setError('Bàn này đang trống, không có đơn hàng.');
        return;
      }

      final orderId = orders.first['id'];

      // 2. Tạo hoặc lấy bill (backend tự động chỉ tính READY/SERVED)
      final billRes = await apiClient.post('/billing/create', data: {
        'order_id': orderId
      });

      final billData = billRes.data['data'] ?? billRes.data;
      ref.read(currentBillProvider.notifier).setBill(BillModel.fromJson(billData));

    } catch (e) {
      // Lấy message từ backend nếu có
      String errMsg = e.toString();
      try {
        final dioErr = e as dynamic;
        errMsg = dioErr.response?.data?['detail'] ?? errMsg;
      } catch (_) {}
      ref.read(billingErrorProvider.notifier).setError(errMsg);
    }
  }

  /// Thanh toán. Trả về [CheckoutReceiptData] nếu thành công, null nếu lỗi.
  Future<CheckoutReceiptData?> checkout(String billId, String paymentMethod, {double? paidAmount, double? billTotal}) async {
    try {
      final Map<String, dynamic> payload = {
        'bill_id': billId,
        'payment_method': paymentMethod,
      };
      if (paidAmount != null) {
        payload['paid_amount'] = paidAmount;
      }

      final res = await apiClient.post('/billing/checkout', data: payload);
      ref.read(currentBillProvider.notifier).setBill(null);
      ref.read(billingErrorProvider.notifier).setError(null);

      final resData = res.data['data'] ?? res.data;
      // Thêm total vào receipt data nếu backend không trả về (fallback từ bill)
      if (resData['total'] == null && billTotal != null) {
        resData['total'] = billTotal;
      }
      return CheckoutReceiptData.fromJson(resData);
    } catch (e) {
      String errMsg = e.toString();
      try {
        final dioErr = e as dynamic;
        errMsg = dioErr.response?.data?['detail'] ?? errMsg;
      } catch (_) {}
      ref.read(billingErrorProvider.notifier).setError(errMsg);
      return null;
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
      String errMsg = e.toString();
      try {
        final dioErr = e as dynamic;
        errMsg = dioErr.response?.data?['detail'] ?? errMsg;
      } catch (_) {}
      ref.read(billingErrorProvider.notifier).setError(errMsg);
      return null;
    }
  }
}

final billingProvider = NotifierProvider<BillingNotifier, void>(BillingNotifier.new);

