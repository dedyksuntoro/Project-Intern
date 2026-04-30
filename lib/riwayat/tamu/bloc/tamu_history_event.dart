part of 'tamu_history_bloc.dart';

abstract class TamuHistoryEvent extends Equatable {
  const TamuHistoryEvent();

  @override
  List<Object> get props => [];
}

class TamuHistoryFetched extends TamuHistoryEvent {}

class TamuHistoryDeleted extends TamuHistoryEvent {
  final int id;

  const TamuHistoryDeleted({required this.id});

  @override
  List<Object> get props => [id];
}