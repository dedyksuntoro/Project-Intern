import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

/// Fungsi utama untuk memproses gambar dan menambahkan watermark
Future<File> processAndWatermarkImage(XFile pickedFile) async {
  final totalStopwatch = Stopwatch()..start();

  try {
    final imageFile = File(pickedFile.path);

    // Dapatkan Lokasi GPS
    final position = await _getCurrentLocation();

    // Persiapan path output dan asset logo
    final tempDir = await getTemporaryDirectory();
    final String outputFilePath =
        '${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';

    List<int>? logoBytes;
    try {
      final ByteData logoData = await rootBundle.load('assets/watermark.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (e) {
      // Logo tidak ditemukan, proses tetap berlanjut tanpa logo
    }

    // Menjalankan proses watermark di background isolate menggunakan compute
    final watermarkedFile = await compute(_addWatermarkInBackground, {
      'filePath': imageFile.path,
      'outputPath': outputFilePath,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'logoBytes': logoBytes,
    });

    if (watermarkedFile == null) {
      throw Exception('Gagal memproses gambar (watermark).');
    }

    totalStopwatch.stop();
    return watermarkedFile;
  } catch (e) {
    totalStopwatch.stop();
    rethrow;
  }
}

/// Helper untuk mendapatkan koordinat GPS saat ini
Future<Position> _getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Layanan lokasi tidak aktif. Mohon aktifkan GPS.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Izin akses lokasi ditolak.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Izin akses lokasi ditolak permanen. Aktifkan di pengaturan.',
    );
  }

  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
}

/// Logika pemrosesan gambar di background isolate
Future<File?> _addWatermarkInBackground(Map<String, dynamic> args) async {
  final String originalFilePath = args['filePath'];
  final String outputFilePath = args['outputPath'];
  final double latitude = args['latitude'];
  final double longitude = args['longitude'];
  final List<int>? logoBytes = args['logoBytes'];

  try {
    final originalFile = File(originalFilePath);
    final originalImageBytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(originalImageBytes);

    if (originalImage == null) return null;

    // Resize gambar jika lebar melebihi 1280px 
    img.Image processedImage = originalImage;
    if (originalImage.width > 1280) {
      processedImage = img.copyResize(originalImage, width: 1280);
    }

    // Pengaturan teks watermark
    final line1 = 'Tanggal Waktu & Lokasi Foto';
    final line2 = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final line3 = 'LAT: ${latitude.toStringAsFixed(5)}, LON: ${longitude.toStringAsFixed(5)}';
    
    final font = img.arial24;
    final textColor = img.ColorRgba8(255, 255, 255, 255);
    final bgColor = img.ColorRgba8(0, 0, 0, 120);
    const textHeight = 30; 
    const startY = 20; 

    // Gambar background rectangle untuk teks agar terbaca
    img.fillRect(
      processedImage,
      x1: 10,
      y1: startY - 10,
      x2: processedImage.width - 10,
      y2: startY + (textHeight * 3) + 10,
      color: bgColor,
      radius: 5,
    );

    // Menuliskan teks watermark (3 baris)
    img.drawString(processedImage, line1, font: font, x: 20, y: startY, color: textColor);
    img.drawString(processedImage, line2, font: font, x: 20, y: startY + textHeight, color: textColor);
    img.drawString(processedImage, line3, font: font, x: 20, y: startY + (textHeight * 2), color: textColor);

    // Proses logo jika tersedia
    if (logoBytes != null) {
      final logoImage = img.decodePng(Uint8List.fromList(logoBytes));
      if (logoImage != null) {
        final logoMaxSize = (processedImage.width * 0.35).round();
        img.Image resizedLogo = logoImage;
        
        if (logoImage.width > logoMaxSize || logoImage.height > logoMaxSize) {
          resizedLogo = (logoImage.width > logoImage.height)
              ? img.copyResize(logoImage, width: logoMaxSize)
              : img.copyResize(logoImage, height: logoMaxSize);
        }

        const logoMargin = 20;
        final logoX = processedImage.width - resizedLogo.width - logoMargin;
        const logoY = logoMargin; 
        
        img.compositeImage(
          processedImage,
          resizedLogo,
          dstX: logoX,
          dstY: logoY,
        );
      }
    }

    // Kompresi dinamis untuk mencapai target ukuran file (max 2MB)
    final watermarkedFile = File(outputFilePath);
    int quality = 85;
    List<int> encodedBytes;
    const maxSizeInBytes = 2 * 1024 * 1024;

    do {
      encodedBytes = img.encodeJpg(processedImage, quality: quality);
      quality -= 10;
    } while (encodedBytes.length > maxSizeInBytes && quality > 40);

    await watermarkedFile.writeAsBytes(encodedBytes);
    return watermarkedFile;
  } catch (e) {
    return null;
  }
}