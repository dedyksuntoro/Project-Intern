part of 'serah_terima_history_bloc.dart';

abstract class SerahTerimaHistoryEvent extends Equatable {
  const SerahTerimaHistoryEvent();

  @override
  List<Object> get props => [];
}

class SerahTerimaHistoryFetched extends SerahTerimaHistoryEvent {}

class SerahTerimaHistoryDeleted extends SerahTerimaHistoryEvent {
  final int id;

  const SerahTerimaHistoryDeleted({required this.id});

  @override
  List<Object> get props => [id];
}