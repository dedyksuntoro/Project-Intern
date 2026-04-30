part of 'tamu_history_bloc.dart';

enum TamuHistoryStatus { initial, loading, success, failure }

class TamuHistoryState extends Equatable {
  const TamuHistoryState({
    this.status = TamuHistoryStatus.initial,
    this.tamuHistoryList = const <TamuHistory>[],
    this.errorMessage,
  });

  final TamuHistoryStatus status;
  final List<TamuHistory> tamuHistoryList;
  final String? errorMessage;

  TamuHistoryState copyWith({
    TamuHistoryStatus? status,
    List<TamuHistory>? tamuHistoryList,
    String? errorMessage,
  }) {
    return TamuHistoryState(
      status: status ?? this.status,
      tamuHistoryList: tamuHistoryList ?? this.tamuHistoryList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tamuHistoryList, errorMessage];
}