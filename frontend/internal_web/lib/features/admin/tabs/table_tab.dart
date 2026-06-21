// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pos/table_provider.dart';

// ─── Mock Zones ───────────────────────────────────────────────────────────────
const _kZones = ['Tất cả', 'Tầng 1', 'Sân vườn', 'Phòng VIP'];

class TableTab extends ConsumerStatefulWidget {
  const TableTab({super.key});

  @override
  ConsumerState<TableTab> createState() => _TableTabState();
}

class _TableTabState extends ConsumerState<TableTab> {
  String _selectedZone = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final tableState = ref.watch(tableProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddTableDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm bàn'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── Zone filter bar ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.table_restaurant_outlined,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Khu vực:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                ..._kZones.map(
                  (zone) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ZoneChip(
                      label: zone,
                      selected: _selectedZone == zone,
                      onTap: () => setState(() => _selectedZone = zone),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Table grid ───────────────────────────────────────────────────
          Expanded(
            child: tableState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại'),
                      onPressed: () => ref.invalidate(tableProvider),
                    ),
                  ],
                ),
              ),
              data: (tables) {
                final filtered = _selectedZone == 'Tất cả'
                    ? tables
                    : tables
                        .where((t) => t.zone == _selectedZone)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_restaurant_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có bàn nào trong khu vực này.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: filtered
                        .map(
                          (t) => _TableCard(
                            tableNumber: t.number,
                            zone: t.zone,
                            status: t.status.name,
                            capacity: t.capacity,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (_) => EditTableDialog(table: t),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zone Chip ────────────────────────────────────────────────────────────────
class _ZoneChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ZoneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3B82F6)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ─── Table Card ───────────────────────────────────────────────────────────────
class _TableCard extends StatefulWidget {
  final int tableNumber;
  final String zone;
  final String status;
  final int? capacity;
  final VoidCallback onEdit;

  const _TableCard({
    required this.tableNumber,
    required this.zone,
    required this.status,
    this.capacity,
    required this.onEdit,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  bool _hovered = false;

  Color get _statusColor {
    switch (widget.status.toLowerCase()) {
      case 'occupied':
        return const Color(0xFFEF4444);
      case 'reserved':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981); // available
    }
  }

  String get _statusLabel {
    switch (widget.status.toLowerCase()) {
      case 'occupied':
        return 'Đang dùng';
      case 'reserved':
        return 'Đã đặt';
      default:
        return 'Trống';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE2E8F0),
            width: _hovered ? 2 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Status indicator top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table icon + number
                  Row(
                    children: [
                      Icon(
                        Icons.table_restaurant_rounded,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bàn ${widget.tableNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Zone
                  Text(
                    widget.zone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),

                  // Capacity
                  if (widget.capacity != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.capacity} ghế',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hover action button
            if (_hovered)
              Positioned(
                right: 8,
                top: 10,
                child: _SmallIconBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF3B82F6),
                  tooltip: 'Sửa bàn',
                  onTap: widget.onEdit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _SmallIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

// ─── Add Table Dialog ─────────────────────────────────────────────────────────
class AddTableDialog extends ConsumerStatefulWidget {
  const AddTableDialog({super.key});

  @override
  ConsumerState<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends ConsumerState<AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  int number = 1;
  String zone = 'Tầng 1';
  int capacity = 4;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_circle_outline, color: Color(0xFF3B82F6)),
          SizedBox(width: 8),
          Text('Thêm Bàn Mới'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: number.toString(),
                decoration: _inputDeco('Số Bàn', Icons.tag),
                keyboardType: TextInputType.number,
                onSaved: (val) => number = int.tryParse(val ?? '1') ?? 1,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Không được trống' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: zone,
                items: const [
                  DropdownMenuItem(value: 'Tầng 1', child: Text('Tầng 1')),
                  DropdownMenuItem(
                    value: 'Sân vườn',
                    child: Text('Sân vườn'),
                  ),
                  DropdownMenuItem(
                    value: 'Phòng VIP',
                    child: Text('Phòng VIP'),
                  ),
                ],
                onChanged: (val) => setState(() => zone = val ?? 'Tầng 1'),
                decoration: _inputDeco('Khu vực', Icons.location_on_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: capacity.toString(),
                decoration: _inputDeco('Sức chứa (số ghế)', Icons.people_alt_outlined),
                keyboardType: TextInputType.number,
                onSaved: (val) => capacity = int.tryParse(val ?? '4') ?? 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Tạo mới'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final success = await ref
                  .read(tableProvider.notifier)
                  .createTable(number, zone);
              if (success && context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      );
}

// ─── Edit Table Dialog ────────────────────────────────────────────────────────
class EditTableDialog extends ConsumerStatefulWidget {
  final dynamic table; // RestaurantTable or dynamic from provider
  const EditTableDialog({super.key, required this.table});

  @override
  ConsumerState<EditTableDialog> createState() => _EditTableDialogState();
}

class _EditTableDialogState extends ConsumerState<EditTableDialog> {
  final _formKey = GlobalKey<FormState>();
  late String zone;
  late int capacity;

  @override
  void initState() {
    super.initState();
    zone = widget.table.zone ?? 'Tầng 1';
    capacity = widget.table.capacity ?? 4;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text('Sửa Bàn ${widget.table.number}'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: zone,
                items: const [
                  DropdownMenuItem(value: 'Tầng 1', child: Text('Tầng 1')),
                  DropdownMenuItem(
                    value: 'Sân vườn',
                    child: Text('Sân vườn'),
                  ),
                  DropdownMenuItem(
                    value: 'Phòng VIP',
                    child: Text('Phòng VIP'),
                  ),
                ],
                onChanged: (val) => setState(() => zone = val ?? zone),
                decoration: InputDecoration(
                  labelText: 'Khu vực',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: capacity.toString(),
                decoration: InputDecoration(
                  labelText: 'Sức chứa (số ghế)',
                  prefixIcon: const Icon(
                    Icons.people_alt_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSaved: (val) => capacity = int.tryParse(val ?? '4') ?? 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Lưu thay đổi'),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final payload = {'zone': zone, 'capacity': capacity};
              final success = await ref
                  .read(tableProvider.notifier)
                  .updateTable(widget.table.id, payload);
              if (success && context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
