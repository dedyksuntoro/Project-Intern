import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';
import 'dart:io';

class SecurityService {
  // Fungsi untuk mengecek apakah device di-jailbreak/root
  static Future<bool> isDeviceSecure() async {
    try {
      bool isJailBroken = await SafeDevice.isJailBroken;
      bool isRealDevice = await SafeDevice.isRealDevice;
      
     
      return isRealDevice && !isJailBroken; // && !isDevelopmentModeEnable;


    } catch (e) {
      if (kDebugMode) {
        print('Error checking device security: $e');
      }
      // Jika error, anggap tidak aman
      return false;
    }
  }

  // Fungsi untuk mengecek detail keamanan
  static Future<Map<String, dynamic>> getSecurityDetails() async {
    try {
      return {
        'isJailBroken': await SafeDevice.isJailBroken,
        'isRealDevice': await SafeDevice.isRealDevice,
        'isDevelopmentModeEnable': await SafeDevice.isDevelopmentModeEnable,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting security details: $e');
      }
      return {
        'isJailBroken': true,
        'isRealDevice': false,
        'isDevelopmentModeEnable': true,
      };
    }
  }


  static Future<bool> isMockLocationActive() async {
    try {
      bool isMockLocation = await SafeDevice.isMockLocation;
      if (kDebugMode) {
        print('-> Pengecekan Mock Location / Fake GPS Aktif? : $isMockLocation');
      }
      return isMockLocation;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking mock location: $e');
      }
      return true; // Anggap aktif jika error
    }
  }
}

// Widget untuk mengecek keamanan saat aplikasi dibuka
class SecurityCheckScreen extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSecurityFailed;

  const SecurityCheckScreen({
    Key? key,
    required this.child,
    this.onSecurityFailed,
  }) : super(key: key);

  @override
  State<SecurityCheckScreen> createState() => _SecurityCheckScreenState();
}

class _SecurityCheckScreenState extends State<SecurityCheckScreen> {
  bool _isChecking = true;
  bool _isSecure = false;
  Map<String, dynamic>? _securityDetails;

  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    // isSecure sekarang HANYA mengecek root/jailbreak. Mode Dev diabaikan.
    final isSecure = await SecurityService.isDeviceSecure();
    final details = await SecurityService.getSecurityDetails();

    if (kDebugMode) {
      print('======================================');
      print('    DETAIL PEMERIKSAAN KEAMANAN    ');
      print('--------------------------------------');
      print('-> Apakah Jailbroken/Root? : ${details['isJailBroken']}');
      print('-> Apakah Device Asli?     : ${details['isRealDevice']}');
      print('-> Apakah Mode Dev Aktif?  : ${details['isDevelopmentModeEnable']} (NOTE: Pengecekan ini dinonaktifkan di logic isDeviceSecure)'); // Log diubah
      print('--------------------------------------');
      print('HASIL AKHIR: Perangkat Aman? -> $isSecure');
      print('======================================');
    }

    setState(() {
      _isSecure = isSecure;
      _securityDetails = details;
      _isChecking = false;
    });

    if (!isSecure) {
      if (kDebugMode) {
        print('SECURITY WARNING: Device tidak aman!');
      }
      widget.onSecurityFailed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF001f3f)),
              ),
              SizedBox(height: 20),
              Text(
                'Memeriksa keamanan perangkat...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF001f3f),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isSecure) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Peringatan Keamanan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  // Pesan diubah, "mode pengembang" dihapus
                  'Aplikasi tidak dapat berjalan pada perangkat yang terdeteksi tidak aman (root atau jailbreak).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hal ini dilakukan untuk melindungi keamanan data Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                if (kDebugMode && _securityDetails != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Keamanan (Debug):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jailbroken/Root: ${_securityDetails!['isJailBroken'] == true ? "Ya" : "Tidak"}',
                          style: TextStyle(fontSize: 13, color: _securityDetails!['isJailBroken'] == true ? Colors.red : Colors.green),
                        ),
                        Text(
                          'Real Device: ${_securityDetails!['isRealDevice'] == true ? "Ya" : "Tidak"}',
                          style: TextStyle(fontSize: 13, color: _securityDetails!['isRealDevice'] == false ? Colors.red : Colors.green),
                        ),
                        Text(
                          'Developer Mode: ${_securityDetails!['isDevelopmentModeEnable'] == true ? "Aktif" : "Tidak"} (DIABAIKAN)',
                          style: TextStyle(fontSize: 13, color: _securityDetails!['isDevelopmentModeEnable'] == true ? Colors.orange : Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  onPressed: () => exit(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  label: const Text(
                    'Keluar Aplikasi',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}