part of 'tugas_ob_bloc.dart';

abstract class TugasObEvent extends Equatable {
  const TugasObEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memuat data awal (Cabang, Area, Tugas, Karyawan)
class TugasObDataLoaded extends TugasObEvent {}

/// Event saat data formulir disubmit
class TugasObSubmitted extends TugasObEvent {
  final int cabangId;
  final int areaId;
  final int tugasId; 
  final int karyawanId;
  final String jamMulai;   
  final String jamSelesai; 
  final String? keteranganLain;
  final List<File> fotoBukti;

  const TugasObSubmitted({
    required this.cabangId,
    required this.areaId,
    required this.tugasId,
    required this.karyawanId,
    required this.jamMulai,
    required this.jamSelesai,
    this.keteranganLain,
    required this.fotoBukti,
  });

  @override
  List<Object?> get props => [
        cabangId,
        areaId,
        tugasId,
        karyawanId,
        jamMulai,
        jamSelesai,
        keteranganLain,
        fotoBukti,
      ];
}

/// Event saat Cabang dipilih
class TugasObCabangChanged extends TugasObEvent {
  final Cabang selectedCabang;
  const TugasObCabangChanged({required this.selectedCabang});

  @override
  List<Object?> get props => [selectedCabang];
}

/// Event saat Area dipilih
class TugasObAreaChanged extends TugasObEvent {
  final ObArea selectedArea; 
  const TugasObAreaChanged({required this.selectedArea});

  @override
  List<Object?> get props => [selectedArea];
}

/// Event saat Jenis Pekerjaan (Tugas) dipilih
class TugasObTugasChanged extends TugasObEvent {
  final ObTugas selectedTugas;
  const TugasObTugasChanged({required this.selectedTugas});

  @override
  List<Object?> get props => [selectedTugas];
}

/// Event saat Karyawan dipilih
class TugasObKaryawanChanged extends TugasObEvent {
  final Karyawan selectedKaryawan;
  const TugasObKaryawanChanged({required this.selectedKaryawan});

  @override
  List<Object?> get props => [selectedKaryawan];
}