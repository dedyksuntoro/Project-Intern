import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'kendaraan/view/halaman_kendaraan_view.dart';
import 'tamu/view/halaman_tamu.dart';
import 'riwayat/view/halaman_riwayat.dart';
import 'truk/view/halaman_truk.dart';
import 'profile/halaman_profil.dart';
import 'dokumen/halaman_dokumen.dart';
import 'Sim/halaman_sim.dart';
import '../tugas umum/view/laporan_tugas_umum_page.dart';
import 'tugas Ob/view/tugas_ob_page.dart';

import 'services/api_service.dart';
import 'services/update_service.dart';
import 'service_locator.dart';

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

// ============================================================================
// Halaman Beranda (Home Page)
// ============================================================================

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key});

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = locator<ApiService>();
  String _userName = '';
  String? _userPhoto;

  late AnimationController _animController;
  String? _weatherInfo;
  IconData? _weatherIcon;
  bool _showWeather = false;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadUser();
    _fetchWeather();

    // Toggle between date and weather every 5 seconds
    _weatherTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_weatherInfo != null && mounted) {
        setState(() {
          _showWeather = !_showWeather;
        });
      }
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      double lat = -6.2088; // Default Jakarta
      double lon = 106.8456;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          try {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 5),
            );
            lat = position.latitude;
            lon = position.longitude;
          } catch (e) {
            try {
              Position? position = await Geolocator.getLastKnownPosition();
              if (position != null) {
                lat = position.latitude;
                lon = position.longitude;
              }
            } catch (_) {}
          }
        }
      }

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        final temp = current['temperature'].round();
        final code = current['weathercode'];

        IconData icon = Icons.wb_sunny_rounded;
        String desc = 'Cerah';

        if (code == 0) {
          icon = Icons.wb_sunny_rounded;
          desc = 'Cerah';
        } else if (code >= 1 && code <= 3) {
          icon = Icons.cloud_rounded;
          desc = 'Berawan';
        } else if (code == 45 || code == 48) {
          icon = Icons.foggy;
          desc = 'Berkabut';
        } else if (code >= 51 && code <= 67) {
          icon = Icons.grain_rounded;
          desc = 'Gerimis';
        } else if (code >= 71 && code <= 77) {
          icon = Icons.ac_unit_rounded;
          desc = 'Salju';
        } else if (code >= 80 && code <= 82) {
          icon = Icons.water_drop_rounded;
          desc = 'Hujan';
        } else if (code >= 95 && code <= 99) {
          icon = Icons.thunderstorm_rounded;
          desc = 'Badai';
        }

        if (mounted) {
          setState(() {
            _weatherInfo = '$temp°C $desc';
            _weatherIcon = icon;
          });
        }
      }
    } catch (e) {
      // Ignore weather errors quietly
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userName = user.nama;
          _userPhoto = user.urlFoto;
        });
        _animController.forward();
      }
    } catch (_) {
      if (mounted) _animController.forward();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    final List<_MenuItem> menuItems = [
      _MenuItem(
        title: 'Formulir Tamu',
        subtitle: 'Catat tamu berkunjung',
        icon: Icons.people_alt_rounded,
        gradientColors: [const Color(0xFFFF9A56), const Color(0xFFFF6B35)],
        page: const GuestMenuScreen(),
      ),
      _MenuItem(
        title: 'Kendaraan',
        subtitle: 'Inventaris keluar/masuk',
        icon: Icons.local_shipping_rounded,
        gradientColors: [const Color(0xFF56B4FF), const Color(0xFF1E88E5)],
        page: const HalamanKendaraanView(),
      ),
      _MenuItem(
        title: 'Cek Truk',
        subtitle: 'Kondisi truk masuk/keluar',
        icon: Icons.fire_truck_rounded,
        gradientColors: [const Color(0xFFFF6B6B), const Color(0xFFD32F2F)],
        page: const TruckPage(),
      ),
      _MenuItem(
        title: 'Dokumen',
        subtitle: 'Serah terima surat & paket',
        icon: Icons.article_rounded,
        gradientColors: [const Color(0xFF66D9A0), const Color(0xFF2E9B63)],
        page: const DocumentHandoverScreen(),
      ),
      _MenuItem(
        title: 'Serah SIM',
        subtitle: 'Serah terima SIM sopir',
        icon: Icons.badge_rounded,
        gradientColors: [const Color(0xFF4DD0C8), const Color(0xFF00897B)],
        page: const SimHandoverScreen(),
      ),
      _MenuItem(
        title: 'Tugas Umum',
        subtitle: 'Tugas & pemakaian inventaris',
        icon: Icons.assignment_ind_rounded,
        gradientColors: [const Color(0xFFFFD54F), const Color(0xFFF9A825)],
        page: const LaporanTugasUmumPage(),
      ),
      _MenuItem(
        title: 'Tugas OB',
        subtitle: 'Pekerjaan Office Boy',
        icon: Icons.cleaning_services_rounded,
        gradientColors: [const Color(0xFFCE93D8), const Color(0xFF8E24AA)],
        page: const TugasObPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // --- Header ---
          _buildHeader(dateStr),

          // --- Section Label ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Menu Aplikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // --- Grid Menu ---
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = menuItems[index];
                      return AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final delay = index * 0.1;
                          final start = delay.clamp(0.0, 0.6);
                          final end = (start + 0.4).clamp(0.0, 1.0);
                          final curvedValue = CurvedAnimation(
                            parent: _animController,
                            curve: Interval(
                              start,
                              end,
                              curve: Curves.easeOutCubic,
                            ),
                          ).value;

                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - curvedValue)),
                            child: Opacity(opacity: curvedValue, child: child),
                          );
                        },
                        child: _MenuGridCard(
                          item: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item.page),
                          ),
                        ),
                      );
                    }, childCount: menuItems.length),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String dateStr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2E6E), Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Background Texture & Watermark Logo
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    top: 0,
                    child: Image.asset(
                      'assets/Hello-rafiki.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: Logo + App Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset('assets/logo.png', width: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(
                                    'MPPM',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(
                                    'GENERAL AFFAIR',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Date chip
                  // Date chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: _showWeather && _weatherInfo != null
                          ? Row(
                              key: const ValueKey('weather'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _weatherIcon,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _weatherInfo!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('date'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    dateStr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Data Model untuk Menu Item
// ============================================================================

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget page;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.page,
  });
}

// ============================================================================
// Menu Grid Card Widget
// ============================================================================

class _MenuGridCard extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _MenuGridCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.gradientColors.last.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: item.gradientColors.first.withOpacity(0.15),
          highlightColor: item.gradientColors.first.withOpacity(0.05),
          child: Stack(
            children: [
              // Background Watermark Icon
              Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    item.icon,
                    size: 80,
                    color: item.gradientColors.last,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: item.gradientColors.last.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 26),
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      item.subtitle,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
