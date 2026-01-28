import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/armada.dart';
import '../../../models/sopir.dart';
import '../../../models/karyawan.dart'; // Pastikan import ini ada
import '../../../models/kendaraan_history.dart';
import '../../../services/api_service.dart';
import '../../../service_locator.dart';

part 'truk_history_event.dart';
part 'truk_history_state.dart';

class TrukHistoryBloc extends Bloc<TrukHistoryEvent, TrukHistoryState> {
  final ApiService _apiService = locator<ApiService>();

  TrukHistoryBloc() : super(const TrukHistoryState()) {
    on<TrukHistoryFetched>(_onHistoryFetched);
    on<TrukHistoryDeleted>(_onHistoryDeleted);
  }

  Future<void> _onHistoryFetched(
    TrukHistoryFetched event,
    Emitter<TrukHistoryState> emit,
  ) async {
    if (state.status != TrukHistoryStatus.success) {
      emit(state.copyWith(status: TrukHistoryStatus.loading));
    }
    
    try {
      final results = await Future.wait([
        _apiService.fetchKendaraanHistory(),
        _apiService.fetchArmada(),
        _apiService.fetchSopir(),
        _apiService.fetchKaryawan(), 
      ]);

      final historyList = results[0] as List<KendaraanHistory>;
      final armadaList = results[1] as List<Armada>;
      final sopirAsliList = results[2] as List<Sopir>;
      final allKaryawanList = results[3]; 

    
      final wawanOnlyList = (allKaryawanList as List).where((k) {
        final nama = k.nama.toString().toUpperCase();
        final id = k.id.toString();
        return id == '204' || nama.contains('WAWAN');
      }).toList();

     
      List<Sopir> wawanJadiSopir = wawanOnlyList.map((k) {
        return Sopir(
          id: k.id.toString(),
          nama: k.nama,
          alias: k.alias ?? k.nama,
          idProg: '-',
          nik: '-',
        );
      }).toList();

     
      final List<Sopir> gabunganSopir = [...sopirAsliList, ...wawanJadiSopir];

     
      final Map<String, Sopir> uniqueSopirMap = {};
      for (var s in gabunganSopir) {
        uniqueSopirMap[s.id] = s;
      }

      emit(state.copyWith(
        status: TrukHistoryStatus.success,
        historyList: historyList,
        armadaList: armadaList,
        sopirList: uniqueSopirMap.values.toList(), // list gabungan
        errorMessage: null,
      ));
    } catch (e) {
      print('Error di _onHistoryFetched (Truk): $e');
      emit(state.copyWith(
        status: TrukHistoryStatus.failure,
        errorMessage: 'Gagal memuat data. Periksa koneksi internet Anda.',
      ));
    }
  }

  Future<void> _onHistoryDeleted(
    TrukHistoryDeleted event,
    Emitter<TrukHistoryState> emit,
  ) async {
    try {
      await _apiService.deleteKendaraanHistory(event.id);
      add(TrukHistoryFetched());
    } catch (e) {
      print('Error di _onHistoryDeleted (Truk): $e');
      emit(state.copyWith(
        status: TrukHistoryStatus.failure,
        errorMessage: 'Gagal menghapus riwayat. Periksa koneksi internet Anda.',
      ));
    }
  }
}