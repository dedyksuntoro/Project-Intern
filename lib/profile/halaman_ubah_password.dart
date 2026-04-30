import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../service_locator.dart';
import '../utils/validasi.dart'; 

class UbahPasswordScreen extends StatefulWidget {
  const UbahPasswordScreen({super.key});

  @override
  State<UbahPasswordScreen> createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
  final _apiService = locator<ApiService>();
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  static const Color navyColor = Color(0xFF001f3f);
  static const Color greyHintColor = Color(0xFF9E9E9E);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _simpanPasswordBaru() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password berhasil diperbarui!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Ubah Password', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordTextField(
                  label: 'Password Saat Ini',
                  controller: _currentPasswordController,
                  hint: 'Masukkan password lama Anda',
                  isVisible: _isCurrentPasswordVisible,
                  onToggleVisibility: () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                  validator: (value) => AppValidators.validate(value, 'Password Saat Ini'),
                ),
                const SizedBox(height: 20),

                _buildPasswordTextField(
                  label: 'Password Baru',
                  controller: _newPasswordController,
                  hint: 'Minimal 8 karakter, kombinasi huruf & angka',
                  isVisible: _isNewPasswordVisible,
                  onToggleVisibility: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                  validator: (value) => AppValidators.validatePassword(value),
                ),
                const SizedBox(height: 20),

                _buildPasswordTextField(
                  label: 'Konfirmasi Password Baru',
                  controller: _confirmPasswordController,
                  hint: 'Ketik ulang password baru Anda',
                  isVisible: _isConfirmPasswordVisible,
                  onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  validator: (value) {
                    final emptyCheck = AppValidators.isNotEmpty(value, 'Konfirmasi Password');
                    if (emptyCheck != null) return emptyCheck;
                    if (value != _newPasswordController.text) return 'Konfirmasi password tidak cocok.';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _simpanPasswordBaru,
          style: ElevatedButton.styleFrom(
            backgroundColor: navyColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text('Simpan Password', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
    
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            children: <TextSpan>[
              TextSpan(text: '$label '),
              const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          style: GoogleFonts.poppins(color: navyColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: greyHintColor, fontSize: 14),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: navyColor, width: 2)),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: greyHintColor,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}