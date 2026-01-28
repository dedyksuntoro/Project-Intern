part of 'tamu_bloc.dart';

abstract class TamuEvent extends Equatable {
  const TamuEvent();

  @override
  List<Object?> get props => [];
}

// Event dikirim saat tombol "SIMPAN DATA" ditekan
class TamuFormSubmitted extends TamuEvent {
  final String nama;
  final String instansi;
  final String menemui;
  final String keperluan;
  final List<File> foto; 

  const TamuFormSubmitted({
    required this.nama,
    required this.instansi,
    required this.menemui,
    required this.keperluan,
    required this.foto,
  });

  @override
  List<Object?> get props => [nama, instansi, menemui, keperluan, foto];
}