part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object> get props => [];
}

// Event untuk mengambil atau me-refresh data riwayat
class HistoryFetched extends HistoryEvent {}