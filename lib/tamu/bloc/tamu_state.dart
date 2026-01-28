part of 'tamu_bloc.dart';

abstract class TamuState extends Equatable {
  const TamuState();

  @override
  List<Object> get props => [];
}

// State awal saat form ditampilkan
class TamuInitial extends TamuState {}

// State saat data sedang dikirim ke server
class TamuSubmissionInProgress extends TamuState {}

// State saat data berhasil disimpan
class TamuSubmissionSuccess extends TamuState {}

// State saat terjadi error
class TamuSubmissionFailure extends TamuState {
  final String error;

  const TamuSubmissionFailure({required this.error});

  @override
  List<Object> get props => [error];
}
