import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import '../models/users.dart';
import '../models/kendaraan_history.dart';
import '../models/armada.dart';
import '../models/karyawan.dart';
import '../models/sopir.dart';
import '../models/tamu_history.dart';
import '../models/serah_terima_history.dart';
import '../models/tugas_umum.dart';
import '../models/cabang.dart';
import '../models/ob_area.dart';
import '../models/ob_tugas.dart';

class ApiService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;
  final _storage = const FlutterSecureStorage();

  String? _inMemoryToken;
  String? _inMemoryCookie;

  static const _keyJwt = 'jwt';
  static const _keyCookie = 'session_cookie';

  Future<void> init() async {
    _inMemoryToken = await _storage.read(key: _keyJwt);
    _inMemoryCookie = await _storage.read(key: _keyCookie);
  }

  Future<String?> getToken() async {
    if (_inMemoryToken != null) return _inMemoryToken;
    _inMemoryToken = await _storage.read(key: _keyJwt);
    return _inMemoryToken;
  }

  Future<String?> getCookie() async {
    if (_inMemoryCookie != null) return _inMemoryCookie;
    _inMemoryCookie = await _storage.read(key: _keyCookie);
    return _inMemoryCookie;
  }

  // --- AUTHENTICATION ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"username": username, "password": password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['jwt'] != null) {
        final token = data['jwt'];
        _inMemoryToken = token;

        final fotoUrl = data['photo'] ?? data['url_foto'];

        await _storage.write(key: _keyJwt, value: token);
        await _storage.write(key: 'id_user', value: data['id']?.toString());
        await _storage.write(key: 'user_nama', value: data['nama']);
        await _storage.write(key: 'user_username', value: data['username']);
        await _storage.write(key: 'user_telp', value: data['telp']);
        await _storage.write(key: 'user_foto', value: fotoUrl);

        String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          String sessionCookie = rawCookie.split(';')[0];
          _inMemoryCookie = sessionCookie;
          await _storage.write(key: _keyCookie, value: sessionCookie);
        }
      }
      return data;
    } on SocketException {
      throw Exception(
        'KONEKSI_GAGAL: Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw Exception(
        'TIMEOUT_GAGAL: Permintaan melebihi batas waktu 15 detik. Sinyal mungkin buruk.',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    _inMemoryToken = null;
    _inMemoryCookie = null;
    await _storage.deleteAll();
  }

  Future<User> getCurrentUser() async {
    final nama = await _storage.read(key: 'user_nama');
    final email = await _storage.read(key: 'user_username');
    final telp = await _storage.read(key: 'user_telp');
    final urlFoto = await _storage.read(key: 'user_foto');

    return User(
      nama: nama ?? 'N/A',
      email: email ?? 'N/A',
      telp: telp ?? 'N/A',
      urlFoto: urlFoto,
    );
  }

  Future<void> updateUserProfile({
    required String nama,
    required String telp,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final response = await http.put(
      Uri.parse('$_baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nama': nama, 'telp': telp}),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode != 200 || responseBody['status'] != true) {
      throw Exception(responseBody['message'] ?? 'Gagal memperbarui profil.');
    } else {
      await _storage.write(key: 'user_nama', value: nama);
      await _storage.write(key: 'user_telp', value: telp);
    }
  }

  Future<String> uploadProfilePhoto(File photo) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final mimeType = lookupMimeType(photo.path) ?? 'image/jpeg';
    final mediaType = MediaType.parse(mimeType);

    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/photo'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          photo.path,
          contentType: mediaType,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      final newPhotoUrl = data['photo'] ?? data['url_foto'];
      await _storage.write(key: 'user_foto', value: newPhotoUrl);
      return newPhotoUrl;
    } else {
      throw Exception(data['message'] ?? 'Gagal mengunggah foto profil.');
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final response = await http.put(
      Uri.parse('$_baseUrl/password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'password': currentPassword,
        'password_new': newPassword,
      }),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode != 200 || responseBody['status'] != true) {
      throw Exception(responseBody['message'] ?? 'Gagal memperbarui password.');
    }
  }

  // --- MASTER DATA ---

  Future<List<Armada>> fetchArmada() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');
    final response = await http.get(
      Uri.parse('$_baseUrl/armada'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((data) => Armada.fromJson(data))
          .toList();
    } else {
      throw Exception('Gagal memuat armada. Status: ${response.statusCode}');
    }
  }

  Future<List<Karyawan>> fetchKaryawan() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');
    final response = await http.get(
      Uri.parse('$_baseUrl/karyawan'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return karyawanFromJson(response.body);
    } else {
      throw Exception(
        'Gagal memuat data karyawan. Status: ${response.statusCode}',
      );
    }
  }

  Future<List<Sopir>> fetchSopir() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');
    final response = await http.get(
      Uri.parse('$_baseUrl/sopir'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return sopirFromJson(response.body);
    } else {
      throw Exception(
        'Gagal memuat data sopir. Status: ${response.statusCode}',
      );
    }
  }

  // --- KENDARAAN / TRUK ---

  Future<List<KendaraanHistory>> fetchKendaraanHistory() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');
    final response = await http.get(
      Uri.parse('$_baseUrl/kendaraan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return kendaraanHistoryFromJson(response.body);
    } else {
      throw Exception(
        'Gagal memuat riwayat kendaraan. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> saveKendaraanCheck({
    required String armadaId,
    required String inventaris,
    int? idSopir,
    int? idKaryawan,
    String? jenis,
    double? kilometer,
    double? bbm,
    String? statusArmada,
    String? statusSopir,
    String? keteranganArmada,
    String? keteranganSopir,
    String? keterangan,
    List<File> attachments = const [],
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    List<int> attachmentIds = [];
    for (var file in attachments) {
      final attachmentId = await _uploadAttachment(token, file, 'kendaraan');
      if (attachmentId != null) {
        attachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu lampiran.');
      }
    }

    final Map<String, dynamic> payloadMap = {
      'id_armada': int.tryParse(armadaId),
      'inventaris': inventaris,
      'id_sopir': idSopir,
      'id_karyawan': idKaryawan,
      'jenis': jenis,
      'kilometer': kilometer,
      'bbm': bbm,
      'status_armada': statusArmada,
      'status_sopir': statusSopir,
      'keterangan_armada': keteranganArmada,
      'keterangan_sopir': keteranganSopir,
      'keterangan': keterangan,
      'attachment': attachments.isNotEmpty ? attachmentIds : null,
    };

    payloadMap.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse('$_baseUrl/kendaraan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal menyimpan data. Status: ${response.statusCode}',
      );
    }
  }

  String? _mapStatusToApi(String? status) {
    if (status == 'Ada') return 'A';
    if (status == 'Mati') return 'M';
    if (status == 'Tidak Ada') return 'T';
    return null;
  }

  Future<Map<String, dynamic>> saveTrukCheck({
    required String armadaId,
    int? idSopir,
    String? jenis,
    double? kilometer,
    double? bbm,
    String? statusArmada,
    String? statusSopir,
    String? keteranganArmada,
    String? keteranganSopir,
    List<File> attachments = const [],
    String? kernet,
    String? statusStnk,
    String? stnkTanggal,
    String? statusKir,
    String? kirTanggal,
    String? kirBet,
    String? noLambung,
    String? keterangan,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    List<int> attachmentIds = [];
    for (var file in attachments) {
      final attachmentId = await _uploadAttachment(token, file, 'kendaraan');
      if (attachmentId != null) {
        attachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu lampiran.');
      }
    }

    // Lakukan mapping status sebelum dikirim ke payload
    final apiStatusStnk = _mapStatusToApi(statusStnk);
    final apiStatusKir = _mapStatusToApi(statusKir);

    final Map<String, dynamic> payloadMap = {
      'id_armada': int.tryParse(armadaId),
      'inventaris': 'N',
      'id_sopir': idSopir,
      'jenis': jenis,
      'kilometer': kilometer,
      'bbm': bbm,
      'status_armada': statusArmada,
      'status_sopir': statusSopir,
      'keterangan_armada': keteranganArmada,
      'keterangan_sopir': keteranganSopir,
      'attachment': attachments.isNotEmpty ? attachmentIds : null,
      'kernet': kernet,
      'status_stnk': apiStatusStnk,
      'stnk_tanggal': stnkTanggal,
      'status_kir': apiStatusKir,
      'kir_tanggal': kirTanggal,
      'kir_bet': kirBet,
      'no_lambung': noLambung,
      'keterangan': keterangan,
    };

    payloadMap.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse('$_baseUrl/kendaraan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal menyimpan data. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> updateKendaraanCheck({
    required int id,
    required String armadaId,
    required String inventaris,
    int? idSopir,
    int? idKaryawan,
    String? jenis,
    double? kilometer,
    double? bbm,
    String? statusArmada,
    String? statusSopir,
    String? keteranganArmada,
    String? keteranganSopir,
    List<int> attachmentIds = const [],
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final payload = {
      'id': id,
      'id_armada': int.tryParse(armadaId),
      'inventaris': inventaris,
      'id_sopir': idSopir,
      'id_karyawan': idKaryawan,
      'jenis': jenis,
      'kilometer': kilometer,
      'bbm': bbm,
      'status_armada': statusArmada,
      'status_sopir': statusSopir,
      'keterangan_armada': keteranganArmada,
      'keterangan_sopir': keteranganSopir,
      'attachment': attachmentIds,
    };

    payload.removeWhere((key, value) => value == null);

    final response = await http.put(
      Uri.parse('$_baseUrl/kendaraan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Error dari server (${response.statusCode}): ${errorBody['message']}',
        );
      } catch (_) {
        throw Exception(
          'Gagal memperbarui data. Status: ${response.statusCode}',
        );
      }
    }
  }

  Future<Map<String, dynamic>> deleteKendaraanHistory(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final url = Uri.parse('$_baseUrl/kendaraan');
    final payload = jsonEncode({"id": id});

    final request = http.Request('DELETE', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json'
      ..body = payload;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Gagal menghapus riwayat kendaraan.',
        );
      }
    } else {
      throw Exception(
        'Gagal menghapus riwayat kendaraan. Status: ${response.statusCode}',
      );
    }
  }

  // --- TAMU ---

  Future<List<TamuHistory>> fetchTamuHistory() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.get(
      Uri.parse('$_baseUrl/tamu'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return tamuHistoryFromJson(response.body);
    } else {
      throw Exception(
        'Gagal memuat riwayat tamu. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> submitTamu({
    required String nama,
    required String instansi,
    required String menemui,
    required String keperluan,
    List<File> foto = const [],
  }) async {
    final token = await getToken();
    if (token == null)
      throw Exception('Sesi tidak valid. Silakan login ulang.');

    List<int> attachmentIds = [];
    for (var file in foto) {
      final attachmentId = await _uploadAttachment(token, file, 'tamu');
      if (attachmentId != null) {
        attachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu dokumen lampiran.');
      }
    }

    final payload = jsonEncode({
      "nama": nama,
      "instansi": instansi,
      "menemui": menemui,
      "keperluan": keperluan,
      "attachment": attachmentIds,
    });

    final response = await http.post(
      Uri.parse('$_baseUrl/tamu'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: payload,
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal menyimpan data tamu. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> deleteTamuHistory(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final url = Uri.parse('$_baseUrl/tamu');
    final payload = jsonEncode({"id": id});

    final request = http.Request('DELETE', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json'
      ..body = payload;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return data;
      } else {
        throw Exception(
          data['message'] ??
              'Gagal menghapus riwayat tamu. Status: ${response.statusCode}',
        );
      }
    } else {
      throw Exception(
        'Gagal menghapus riwayat tamu. Status: ${response.statusCode}',
      );
    }
  }

  // --- SERAH TERIMA (DOKUMEN & SIM) ---

  Future<List<SerahTerimaHistory>> fetchSerahTerimaHistory({
    int? id,
    String? jenis,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    Map<String, String> queryParams = {};
    if (id != null) queryParams['id'] = id.toString();
    if (jenis != null) queryParams['jenis'] = jenis;

    final uri = Uri.parse(
      '$_baseUrl/sterima',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return serahTerimaHistoryFromJson(response.body);
    } else {
      throw Exception(
        'Gagal memuat riwayat serah terima. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> submitDokumen({
    required String dokumenDari,
    required String diterimaOleh,
    required String jenis,
    List<File> attachments = const [],
    String? keterangan,
  }) async {
    final token = await getToken();
    if (token == null)
      throw Exception('Sesi tidak valid. Silakan login ulang.');

    List<int> attachmentIds = [];
    for (var file in attachments) {
      final attachmentId = await _uploadAttachment(token, file, 'serah_terima');
      if (attachmentId != null) {
        attachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu lampiran dokumen.');
      }
    }

    final Map<String, dynamic> payloadMap = {
      "dokumen_dari": dokumenDari,
      "diterima_oleh": diterimaOleh,
      "jenis": jenis.toLowerCase(),
      "attachment": attachmentIds,
      "keterangan": keterangan,
    };

    payloadMap.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse('$_baseUrl/sterima'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal menyimpan data dokumen. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> submitSimHandover({
    required int idSopir,
    required String statusSim,
    List<File> attachments = const [],
    String? keterangan,
  }) async {
    final token = await getToken();
    if (token == null)
      throw Exception('Sesi tidak valid. Silakan login ulang.');

    List<int> attachmentIds = [];
    for (var file in attachments) {
      final attachmentId = await _uploadAttachment(token, file, 'serah_terima');
      if (attachmentId != null) {
        attachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu lampiran SIM.');
      }
    }

    final Map<String, dynamic> payloadMap = {
      "id_sopir": idSopir,
      "jenis": "sim",
      "status_sim": statusSim.toLowerCase(),
      "attachment": attachmentIds,
      "keterangan": keterangan,
    };

    payloadMap.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse('$_baseUrl/sterima'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal menyimpan data SIM. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> updateSerahTerima({
    required int id,
    required String jenis,
    // Parameter Umum
    String? keterangan,
    List<File> newAttachments = const [],
    List<int> existingAttachmentIds = const [],
    // Parameter Khusus Dokumen/Surat
    String? dokumenDari,
    String? diterimaOleh,
    // Parameter Khusus SIM
    int? idSopir,
    String? statusSim,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    List<int> allAttachmentIds = List.from(existingAttachmentIds);
    for (var file in newAttachments) {
      final attachmentId = await _uploadAttachment(token, file, 'serah_terima');
      if (attachmentId != null) {
        allAttachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu lampiran baru.');
      }
    }

    final Map<String, dynamic> payloadMap = {
      "id": id,
      "jenis": jenis.toLowerCase(),
      "attachment": allAttachmentIds,
      "keterangan": keterangan,
    };

    if (jenis.toLowerCase() == 'sim') {
      if (idSopir != null) payloadMap['id_sopir'] = idSopir;
      if (statusSim != null) payloadMap['status_sim'] = statusSim;
    } else {
      if (dokumenDari != null) payloadMap['dokumen_dari'] = dokumenDari;
      if (diterimaOleh != null) payloadMap['diterima_oleh'] = diterimaOleh;
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/sterima'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal memperbarui data.');
    }
  }

  Future<Map<String, dynamic>> deleteSerahTerimaHistory(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final url = Uri.parse('$_baseUrl/sterima');
    final payload = jsonEncode({"id": id});

    final request = http.Request('DELETE', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json'
      ..body = payload;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Gagal menghapus riwayat serah terima.',
        );
      }
    } else {
      throw Exception(
        'Gagal menghapus riwayat serah terima. Status: ${response.statusCode}',
      );
    }
  }

  // --- TUGAS UMUM ---

  Future<List<dynamic>> fetchTugasUmumHistory() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.get(
      Uri.parse('$_baseUrl/tumum'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Gagal memuat riwayat tugas umum. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> submitTugasUmum({
    required String karyawanId,
    required String keperluan,
    required String jamBerangkat,
    required String statusKendaraan,
    String? armadaId,
    List<File> foto = const [],
  }) async {
    final token = await getToken();
    if (token == null)
      throw Exception('Sesi tidak valid. Silakan login ulang.');

    List<int> attachmentIds = [];
    for (var file in foto) {
      final attachmentId = await _uploadAttachment(token, file, 'tugas_umum');
      if (attachmentId != null) {
        attachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu foto bukti.');
      }
    }

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final String datePart = formatter.format(now);
    final String fullDateTime = "$datePart $jamBerangkat";

    final Map<String, dynamic> payloadMap = {
      "id_karyawan": int.tryParse(karyawanId),
      "keperluan_tugas": keperluan,
      "jam_berangkat": fullDateTime,
      "status_kendaraan": statusKendaraan,
      "attachment": attachmentIds,
    };

    if (statusKendaraan == 'INVENTARIS' &&
        armadaId != null &&
        armadaId.isNotEmpty) {
      payloadMap["id_armada"] = int.tryParse(armadaId);
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/tumum'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal menyimpan tugas umum. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> updateTugasUmum({
    required int id,
    required String karyawanId,
    required String keperluan,
    required String jamBerangkat,
    required String statusKendaraan,
    String? armadaId,
    List<File> newFoto = const [],
    List<int> existingAttachmentIds = const [],
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    List<int> allAttachmentIds = List.from(existingAttachmentIds);
    for (var file in newFoto) {
      final attachmentId = await _uploadAttachment(token, file, 'tugas_umum');
      if (attachmentId != null) {
        allAttachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu foto baru.');
      }
    }

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final String datePart = formatter.format(now);

    String fullDateTime;
    if (jamBerangkat.contains('-')) {
      fullDateTime = jamBerangkat;
    } else {
      fullDateTime = "$datePart $jamBerangkat";
    }

    final Map<String, dynamic> payloadMap = {
      "id": id,
      "id_karyawan": int.tryParse(karyawanId),
      "keperluan_tugas": keperluan,
      "jam_berangkat": fullDateTime,
      "status_kendaraan": statusKendaraan,
      "attachment": allAttachmentIds,
    };

    if (statusKendaraan == 'INVENTARIS' &&
        armadaId != null &&
        armadaId.isNotEmpty) {
      payloadMap["id_armada"] = int.tryParse(armadaId);
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/tumum'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal memperbarui tugas umum. Status: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> deleteTugasUmum(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final response = await http.delete(
      Uri.parse('$_baseUrl/tumum'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id": id}),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(
        responseBody['message'] ??
            'Gagal menghapus tugas umum. Status: ${response.statusCode}',
      );
    }
  }

  Future<void> updateTugasUmumSelesai(TugasUmum item) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final now = DateTime.now();
    final jamSelesaiStr = DateFormat('yyyy-MM-dd HH:mm').format(now);

    // format jam berangkat yyyy-MM-dd HH:mm
    String safeJamBerangkat = item.jamBerangkat;
    try {
      final parsed = DateTime.parse(item.jamBerangkat);
      safeJamBerangkat = DateFormat('yyyy-MM-dd HH:mm').format(parsed);
    } catch (_) {}

    final Map<String, dynamic> payload = {
      "id": item.id,
      "id_karyawan": item.idKaryawan,
      "keperluan_tugas": item.keperluan,
      "jam_berangkat": safeJamBerangkat,
      "jam_selesai": jamSelesaiStr,
      "status_kendaraan": item.statusKendaraan,
    };

    if (item.idArmada != null) {
      payload["id_armada"] = item.idArmada;
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/tumum'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return;
    } else {
      throw Exception(
        responseBody['message'] ?? 'Gagal update status selesai.',
      );
    }
  }

  // --- OFFICE BOY (OB) ---

  // 1. Fetch Master Cabang
  Future<List<Cabang>> fetchCabang() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.get(
      Uri.parse('$_baseUrl/cabang'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Cabang.fromJson(json)).toList();
    } else {
      throw Exception(
        'Gagal memuat data cabang. Status: ${response.statusCode}',
      );
    }
  }

  // 2. Fetch Master Area
  Future<List<ObArea>> fetchObArea({int? cabangId}) async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    String query = '';
    if (cabangId != null) {
      query = '?cabang=$cabangId';
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/oba$query'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ObArea.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data area. Status: ${response.statusCode}');
    }
  }

  // 3. Fetch Master Tugas
  Future<List<ObTugas>> fetchObMasterTugas() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.get(
      Uri.parse('$_baseUrl/obmt'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ObTugas.fromJson(json)).toList();
    } else {
      throw Exception(
        'Gagal memuat master tugas. Status: ${response.statusCode}',
      );
    }
  }

  // 4. Fetch History Tugas OB
  Future<List<dynamic>> fetchObHistory() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.get(
      Uri.parse('$_baseUrl/obt'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Gagal memuat riwayat tugas OB. Status: ${response.statusCode}',
      );
    }
  }

  // 5. Submit Tugas OB
  Future<Map<String, dynamic>> submitTugasOb({
    required int areaId,
    required int tugasId,
    required int karyawanId,
    required String begin, // Format: yyyy-mm-dd HH:mm
    required String end, // Format: yyyy-mm-dd HH:mm
    String? keterangan,
    List<File> foto = const [],
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    // A. Upload Foto
    List<int> attachmentIds = [];
    for (var file in foto) {
      final attachmentId = await _uploadAttachment(token, file, 'tugas_ob');
      if (attachmentId != null) {
        attachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah salah satu foto bukti.');
      }
    }

    // B. Susun Payload
    final Map<String, dynamic> payloadMap = {
      "id_area": areaId,
      "id_tugas": tugasId,
      "id_karyawan": karyawanId,
      "begin": begin,
      "end": end,
      "keterangan": keterangan,
      "attachment": attachmentIds,
    };

    payloadMap.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse('$_baseUrl/obt'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal menyimpan tugas OB.');
    }
  }

  // 6. Update Tugas OB
  Future<Map<String, dynamic>> updateTugasOb({
    required int id,
    required int areaId,
    required int tugasId,
    required int karyawanId,
    required String begin,
    required String end,
    String? keterangan,
    List<File> newFoto = const [],
    List<int> existingAttachmentIds = const [],
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    // A. Upload Foto Baru
    List<int> allAttachmentIds = List.from(existingAttachmentIds);
    for (var file in newFoto) {
      final attachmentId = await _uploadAttachment(token, file, 'tugas_ob');
      if (attachmentId != null) {
        allAttachmentIds.add(attachmentId);
      } else {
        throw Exception('Gagal mengunggah foto baru.');
      }
    }

    final Map<String, dynamic> payloadMap = {
      "id": id,
      "id_area": areaId,
      "id_tugas": tugasId,
      "id_karyawan": karyawanId,
      "begin": begin,
      "end": end,
      "keterangan": keterangan,
      "attachment": allAttachmentIds,
    };

    payloadMap.removeWhere((key, value) => value == null);

    final response = await http.put(
      Uri.parse('$_baseUrl/obt'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payloadMap),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal update tugas OB.');
    }
  }

  // 7. Delete Tugas OB
  Future<Map<String, dynamic>> deleteTugasOb(int id) async {
    final token = await getToken();
    if (token == null) throw Exception('Sesi tidak valid.');

    final response = await http.delete(
      Uri.parse('$_baseUrl/obt'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id": id}),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal menghapus tugas OB.');
    }
  }

  // --- HELPERS ---

  Future<int?> _uploadAttachment(String token, File file, String type) async {
    final uri = Uri.parse('$_baseUrl/attachment');

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mediaType = MediaType.parse(mimeType);

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['type'] = type
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: mediaType,
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['id_attachment'] != null) {
          return data['id_attachment'];
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
