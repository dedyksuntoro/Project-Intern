import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../../models/cabang.dart';
import '../../models/ob_area.dart';
import '../../models/ob_tugas.dart';
import '../../models/karyawan.dart';
import '../../services/api_service.dart';

part 'tugas_ob_event.dart';
part 'tugas_ob_state.dart';

class TugasObBloc extends Bloc<TugasObEvent, TugasObState> {
  final ApiService apiService;

  TugasObBloc({required this.apiService}) : super(const TugasObState()) {
    on<TugasObDataLoaded>(_onDataLoaded);
    on<TugasObSubmitted>(_onDataSubmitted);
    on<TugasObCabangChanged>(_onCabangChanged);
    on<TugasObAreaChanged>(_onAreaChanged);
    on<TugasObTugasChanged>(_onTugasChanged);
    on<TugasObKaryawanChanged>(_onKaryawanChanged);
  }

  Future<void> _onDataLoaded(
    TugasObDataLoaded event,
    Emitter<TugasObState> emit,
  ) async {
    emit(state.copyWith(status: TugasObStatus.loading));
    try {
      // Panggil 4 API sekaligus secara paralel
      final results = await Future.wait([
        apiService.fetchCabang(),        // index 0
        apiService.fetchObArea(),        // index 1
        apiService.fetchObMasterTugas(), // index 2
        apiService.fetchKaryawan(),      // index 3
      ]);

      emit(state.copyWith(
        status: TugasObStatus.initial,
        daftarCabang: results[0] as List<Cabang>,
        daftarArea: results[1] as List<ObArea>,
        daftarTugas: results[2] as List<ObTugas>,
        daftarKaryawan: results[3] as List<Karyawan>,
      ));
    } catch (e) {
      // Deteksi Error Jaringan (Load Data)
      String errorMessage;
      if (e.toString().contains('SocketException')) {
        errorMessage = "KONEKSI_GAGAL: Tidak dapat terhubung ke server. Periksa koneksi internet Anda.";
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      emit(state.copyWith(
        status: TugasObStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }

  Future<void> _onDataSubmitted(
    TugasObSubmitted event,
    Emitter<TugasObState> emit,
  ) async {
    emit(state.copyWith(status: TugasObStatus.submitting));

    try {
      // 1. Format Tanggal
      final now = DateTime.now();
      final datePart = DateFormat('yyyy-MM-dd').format(now);
      
      final String fullBegin = "$datePart ${event.jamMulai}";
      final String fullEnd = "$datePart ${event.jamSelesai}";

      // 2. Panggil API Submit
      await apiService.submitTugasOb(
        areaId: event.areaId,
        tugasId: event.tugasId,
        karyawanId: event.karyawanId,
        begin: fullBegin,
        end: fullEnd,
        keterangan: event.keteranganLain,
        foto: event.fotoBukti,
      );

      emit(state.copyWith(status: TugasObStatus.success));
    } catch (e) {
      //Deteksi Error Jaringan (Submit Data)
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('SocketException')) {
          errorMessage = "KONEKSI_GAGAL_SIMPAN: Gagal menyimpan data karena masalah jaringan. Coba lagi.";
      }

      emit(state.copyWith(
        status: TugasObStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }

  void _onCabangChanged(
      TugasObCabangChanged event, Emitter<TugasObState> emit) {
    emit(state.copyWith(
      selectedCabang: event.selectedCabang,
      selectedArea: null,
    ));
  }

  void _onAreaChanged(TugasObAreaChanged event, Emitter<TugasObState> emit) {
    emit(state.copyWith(selectedArea: event.selectedArea));
  }

  void _onTugasChanged(TugasObTugasChanged event, Emitter<TugasObState> emit) {
    emit(state.copyWith(selectedTugas: event.selectedTugas));
  }

  void _onKaryawanChanged(
      TugasObKaryawanChanged event, Emitter<TugasObState> emit) {
    emit(state.copyWith(selectedKaryawan: event.selectedKaryawan));
  }
}