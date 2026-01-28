class Armada {
  final String id;
  final String nopol;
  final String inventaris; // "Y" atau "N"

  Armada({
    required this.id,
    required this.nopol,
    required this.inventaris
  });

  factory Armada.fromJson(Map<String, dynamic> json) {
    return Armada(
      id: json['id'].toString(),
      nopol: json['nopol'],
      inventaris: json['inventaris'],
    );
  }
}