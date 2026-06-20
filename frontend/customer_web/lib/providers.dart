import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared/models/table.dart';

// Đổi base URL nếu chạy trên môi trường khác.
// Nếu chạy Docker cục bộ trên Windows, proxy Nginx gọi vào /api.
// Ở Customer Web, chúng ta gọi trực tiếp /api/...
const String baseUrl = '/api';

// --- State Class cho Available Tables ---
class AvailableTablesState {
  final bool isLoading;
  final List<TableModel> tables;
  final String? error;

  AvailableTablesState({
    this.isLoading = false,
    this.tables = const [],
    this.error,
  });
}

class AvailableTablesNotifier extends StateNotifier<AvailableTablesState> {
  AvailableTablesNotifier() : super(AvailableTablesState());

  Future<void> fetchTables(String date, String time) async {
    state = AvailableTablesState(isLoading: true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tables/available?date=$date&time=$time'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        final tables = data.map((t) => TableModel.fromJson(t)).toList();
        state = AvailableTablesState(isLoading: false, tables: tables);
      } else {
        state = AvailableTablesState(error: 'Không thể lấy dữ liệu bàn.');
      }
    } catch (e) {
      state = AvailableTablesState(error: e.toString());
    }
  }
}

final availableTablesProvider =
    StateNotifierProvider<AvailableTablesNotifier, AvailableTablesState>((ref) {
      return AvailableTablesNotifier();
    });

// --- Service tạo Đặt bàn ---
final reservationServiceProvider = Provider((ref) => ReservationService());

class ReservationService {
  Future<String?> createReservation(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reservations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) {
        final resData = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        return resData['id']; // Trả về reservation_id
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifyOtp(String reservationId, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reservations/$reservationId/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'otp_code': otpCode}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
