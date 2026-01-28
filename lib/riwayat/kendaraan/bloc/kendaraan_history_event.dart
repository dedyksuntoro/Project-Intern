part of 'kendaraan_history_bloc.dart';

abstract class KendaraanHistoryEvent extends Equatable {
  const KendaraanHistoryEvent();

  @override
  List<Object> get props => [];
}

// Event untuk mengambil atau me-refresh data riwayat kendaraan
class KendaraanHistoryFetched extends KendaraanHistoryEvent {}

// Event untuk menghapus data riwayat kendaraan
class KendaraanHistoryDeleted extends KendaraanHistoryEvent {
  final int id;

  const KendaraanHistoryDeleted({required this.id});

  @override
  List<Object> get props => [id];
}