import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../models/users.dart';
import '../services/api_service.dart';
import '../login/view/halaman_login_baru.dart';
import '../service_locator.dart';
import 'halaman_edit_profile.dart';
import 'faq_page.dart';
import 'halaman_ubah_password.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = locator<ApiService>();
  final ScrollController _scrollController = ScrollController();
  bool _showAppBar = false;

  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserProfileFromStorage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfileFromStorage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Gagal memuat data user dari storage: $e");
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;
    final bool? shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _user!),
      ),
    );
    if (shouldRefresh == true) {
      _loadUserProfileFromStorage();
    }
  }

  void _showPhotoDetail(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showAppBar) {
      setState(() => _showAppBar = true);
    } else if (_scrollController.offset <= 100 && _showAppBar) {
      setState(() => _showAppBar = false);
    }
  }

  
  Future<void> _handleLogout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin keluar?',
              style: GoogleFonts.poppins()),
          actions: <Widget>[
            TextButton(
                child: Text('Batal', style: GoogleFonts.poppins()),
                onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
                child: Text('Ya, Logout',
                    style: GoogleFonts.poppins(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      
      try {
        await _apiService.logout();
      } catch (e) {
        
        print("Error saat server logout: $e");
      }

      // hapus token dr shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token'); 
      

      if (context.mounted) {
        // Arahkan kembali ke halaman login
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPageBaru()),
            (Route<dynamic> route) => false);
      }
    }
  }
  

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.mandala-group.co.id/privacy-policy/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Tidak dapat membuka link',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);
    const Color greyTextColor = Color(0xFF6c757d);
    final bool hasPhoto = _user?.urlFoto != null && _user!.urlFoto!.isNotEmpty;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width / 2.16,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/profile_bg.png'),
                        fit: BoxFit.cover),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24)),
                  ),
                  clipBehavior: Clip.antiAlias,
                ),
                RefreshIndicator(
                  onRefresh: _loadUserProfileFromStorage,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 90),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    spreadRadius: 2,
                                    blurRadius: 10)
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: hasPhoto
                                      ? () => _showPhotoDetail(_user!.urlFoto!)
                                      : null,
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: hasPhoto
                                        ? NetworkImage(_user!.urlFoto!)
                                        : null,
                                    child: !hasPhoto
                                        ? const Icon(Icons.person,
                                            size: 30, color: navyColor)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_user?.nama ?? 'Memuat...',
                                          style: GoogleFonts.roboto(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: navyColor)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.gpp_good_outlined,
                                              color: Colors.blue,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text('Security',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  color: greyTextColor)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.add_ic_call_outlined,
                                              color: Colors.green,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(_user?.telp ?? '...',
                                              style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  color: greyTextColor)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text('Preferensi',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 5)
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildProfileMenu(
                                  title: 'Edit Profile',
                                  icon: Icons.person_outline,
                                  onTap: _navigateToEditProfile,
                                ),
                                const Divider(
                                    height: 1, indent: 56, endIndent: 16),
                                _buildProfileMenu(
                                  title: 'Ubah Password',
                                  icon: Icons.lock_outline,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const UbahPasswordScreen()),
                                    );
                                  },
                                ),
                                const Divider(
                                    height: 1, indent: 56, endIndent: 16),
                                _buildProfileMenu(
                                    title: 'Pengaturan',
                                    icon: Icons.settings_outlined,
                                    onTap: () {}),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text('Bantuan & Informasi',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 5)
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildProfileMenu(
                                    title: 'Kebijakan Aplikasi',
                                    icon: Icons.info_outline,
                                    onTap: () => _openPrivacyPolicy()),
                                const Divider(
                                    height: 1, indent: 56, endIndent: 16),
                                _buildProfileMenu(
                                    title: 'FAQ',
                                    icon: Icons.help_outline,
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FaqScreen()));
                                    }),
                                const Divider(
                                    height: 1, indent: 56, endIndent: 16),
                                _buildProfileMenu(
                                    title: 'Logout',
                                    icon: Icons.logout,
                                    color: Colors.red,
                                    onTap: () => _handleLogout(context)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _showAppBar ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF001f3f),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text('Profilku',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileMenu({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? const Color(0xFF001f3f)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: color),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color ?? Colors.grey,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}