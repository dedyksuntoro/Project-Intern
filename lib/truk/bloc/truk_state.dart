part of 'truk_bloc.dart';

enum TrukStatus {
  initial,
  loading,
  success,
  failure,
  submitting,
  submissionSuccess,
  submissionFailure
}

@immutable
class TrukState extends Equatable {
  const TrukState({
    this.status = TrukStatus.initial,
    this.daftarArmada = const [],
    this.daftarSopir = const [], 
    this.armadaTerpilih,
    this.sopirTerpilih, 
    this.errorMessage,
  });

  final TrukStatus status;
  final List<Armada> daftarArmada;
  final List<Sopir> daftarSopir; 
  final String? armadaTerpilih;
  final String? sopirTerpilih; 
  final String? errorMessage;

  TrukState copyWith({
    TrukStatus? status,
    List<Armada>? daftarArmada,
    List<Sopir>? daftarSopir, 
    String? armadaTerpilih,
    String? sopirTerpilih, 
    String? errorMessage,
    bool clearError = false,
  }) {
    return TrukState(
      status: status ?? this.status,
      daftarArmada: daftarArmada ?? this.daftarArmada,
      daftarSopir: daftarSopir ?? this.daftarSopir, 
      armadaTerpilih: armadaTerpilih ?? this.armadaTerpilih,
      sopirTerpilih: sopirTerpilih ?? this.sopirTerpilih, 
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        daftarArmada,
        daftarSopir, 
        armadaTerpilih,
        sopirTerpilih, 
        errorMessage
      ];
}