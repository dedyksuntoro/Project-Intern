import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/serah_terima_history.dart'; 
import '../../../models/sopir.dart'; 
import '../../../services/api_service.dart';
import '../../../service_locator.dart';
part 'sim_history_event.dart';
part 'sim_history_state.dart';

class SimHistoryBloc extends Bloc<SimHistoryEvent, SimHistoryState> {
  final ApiService _apiService = locator<ApiService>(); 

  SimHistoryBloc() : super(const SimHistoryState()) {
    on<SimHistoryFetched>(_onHistoryFetched);
    on<SimHistoryDeleted>(_onHistoryDeleted);
  }

  Future<void> _onHistoryFetched(
    SimHistoryFetched event,
    Emitter<SimHistoryState> emit,
  ) async {
    if (state.status != SimHistoryStatus.success) {
      emit(state.copyWith(status: SimHistoryStatus.loading)); 
    }
    
    try {
      // Fetch data serah terima dan data sopir secara parallel
      final results = await Future.wait([
        _apiService.fetchSerahTerimaHistory(),
        _apiService.fetchSopir(), 
      ]);
      
      final allData = results[0] as List<SerahTerimaHistory>;
      final sopirList = results[1] as List<Sopir>; 
      
      // Filter henis sim
      final simList = allData.where((item) {
        return item.jenis.toLowerCase().trim() == 'sim';
      }).toList();
      
      emit(state.copyWith( 
        status: SimHistoryStatus.success,
        simHistoryList: simList,
        sopirList: sopirList, 
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith( 
        status: SimHistoryStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
      ));
    }
  }

  Future<void> _onHistoryDeleted(
    SimHistoryDeleted event,
    Emitter<SimHistoryState> emit,
  ) async {
    try {
      await _apiService.deleteSerahTerimaHistory(event.id); 
      add(SimHistoryFetched()); 
    } catch (e) {
      emit(state.copyWith(
        status: SimHistoryStatus.failure,
        errorMessage: 'Gagal menghapus riwayat. Periksa koneksi internet Anda.',
      ));
    }
  }
}