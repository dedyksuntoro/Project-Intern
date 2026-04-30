part of 'tugas_umum_bloc.dart';

@immutable
abstract class TugasUmumEvent extends Equatable {
  const TugasUmumEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk memuat data awal (Armada & Karyawan)
class LoadTugasData extends TugasUmumEvent {}

/// Event untuk mengirim data form ke API
class SubmitTugasUmum extends TugasUmumEvent {
  final String armadaId;
  final String karyawanId;
  final String keperluan;
  final String jamBerangkat;
  final List<File> foto;

  const SubmitTugasUmum({
    required this.armadaId,
    required this.karyawanId,
    required this.keperluan,
    required this.jamBerangkat,
    required this.foto, 
  });

  @override
  List<Object?> get props => [armadaId, karyawanId, keperluan, jamBerangkat, foto]; 
}