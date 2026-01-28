import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../models/ob_history.dart';
import '../../../../models/karyawan.dart';
import '../../../../models/ob_area.dart';
import '../../../../models/ob_tugas.dart';
import '../../../../services/api_service.dart';
import '../../../../service_locator.dart';

part 'tugas_ob_history_event.dart';
part 'tugas_ob_history_state.dart';

class TugasObHistoryBloc extends Bloc<TugasObHistoryEvent, TugasObHistoryState> {
  final _apiService = locator<ApiService>();

  TugasObHistoryBloc() : super(const TugasObHistoryState()) {
    on<TugasObHistoryFetched>(_onFetched);
    on<TugasObHistoryDeleted>(_onDeleted);
  }

  Future<void> _onFetched(
    TugasObHistoryFetched event,
    Emitter<TugasObHistoryState> emit,
  ) async {
    if (state.status != TugasObHistoryStatus.success) {
      emit(state.copyWith(status: TugasObHistoryStatus.loading));
    }
    try {
      final results = await Future.wait([
        _apiService.fetchObHistory(),     // 0
        _apiService.fetchKaryawan(),      // 1
        _apiService.fetchObArea(),        // 2
        _apiService.fetchObMasterTugas(), // 3
      ]);
      
      // Mengembalikan deklarasi sesuai referensi tugas_umum_history_bloc.dart
      final List rawHistory = results[0]; 
      final masterKaryawan = results[1] as List<Karyawan>;
      final masterArea = results[2] as List<ObArea>;
      final masterTugas = results[3] as List<ObTugas>;

      final List<ObHistory> data = rawHistory.map((json) {
        var item = ObHistory.fromJson(json as Map<String, dynamic>);

        // A. TAMBAL NAMA KARYAWAN
        if (item.namaKaryawan == '-' || item.namaKaryawan == 'Tanpa Nama') {
          try {
            final found = masterKaryawan.firstWhere(
              (k) => k.id.toString().trim() == item.idKaryawan.toString().trim(),
            );
            item = item.copyWith(namaKaryawan: found.nama);
          } catch (_) {}
        }

        // B. TAMBAL NAMA AREA
        if (item.namaArea == '-' || item.namaArea == '') {
          try {
            final found = masterArea.firstWhere(
              (a) => a.id.toString().trim() == item.idArea.toString().trim(),
            );
            item = item.copyWith(namaArea: found.nama);
          } catch (_) {}
        }

        // C. TAMBAL NAMA TUGAS
        if (item.namaTugas == '-' || item.namaTugas == '') {
          try {
            final found = masterTugas.firstWhere(
              (t) => t.id.toString().trim() == item.idTugas.toString().trim(),
            );
            item = item.copyWith(namaTugas: found.nama);
          } catch (_) {}
        }

        return item;
      }).toList();

      data.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(state.copyWith(
        status: TugasObHistoryStatus.success,
        historyList: data,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TugasObHistoryStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
      ));
    }
  }

  Future<void> _onDeleted(
    TugasObHistoryDeleted event,
    Emitter<TugasObHistoryState> emit,
  ) async {
    try {
      await _apiService.deleteTugasOb(event.id);
      add(TugasObHistoryFetched());
    } catch (e) {
      // HANYA MENGUBAH BAGIAN INI
      emit(state.copyWith(
        status: TugasObHistoryStatus.failure,
        errorMessage: 'Gagal menghapus riwayat.',
      ));
    }
  }
}