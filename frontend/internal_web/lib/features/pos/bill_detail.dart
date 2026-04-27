import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'billing_provider.dart';
import 'package:shared/models/billing.dart';

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
                    // Thông tin khách hàng (nếu có)
                    if (currentBill.tableNumber != null ||
                        currentBill.customerName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentBill.tableNumber != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.table_restaurant,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bàn số: ${currentBill.tableNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            if (currentBill.customerName != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Khách: ${currentBill.customerName}',
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (currentBill.phone != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SĐT: ${currentBill.phone}',
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Mã Bill: ${currentBill.id}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildRow(
                      'Tạm tính (đã hoàn thành):',
                      currentBill.subtotal,
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SplitBillDialog
// ─────────────────────────────────────────────────────────────────────────────

class SplitBillDialog extends ConsumerStatefulWidget {
  final BillModel bill;
  const SplitBillDialog({super.key, required this.bill});

  @override
  ConsumerState<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends ConsumerState<SplitBillDialog> {
  int splitCount = 2;
  dynamic splitData;
  final Set<int> paidParts = {};
  bool isLoading = false;

  Future<void> _fetchSplit() async {
    setState(() => isLoading = true);
    final res = await ref
        .read(billingProvider.notifier)
        .splitBill(widget.bill.id, splitCount);
    if (mounted) {
      setState(() {
        splitData = res;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchSplit());
  }

  void _payPart(int partIndex) async {
    setState(() => paidParts.add(partIndex));

    if (splitData != null && paidParts.length == splitData!.parts.length) {
      final receipt = await ref
          .read(billingProvider.notifier)
          .checkout(
            widget.bill.id,
            'CASH',
            paidAmount: widget.bill.total,
            billTotal: widget.bill.total,
          );
      if (receipt != null && mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => PaymentReceiptDialog(
            receipt: receipt,
            subtotal: widget.bill.subtotal,
            tax: widget.bill.tax,
            serviceFee: widget.bill.serviceFee,
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

// ─────────────────────────────────────────────────────────────────────────────
// PaymentDialog
// ─────────────────────────────────────────────────────────────────────────────

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

  bool get _canConfirm {
    if (_method == 'CASH') {
      return _paidAmount != null && _paidAmount! >= widget.total;
    }
    return true; // VIETQR / CARD không cần nhập tay
  }

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
            initialValue: _method,
            items: const [
              DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt (CASH)')),
              DropdownMenuItem(
                value: 'VIETQR',
                child: Text('Chuyển khoản (VIETQR)'),
              ),
              DropdownMenuItem(value: 'CARD', child: Text('Quẹt Máy (CARD)')),
            ],
            onChanged: (val) => setState(() {
              _method = val!;
              _paidAmount = null;
              _amountController.clear();
            }),
            decoration: const InputDecoration(
              labelText: 'Phương thức thanh toán',
            ),
          ),
          const SizedBox(height: 16),
          if (_method == 'CASH') ...[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Khách đưa (₫)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  setState(() => _paidAmount = double.tryParse(val)),
            ),
            const SizedBox(height: 8),
            // Hiển thị tiền thừa hoặc cảnh báo thiếu
            if (_paidAmount != null && _paidAmount! >= widget.total)
              Text(
                'Tiền thừa: ${(_paidAmount! - widget.total).toStringAsFixed(0)} ₫',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            else if (_paidAmount != null && _paidAmount! < widget.total)
              Text(
                'Thiếu: ${(widget.total - _paidAmount!).toStringAsFixed(0)} ₫ — Vui lòng nhập đủ tiền',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
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
          // Disable khi chưa đủ điều kiện
          onPressed: _canConfirm
              ? () async {
                  final receipt = await ref
                      .read(billingProvider.notifier)
                      .checkout(
                        widget.billId,
                        _method,
                        paidAmount: _method == 'CASH' ? _paidAmount : null,
                        billTotal: widget.total,
                      );
                  if (receipt != null && mounted) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => PaymentReceiptDialog(receipt: receipt),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${ref.read(billingErrorProvider)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canConfirm ? Colors.green : Colors.grey,
          ),
          child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentReceiptDialog — Phiếu hóa đơn sau thanh toán
// ─────────────────────────────────────────────────────────────────────────────

class PaymentReceiptDialog extends StatelessWidget {
  final CheckoutReceiptData receipt;
  final double? subtotal;
  final double? tax;
  final double? serviceFee;

  const PaymentReceiptDialog({
    super.key,
    required this.receipt,
    this.subtotal,
    this.tax,
    this.serviceFee,
  });

  Widget _receiptRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payMethodLabel =
        {
          'CASH': '💵 Tiền mặt',
          'VIETQR': '📲 Chuyển khoản',
          'CARD': '💳 Quẹt thẻ',
        }[receipt.paymentMethod] ??
        receipt.paymentMethod;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'PHIẾU THANH TOÁN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(thickness: 2),

            // Thông tin bàn & khách
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (receipt.tableNumber != null)
                    _receiptRow('Bàn số:', receipt.tableNumber!, bold: true),
                  if (receipt.customerName != null)
                    _receiptRow('Khách hàng:', receipt.customerName!),
                  if (receipt.phone != null)
                    _receiptRow('Số điện thoại:', receipt.phone!),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Chi tiết tiền
            if (subtotal != null)
              _receiptRow('Tạm tính:', '${subtotal!.toStringAsFixed(0)} ₫'),
            if (tax != null)
              _receiptRow('VAT:', '${tax!.toStringAsFixed(0)} ₫'),
            if (serviceFee != null)
              _receiptRow(
                'Phí dịch vụ:',
                '${serviceFee!.toStringAsFixed(0)} ₫',
              ),
            const Divider(),
            _receiptRow(
              'TỔNG CỘNG:',
              '${receipt.total.toStringAsFixed(0)} ₫',
              bold: true,
              color: Colors.red.shade700,
            ),
            const Divider(),
            _receiptRow('Phương thức:', payMethodLabel),
            _receiptRow(
              'Khách đưa:',
              '${receipt.paidAmount.toStringAsFixed(0)} ₫',
            ),
            _receiptRow(
              'Tiền thừa:',
              '${receipt.changeAmount.toStringAsFixed(0)} ₫',
              bold: true,
              color: Colors.green.shade700,
            ),

            const SizedBox(height: 16),

            // Footer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Thanh toán thành công!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('In hóa đơn'),
                    onPressed: () {
                      // TODO: Tích hợp in hóa đơn
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tính năng in hóa đơn sẽ được tích hợp sau.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
