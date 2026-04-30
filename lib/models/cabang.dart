class Cabang {
  final int id;
  final String nama; // key di JSON adalah 'cabang'
  final String shortname;
  final String? keterangan;

  Cabang({
    required this.id,
    required this.nama,
    required this.shortname,
    this.keterangan,
  });

  factory Cabang.fromJson(Map<String, dynamic> json) {
    return Cabang(
      // Handle ID 
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: json['cabang'] ?? '',
      shortname: json['shortname'] ?? '',
      keterangan: json['keterangan'],
    );
  }

  // Untuk keperluan debugging/printing
  @override
  String toString() => 'Cabang(id: $id, nama: $nama)';
}