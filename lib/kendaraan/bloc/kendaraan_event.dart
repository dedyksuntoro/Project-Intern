part of 'kendaraan_bloc.dart';

@immutable
abstract class KendaraanEvent extends Equatable {
  const KendaraanEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialData extends KendaraanEvent {}

class ArmadaChanged extends KendaraanEvent {
  final String? armadaId;
  const ArmadaChanged({required this.armadaId});
  @override
  List<Object?> get props => [armadaId];
}

class KaryawanChanged extends KendaraanEvent {
  final String? karyawanId;
  const KaryawanChanged({required this.karyawanId});
  @override
  List<Object?> get props => [karyawanId];
}

class StatusPilihanChanged extends KendaraanEvent {
  final String status;
  const StatusPilihanChanged({required this.status});
  @override
  List<Object?> get props => [status];
}

class BbmChanged extends KendaraanEvent {
  final double bbmValue;
  const BbmChanged({required this.bbmValue});
  @override
  List<Object?> get props => [bbmValue];
}

class SubmitData extends KendaraanEvent {
  final String kilometer;
  final List<File> fotoLuar;
  final List<File> fotoDalam;
  final List<File> fotoSurat;
  final List<File> fotoPenanggungJawab; // <-- TAMBAHAN BARU
  final String? keteranganLain;

  const SubmitData({
    required this.kilometer,
    required this.fotoLuar,
    required this.fotoDalam,
    required this.fotoSurat,
    required this.fotoPenanggungJawab, // <-- TAMBAHAN BARU
    this.keteranganLain,
  });

  @override
  List<Object?> get props => [
        kilometer,
        fotoLuar,
        fotoDalam,
        fotoSurat,
        fotoPenanggungJawab, // <-- TAMBAHAN BARU
        keteranganLain,
      ];
}