import 'package:flutter/material.dart';
import 'package:shared/models/table.dart';

class TableTile extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;

  const TableTile({super.key, required this.table, required this.onTap});

  List<Color> _getGradient() {
    switch (table.status) {
      case TableStatus.empty: return [Colors.white, Colors.grey.shade100];
      case TableStatus.occupied: return [Colors.blue.shade500, Colors.blue.shade700];
      case TableStatus.reserved: return [Colors.orange.shade400, Colors.orange.shade600];
      case TableStatus.cleaning: return [Colors.teal.shade400, Colors.teal.shade600];
    }
  }

  Color _getTextColor() {
    return table.status == TableStatus.empty ? Colors.black87 : Colors.white;
  }

  IconData _getIcon() {
    switch (table.status) {
      case TableStatus.empty: return Icons.event_seat;
      case TableStatus.occupied: return Icons.restaurant;
      case TableStatus.reserved: return Icons.history_toggle_off;
      case TableStatus.cleaning: return Icons.cleaning_services;
    }
  }

  String _getStatusText() {
    switch (table.status) {
      case TableStatus.empty: return 'TRỐNG';
      case TableStatus.occupied: return 'ĐANG DÙNG';
      case TableStatus.reserved: return 'ĐẶT TRƯỚC';
      case TableStatus.cleaning: return 'DỌN DẸP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradient(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getGradient()[1].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: table.status == TableStatus.empty 
              ? Border.all(color: Colors.grey.shade300, width: 1.5) 
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                _getIcon(), 
                size: 80, 
                color: textColor.withOpacity(0.15)
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        table.zone, 
                        style: TextStyle(fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8), fontSize: 13)
                      ),
                      Icon(_getIcon(), size: 18, color: textColor.withOpacity(0.8)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Bàn ${table.number}', 
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(), 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
