import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../models/armada.dart';
import '../../models/karyawan.dart';
import '../../services/api_service.dart';

part 'tugas_umum_event.dart';
part 'tugas_umum_state.dart';

class TugasUmumBloc extends Bloc<TugasUmumEvent, TugasUmumState> {
  final ApiService _apiService;

  TugasUmumBloc({required ApiService apiService})
      : _apiService = apiService,
        super(const TugasUmumState()) {
    on<LoadTugasData>(_onLoadTugasData);
    on<SubmitTugasUmum>(_onSubmitTugasUmum);
  }

  /// Memuat data Armada dan Karyawan dari API
  Future<void> _onLoadTugasData(
    LoadTugasData event,
    Emitter<TugasUmumState> emit,
  ) async {
    emit(state.copyWith(status: TugasUmumStatus.loading));
    try {
      final futureArmada = _apiService.fetchArmada();
      final futureKaryawan = _apiService.fetchKaryawan();

      final results = await Future.wait([futureArmada, futureKaryawan]);

      final allArmada = results[0] as List<Armada>;
      final daftarKaryawan = results[1] as List<Karyawan>;

      // Filter hanya armada yang merupakan inventaris
      final daftarInventaris =
          allArmada.where((armada) => armada.inventaris == "Y").toList();

      emit(state.copyWith(
        status: TugasUmumStatus.loaded,
        daftarArmada: daftarInventaris,
        daftarKaryawan: daftarKaryawan,
      ));
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('SocketException')) {
        errorMessage = "KONEKSI_GAGAL: Tidak dapat terhubung ke server. Periksa koneksi internet Anda.";
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      emit(state.copyWith(
        status: TugasUmumStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }

  /// Mengirim formulir tugas umum ke server
  Future<void> _onSubmitTugasUmum(
    SubmitTugasUmum event,
    Emitter<TugasUmumState> emit,
  ) async {
    emit(state.copyWith(status: TugasUmumStatus.submitting));
    try {
      final String statusKendaraan = (event.armadaId.isNotEmpty) ? 'INVENTARIS' : 'PRIBADI';

      await _apiService.submitTugasUmum(
        karyawanId: event.karyawanId,
        keperluan: event.keperluan,
        jamBerangkat: event.jamBerangkat,
        statusKendaraan: statusKendaraan,
        armadaId: event.armadaId, 
        foto: event.foto,
      );

      emit(state.copyWith(status: TugasUmumStatus.success));
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('SocketException')) {
          errorMessage = "KONEKSI_GAGAL_SIMPAN: Gagal menyimpan data karena masalah jaringan. Coba lagi.";
      }

      emit(state.copyWith(
        status: TugasUmumStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }
}