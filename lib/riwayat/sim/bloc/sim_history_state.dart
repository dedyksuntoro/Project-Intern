part of 'sim_history_bloc.dart';

enum SimHistoryStatus { initial, loading, success, failure }

class SimHistoryState extends Equatable {
  const SimHistoryState({
    this.status = SimHistoryStatus.initial,
    this.simHistoryList = const <SerahTerimaHistory>[], 
    this.sopirList = const <Sopir>[], 
    this.errorMessage,
  });

  final SimHistoryStatus status;
  final List<SerahTerimaHistory> simHistoryList;
  final List<Sopir> sopirList; 
  final String? errorMessage;

  SimHistoryState copyWith({
    SimHistoryStatus? status,
    List<SerahTerimaHistory>? simHistoryList,
    List<Sopir>? sopirList, 
    String? errorMessage,
  }) {
    return SimHistoryState(
      status: status ?? this.status,
      simHistoryList: simHistoryList ?? this.simHistoryList,
      sopirList: sopirList ?? this.sopirList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, simHistoryList, sopirList, errorMessage]; 
}