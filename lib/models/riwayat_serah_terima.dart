import 'dart:convert';
import 'package:intl/intl.dart';



// Untuk Dokumen (surat, dokumen, paket)
List<Dokumen> dokumenRiwayatFromJson(String str) =>
    List<Dokumen>.from(json.decode(str).map((x) => Dokumen.fromJson(x)));

// Untuk SIM
List<Sim> simRiwayatFromJson(String str) =>
    List<Sim>.from(json.decode(str).map((x) => Sim.fromJson(x)));


class Dokumen {
  final int id;
  final String jenis;
  final String dokumenDari; 
  final String diterimaOleh; 
  final DateTime createdAt;
  final int idUser;
  final int countAttachment;
  final List<String> attachment;

  Dokumen({
    required this.id,
    required this.jenis,
    required this.dokumenDari,
    required this.diterimaOleh,
    required this.createdAt,
    required this.idUser,
    required this.countAttachment,
    required this.attachment,
  });

  factory Dokumen.fromJson(Map<String, dynamic> json) {
    return Dokumen(
      id: json["id"] is String ? int.parse(json["id"]) : json["id"] ?? 0,
      jenis: json["jenis"] ?? 'N/A',
      // Menggunakan default value 'N/A' untuk menghindari error parsing 'Null'
      dokumenDari: json["dokumen_dari"] ?? 'N/A', 
      diterimaOleh: json["diterima_oleh"] ?? 'N/A', 
      createdAt: json["created_at"] != null
          ? DateFormat("yyyy-MM-dd HH:mm:ss").parse(json["created_at"], true).toLocal()
          : DateTime.now(),
      idUser: json["id_user"] ?? 0,
      countAttachment: json["count_attachment"] ?? 0,
      attachment: json["attachment"] != null
          ? List<String>.from(json["attachment"].map((x) => x))
          : [],
    );
  }
}


class Sim {
  final int id;
  final String jenis; // 'sim'
  final int idSopir; // Wajib di SIM
  final String statusSim; // Wajib di SIM
  final DateTime createdAt;
  final int idUser;
  final int countAttachment;
  final List<String> attachment;

  Sim({
    required this.id,
    required this.jenis,
    required this.idSopir,
    required this.statusSim,
    required this.createdAt,
    required this.idUser,
    required this.countAttachment,
    required this.attachment,
  });

  factory Sim.fromJson(Map<String, dynamic> json) {
    return Sim(
      id: json["id"] is String ? int.parse(json["id"]) : json["id"] ?? 0,
      jenis: json["jenis"] ?? 'sim',
      idSopir: json["id_sopir"] is String ? int.tryParse(json["id_sopir"]!) ?? 0 : json["id_sopir"] ?? 0,
      statusSim: json["status_sim"] ?? 'N/A',
      createdAt: json["created_at"] != null
          ? DateFormat("yyyy-MM-dd HH:mm:ss").parse(json["created_at"], true).toLocal()
          : DateTime.now(),
      idUser: json["id_user"] ?? 0,
      countAttachment: json["count_attachment"] ?? 0,
      attachment: json["attachment"] != null
          ? List<String>.from(json["attachment"].map((x) => x))
          : [],
    );
  }
}