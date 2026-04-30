import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../utils/validasi.dart';
import '../../halaman_utama.dart';
import '../bloc/login_bloc.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';
import '../../services/antijailbreak.dart';

class LoginPageBaru extends StatelessWidget {
  const LoginPageBaru({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        apiService: locator<ApiService>(),
      ),
      child: const LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSecurity();
    });
  }

  Future<void> _checkSecurity() async {
    final bool isDeviceSecure = await SecurityService.isDeviceSecure();
    if (!isDeviceSecure && mounted) {
      _showSecurityWarning();
    }
  }

  void _showSecurityWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Peringatan Keamanan'),
          content: const Text(
            'Aplikasi ini tidak dapat berjalan pada perangkat yang telah di-root atau di-jailbreak karena alasan keamanan.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Keluar'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            LoginButtonPressed(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);

    return Scaffold(
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            String errorMessage = state.error;
            Color backgroundColor = Colors.red;
            String userFriendlyMessage;

            // Mapping pesan error teknis ke pesan user-friendly
            if (errorMessage.startsWith('KONEKSI_GAGAL')) {
              userFriendlyMessage = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
              backgroundColor = Colors.orange;
            } else if (errorMessage.startsWith('TIMEOUT_GAGAL')) {
              userFriendlyMessage = 'Waktu koneksi habis. Sinyal mungkin buruk atau server sibuk.';
              backgroundColor = Colors.orange;
            } else if (errorMessage.contains('Username atau password salah')) {
              userFriendlyMessage = 'Username atau Password salah. Silakan coba lagi.';
              backgroundColor = Colors.red;
            } else {
              userFriendlyMessage = errorMessage;
              backgroundColor = Colors.red;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userFriendlyMessage),
                backgroundColor: backgroundColor,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          
          if (state is LoginSuccess) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(key: UniqueKey()),
              ),
              (Route<dynamic> route) => false,
            );
          }
        },
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/background_login.png',
                fit: BoxFit.cover,
              ),
            ),
            // Overlay Gelap (lebih tipis)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
              ),
            ),
            // Form Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/logo.png', height: 100),
                              const SizedBox(height: 16),
                              Text(
                                'Selamat Datang',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Masuk untuk melanjutkan',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 40),
                              
                              // Input Username
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: GoogleFonts.poppins(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.15),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                ),
                                validator: (value) => AppValidators.validate(value, 'Username'),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: 20),

                              // Input Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: GoogleFonts.poppins(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.15),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.white, width: 1.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                ),
                                validator: (value) => AppValidators.validate(value, 'Password'),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: 32),

                              // Login Button
                              BlocBuilder<LoginBloc, LoginState>(
                                builder: (context, state) {
                                  return Container(
                                    width: double.infinity,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: state is LoginLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: state is LoginLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Text(
                                              'LOGIN',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 1.2,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Lupa Password?',
                                  style: GoogleFonts.poppins(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}