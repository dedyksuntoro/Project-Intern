class TugasUmum {
  final int id;
  final int idKaryawan;
  final String namaKaryawan;
  final String keperluan;
  final String statusKendaraan;
  final int? idArmada;
  final String? nopol;
  final String jamBerangkat;
  final String? jamSelesai; 
  final int countAttachment;
  final List<String> attachment;
  final DateTime createdAt;

  TugasUmum({
    required this.id,
    required this.idKaryawan,
    required this.namaKaryawan,
    required this.keperluan,
    required this.statusKendaraan,
    this.idArmada,
    this.nopol,
    required this.jamBerangkat,
    this.jamSelesai, 
    required this.countAttachment,
    required this.attachment,
    required this.createdAt,
  });

  
  TugasUmum copyWith({
    String? namaKaryawan,
    String? nopol,
    String? jamSelesai, 
  }) {
    return TugasUmum(
      id: id,
      idKaryawan: idKaryawan,
      namaKaryawan: namaKaryawan ?? this.namaKaryawan, 
      keperluan: keperluan,
      statusKendaraan: statusKendaraan,
      idArmada: idArmada,
      nopol: nopol ?? this.nopol, 
      jamBerangkat: jamBerangkat,
      jamSelesai: jamSelesai ?? this.jamSelesai, 
      countAttachment: countAttachment,
      attachment: attachment,
      createdAt: createdAt,
    );
  }

  factory TugasUmum.fromJson(Map<String, dynamic> json) {
    // Helper ID fallback
    final idKaryawanRaw = json['id_karyawan'] is int 
        ? json['id_karyawan'] 
        : int.tryParse(json['id_karyawan']?.toString() ?? '0') ?? 0;

    // Helper Parse Nama
    String parseName(dynamic data, String keyName) {
      if (data != null) {
        if (data is String) return data; 
        if (data is Map) return data[keyName]?.toString() ?? '-';
      }
      return '-'; 
    }

    // Helper Parse Nopol
    String? parseNopol(Map<String, dynamic> json) {
      if (json['nopol'] != null && json['nopol'] is String) return json['nopol'];
      if (json['no_polisi'] != null && json['no_polisi'] is String) return json['no_polisi'];
      if (json['armada'] != null && json['armada'] is Map) return json['armada']['nopol']?.toString();
      return null;
    }

    return TugasUmum(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      idKaryawan: idKaryawanRaw,
      namaKaryawan: parseName(json['karyawan'], 'nama'),
      keperluan: json['keperluan_tugas'] ?? json['keperluan'] ?? '-',
      statusKendaraan: json['status_kendaraan'] ?? 'PRIBADI',
      idArmada: json['id_armada'] != null ? int.tryParse(json['id_armada'].toString()) : null,
      nopol: parseNopol(json),
      jamBerangkat: json['jam_berangkat'] ?? '',
      
      // 4. MAPPING DARI JSON
      jamSelesai: json['jam_selesai']?.toString(),

      countAttachment: json['count_attachment'] is int ? json['count_attachment'] : int.tryParse(json['count_attachment']?.toString() ?? '0') ?? 0,
      attachment: json['attachment'] != null && json['attachment'] is List
          ? List<String>.from(json['attachment'].map((x) => x.toString()))
          : [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}