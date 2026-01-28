import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart'; 
import '../../../../models/tugas_umum.dart';
import '../../../../models/karyawan.dart';
import '../../../../models/armada.dart';
import '../../../../services/api_service.dart';
import '../../../../service_locator.dart';
part 'tugas_umum_history_event.dart';
part 'tugas_umum_history_state.dart';

class TugasUmumHistoryBloc extends Bloc<TugasUmumHistoryEvent, TugasUmumHistoryState> {
  final _apiService = locator<ApiService>();

  TugasUmumHistoryBloc() : super(const TugasUmumHistoryState()) {
    on<TugasUmumHistoryFetched>(_onHistoryFetched);
    on<TugasUmumHistoryDeleted>(_onHistoryDeleted);
    on<TugasUmumHistorySelesai>(_onHistorySelesai);
  }

  Future<void> _onHistoryFetched(
    TugasUmumHistoryFetched event,
    Emitter<TugasUmumHistoryState> emit,
  ) async {
    if (state.status != TugasUmumHistoryStatus.success) {
      emit(state.copyWith(status: TugasUmumHistoryStatus.loading));
    }
    try {
      final results = await Future.wait([
        _apiService.fetchTugasUmumHistory(),
        _apiService.fetchKaryawan(),
        _apiService.fetchArmada(),
      ]);
      
      final List rawHistory = results[0];
      final masterKaryawan = results[1] as List<Karyawan>;
      final masterArmada = results[2] as List<Armada>;

      final data = rawHistory.map<TugasUmum>((json) {
        var item = TugasUmum.fromJson(json);

        if (item.namaKaryawan == '-' || item.namaKaryawan == 'Tanpa Nama') {
          try {
            final karyawanFound = masterKaryawan.firstWhere(
              (k) => k.id.toString() == item.idKaryawan.toString(), 
            );
            item = item.copyWith(namaKaryawan: karyawanFound.nama);
          } catch (_) {}
        }

        if (item.idArmada != null) {
          try {
            final armadaFound = masterArmada.firstWhere(
              (a) => a.id.toString() == item.idArmada.toString(),
            );
            item = item.copyWith(nopol: armadaFound.nopol);
          } catch (_) {}
        }

        return item;
      }).toList();

      data.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(state.copyWith(
        status: TugasUmumHistoryStatus.success,
        historyList: data,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TugasUmumHistoryStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
      ));
    }
  }

  Future<void> _onHistoryDeleted(
    TugasUmumHistoryDeleted event,
    Emitter<TugasUmumHistoryState> emit,
  ) async {
    try {
      await _apiService.deleteTugasUmum(event.id);
      add(TugasUmumHistoryFetched());
    } catch (e) {
      emit(state.copyWith(
        status: TugasUmumHistoryStatus.failure,
        errorMessage: 'Gagal menghapus riwayat.',
      ));
    }
  }

  Future<void> _onHistorySelesai(
    TugasUmumHistorySelesai event,
    Emitter<TugasUmumHistoryState> emit,
  ) async {
    try {
      // 1. Panggil API PUT
      await _apiService.updateTugasUmumSelesai(event.item);

      // 2. Update Lokal (Optimistic UI)
      final currentList = state.historyList;
      final updatedList = currentList.map((tugas) {
        if (tugas.id == event.item.id) {
          final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
          return tugas.copyWith(jamSelesai: nowStr);
        }
        return tugas;
      }).toList();

      emit(state.copyWith(
        historyList: updatedList,
        status: TugasUmumHistoryStatus.success,
      ));
      
    } catch (e) {
      final rawError = e.toString();
      final cleanError = rawError.replaceAll('Exception:', '').trim();

      emit(state.copyWith(
        // penampillan alasan JELAS gagal
        errorMessage: cleanError, 
      ));
    }
  }
}