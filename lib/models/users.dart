class User {
  final String nama;
  final String email;
  final String telp;
  final String? urlFoto; 

  User({
    required this.nama,
    required this.email,
    required this.telp,
    this.urlFoto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nama: json['nama'] ?? 'Nama Tidak Ditemukan',
      email: json['email'] ?? 'Email Tidak Ditemukan',
      telp: json['telp'] ?? 'Telepon Tidak Ditemukan',
      urlFoto: json['photo'] ?? json['url_foto'],
    );
  }
}