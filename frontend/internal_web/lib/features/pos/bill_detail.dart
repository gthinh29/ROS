import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'billing_provider.dart';
import '../../models/billing.dart';

class BillDetailPane extends ConsumerWidget {
  const BillDetailPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBill = ref.watch(currentBillProvider);
    final error = ref.watch(billingErrorProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'CHI TIẾT HÓA ĐƠN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (error != null)
              Expanded(
                child: Center(
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                ),
              ),
            if (error == null && currentBill == null)
              const Expanded(
                child: Center(
                  child: Text('Vui lòng chọn một bàn đang có khách (Màu đỏ).'),
                ),
              ),
            if (currentBill != null) ...[
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Mã Bill: ${currentBill.id}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildRow('Tạm tính:', currentBill.subtotal),
                    _buildRow('VAT (8%):', currentBill.tax),
                    _buildRow('Phí phục vụ:', currentBill.serviceFee),
                    if (currentBill.discount > 0)
                      _buildRow(
                        'Giảm giá:',
                        -currentBill.discount,
                        color: Colors.green,
                      ),
                    const Divider(thickness: 2),
                    _buildRow(
                      'TỔNG CỘNG:',
                      currentBill.total,
                      isBold: true,
                      fontSize: 24,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => SplitBillDialog(bill: currentBill),
                        );
                      },
                      child: const Text('TÁCH BILL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () => _showPaymentDialog(
                        context,
                        ref,
                        currentBill.id,
                        currentBill.total,
                      ),
                      child: const Text(
                        'THANH TOÁN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 16,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
                color: color,
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${amount.toStringAsFixed(0)} ₫',
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    String billId,
    double total,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => PaymentDialog(billId: billId, total: total),
    );
  }
}

class SplitBillDialog extends ConsumerStatefulWidget {
  final BillModel bill;
  const SplitBillDialog({super.key, required this.bill});

  @override
  ConsumerState<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends ConsumerState<SplitBillDialog> {
  int splitCount = 2;
  dynamic splitData; // SplitBillResponse
  final Set<int> paidParts = {};
  bool isLoading = false;

  Future<void> _fetchSplit() async {
    setState(() => isLoading = true);
    final res = await ref
        .read(billingProvider.notifier)
        .splitBill(widget.bill.id, splitCount);
    if (mounted)
      setState(() {
        splitData = res;
        isLoading = false;
      });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchSplit());
  }

  void _payPart(int partIndex) async {
    setState(() => paidParts.add(partIndex));

    // Nếu đây là người cuối cùng thanh toán, tự động Checkout tống cho Backend
    if (splitData != null && paidParts.length == splitData!.parts.length) {
      final success = await ref
          .read(billingProvider.notifier)
          .checkout(widget.bill.id, 'CASH', paidAmount: widget.bill.total);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tất cả đã thanh toán xong! Bàn đã được đóng.'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${ref.read(billingErrorProvider)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chia Đều (Split Bill)'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chia cho mấy người?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: splitCount,
                  items: [2, 3, 4, 5, 6, 7, 8]
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e, child: Text('$e người')),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null && val != splitCount) {
                      setState(() {
                        splitCount = val;
                        paidParts.clear();
                      });
                      _fetchSplit();
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (!isLoading && splitData != null)
              ...splitData!.parts.map((p) {
                final partIndex = p.partIndex;
                final isPaid = paidParts.contains(partIndex);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Phần $partIndex',
                    style: const TextStyle(fontSize: 18),
                  ),
                  subtitle: Text(
                    '${p.amount.toStringAsFixed(0)} ₫',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isPaid
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Đã thu',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: () => _payPart(partIndex),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text(
                            'Thu tiền',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                );
              }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class PaymentDialog extends ConsumerStatefulWidget {
  final String billId;
  final double total;
  const PaymentDialog({super.key, required this.billId, required this.total});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String _method = 'CASH';
  double? _paidAmount;
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thanh Toán'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tổng tiền: ${widget.total.toStringAsFixed(0)} ₫',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _method,
            items: const [
              DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt (CASH)')),
              DropdownMenuItem(
                value: 'VIETQR',
                child: Text('Chuyển khoản (VIETQR)'),
              ),
              DropdownMenuItem(value: 'CARD', child: Text('Quẹt Máy (CARD)')),
            ],
            onChanged: (val) => setState(() => _method = val!),
            decoration: const InputDecoration(
              labelText: 'Phương thức thanh toán',
            ),
          ),
          const SizedBox(height: 16),
          if (_method == 'CASH')
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Khách đưa',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  setState(() => _paidAmount = double.tryParse(val)),
            ),
          if (_method == 'CASH' &&
              _paidAmount != null &&
              _paidAmount! >= widget.total)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Tiền thừa: ${(_paidAmount! - widget.total).toStringAsFixed(0)} ₫',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_method == 'VIETQR')
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 150,
              height: 150,
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.qr_code, size: 100)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await ref
                .read(billingProvider.notifier)
                .checkout(
                  widget.billId,
                  _method,
                  paidAmount: _method == 'CASH' ? _paidAmount : null,
                );
            if (success && mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thanh toán thành công. Bàn đã được đóng.'),
                ),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${ref.read(billingErrorProvider)}'),
                ),
              );
            }
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
