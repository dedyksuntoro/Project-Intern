import 'dart:convert';

List<Karyawan> karyawanFromJson(String str) =>
    List<Karyawan>.from(json.decode(str).map((x) => Karyawan.fromJson(x)));

class Karyawan {
  final String id;
  final String nama;
  final String namaCabang;
  final String alias;

  Karyawan({
    required this.id,
    required this.nama,
    required this.namaCabang,
    required this.alias,
  });

  factory Karyawan.fromJson(Map<String, dynamic> json) {
    return Karyawan(
      // menangani jika ada data null dari server
      id: json["id"]?.toString() ?? '',
      nama: json["nama"] ?? 'Tanpa Nama',
      namaCabang: json["nama_cabang"] ?? '',
      alias: json["alias"] ?? '',
    );
  }
}
