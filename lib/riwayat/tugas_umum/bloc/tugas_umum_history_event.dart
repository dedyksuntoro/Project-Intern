part of 'tugas_umum_history_bloc.dart';

abstract class TugasUmumHistoryEvent extends Equatable {
  const TugasUmumHistoryEvent();

  @override
  List<Object> get props => [];
}

class TugasUmumHistoryFetched extends TugasUmumHistoryEvent {}

class TugasUmumHistoryDeleted extends TugasUmumHistoryEvent {
  final int id;

  const TugasUmumHistoryDeleted({required this.id});

  @override
  List<Object> get props => [id];
}

// --- TAMBAHAN EVENT BARU (Tandai Selesai) ---
class TugasUmumHistorySelesai extends TugasUmumHistoryEvent {
  final TugasUmum item;

  const TugasUmumHistorySelesai({required this.item});

  @override
  List<Object> get props => [item];
}