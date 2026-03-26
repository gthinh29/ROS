import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/order.dart';

class OrderCard extends StatefulWidget {
  final OrderItemModel item;
  final int batchedQty;
  final Function(OrderItemStatus newStatus) onStatusChange;

  const OrderCard({
    super.key,
    required this.item,
    this.batchedQty = 1,
    required this.onStatusChange,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.item.createdAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.item.createdAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  Color _getBorderColor() {
    if (widget.item.status == OrderItemStatus.preparing) return Colors.orangeAccent;
    if (widget.item.status == OrderItemStatus.ready) return Colors.greenAccent;
    return Colors.grey.shade700; // Pending
  }
  
  Color _getTimeColor() {
    if (_elapsed.inMinutes > 15) return Colors.redAccent;
    if (_elapsed.inMinutes > 10) return Colors.orangeAccent;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor();
    final isReady = widget.item.status == OrderItemStatus.ready;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: widget.item.status != OrderItemStatus.pending ? [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Table + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: borderColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      'Bàn ${widget.item.tableNumber}', 
                      style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: _getTimeColor()),
                    const SizedBox(width: 4),
                    Text(_formatDuration(_elapsed), style: TextStyle(color: _getTimeColor(), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Item details
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.menuItemName,
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isReady ? Colors.white70 : Colors.white,
                      decoration: isReady ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (widget.batchedQty > 1) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('x${widget.batchedQty}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                  ),
                if (widget.batchedQty == 1 && widget.item.qty > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('x${widget.item.qty}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                  ),
              ],
            ),
            if (widget.item.variantName != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Loại: ${widget.item.variantName}', style: const TextStyle(color: Colors.white60, fontSize: 14)),
              ),
            if (widget.item.note != null && widget.item.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.item.note!, style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            // Action Buttons
            Row(
              children: [
                if (widget.item.status == OrderItemStatus.pending)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent, 
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => widget.onStatusChange(OrderItemStatus.preparing),
                      child: const Text('BẮT ĐẦU CHẾ BIẾN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (widget.item.status == OrderItemStatus.preparing)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent, 
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => widget.onStatusChange(OrderItemStatus.ready),
                      child: const Text('ĐÃ XONG (READY)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (widget.item.status == OrderItemStatus.ready)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.greenAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: null,
                      child: const Text('CHỜ BƯNG RA', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}
