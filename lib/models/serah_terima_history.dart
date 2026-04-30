import 'dart:convert';

List<SerahTerimaHistory> serahTerimaHistoryFromJson(String str) =>
    List<SerahTerimaHistory>.from(
        json.decode(str).map((x) => SerahTerimaHistory.fromJson(x)));

class SerahTerimaHistory {
  final int id;
  // Field Dokumen (nullable)
  final String? dokumenDari; 
  final String? diterimaOleh; 
  
  // Field SIM (nullable)
  final int? idSopir; 
  final String? statusSim; 

  final String jenis;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int idUser;
  final int countAttachment;
  final List<String> attachment;
  final String? keterangan; 


 
  SerahTerimaHistory({
    required this.id,
    this.dokumenDari, 
    this.diterimaOleh, 
    this.idSopir, 
    this.statusSim, 
    required this.jenis,
    required this.createdAt,
    required this.updatedAt,
    required this.idUser,
    required this.countAttachment,
    required this.attachment,
    this.keterangan,

  });

  factory SerahTerimaHistory.fromJson(Map<String, dynamic> json) =>
      SerahTerimaHistory(
        id: json["id"] as int? ?? 0, 

        // Parsing Dokumen
        dokumenDari: json["dokumen_dari"] as String?, 
        diterimaOleh: json["diterima_oleh"] as String?,
        
        // Parsing SIM
        idSopir: json["id_sopir"] as int?, 
        statusSim: json["status_sim"] as String?, 
        
        // Parsing Umum (Aman)
        jenis: json["jenis"] as String? ?? 'N/A',
        createdAt: DateTime.parse(json["created_at"] as String),
        updatedAt: DateTime.parse(json["updated_at"] as String),
        idUser: json["id_user"] as int? ?? 0,
        countAttachment: json["count_attachment"] as int? ?? 0,
        
        attachment: json["attachment"] != null
            ? List<String>.from(json["attachment"].map((x) => x as String))
            : const [],


        keterangan: json["keterangan"] as String?,
    
      );
}