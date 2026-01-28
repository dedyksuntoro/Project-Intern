part of 'tugas_umum_history_bloc.dart';

enum TugasUmumHistoryStatus { initial, loading, success, failure }

class TugasUmumHistoryState extends Equatable {
  const TugasUmumHistoryState({
    this.status = TugasUmumHistoryStatus.initial,
    this.historyList = const <TugasUmum>[],
    this.errorMessage,
  });

  final TugasUmumHistoryStatus status;
  final List<TugasUmum> historyList;
  final String? errorMessage;

  TugasUmumHistoryState copyWith({
    TugasUmumHistoryStatus? status,
    List<TugasUmum>? historyList,
    String? errorMessage,
  }) {
    return TugasUmumHistoryState(
      status: status ?? this.status,
      historyList: historyList ?? this.historyList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, historyList, errorMessage];
}