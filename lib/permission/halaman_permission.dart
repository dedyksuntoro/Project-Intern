import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // Untuk AuthWrapper

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // Meminta izin satu per satu atau bersamaan
    await [
      Permission.camera,
      Permission.location,
      Permission.storage,
    ].request();

    // Simpan status bahwa pengguna telah melihat halaman permission
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);

    if (!mounted) return;

    // Lanjut ke AuthWrapper untuk menentukan status login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Ikon Animasi atau Badge
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: navyColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_outlined,
                  size: 100,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Izin Akses Aplikasi',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Untuk memberikan pengalaman terbaik, MPPM App membutuhkan beberapa izin akses pada perangkat Anda:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // List Izin
              _buildPermissionItem(
                icon: Icons.camera_alt_outlined,
                title: 'Kamera',
                desc: 'Untuk mengambil gambar kegiatan pemotretan',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                icon: Icons.location_on_outlined,
                title: 'Lokasi',
                desc: 'Untuk fitur pelacakan koordinat kegiatan',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                icon: Icons.folder_outlined,
                title: 'Penyimpanan',
                desc: 'Untuk mengunggah file dan pembaruan aplikasi',
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: navyColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Izinkan & Lanjutkan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF001f3f).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF001f3f), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF001f3f),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
