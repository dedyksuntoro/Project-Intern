class ObTugas {
  final int id;
  final String nama;
  final String kategoriArea; // 'INDOOR' / 'OUTDOOR'
  final String periode; // 'HARIAN' dll
  final String? keterangan;

  ObTugas({
    required this.id,
    required this.nama,
    required this.kategoriArea,
    required this.periode,
    this.keterangan,
  });

  factory ObTugas.fromJson(Map<String, dynamic> json) {
    return ObTugas(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: json['tugas'] ?? '',
      kategoriArea: json['kategori_area'] ?? '',
      periode: json['periode'] ?? '',
      keterangan: json['keterangan'],
    );
  }

  @override
  String toString() => 'ObTugas(id: $id, nama: $nama)';
}