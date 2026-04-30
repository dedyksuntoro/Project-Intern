import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/armada.dart';
import '../../../models/karyawan.dart';
import '../../../models/kendaraan_history.dart';
import '../../../services/api_service.dart';
import '../../../service_locator.dart';
part 'kendaraan_history_event.dart';
part 'kendaraan_history_state.dart';

class KendaraanHistoryBloc extends Bloc<KendaraanHistoryEvent, KendaraanHistoryState> {
  final ApiService _apiService = locator<ApiService>();

  KendaraanHistoryBloc() : super(const KendaraanHistoryState()) {
    on<KendaraanHistoryFetched>(_onHistoryFetched);
    on<KendaraanHistoryDeleted>(_onHistoryDeleted);
  }

  Future<void> _onHistoryFetched(
    KendaraanHistoryFetched event,
    Emitter<KendaraanHistoryState> emit,
  ) async {

    // Tampilkan loading jika status bukan success (initial, loading, atau failure)
    if (state.status != KendaraanHistoryStatus.success) {
      emit(state.copyWith(status: KendaraanHistoryStatus.loading));
    }
    
    try {
      final results = await Future.wait([
        _apiService.fetchKendaraanHistory(),
        _apiService.fetchArmada(),
        _apiService.fetchKaryawan(),
      ]);

      emit(state.copyWith(
        status: KendaraanHistoryStatus.success,
        historyList: results[0] as List<KendaraanHistory>,
        armadaList: results[1] as List<Armada>,
        karyawanList: results[2] as List<Karyawan>,
        errorMessage: null, 
      ));
    } catch (e) {
      // Cetak error dev
      print('Error di _onHistoryFetched (Kendaraan): $e');

      // Kirim pesan ke user
      emit(state.copyWith(
        status: KendaraanHistoryStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
      ));
    }
  }

  Future<void> _onHistoryDeleted(
    KendaraanHistoryDeleted event,
    Emitter<KendaraanHistoryState> emit,
  ) async {
    try {
      await _apiService.deleteKendaraanHistory(event.id);
      // Panggil event fetched untuk refresh list setelah berhasil hapus
      add(KendaraanHistoryFetched());
    } catch (e) {
      // Cetak error teknis ke konsol (untuk developer)
      print('Error di _onHistoryDeleted (Kendaraan): $e');
      
      // Kirim pesan yang user-friendly ke UI
      emit(state.copyWith(
        status: KendaraanHistoryStatus.failure,
        errorMessage: 'Gagal menghapus riwayat. Periksa koneksi internet Anda.',
      ));
    }
  }
}