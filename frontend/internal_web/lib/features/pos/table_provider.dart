import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/table.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class TableNotifier extends Notifier<AsyncValue<List<TableModel>>> {
  WebSocketChannel? _channel;

  @override
  AsyncValue<List<TableModel>> build() {
    _fetchTables();
    _connectWebSocket();
    
    ref.onDispose(() {
      _channel?.sink.close();
    });
    
    return const AsyncValue.loading();
  }

  Future<void> _fetchTables() async {
    try {
      final response = await apiClient.get('/tables');
      final List<dynamic> data = response.data;
      final tables = data.map((e) => TableModel.fromJson(e)).toList();
      state = AsyncValue.data(tables);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('${AppConstants.wsUrl}/pos'));
      _channel!.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          final tableId = data['table_id'];
          final statusStr = data['status'];
          if (tableId != null && statusStr != null) {
            final status = TableStatus.values.firstWhere(
              (e) => e.name.toUpperCase() == statusStr.toString().toUpperCase(),
              orElse: () => TableStatus.empty,
            );
            
            if (state.value != null) {
              final tables = state.value!.toList();
              final index = tables.indexWhere((t) => t.id == tableId);
              if (index != -1) {
                tables[index] = tables[index].copyWith(status: status);
                state = AsyncValue.data(tables);
              }
            }
          } else if (data['type'] == 'refresh') {
             _fetchTables();
          }
        } catch (_) {
          _fetchTables();
        }
      }, onError: (e) {
        print('WS Error: $e');
      }, onDone: () {
        print('WS Closed');
      });
    } catch (e) {
      print('WS Connect Error: $e');
    }
  }
}

final tableProvider = NotifierProvider<TableNotifier, AsyncValue<List<TableModel>>>(TableNotifier.new);
