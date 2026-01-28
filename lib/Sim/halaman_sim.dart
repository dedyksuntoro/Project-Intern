import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/sopir.dart';
import '../services/api_service.dart';
import '../service_locator.dart';
import '../utils/image_processor.dart';
import '../widgets/image_detail.dart';

class SimHandoverScreen extends StatefulWidget {
  const SimHandoverScreen({super.key});

  @override
  State<SimHandoverScreen> createState() => _SimHandoverScreenState();
}

class _SimHandoverScreenState extends State<SimHandoverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaSopirController = TextEditingController();
  
  // controller keterangan
  final _keteranganLainController = TextEditingController(); 
  bool _showKeteranganLain = false;
 

  Set<String> _statusSim = {'Terima'};
  List<File> _fotoBukti = [];

  List<Sopir> _daftarSopir = [];
  bool _isLoadingSopir = false;
  Sopir? _selectedSopir;

  final ImagePicker _picker = ImagePicker();
  bool _isProcessingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSopir();
  }

  @override
  void dispose() {
    _namaSopirController.dispose();
    _keteranganLainController.dispose(); 
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    
    String userFriendlyMessage;
    Color backgroundColor = Colors.red;
    Duration duration = const Duration(seconds: 4);

    if (message.startsWith('KONEKSI_GAGAL_LOAD')) {
      userFriendlyMessage = 'Gagal memuat daftar sopir! Periksa koneksi internet Anda.';
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    } else if (message.startsWith('KONEKSI_GAGAL_SIMPAN')) {
      userFriendlyMessage = 'Gagal menyimpan data karena masalah jaringan atau sinyal buruk. Coba lagi.';
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    } else {
      userFriendlyMessage = message; 
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
      duration = const Duration(seconds: 4);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFriendlyMessage), backgroundColor: backgroundColor, duration: duration),
    );
  }

  Future<void> _fetchSopir() async {
    if (mounted) setState(() => _isLoadingSopir = true);
    try {
      final apiService = locator<ApiService>();
      final sopirList = await apiService.fetchSopir();
      if (mounted) {
        setState(() {
          _daftarSopir = sopirList;
        });
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (e is SocketException || e.toString().contains('ClientException') || e.toString().contains('TimeoutException')) {
          errorMessage = 'KONEKSI_GAGAL_LOAD: $errorMessage';
      }
      if (mounted) _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoadingSopir = false);
    }
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
            _fotoBukti.add(watermarkedFile);
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

    if (mounted) setState(() { _isProcessingImage = false; });
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

    final File fileToDelete = _fotoBukti.removeAt(index);
    setState(() {});

    try {
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
      }
    } catch (e) {
      print('[SimForm] Gagal menghapus file dari cache: $e');
    }
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;
    
    if (!isFormValid) {
      _showError('Mohon lengkapi semua data dengan benar.');
      return;
    }
    
    if (_selectedSopir == null) {
      _showError('Mohon pilih nama sopir dari daftar.');
      return;
    }

    if (_fotoBukti.isEmpty) {
      _showError('Mohon upload foto bukti.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final int? idSopir = int.tryParse(_selectedSopir!.id);
    if (idSopir == null || idSopir == 0) {
      _showError('ID Sopir tidak valid.');
      setState(() => _isSubmitting = false);
      return;
    }

    final String statusSimUi = _statusSim.first;
    final List<File> foto = _fotoBukti;
    
    final String statusApi = statusSimUi == 'Terima' ? 'diterima' : 'diserahkan';
    
    try {
      final apiService = locator<ApiService>(); 

      // kirim parameter ktrngn
      await apiService.submitSimHandover(
        idSopir: idSopir,
        statusSim: statusApi,
        attachments: foto,
        // Kirim teks hanya jika checkbox dicentang, jika tidak kirim null
        keterangan: _showKeteranganLain ? _keteranganLainController.text : null,
      );


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data Serah SIM berhasil disimpan!'),
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
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (e is SocketException || e.toString().contains('ClientException') || e.toString().contains('TimeoutException')) {
          errorMessage = 'KONEKSI_GAGAL_SIMPAN: $errorMessage';
      }
      _showError(errorMessage);
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
        title: Text('Serah SIM',
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
                      Text('Detail SIM',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: navyColor)),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      _buildSopirDropdown(),
                      const SizedBox(height: 24),
                      
                      Text('Status SIM',
                          style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity, 
                        child: SegmentedButton<String>(
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment<String>(
                                value: 'Terima',
                                label: Text('Terima', style: TextStyle(fontSize: 13))),
                            ButtonSegment<String>(
                                value: 'Serah',
                                label: Text('Serah', style: TextStyle(fontSize: 13))),
                          ],
                          selected: _statusSim,
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              if (newSelection.isNotEmpty) {
                                _statusSim = {newSelection.last};
                              }
                            });
                          },
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
                
                // UI keterangan lain laim
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
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
                    children: [
                      CheckboxListTile(
                        title: Text(
                          'Tambah Keterangan Lain-Lain',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF001f3f)),
                        ),
                        value: _showKeteranganLain,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _showKeteranganLain = newValue ?? false;
                            if (!_showKeteranganLain) {
                              _keteranganLainController.clear();
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFF001f3f),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_showKeteranganLain)
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 12.0, left: 8.0, right: 8.0),
                          child: TextFormField(
                            controller: _keteranganLainController,
                            decoration: _buildInputDecoration(
                              label: 'Keterangan Lain-Lain',
                              icon: Icons.notes_outlined,
                            ),
                            maxLines: 4,
                          ),
                        ),
                    ],
                  ),
                ),
               

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

  Widget _buildSopirDropdown() {
    return TypeAheadField<Sopir>(
      controller: _namaSopirController,
      decorationBuilder: (context, child) {
        return Material(
          color: Colors.white,
          type: MaterialType.card,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: child,
        );
      },
      builder: (context, controller, focusNode) {
        return Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildInputDecoration(
                  label: 'Nama Sopir', icon: Icons.badge_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Mohon pilih nama sopir.";
                }
                final isValid = _daftarSopir.any((s) => s.nama == value);
                if (!isValid) {
                  _selectedSopir = null;
                  return "Pilih nama sopir dari daftar.";
                }
                return null;
              },
            ),
            if (_isLoadingSopir)
              const Padding(
                padding: EdgeInsets.only(right: 12.0, bottom: 10.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF001f3f)),
                ),
              ),
          ],
        );
      },
      suggestionsCallback: (pattern) {
        if (_isLoadingSopir) return [];
        return _daftarSopir
            .where((s) =>
                s.nama.toLowerCase().contains(pattern.toLowerCase()) ||
                s.alias.toLowerCase().contains(pattern.toLowerCase()))
            .toList();
      },
      itemBuilder: (context, sopir) => ListTile(
        title: Text(sopir.nama, style: GoogleFonts.poppins()),
        subtitle:
            Text("NIK: ${sopir.nik}", style: GoogleFonts.poppins(fontSize: 12)),
      ),
      onSelected: (sopir) {
        _namaSopirController.text = sopir.nama;
        _selectedSopir = sopir;
        FocusScope.of(context).unfocus();
      },
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
          Text('Upload Foto Bukti',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF001f3f))),
          const SizedBox(height: 4),
          Text('Bisa tambah lebih dari satu foto.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
          if (_fotoBukti.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _fotoBukti.length,
              itemBuilder: (context, index) {
                final file = _fotoBukti[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageDetailScreen(imageFile: file),
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
          if (_fotoBukti.isNotEmpty) const SizedBox(height: 16),
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