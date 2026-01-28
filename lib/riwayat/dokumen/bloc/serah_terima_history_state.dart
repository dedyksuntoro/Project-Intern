part of 'serah_terima_history_bloc.dart';

enum SerahTerimaHistoryStatus { initial, loading, success, failure }

class SerahTerimaHistoryState extends Equatable {
  const SerahTerimaHistoryState({
    this.status = SerahTerimaHistoryStatus.initial,
    this.serahTerimaList = const <SerahTerimaHistory>[],
    this.errorMessage,
  });

  final SerahTerimaHistoryStatus status;
  final List<SerahTerimaHistory> serahTerimaList; 
  final String? errorMessage;

  SerahTerimaHistoryState copyWith({
    SerahTerimaHistoryStatus? status,
    List<SerahTerimaHistory>? serahTerimaList,
    String? errorMessage,
  }) {
    return SerahTerimaHistoryState(
      status: status ?? this.status,
      serahTerimaList: serahTerimaList ?? this.serahTerimaList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, serahTerimaList, errorMessage];
}