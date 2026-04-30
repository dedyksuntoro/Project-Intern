import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../models/serah_terima_history.dart'; // Sesuaikan path model Anda
import '../../../../services/api_service.dart';
import '../../../../service_locator.dart';

part 'serah_terima_history_event.dart';
part 'serah_terima_history_state.dart';

class SerahTerimaHistoryBloc extends Bloc<SerahTerimaHistoryEvent, SerahTerimaHistoryState> {
  final ApiService _apiService = locator<ApiService>();

  SerahTerimaHistoryBloc() : super(const SerahTerimaHistoryState()) {
    on<SerahTerimaHistoryFetched>(_onHistoryFetched);
    on<SerahTerimaHistoryDeleted>(_onHistoryDeleted);
  }

  Future<void> _onHistoryFetched(
    SerahTerimaHistoryFetched event,
    Emitter<SerahTerimaHistoryState> emit,
  ) async {
    if (state.status != SerahTerimaHistoryStatus.success) {
      emit(state.copyWith(status: SerahTerimaHistoryStatus.loading));
    }
    
    try {
      // Panggil API tanpa filter jenis ('sim', 'surat', 'dokumen', 'paket' semua diambil)
      final serahTerimaList = await _apiService.fetchSerahTerimaHistory(); 
      
      emit(state.copyWith(
        status: SerahTerimaHistoryStatus.success,
        serahTerimaList: serahTerimaList,
        errorMessage: null,
      ));
    } catch (e) {
      print('Error di _onHistoryFetched Serah Terima: $e');
      emit(state.copyWith(
        status: SerahTerimaHistoryStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
      ));
    }
  }

  Future<void> _onHistoryDeleted(
    SerahTerimaHistoryDeleted event,
    Emitter<SerahTerimaHistoryState> emit,
  ) async {
    try {
      await _apiService.deleteSerahTerimaHistory(event.id);
      // Refresh list setelah penghapusan berhasil
      add(SerahTerimaHistoryFetched()); 
    } catch (e) {
      print('Error di _onHistoryDeleted Serah Terima: $e');
      emit(state.copyWith(
        status: SerahTerimaHistoryStatus.failure,
        errorMessage: 'Gagal menghapus riwayat dokumen.',
      ));
    }
  }
}