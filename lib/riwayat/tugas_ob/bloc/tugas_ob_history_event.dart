part of 'tugas_ob_history_bloc.dart';

abstract class TugasObHistoryEvent extends Equatable {
  const TugasObHistoryEvent();
  @override
  List<Object> get props => [];
}

class TugasObHistoryFetched extends TugasObHistoryEvent {}

class TugasObHistoryDeleted extends TugasObHistoryEvent {
  final int id;
  const TugasObHistoryDeleted({required this.id});
  @override
  List<Object> get props => [id];
}