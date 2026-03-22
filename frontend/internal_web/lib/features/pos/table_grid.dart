import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'table_provider.dart';
import '../../widgets/table_tile.dart';

class TableGrid extends ConsumerWidget {
  const TableGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tableProvider);

    return tablesAsync.when(
      data: (tables) {
        if (tables.isEmpty) {
          return const Center(child: Text('Không có dữ liệu bàn.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return TableTile(
              table: table,
              onTap: () {
                // Hành động khi bấm vào bàn
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu bàn: $err')),
    );
  }
}
