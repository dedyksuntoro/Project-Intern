import 'dart:convert';

List<TamuHistory> tamuHistoryFromJson(String str) => List<TamuHistory>.from(json.decode(str).map((x) => TamuHistory.fromJson(x)));

class TamuHistory {
    final int id;
    final String nama;
    final String instansi;
    final String menemui;
    final String keperluan;
    final DateTime createdAt;
    final int countAttachment;
    final List<String> attachment;

    TamuHistory({
        required this.id,
        required this.nama,
        required this.instansi,
        required this.menemui,
        required this.keperluan,
        required this.createdAt,
        required this.countAttachment,
        required this.attachment,
    });

    factory TamuHistory.fromJson(Map<String, dynamic> json) => TamuHistory(
        id: json["id"],
        nama: json["nama"],
        instansi: json["instansi"],
        menemui: json["menemui"],
        keperluan: json["keperluan"],
        createdAt: DateTime.parse(json["created_at"]),
        countAttachment: json["count_attachment"],
        attachment: List<String>.from(json["attachment"].map((x) => x)),
    );
}