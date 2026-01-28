import 'dart:convert';

List<KendaraanHistory> kendaraanHistoryFromJson(String str) =>
    List<KendaraanHistory>.from(
        json.decode(str).map((x) => KendaraanHistory.fromJson(x)));

class KendaraanHistory {
  final int id;
  final int idArmada;
  final int? idSopir;
  final int? idKaryawan;
  final String inventaris;
  final String jenis;
  final double kilometer;
  final double bbm;
  final String? statusArmada;
  final String? keteranganArmada;
  final String? keteranganSopir; 
  final String? keterangan; 
  final DateTime createdAt;
  final String nopol;
  final String? sopir;
  final String? karyawan;
  final String? kernet;
  final DateTime? stnkTanggal; 
  final DateTime? kirTanggal;
  final String? kirBet;
  final String? noLambung;
  final String? statusStnk;
  final String? statusKir;
  final List<String> attachment;

  KendaraanHistory({
    required this.id,
    required this.idArmada,
    this.idSopir,
    this.idKaryawan,
    required this.inventaris,
    required this.jenis,
    required this.kilometer,
    required this.bbm,
    this.statusArmada,
    this.keteranganArmada,
    this.keteranganSopir, 
    this.keterangan, 
    required this.createdAt,
    required this.nopol,
    this.sopir,
    this.karyawan,
    this.kernet,
    this.stnkTanggal, 
    this.kirTanggal,
    this.kirBet,
    this.noLambung,
    this.statusStnk,
    this.statusKir,
    required this.attachment,
  });

  factory KendaraanHistory.fromJson(Map<String, dynamic> json) {
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    // Fungsi bantuan untuk parsing tanggal
    DateTime? safeParseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    return KendaraanHistory(
      id: safeParseInt(json["id"]) ?? 0,
      idArmada: safeParseInt(json["id_armada"]) ?? 0,
      idSopir: safeParseInt(json["id_sopir"]),
      idKaryawan: safeParseInt(json["id_karyawan"]),
      inventaris: json["inventaris"] ?? 'N',
      jenis: json["jenis"] ?? 'IN',
      kilometer: (json["kilometer"] as num?)?.toDouble() ?? 0.0,
      bbm: (json["bbm"] as num?)?.toDouble() ?? 0.0,
      statusArmada: json["status_armada"],
      keteranganArmada: json["keterangan_armada"],
      keteranganSopir: json["keterangan_sopir"], 
      keterangan: json["keterangan"], 
      createdAt: safeParseDate(json["created_at"]) ?? DateTime.now(),
      nopol: json["nopol"] ?? 'N/A',
      sopir: json["sopir"],
      karyawan: json["karyawan"],
      kernet: json["kernet"],
      stnkTanggal: safeParseDate(json["stnk_tanggal"]), 
      kirTanggal: safeParseDate(json["kir_tanggal"]),
      kirBet: json["kir_bet"],
      noLambung: json["no_lambung"],
      statusStnk: json["status_stnk"],
      statusKir: json["status_kir"],

      attachment: json["attachment"] == null
          ? []
          : List<String>.from(json["attachment"].map((x) => x)),
    );
  }
}