import 'dart:convert';

List<Sopir> sopirFromJson(String str) =>
    List<Sopir>.from(json.decode(str).map((x) => Sopir.fromJson(x)));

class Sopir {
  final String id;
  final String nama;
  final String alias;
  final String idProg;
  final String nik;

  Sopir({
    required this.id,
    required this.nama,
    required this.alias,
    required this.idProg,
    required this.nik,
  });

  factory Sopir.fromJson(Map<String, dynamic> json) {
    return Sopir(
      id: json["id"]?.toString() ?? '',
      nama: json["nama"] ?? 'Tanpa Nama',
      alias: json["alias"] ?? '',
      idProg: json["id_prog"] ?? '',
      nik: json["nik"] ?? '',
    );
  }
}