import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import '../../models/armada.dart';
import '../../models/sopir.dart';
import '../../services/api_service.dart';

part 'truk_event.dart';
part 'truk_state.dart';

class TrukBloc extends Bloc<TrukEvent, TrukState> {
  final ApiService _apiService;

  TrukBloc({required ApiService apiService})
      : _apiService = apiService,
        super(const TrukState()) {
    on<TrukDataLoaded>(_onDataLoaded);
    on<TrukArmadaChanged>(_onArmadaChanged);
    on<TrukSopirChanged>(_onSopirChanged);
    on<TrukDataSubmitted>(_onDataSubmitted);
  }

  Future<void> _onDataLoaded(
      TrukDataLoaded event, Emitter<TrukState> emit) async {
    emit(state.copyWith(status: TrukStatus.loading));
    try {
      // 1. Ambil data Armada, Sopir, dan Karyawan
      final results = await Future.wait([
        _apiService.fetchArmada(),
        _apiService.fetchSopir(),
        _apiService.fetchKaryawan(),
      ]);

      final armadaList = results[0] as List<Armada>;
      final sopirAsliList = results[1] as List<Sopir>;
      
      // Ambil list karyawan (bisa dynamic atau List<Karyawan> tergantung model Anda)
      final allKaryawanList = results[2]; 

      // 2. Filter Armada (Non-Inventaris)
      final filteredArmada =
          armadaList.where((armada) => armada.inventaris == 'N').toList();

      // 3. FILTER KHUSUS: Hanya ambil "WAWAN" (ID 204)
      // Kita cek apakah namanya mengandung "WAWAN" atau ID-nya "204"
      final wawanOnlyList = (allKaryawanList as List).where((k) {
        // Asumsi model Karyawan punya properti 'nama' dan 'id'
        // Kita gunakan toString() dan toUpperCase() untuk keamanan
        final nama = k.nama.toString().toUpperCase();
        final id = k.id.toString();
        
        return id == '204' || nama.contains('WAWAN');
      }).toList();

      // 4. Konversi Wawan menjadi Object Sopir
      List<Sopir> wawanJadiSopir = wawanOnlyList.map((k) {
        return Sopir(
          id: k.id.toString(),
          nama: k.nama,
          alias: k.alias ?? k.nama, // Pakai alias jika ada
          idProg: '-', // Dummy data
          nik: '-',    // Dummy data agar tidak error di UI
        );
      }).toList();

      // 5. Gabungkan List: Sopir Asli + Wawan
      final List<Sopir> gabunganList = [...sopirAsliList, ...wawanJadiSopir];

      // Hapus duplikat (jika Wawan ternyata sudah ada di list Sopir asli)
      final Map<String, Sopir> uniqueMap = {};
      for (var s in gabunganList) {
        uniqueMap[s.id] = s;
      }

      emit(state.copyWith(
        status: TrukStatus.success,
        daftarArmada: filteredArmada,
        daftarSopir: uniqueMap.values.toList(),
      ));

    } catch (e) {
      String errorMessage;
      if (e.toString().contains('SocketException')) {
        errorMessage =
            "KONEKSI_GAGAL: Tidak dapat terhubung ke server. Periksa koneksi internet Anda.";
      } else {
        errorMessage =
            "Gagal memuat data awal: ${e.toString().replaceAll("Exception: ", "")}";
      }

      emit(state.copyWith(
        status: TrukStatus.failure,
        errorMessage: errorMessage,
      ));
    }
  }

  void _onArmadaChanged(TrukArmadaChanged event, Emitter<TrukState> emit) {
    emit(state.copyWith(armadaTerpilih: event.armadaId));
  }

  void _onSopirChanged(TrukSopirChanged event, Emitter<TrukState> emit) {
    emit(state.copyWith(sopirTerpilih: event.sopirId));
  }

  Future<void> _onDataSubmitted(
      TrukDataSubmitted event, Emitter<TrukState> emit) async {
    if (state.armadaTerpilih == null) {
      return emit(state.copyWith(
          status: TrukStatus.submissionFailure,
          errorMessage: "Mohon pilih NOPOL terlebih dahulu."));
    }
    if (state.sopirTerpilih == null) {
      return emit(state.copyWith(
          status: TrukStatus.submissionFailure,
          errorMessage: "Mohon pilih nama sopir terlebih dahulu."));
    }

    emit(state.copyWith(status: TrukStatus.submitting));

    try {
      String? formatTanggal(String tanggal) {
        try {
          if (tanggal.isEmpty) return null;
          final parsedDate = DateFormat('dd-MM-yyyy').parse(tanggal);
          return DateFormat('yyyy-MM-dd').format(parsedDate);
        } catch (e) {
          return null;
        }
      }

      final List<File> validAttachments =
          event.attachments.whereType<File>().toList();

      String keteranganLain = event.keteranganLain ?? '';
      if (event.statusKIR == 'Tidak Ada') {
        keteranganLain = (keteranganLain.isEmpty ? '' : '$keteranganLain\n') +
            'Tidak ada Keterangan';
      }

      await _apiService.saveTrukCheck(
        armadaId: state.armadaTerpilih!,
        idSopir: int.tryParse(state.sopirTerpilih!),
        jenis: event.statusPengecekan == 'Masuk' ? 'IN' : 'OUT',
        kilometer: double.tryParse(event.kilometer),
        bbm: event.bbm,
        statusArmada: event.statusKondisi == 'Ready' ? 'Y' : 'N',
        keteranganArmada: event.statusKondisi == 'Servis'
            ? event.keteranganServis
            : 'Pengecekan Kendaraan Truk',
        keteranganSopir: "Sopir: ${event.namaSopir}",
        attachments: validAttachments,
        kernet: event.namaKernet,
        statusStnk: event.statusSTNK,
        stnkTanggal: formatTanggal(event.stnkTanggal),
        statusKir: event.statusKIR,
        kirTanggal: formatTanggal(event.kirTanggal),
        kirBet: event.kirBet.isEmpty ? null : event.kirBet,
        noLambung: event.noLambung,
        keterangan: keteranganLain,
      );

      emit(state.copyWith(status: TrukStatus.submissionSuccess));
    } catch (e) {
      String errorMessage = e.toString().replaceAll("Exception: ", "");
      if (errorMessage.contains('SocketException')) {
        errorMessage =
            "KONEKSI_GAGAL_SIMPAN: Gagal menyimpan data karena masalah jaringan. Coba lagi.";
      }

      emit(state.copyWith(
        status: TrukStatus.submissionFailure,
        errorMessage: errorMessage,
      ));
    } finally {
      emit(state.copyWith(status: TrukStatus.success, clearError: true));
    }
  }
}