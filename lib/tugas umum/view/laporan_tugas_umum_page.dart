import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 
import '../bloc/tugas_umum_bloc.dart';
import '../../models/armada.dart';
import '../../models/karyawan.dart';
import '../../service_locator.dart';
import '../../services/api_service.dart';
import '../../utils/validasi.dart';
import '../../utils/image_processor.dart'; 
import '../../widgets/image_detail.dart'; 

class LaporanTugasUmumPage extends StatelessWidget {
  const LaporanTugasUmumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TugasUmumBloc(
        apiService: locator<ApiService>(),
      )..add(LoadTugasData()), 
      child: const _TugasUmumScreen(),
    );
  }
}

class _TugasUmumScreen extends StatefulWidget {
  const _TugasUmumScreen();

  @override
  State<_TugasUmumScreen> createState() => __TugasUmumScreenState();
}

class __TugasUmumScreenState extends State<_TugasUmumScreen> {
  final _formKey = GlobalKey<FormState>();

  final _armadaController = TextEditingController();
  final _karyawanController = TextEditingController();
  final _keperluanTugasController = TextEditingController();
  final _jamBerangkatController = TextEditingController();

  Armada? _selectedArmada;
  Karyawan? _selectedKaryawan;
  String _statusKendaraan = 'PRIBADI'; 

  final List<File> _fotoTugas = [];
  final ImagePicker _picker = ImagePicker();
  bool _isProcessingImage = false;

