part of 'truk_history_bloc.dart';

abstract class TrukHistoryEvent extends Equatable {
  const TrukHistoryEvent();

  @override
  List<Object> get props => [];
}

// Event untuk mengambil atau me-refresh data riwayat
class TrukHistoryFetched extends TrukHistoryEvent {}

// Event untuk menghapus data riwayat
class TrukHistoryDeleted extends TrukHistoryEvent {
  final int id;

  const TrukHistoryDeleted({required this.id});

  @override
  List<Object> get props => [id];
}