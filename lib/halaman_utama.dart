import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kendaraan/view/halaman_kendaraan_view.dart';
import 'tamu/view/halaman_tamu.dart';
import 'riwayat/view/halaman_riwayat.dart';
import 'truk/view/halaman_truk.dart';
import 'profile/halaman_profil.dart';
import 'dokumen/halaman_dokumen.dart';
import 'Sim/halaman_sim.dart';
import '../tugas umum/view/laporan_tugas_umum_page.dart';
import 'tugas Ob/view/tugas_ob_page.dart';

import 'services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _halamanWidget = [
    const HalamanBeranda(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    // Check for update after build, with a slight delay to ensure UI is ready
    // and avoid blocking the main thread during initial rendering.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        UpdateService().checkForUpdate(context);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _halamanWidget),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF6366F1),
            unselectedItemColor: Colors.grey[500],
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class HalamanBeranda extends StatelessWidget {
  const HalamanBeranda({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF007BFF);
    // Mengambil tinggi layar agar header tetap proporsional
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        // Tinggi header dibuat dinamis
        preferredSize: Size.fromHeight(screenHeight * 0.22),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Atas: Logo dan Notifikasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset('assets/logo.png', width: 24),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'PT. Mandalaputra',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  // Header Teks Selamat Datang
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selamat Datang,',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pilih Menu Operasional',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          MenuCard(
            title: 'Formulir Tamu',
            subtitle: 'Catat tamu yang berkunjung',
            icon: Icons.people_alt_outlined,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GuestMenuScreen()),
            ),
          ),
          const SizedBox(height: 16),
          MenuCard(
            title: 'Kendaraan Inven',
            subtitle: 'Catat kendaraan inventaris Keluar/Masuk',
            icon: Icons.local_shipping_outlined,
            color: accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HalamanKendaraanView(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          MenuCard(
            title: 'Cek Truk',
            subtitle: 'Catat kondisi truk masuk & keluar',
            icon: Icons.fire_truck_outlined,
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TruckPage()),
            ),
          ),
          const SizedBox(height: 16),
          MenuCard(
            title: 'Dokumen',
            subtitle: 'Serah terima paket, dokumen dan surat',
            icon: Icons.article_outlined,
            color: const Color.fromARGB(255, 0, 165, 8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DocumentHandoverScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          MenuCard(
            title: 'Serah SIM',
            subtitle: 'Serah terima SIM sopir',
            icon: Icons.badge_outlined,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SimHandoverScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          MenuCard(
            title: 'Tugas Umum',
            subtitle: 'Catat tugas umum & pemakaian inventaris',
            icon: Icons.assignment_ind_outlined,
            color: const Color.fromARGB(255, 221, 203, 36),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LaporanTugasUmumPage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          MenuCard(
            title: 'Tugas OB',
            subtitle: 'Catat pekerjaan Office Boy',
            icon: Icons.cleaning_services_outlined,
            color: const Color.fromARGB(255, 177, 35, 101),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TugasObPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF001f3f),
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
