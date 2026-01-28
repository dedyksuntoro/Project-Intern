import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../../models/armada.dart';
import '../../models/karyawan.dart';
import '../../services/api_service.dart';
part 'kendaraan_event.dart';
part 'kendaraan_state.dart';

class KendaraanBloc extends Bloc<KendaraanEvent, KendaraanState> {
  final ApiService _apiService;

  KendaraanBloc({required ApiService apiService})
      : _apiService = apiService,
        super(const KendaraanState()) {
    on<LoadInitialData>(_onLoadInitialData);
    on<ArmadaChanged>(_onArmadaChanged);
    on<KaryawanChanged>(_onKaryawanChanged);
    on<StatusPilihanChanged>(_onStatusPilihanChanged);
    on<BbmChanged>(_onBbmChanged);
    on<SubmitData>(_onSubmitData);
  }

  Future<void> _onLoadInitialData(
      LoadInitialData event, Emitter<KendaraanState> emit) async {
    emit(state.copyWith(status: KendaraanStatus.loading));
    try {
      // Memuat armada dan karyawan secara paralel
      final futureArmada = _apiService.fetchArmada();
      final futureKaryawan = _apiService.fetchKaryawan();

      final results = await Future.wait([futureArmada, futureKaryawan]);

      final List<Armada> armadaList = results[0] as List<Armada>;
      final List<Karyawan> karyawanList = results[1] as List<Karyawan>;

      // Filter hanya armada yang berstatus inventaris 'Y'
      final filteredArmada =
          armadaList.where((armada) => armada.inventaris == 'Y').toList();

      emit(state.copyWith(
        status: KendaraanStatus.success,
        daftarArmada: filteredArmada,
        daftarKaryawan: karyawanList,
      ));
    } catch (e) {
      String errorMessage;
      // Deteksi kegagalan koneksi
      if (e.toString().contains('SocketException')) {
        errorMessage = "KONEKSI_GAGAL: Tidak dapat terhubung ke server. Periksa koneksi internet Anda.";
      } else {
        errorMessage = "Gagal memuat data: ${e.toString().replaceAll("Exception: ", "")}";
      }

      emit(state.copyWith(
        status: KendaraanStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }

  void _onArmadaChanged(ArmadaChanged event, Emitter<KendaraanState> emit) {
    emit(state.copyWith(armadaTerpilih: event.armadaId));
  }

  void _onKaryawanChanged(KaryawanChanged event, Emitter<KendaraanState> emit) {
    emit(state.copyWith(karyawanTerpilih: event.karyawanId));
  }

  void _onStatusPilihanChanged(
      StatusPilihanChanged event, Emitter<KendaraanState> emit) {
    emit(state.copyWith(statusPilihan: event.status));
  }

  void _onBbmChanged(BbmChanged event, Emitter<KendaraanState> emit) {
    emit(state.copyWith(sisaBBM: event.bbmValue));
  }

  Future<void> _onSubmitData(
      SubmitData event, Emitter<KendaraanState> emit) async {
    // Validasi input dasar
    if (state.armadaTerpilih == null) {
      return emit(state.copyWith(
          status: KendaraanStatus.submissionFailure,
          errorMessage: "Mohon pilih NOPOL."));
    }
    if (state.karyawanTerpilih == null) {
      return emit(state.copyWith(
          status: KendaraanStatus.submissionFailure,
          errorMessage: "Mohon pilih nama karyawan."));
    }
    final kilometerValue = double.tryParse(event.kilometer);
    if (kilometerValue == null) {
      return emit(state.copyWith(
          status: KendaraanStatus.submissionFailure,
          errorMessage: "Kilometer tidak valid."));
    }

    // Validasi kelengkapan 4 kategori foto
    if (event.fotoLuar.isEmpty ||
        event.fotoDalam.isEmpty ||
        event.fotoSurat.isEmpty ||
        event.fotoPenanggungJawab.isEmpty) {
      return emit(state.copyWith(
          status: KendaraanStatus.submissionFailure,
          errorMessage: "Mohon unggah minimal satu foto untuk setiap kategori."));
    }

    emit(state.copyWith(status: KendaraanStatus.submitting));

    try {
      final List<File> attachments = [
        ...event.fotoLuar,
        ...event.fotoDalam,
        ...event.fotoSurat,
        ...event.fotoPenanggungJawab
      ];

      await _apiService.saveKendaraanCheck(
        armadaId: state.armadaTerpilih!,
        inventaris: 'Y',
        idKaryawan: int.tryParse(state.karyawanTerpilih!),
        jenis: state.statusPilihan == 'Masuk' ? 'IN' : 'OUT',
        kilometer: kilometerValue,
        bbm: state.sisaBBM,
        attachments: attachments,
        keterangan: event.keteranganLain,
        idSopir: null,
        statusArmada: 'Y',
        statusSopir: 'Y',
        keteranganArmada: 'Pengecekan Kendaraan Inventaris',
        keteranganSopir: null,
      );

      emit(state.copyWith(status: KendaraanStatus.submissionSuccess));

      _hapusFileTemporer(attachments);
    } catch (e) {
      String errorMessage = e.toString().replaceAll("Exception: ", "");
      if (errorMessage.contains('SocketException')) {
          errorMessage = "KONEKSI_GAGAL_SIMPAN: Gagal menyimpan data karena masalah jaringan. Coba lagi.";
      }
      
      emit(state.copyWith(
        status: KendaraanStatus.submissionFailure,
        errorMessage: errorMessage,
      ));
    } finally {
      // Reset status agar tidak memicu listener berulang
      emit(state.copyWith(
          status: KendaraanStatus.success, clearErrorMessage: true));
    }
  }

  Future<void> _hapusFileTemporer(List<File> files) async {
    for (var file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Abaikan error penghapusan file temporer
      }
    }
  }
}