  @override
  void dispose() {
    _armadaController.dispose();
    _karyawanController.dispose();
    _keperluanTugasController.dispose();
    _jamBerangkatController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    
    String userFriendlyMessage;
    const Color backgroundColor = Color.fromRGBO(244, 67, 54, 1);

    if (message.startsWith('KONEKSI_GAGAL_SIMPAN')) {
      userFriendlyMessage = 'Gagal menyimpan data karena masalah jaringan. Coba lagi.';
    } else if (message.startsWith('KONEKSI_GAGAL')) {
      userFriendlyMessage = 'Gagal memuat data! Periksa koneksi internet Anda.';
    } else {
      userFriendlyMessage = message;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userFriendlyMessage), 
        backgroundColor: backgroundColor, 
        duration: const Duration(seconds: 4)
      ),
    );
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

    setState(() { _isProcessingImage = true; });

    for (XFile pickedFile in pickedFiles) {
      final File originalTempFile = File(pickedFile.path); 
      try {
        // Proses watermark sebelum ditampilkan
        final File watermarkedFile = await processAndWatermarkImage(pickedFile);
        if (mounted) setState(() { _fotoTugas.add(watermarkedFile); });
      } catch (e) {
        if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
      } finally {
        // Bersihkan file temp original jika dari kamera untuk hemat storage
        if (source == ImageSource.camera) {
           try {
             if (await originalTempFile.exists()) await originalTempFile.delete();
           } catch (_) {}
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
        content: Text('Anda yakin ingin menghapus foto ini?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    
    final File fileToDelete = _fotoTugas.removeAt(index);
    setState(() {});
    
    try {
      if (await fileToDelete.exists()) await fileToDelete.delete();
    } catch (_) {}
  }

  // Membersihkan file foto dari cache setelah sukses submit
  Future<void> _cleanupFiles(List<File> files) async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (var file in files) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> _pilihJamBerangkat() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _jamBerangkatController.text = DateFormat('HH:mm').format(dt);
    }
  }

  void _simpanData() {
    FocusScope.of(context).unfocus();

    // Reset data armada jika status kembali ke pribadi
    if (_statusKendaraan == 'PRIBADI') {
      _selectedArmada = null;
      _armadaController.clear();
    }

    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (_statusKendaraan == 'INVENTARIS' && _selectedArmada == null) {
      _showError('Mohon pilih Nomor Polisi Kendaraan Inventaris.');
      return;
    }
    
    if (!isFormValid || _selectedKaryawan == null) {
      _showError('Mohon lengkapi semua data dengan benar.');
      return;
    }

    if (_fotoTugas.isEmpty) {
      _showError('Mohon unggah minimal satu foto bukti tugas.');
      return;
    }

    context.read<TugasUmumBloc>().add(
      SubmitTugasUmum(
        armadaId: _statusKendaraan == 'INVENTARIS' ? _selectedArmada!.id.toString() : '',
        karyawanId: _selectedKaryawan!.id,
        keperluan: _keperluanTugasController.text,
        jamBerangkat: _jamBerangkatController.text,
        foto: _fotoTugas, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);

    return BlocListener<TugasUmumBloc, TugasUmumState>(
      listener: (context, state) {
        if (state.status == TugasUmumStatus.failure) {
          _showError(state.errorMessage ?? 'Terjadi kesalahan');
        }
        if (state.status == TugasUmumStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Laporan tugas berhasil disimpan!"), backgroundColor: Colors.green),
          );
          // Bersihkan cache gambar setelah berhasil
          final List<File> filesToClean = List.from(_fotoTugas);
          Navigator.of(context).pop();
          _cleanupFiles(filesToClean);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text('Tugas Umum', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detail Tugas Umum', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: navyColor)),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        _buildStatusKendaraanSelector(),

                        const SizedBox(height: 24),
                        if (_statusKendaraan == 'INVENTARIS') ...[
                          _buildArmadaDropdown(),
                          const SizedBox(height: 16),
                        ],
                        _buildKaryawanDropdown(),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _keperluanTugasController,
                          decoration: _buildInputDecoration(label: 'Keperluan Tugas', icon: Icons.description_outlined),
                          maxLines: 3,
                          validator: (value) => AppValidators.validate(value, 'Keperluan Tugas'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _jamBerangkatController,
                          decoration: _buildInputDecoration(label: 'Jam Berangkat', icon: Icons.access_time_outlined),
                          readOnly: true,
                          onTap: _pilihJamBerangkat,
                          validator: (value) => AppValidators.validate(value, 'Jam Berangkat'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildImagePickerList(), 
                  const SizedBox(height: 20),
                  _buildSubmitButton(navyColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusKendaraanSelector() {
    const Color navyColor = Color(0xFF001f3f);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status Kendaraan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'PRIBADI', 
                label: Text('Pribadi', style: TextStyle(fontSize: 13))
              ),
              ButtonSegment(
                value: 'INVENTARIS', 
                label: Text('Inventaris', style: TextStyle(fontSize: 13))
              ),
            ],
            selected: {_statusKendaraan},
            onSelectionChanged: (newSelection) {
              setState(() {
                _statusKendaraan = newSelection.first;
                _selectedArmada = null;
                _armadaController.clear();
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
    );
  }

  Widget _buildImagePickerList() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Foto Bukti Tugas', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF001f3f))),
          const SizedBox(height: 4),
          Text('Bisa tambah lebih dari satu foto.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
          if (_fotoTugas.isNotEmpty)
            GridView.builder(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _fotoTugas.length,
              itemBuilder: (context, index) {
                final file = _fotoTugas[index];
                return Stack(
                  clipBehavior: Clip.none, 
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ImageDetailScreen(imageFile: file))),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8), 
                          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -10, right: -10,
                      child: GestureDetector(
                        onTap: () => _hapusFoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (_fotoTugas.isNotEmpty) const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text('Tambah Foto', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onPressed: _isProcessingImage ? null : _pilihSumberGambar,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: const Color(0xFF001f3f),
              side: const BorderSide(color: Color(0xFF001f3f)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_isProcessingImage) const Padding(padding: EdgeInsets.only(top: 16.0), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(Color navyColor) {
    return SafeArea(
      top: false,
      child: BlocBuilder<TugasUmumBloc, TugasUmumState>(
        builder: (context, state) {
          final isSubmitting = state.status == TugasUmumStatus.submitting;
          return ElevatedButton(
            onPressed: isSubmitting ? null : _simpanData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              backgroundColor: navyColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text('SIMPAN DATA', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1)),
          );
        },
      ),
    );
  }

  Widget _buildArmadaDropdown() {
    return BlocBuilder<TugasUmumBloc, TugasUmumState>(
      buildWhen: (p, c) => p.daftarArmada != c.daftarArmada,
      builder: (context, state) {
        if (state.status == TugasUmumStatus.loading && state.daftarArmada.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return TypeAheadField<Armada>(
          controller: _armadaController,
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
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildInputDecoration(label: 'Nomor Polisi Kendaraan', icon: Icons.pin_outlined),
              validator: (value) {
                if (_statusKendaraan == 'INVENTARIS') {
                  if (value == null || value.isEmpty || _selectedArmada == null) return "Mohon pilih nomor polisi.";
                  if (!state.daftarArmada.any((a) => a.nopol == value)) return "Pilih nomor polisi dari daftar.";
                }
                return null;
              },
            );
          },
          suggestionsCallback: (pattern) => state.daftarArmada.where((a) => a.nopol.toLowerCase().contains(pattern.toLowerCase())).toList(),
          itemBuilder: (context, armada) => ListTile(title: Text(armada.nopol, style: GoogleFonts.poppins())),
          onSelected: (armada) {
            _armadaController.text = armada.nopol;
            setState(() => _selectedArmada = armada);
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  Widget _buildKaryawanDropdown() {
    return BlocBuilder<TugasUmumBloc, TugasUmumState>(
      buildWhen: (p, c) => p.daftarKaryawan != c.daftarKaryawan,
      builder: (context, state) {
        if (state.status == TugasUmumStatus.loading && state.daftarKaryawan.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return TypeAheadField<Karyawan>(
          controller: _karyawanController,
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
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildInputDecoration(label: 'Nama Karyawan', icon: Icons.person_outline),
              validator: (value) {
                if (value == null || value.isEmpty || _selectedKaryawan == null) return "Mohon pilih nama karyawan.";
                if (!state.daftarKaryawan.any((k) => k.nama == value)) return "Pilih nama karyawan dari daftar.";
                return null;
              },
            );
          },
          suggestionsCallback: (pattern) => state.daftarKaryawan.where((k) => k.nama.toLowerCase().contains(pattern.toLowerCase()) || k.alias.toLowerCase().contains(pattern.toLowerCase())).toList(),
          itemBuilder: (context, karyawan) => ListTile(
            title: Text(karyawan.nama, style: GoogleFonts.poppins()),
            subtitle: karyawan.alias.isNotEmpty ? Text(karyawan.alias, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])) : null,
          ),
          onSelected: (karyawan) {
            _karyawanController.text = karyawan.nama;
            setState(() => _selectedKaryawan = karyawan);
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      floatingLabelStyle: GoogleFonts.poppins(color: const Color(0xFF001f3f)),
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF001f3f), width: 2)),
    );
  }
}