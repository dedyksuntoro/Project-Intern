part of 'tugas_ob_history_bloc.dart';

enum TugasObHistoryStatus { initial, loading, success, failure }

class TugasObHistoryState extends Equatable {
  const TugasObHistoryState({
    this.status = TugasObHistoryStatus.initial,
    this.historyList = const <ObHistory>[],
    this.errorMessage,
  });

  final TugasObHistoryStatus status;
  final List<ObHistory> historyList;
  final String? errorMessage;

  TugasObHistoryState copyWith({
    TugasObHistoryStatus? status,
    List<ObHistory>? historyList,
    String? errorMessage,
  }) {
    return TugasObHistoryState(
      status: status ?? this.status,
      historyList: historyList ?? this.historyList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, historyList, errorMessage];
}