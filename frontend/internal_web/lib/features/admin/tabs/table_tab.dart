import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import '../../pos/table_provider.dart';
import '../../../core/constants.dart';

class TableTab extends ConsumerWidget {
  const TableTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableState = ref.watch(tableProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddTableDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: tableState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: \$e')),
        data: (tables) {
          if (tables.isEmpty) {
            return const Center(child: Text('Chưa có bàn nào.'));
          }
          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Số Bàn')),
                DataColumn(label: Text('Khu vực (Zone)')),
                DataColumn(label: Text('Trạng thái hiện tại')),
                DataColumn(label: Text('QR Order')),
              ],
              rows: tables.map((t) {
                return DataRow(
                  cells: [
                    DataCell(Text('Bàn ${t.number}')),
                    DataCell(Text(t.zone)),
                    DataCell(Text(t.status.name.toUpperCase())),
                    DataCell(
                      TextButton.icon(
                        icon: const Icon(Icons.qr_code, color: Colors.blue),
                        label: const Text('Tải QR'),
                        onPressed: () {
                          final url =
                              '${AppConstants.baseUrl}/tables/${t.id}/qr';
                          html.window.open(url, '_blank');
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class AddTableDialog extends ConsumerStatefulWidget {
  const AddTableDialog({super.key});

  @override
  ConsumerState<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends ConsumerState<AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  int number = 1;
  String zone = 'main';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Bàn Mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: number.toString(),
              decoration: const InputDecoration(labelText: 'Số Bàn'),
              keyboardType: TextInputType.number,
              onSaved: (val) => number = int.tryParse(val ?? '1') ?? 1,
            ),
            TextFormField(
              initialValue: zone,
              decoration: const InputDecoration(
                labelText: 'Khu vực (VD: T1, T2, VIP)',
              ),
              onSaved: (val) => zone = val ?? 'main',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final success = await ref
                  .read(tableProvider.notifier)
                  .createTable(number, zone);
              if (success && mounted) Navigator.pop(context);
            }
          },
          child: const Text('Tạo mới'),
        ),
      ],
    );
  }
}
