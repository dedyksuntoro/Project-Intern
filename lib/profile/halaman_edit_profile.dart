import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/users.dart';
import '../services/api_service.dart';
import '../service_locator.dart';
import '../utils/validasi.dart'; 

class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _apiService = locator<ApiService>();
  final _formKey = GlobalKey<FormState>(); 
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  bool _isLoading = false;

  File? _fotoProfilBaru;
  final ImagePicker _picker = ImagePicker();

  static const Color navyColor = Color(0xFF001f3f);
  static const Color blueButtonColor = Color.fromARGB(255, 2, 154, 255);
  static const Color greyHintColor = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.user.nama;
    _teleponController.text = widget.user.telp;
  }
  
  Future<void> _pilihSumberGambar() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Pilih dari Galeri', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  _ambilGambar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Ambil dari Kamera', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  _ambilGambar(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _ambilGambar(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Sesuaikan Gambar',
              toolbarColor: navyColor,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
              hideBottomControls: true, 
          ),
          IOSUiSettings(
            title: 'Sesuaikan Gambar',
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
            rotateButtonsHidden: true,
            aspectRatioPickerButtonHidden: true,
            doneButtonTitle: 'Selesai',
            cancelButtonTitle: 'Batal',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _fotoProfilBaru = File(croppedFile.path);
        });
      }
    }
  }

  Future<void> _simpanPerubahan() async {
    FocusScope.of(context).unfocus();
    // Validasi form sebelum menyimpan
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_fotoProfilBaru != null) {
        await _apiService.uploadProfilePhoto(_fotoProfilBaru!);
      }

      if (_namaController.text != widget.user.nama || _teleponController.text != widget.user.telp) {
        await _apiService.updateUserProfile(
          nama: _namaController.text,
          telp: _teleponController.text,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Profil berhasil diperbarui!', style: GoogleFonts.poppins()), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    super.dispose();
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
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Bungkus Column dengan widget Form
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Foto profil', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _fotoProfilBaru != null
                          ? FileImage(_fotoProfilBaru!) as ImageProvider
                          : (widget.user.urlFoto != null && widget.user.urlFoto!.isNotEmpty)
                              ? NetworkImage(widget.user.urlFoto!)
                              : null,
                      child: _fotoProfilBaru == null && (widget.user.urlFoto == null || widget.user.urlFoto!.isEmpty)
                          ? const Icon(Icons.person, color: navyColor, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pasang foto yang sangar! semua orang bakal bisa lihat', style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, height: 1.4)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _pilihSumberGambar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blueButtonColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            ),
                            child: Text('Pilih foto', style: GoogleFonts.poppins(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
             
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    children: const <TextSpan>[
                      TextSpan(text: 'Nama Lengkap '),
                      TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                TextFormField( 
                  controller: _namaController,
                  style: GoogleFonts.poppins(color: navyColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Contoh : Agus Suprityo',
                    hintStyle: GoogleFonts.poppins(color: greyHintColor, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: navyColor, width: 2)),
                  ),
                  validator: (value) => AppValidators.validateName(value, 'Nama Lengkap'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 20),
                
               
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    children: const <TextSpan>[
                      TextSpan(text: 'Nomor HP '),
                      TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                TextFormField( 
                  controller: _teleponController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(color: navyColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Contoh : 08123456789',
                    hintStyle: GoogleFonts.poppins(color: greyHintColor, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: navyColor, width: 2)),
                  ),
                  validator: (value) => AppValidators.validatePhone(value),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _simpanPerubahan,
          style: ElevatedButton.styleFrom(
            backgroundColor: navyColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text('Simpan Data', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}