part of 'truk_bloc.dart';

@immutable
abstract class TrukEvent extends Equatable {
  const TrukEvent();

  @override
  List<Object?> get props => [];
}

// Mengganti nama agar lebih umum karena sekarang memuat lebih dari 1 data
class TrukDataLoaded extends TrukEvent {}

class TrukArmadaChanged extends TrukEvent {
  final String? armadaId;

  const TrukArmadaChanged({required this.armadaId});

  @override
  List<Object?> get props => [armadaId];
}

class TrukSopirChanged extends TrukEvent {
  final String? sopirId;

  const TrukSopirChanged({required this.sopirId});

  @override
  List<Object?> get props => [sopirId];
}

class TrukDataSubmitted extends TrukEvent {
  final String namaSopir;
  final String statusPengecekan;
  final String statusKernet;
  final String? namaKernet;
  final String statusSTNK; 
  final String stnkTanggal;
  final String statusKIR; 
  final String statusKIRBet;
  final String kirTanggal;
  final String kirTanggalBet;
  final String noLambung;
  final String kilometer;
  final double bbm;
  final String statusKondisi;
  final String? keteranganServis;
  final String? keteranganLain; 
  final List<File?> attachments;

  const TrukDataSubmitted({
    required this.namaSopir,
    required this.statusPengecekan,
    required this.statusKernet,
    this.namaKernet,
    required this.statusSTNK,
    required this.stnkTanggal,
    required this.statusKIR,
    required this.statusKIRBet,
    required this.kirTanggal,
    required this.kirTanggalBet,
    required this.noLambung,
    required this.kilometer,
    required this.bbm,
    required this.statusKondisi,
    this.keteranganServis,
    this.keteranganLain,
    required this.attachments,
  });

  @override
  List<Object?> get props => [
        namaSopir,
        statusPengecekan,
        statusKernet,
        namaKernet,
        statusSTNK,
        stnkTanggal,
        statusKIR,
        statusKIRBet,
        kirTanggal,
        kirTanggalBet,
        noLambung,
        kilometer,
        bbm,
        statusKondisi,
        keteranganServis,
        keteranganLain, 
        attachments
      ];
}