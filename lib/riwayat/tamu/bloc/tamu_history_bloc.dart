import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/tamu_history.dart';
import '../../../services/api_service.dart';
import '../../../service_locator.dart';
part 'tamu_history_event.dart';
part 'tamu_history_state.dart';

class TamuHistoryBloc extends Bloc<TamuHistoryEvent, TamuHistoryState> {
  final ApiService _apiService = locator<ApiService>();

  TamuHistoryBloc() : super(const TamuHistoryState()) {
    on<TamuHistoryFetched>(_onHistoryFetched);
    on<TamuHistoryDeleted>(_onHistoryDeleted);
  }

  Future<void> _onHistoryFetched(
    TamuHistoryFetched event,
    Emitter<TamuHistoryState> emit,
  ) async {
    if (state.status != TamuHistoryStatus.success) {
      emit(state.copyWith(status: TamuHistoryStatus.loading));
    }
    
    try {
      final tamuList = await _apiService.fetchTamuHistory();
      emit(state.copyWith(
        status: TamuHistoryStatus.success,
        tamuHistoryList: tamuList,
        errorMessage: null, // Bersihkan error message jika sukses
      ));
    } catch (e) {
      // Cetak error dev
      print('Error di _onHistoryFetched: $e');

      // gagal muat data
      emit(state.copyWith(
        status: TamuHistoryStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
      ));
    }
  }

  Future<void> _onHistoryDeleted(
    TamuHistoryDeleted event,
    Emitter<TamuHistoryState> emit,
  ) async {
    try {
      await _apiService.deleteTamuHistory(event.id);
    
      add(TamuHistoryFetched());
    } catch (e) {
      // Cetak error teknis ke konsol (untuk developer)
      print('Error di _onHistoryDeleted: $e');

      
      emit(state.copyWith(
        status: TamuHistoryStatus.failure,
        errorMessage: 'Gagal menghapus riwayat. Periksa koneksi internet Anda.',
      ));
    }
  }
}