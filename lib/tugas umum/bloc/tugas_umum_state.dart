part of 'tugas_umum_bloc.dart';

/// Enum untuk status UI
enum TugasUmumStatus { initial, loading, loaded, submitting, success, failure }

class TugasUmumState extends Equatable {
  final TugasUmumStatus status;
  final List<Armada> daftarArmada;
  final List<Karyawan> daftarKaryawan;
  final String? errorMessage;

  const TugasUmumState({
    this.status = TugasUmumStatus.initial,
    this.daftarArmada = const [],
    this.daftarKaryawan = const [],
    this.errorMessage,
  });

  /// Helper copyWith untuk memperbarui state
  TugasUmumState copyWith({
    TugasUmumStatus? status,
    List<Armada>? daftarArmada,
    List<Karyawan>? daftarKaryawan,
    String? errorMessage,
  }) {
    return TugasUmumState(
      status: status ?? this.status,
      daftarArmada: daftarArmada ?? this.daftarArmada,
      daftarKaryawan: daftarKaryawan ?? this.daftarKaryawan,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, daftarArmada, daftarKaryawan, errorMessage];
}