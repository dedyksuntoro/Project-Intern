class ObHistory {
  final int id;
  final int idKaryawan;
  final String namaKaryawan;
  final int idArea;
  final String namaArea;
  final int idTugas;
  final String namaTugas;
  final DateTime jamMulai;
  final DateTime jamSelesai;
  final DateTime createdAt;
  final String? keterangan;
  final List<String> attachment;
  final int countAttachment;

  ObHistory({
    required this.id,
    required this.idKaryawan,
    required this.namaKaryawan,
    required this.idArea,
    required this.namaArea,
    required this.idTugas,
    required this.namaTugas,
    required this.jamMulai,
    required this.jamSelesai,
    required this.createdAt,
    this.keterangan,
    required this.attachment,
    required this.countAttachment,
  });

  ObHistory copyWith({
    String? namaKaryawan,
    String? namaArea,
    String? namaTugas,
  }) {
    return ObHistory(
      id: id,
      idKaryawan: idKaryawan,
      namaKaryawan: namaKaryawan ?? this.namaKaryawan,
      idArea: idArea,
      namaArea: namaArea ?? this.namaArea,
      idTugas: idTugas,
      namaTugas: namaTugas ?? this.namaTugas,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      createdAt: createdAt,
      keterangan: keterangan,
      attachment: attachment,
      countAttachment: countAttachment,
    );
  }

  factory ObHistory.fromJson(Map<String, dynamic> json) {
    // Parsing attachment
    var listFiles = <String>[];
    if (json['attachment'] != null && json['attachment'] is List) {
      listFiles = (json['attachment'] as List)
          .map((e) => e.toString())
          .toSet() 
          .toList();
    }

    // Helper Date Parser
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null) return DateTime.now();
      return DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
    }

    // Helper Nama Parser
    String parseName(dynamic data, String keyName) {
      if (data == null) return '-';
      if (data is String) return data;
      if (data is Map) return data[keyName]?.toString() ?? '-';
      return '-';
    }

    return ObHistory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      
      idKaryawan: json['id_karyawan'] is int 
          ? json['id_karyawan'] 
          : int.tryParse(json['id_karyawan']?.toString() ?? '0') ?? 0,
      
      namaKaryawan: parseName(json['karyawan'], 'nama'),

      idArea: json['id_area'] is int 
          ? json['id_area'] 
          : int.tryParse(json['id_area']?.toString() ?? '0') ?? 0,

      namaArea: parseName(json['area'], 'nama'),

      idTugas: json['id_tugas'] is int 
          ? json['id_tugas'] 
          : int.tryParse(json['id_tugas']?.toString() ?? '0') ?? 0,

      namaTugas: parseName(json['tugas'], 'nama'),

      jamMulai: parseDate(json['begin']),
      jamSelesai: parseDate(json['end']),
      createdAt: parseDate(json['created_at']), 

      keterangan: json['keterangan']?.toString(),
      attachment: listFiles,
      countAttachment: listFiles.length,
    );
  }
}