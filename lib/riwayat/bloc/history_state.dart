part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, success, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.historyList = const <KendaraanHistory>[],
    this.tamuHistoryList = const <TamuHistory>[],
    this.armadaList = const <Armada>[],
    this.serahTerimaHistoryList = const <SerahTerimaHistory>[], // <-- BARU: List gabungan Dokumen/SIM
    this.errorMessage,
  });

  final HistoryStatus status;
  final List<KendaraanHistory> historyList;
  final List<TamuHistory> tamuHistoryList; 
  final List<Armada> armadaList;
  final List<SerahTerimaHistory> serahTerimaHistoryList; // <-- BARU
  final String? errorMessage;

  HistoryState copyWith({
    HistoryStatus? status,
    List<KendaraanHistory>? historyList,
    List<TamuHistory>? tamuHistoryList, 
    List<Armada>? armadaList,
    List<SerahTerimaHistory>? serahTerimaHistoryList, // <-- BARU
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      historyList: historyList ?? this.historyList,
      tamuHistoryList: tamuHistoryList ?? this.tamuHistoryList, 
      armadaList: armadaList ?? this.armadaList,
      serahTerimaHistoryList: serahTerimaHistoryList ?? this.serahTerimaHistoryList, // <-- BARU
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  
  List<Object?> get props => [status, historyList, tamuHistoryList, armadaList, serahTerimaHistoryList, errorMessage];
}