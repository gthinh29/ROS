import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/core/api_client.dart';
import 'package:shared/models/reservation.dart';

class ReservationsState {
  final bool isLoading;
  final List<ReservationModel> reservations;
  final String? error;

  ReservationsState({
    this.isLoading = false,
    this.reservations = const [],
    this.error,
  });

  ReservationsState copyWith({
    bool? isLoading,
    List<ReservationModel>? reservations,
    String? error,
  }) {
    return ReservationsState(
      isLoading: isLoading ?? this.isLoading,
      reservations: reservations ?? this.reservations,
      error: error,
    );
  }
}

class ReservationsNotifier extends Notifier<ReservationsState> {
  @override
  ReservationsState build() {
    return ReservationsState();
  }

  Future<void> fetchReservations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.get('/reservations');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final reservations = data.map((e) => ReservationModel.fromJson(e)).toList();
        state = state.copyWith(isLoading: false, reservations: reservations);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to fetch reservations');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> checkin(String reservationId) async {
    try {
      final response = await apiClient.post('/reservations/$reservationId/checkin');
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchReservations(); 
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final reservationsProvider = NotifierProvider<ReservationsNotifier, ReservationsState>(
  ReservationsNotifier.new
);
