import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../widgets/image_detail.dart';
import '../bloc/tamu_bloc.dart';
import '../../utils/validasi.dart';
import '../../utils/image_processor.dart';

class GuestMenuScreen extends StatelessWidget {
  const GuestMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TamuBloc(),
      child: const GuestForm(),
    );
  }
}

class GuestForm extends StatefulWidget {
  const GuestForm({super.key});

  @override
  State<GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends State<GuestForm> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _instansiController = TextEditingController();
  final _menemuiController = TextEditingController();
  final _keperluanController = TextEditingController();

  List<File> _fotoDokumen = [];
  final ImagePicker _picker = ImagePicker();

  bool _isProcessingImage = false;

  @override
  void dispose() {
    _namaController.dispose();
    _instansiController.dispose();
    _menemuiController.dispose();
    _keperluanController.dispose();
    super.dispose();
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
    List<XFile> pickedFiles = [];
    if (source == ImageSource.gallery) {
      pickedFiles = await _picker.pickMultiImage();
    } else {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) pickedFiles.add(pickedFile);
    }
    if (pickedFiles.isEmpty || !mounted) return;
    
    setState(() {
      _isProcessingImage = true;
    });

    for (XFile pickedFile in pickedFiles) {
      final File originalTempFile = File(pickedFile.path);
      try {
        final File watermarkedFile = await processAndWatermarkImage(pickedFile);
        if (await originalTempFile.exists()) await originalTempFile.delete();
        if (mounted) {
          setState(() {
            _fotoDokumen.add(watermarkedFile);
          });
        }
      } catch (e) {
        if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }

    if (mounted) {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _hapusFoto(int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Foto?', style: GoogleFonts.poppins()),
        content: Text('Anda yakin ingin menghapus foto ini?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    final File fileToDelete = _fotoDokumen.removeAt(index);
    setState(() {});

    try {
      if (await fileToDelete.exists()) await fileToDelete.delete();
    } catch (_) {}
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
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
          title: Text('Formulir Tamu',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.white)),
          centerTitle: true,
        ),
        body: BlocListener<TamuBloc, TamuState>(
          listener: (context, state) {
            if (state is TamuSubmissionFailure) {
              _showError(state.error);
            }
            if (state is TamuSubmissionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Data tamu berhasil disimpan!'),
                    backgroundColor: Colors.green),
              );
              if (mounted) Navigator.of(context).pop();
            }
          },
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Informasi Tamu',
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: navyColor)),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _namaController,
                            decoration: _buildInputDecoration(
                                label: 'Nama Lengkap',
                                icon: Icons.person_outline),
                            validator: (v) =>
                                AppValidators.validateName(v, 'Nama Lengkap'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _instansiController,
                            decoration: _buildInputDecoration(
                                label: 'Asal Instansi/Perusahaan',
                                icon: Icons.business_center_outlined),
                            validator: (v) => AppValidators.validate(
                                v, 'Asal Instansi/Perusahaan'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _menemuiController,
                            decoration: _buildInputDecoration(
                                label: 'Menemui Siapa',
                                icon: Icons.support_agent_outlined),
                            validator: (v) =>
                                AppValidators.validate(v, 'Menemui Siapa'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _keperluanController,
                            decoration: _buildInputDecoration(
                                label: 'Keperluan',
                                icon: Icons.comment_outlined),
                            maxLines: 3,
                            validator: (v) =>
                                AppValidators.validate(v, 'Keperluan'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildImagePickerList(),
                    const SizedBox(height: 24),
                    BlocBuilder<TamuBloc, TamuState>(
                      builder: (context, state) {
                        return SafeArea(
                          child: ElevatedButton(
                            onPressed: state is TamuSubmissionInProgress
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    final isFormValid =
                                        _formKey.currentState?.validate() ??
                                            false;
                                    if (!isFormValid) {
                                      _showError(
                                          'Mohon lengkapi semua data dengan benar.');
                                      return;
                                    }
                                    if (_fotoDokumen.isEmpty) {
                                      _showError(
                                          'Mohon unggah minimal satu foto KTP/Dokumen.');
                                      return;
                                    }
                                    context.read<TamuBloc>().add(
                                          TamuFormSubmitted(
                                            nama: _namaController.text,
                                            instansi: _instansiController.text,
                                            menemui: _menemuiController.text,
                                            keperluan: _keperluanController.text,
                                            foto: _fotoDokumen,
                                          ),
                                        );
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              backgroundColor: navyColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: state is TamuSubmissionInProgress
                                ? const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3)
                                : Text('SIMPAN DATA',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerList() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Foto Bukti',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF001f3f)),
          ),
          const SizedBox(height: 4),
          Text(
            'Bisa tambah lebih dari satu foto.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (_fotoDokumen.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _fotoDokumen.length,
              itemBuilder: (context, index) {
                final file = _fotoDokumen[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ImageDetailScreen(imageFile: file),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -10,
                      right: -10,
                      child: GestureDetector(
                        onTap: () => _hapusFoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (_fotoDokumen.isNotEmpty) const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text('Tambah Foto',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onPressed: _isProcessingImage ? null : _pilihSumberGambar,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: const Color(0xFF001f3f),
              side: const BorderSide(color: Color(0xFF001f3f)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_isProcessingImage)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      floatingLabelStyle: GoogleFonts.poppins(color: const Color(0xFF001f3f)),
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF001f3f), width: 2),
      ),
    );
  }
}