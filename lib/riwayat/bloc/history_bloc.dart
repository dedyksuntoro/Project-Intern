import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/armada.dart';
import '../../models/kendaraan_history.dart';
import '../../models/tamu_history.dart'; 
import '../../models/serah_terima_history.dart'; 
import '../../services/api_service.dart';
import '../../service_locator.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ApiService _apiService = locator<ApiService>();

  HistoryBloc() : super(const HistoryState()) {
    on<HistoryFetched>(_onHistoryFetched);
  }

  Future<void> _onHistoryFetched(
    HistoryFetched event,
    Emitter<HistoryState> emit,
  ) async {
    
    if (state.status != HistoryStatus.success) {
      emit(state.copyWith(status: HistoryStatus.loading));
    }
    try {
      
      final results = await Future.wait([
        _apiService.fetchKendaraanHistory(),
        _apiService.fetchArmada(),
        _apiService.fetchTamuHistory(), 
        _apiService.fetchSerahTerimaHistory(),
      ]);

   
      emit(state.copyWith(
        status: HistoryStatus.success,
        historyList: results[0] as List<KendaraanHistory>,
        armadaList: results[1] as List<Armada>,
        tamuHistoryList: results[2] as List<TamuHistory>,
        serahTerimaHistoryList: results[3] as List<SerahTerimaHistory>, 
      ));
    } catch (e) {
      // PERBAIKAN: Mengamankan error message agar tidak menyebabkan crash
      final errorMessage = e.toString().contains('Exception:') 
          ? e.toString().replaceAll('Exception: ', '') 
          : 'Terjadi kesalahan koneksi yang tidak diketahui.';

      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }
}