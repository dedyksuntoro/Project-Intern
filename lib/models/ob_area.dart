class ObArea {
  final int id;
  final int cabangId; // key di JSON 'cabang'
  final String nama;  // key di JSON 'area'
  final String kategori; // 'INDOOR' / 'OUTDOOR'
  final String? golongan;
  final String? keterangan;

  ObArea({
    required this.id,
    required this.cabangId,
    required this.nama,
    required this.kategori,
    this.golongan,
    this.keterangan,
  });

  factory ObArea.fromJson(Map<String, dynamic> json) {
    return ObArea(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      cabangId: json['cabang'] is int ? json['cabang'] : int.parse(json['cabang'].toString()),
      nama: json['area'] ?? '',
      kategori: json['kategori'] ?? '',
      golongan: json['golongan'],
      keterangan: json['keterangan'],
    );
  }

  @override
  String toString() => 'ObArea(id: $id, nama: $nama)';
}