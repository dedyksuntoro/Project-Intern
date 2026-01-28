part of 'kendaraan_bloc.dart';

enum KendaraanStatus {
  initial,
  loading, 
  success, 
  failure, 
  submitting,
  submissionSuccess,
  submissionFailure
}

@immutable
class KendaraanState extends Equatable {
  const KendaraanState({
    this.status = KendaraanStatus.initial,
    this.daftarArmada = const [],
    this.daftarKaryawan = const [], 
    this.armadaTerpilih,
    this.karyawanTerpilih, 
    this.statusPilihan = 'Masuk',
    this.sisaBBM = 50.0,
    this.errorMessage,
  });

  final KendaraanStatus status;
  final List<Armada> daftarArmada;
  final List<Karyawan> daftarKaryawan; 
  final String? armadaTerpilih;
  final String? karyawanTerpilih; 
  final String statusPilihan;
  final double sisaBBM;
  final String? errorMessage;

  KendaraanState copyWith({
    KendaraanStatus? status,
    List<Armada>? daftarArmada,
    List<Karyawan>? daftarKaryawan, 
    String? armadaTerpilih,
    String? karyawanTerpilih, 
    String? statusPilihan,
    double? sisaBBM,
    String? errorMessage,
    bool clearErrorMessage = false, 
  }) {
    return KendaraanState(
      status: status ?? this.status,
      daftarArmada: daftarArmada ?? this.daftarArmada,
      daftarKaryawan: daftarKaryawan ?? this.daftarKaryawan, 
      armadaTerpilih: armadaTerpilih ?? this.armadaTerpilih,
      karyawanTerpilih: karyawanTerpilih ?? this.karyawanTerpilih, 
      statusPilihan: statusPilihan ?? this.statusPilihan,
      sisaBBM: sisaBBM ?? this.sisaBBM,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        daftarArmada,
        daftarKaryawan, 
        armadaTerpilih,
        karyawanTerpilih, 
        statusPilihan,
        sisaBBM,
        errorMessage
      ];
}