part of 'sim_history_bloc.dart';

abstract class SimHistoryEvent extends Equatable {
  const SimHistoryEvent();

  @override
  List<Object> get props => [];
}

class SimHistoryFetched extends SimHistoryEvent {}

class SimHistoryDeleted extends SimHistoryEvent {
  final int id;

  const SimHistoryDeleted({required this.id});

  @override
  List<Object> get props => [id];
}