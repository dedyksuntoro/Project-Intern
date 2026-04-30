part of 'kendaraan_history_bloc.dart';

enum KendaraanHistoryStatus { initial, loading, success, failure }

class KendaraanHistoryState extends Equatable {
  const KendaraanHistoryState({
    this.status = KendaraanHistoryStatus.initial,
    this.historyList = const <KendaraanHistory>[],
    this.armadaList = const <Armada>[],
    this.karyawanList = const <Karyawan>[], 
    this.errorMessage,
  });

  final KendaraanHistoryStatus status;
  final List<KendaraanHistory> historyList;
  final List<Armada> armadaList;
  final List<Karyawan> karyawanList; 
  final String? errorMessage;

  KendaraanHistoryState copyWith({
    KendaraanHistoryStatus? status,
    List<KendaraanHistory>? historyList,
    List<Armada>? armadaList,
    List<Karyawan>? karyawanList, 
    String? errorMessage,
  }) {
    return KendaraanHistoryState(
      status: status ?? this.status,
      historyList: historyList ?? this.historyList,
      armadaList: armadaList ?? this.armadaList,
      karyawanList: karyawanList ?? this.karyawanList, 
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, historyList, armadaList, karyawanList, errorMessage]; 
}