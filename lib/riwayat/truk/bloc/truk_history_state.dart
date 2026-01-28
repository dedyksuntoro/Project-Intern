part of 'truk_history_bloc.dart';

enum TrukHistoryStatus { initial, loading, success, failure }

class TrukHistoryState extends Equatable {
  const TrukHistoryState({
    this.status = TrukHistoryStatus.initial,
    this.historyList = const <KendaraanHistory>[],
    this.armadaList = const <Armada>[],
    this.sopirList = const <Sopir>[], 
    this.errorMessage,
  });

  final TrukHistoryStatus status;
  final List<KendaraanHistory> historyList;
  final List<Armada> armadaList;
  final List<Sopir> sopirList; 
  final String? errorMessage;

  TrukHistoryState copyWith({
    TrukHistoryStatus? status,
    List<KendaraanHistory>? historyList,
    List<Armada>? armadaList,
    List<Sopir>? sopirList, 
    String? errorMessage,
  }) {
    return TrukHistoryState(
      status: status ?? this.status,
      historyList: historyList ?? this.historyList,
      armadaList: armadaList ?? this.armadaList,
      sopirList: sopirList ?? this.sopirList, 
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, historyList, armadaList, sopirList, errorMessage];
}