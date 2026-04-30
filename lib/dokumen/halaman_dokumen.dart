import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/image_processor.dart';
import '../utils/validasi.dart';
import '../widgets/image_detail.dart';

class DocumentHandoverScreen extends StatefulWidget {
  const DocumentHandoverScreen({super.key});

  @override
  State<DocumentHandoverScreen> createState() => _DocumentHandoverScreenState();
}

class _DocumentHandoverScreenState extends State<DocumentHandoverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dokumenDariController = TextEditingController();
  final _diterimaOlehController = TextEditingController();

  Set<String> _jenisDokumen = {'Surat'};

  List<File> _fotoDokumen = [];

  final ImagePicker _picker = ImagePicker();
  bool _isProcessingImage = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _dokumenDariController.dispose();
    _diterimaOlehController.dispose();
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
      File? sourceFileCopy;
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String safePath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        sourceFileCopy = await File(pickedFile.path).copy(safePath);

        final File watermarkedFile =
            await processAndWatermarkImage(XFile(sourceFileCopy.path));

        if (mounted) {
          setState(() {
            _fotoDokumen.add(watermarkedFile);
          });
        }
      } catch (e) {
        if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
      } finally {
        if (sourceFileCopy != null && await sourceFileCopy.exists()) {
          try {
            await sourceFileCopy.delete();
          } catch (e) {
            print('Gagal hapus file copy: $e');
          }
        }
      }
    }

    if (mounted)
      setState(() {
        _isProcessingImage = false;
      });
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
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
      }
    } catch (e) {
      print('[DokumenForm] Gagal menghapus file dari cache: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      _showError('Mohon lengkapi semua data dengan benar.');
      return;
    }

    if (_fotoDokumen.isEmpty) {
      _showError('Mohon ambil Foto dengan Penerima.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final dokumenDari = _dokumenDariController.text;
    final diterimaOleh = _diterimaOlehController.text;
    final jenis = _jenisDokumen.first;
    final List<File> foto = _fotoDokumen;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      await apiService.submitDokumen(
        dokumenDari: dokumenDari,
        diterimaOleh: diterimaOleh,
        jenis: jenis,
        attachments: foto,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data dokumen berhasil disimpan!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);

      for (var file in foto) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Gagal hapus file temp: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);

    return Scaffold(
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
        title: Text('Form Dokumen',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Detail Serah Terima',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: navyColor)),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dokumenDariController,
                        decoration: _buildInputDecoration(
                            label: 'Dokumen Dari',
                            icon: Icons.person_search_outlined),
                        validator: (value) =>
                            AppValidators.validate(value, 'Dokumen Dari'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diterimaOlehController,
                        decoration: _buildInputDecoration(
                            label: 'Diterima oleh',
                            icon: Icons.person_pin_circle_outlined),
                        validator: (value) =>
                            AppValidators.validate(value, 'Diterima oleh'),
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // JENIS DOKUMEN (STYLE UPDATED: Compact)
                      // ==========================================
                      Text('Jenis Dokumen',
                          style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity, // Full Width
                        child: SegmentedButton<String>(
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment<String>(
                                value: 'Surat',
                                label: Text('Surat', style: TextStyle(fontSize: 13))),
                            ButtonSegment<String>(
                                value: 'Dokumen',
                                label: Text('Dokumen', style: TextStyle(fontSize: 13))),
                            ButtonSegment<String>(
                                value: 'Paket',
                                label: Text('Paket', style: TextStyle(fontSize: 13))),
                          ],
                          selected: _jenisDokumen,
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              if (newSelection.isNotEmpty) {
                                _jenisDokumen = {newSelection.last};
                              }
                            });
                          },
                          // STYLE DISAMAKAN DENGAN HALAMAN TRUK
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return navyColor;
                                }
                                return Colors.grey[200]!;
                              },
                            ),
                            foregroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.white;
                                }
                                return navyColor;
                              },
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildImagePickerList(),

                const SizedBox(height: 20),

                SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: navyColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 5,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3),
                          )
                        : Text(
                            'SIMPAN DATA',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                  ),
                ),
              ],
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
            'Foto Dokumen & Penerima',
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