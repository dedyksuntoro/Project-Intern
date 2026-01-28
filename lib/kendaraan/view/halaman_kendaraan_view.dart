import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/image_processor.dart';
import '../../kendaraan/bloc/kendaraan_bloc.dart';
import '../../models/armada.dart';
import '../../models/karyawan.dart';
import '../../service_locator.dart';
import '../../services/api_service.dart';
import '../../widgets/image_detail.dart';
import '../../utils/validasi.dart';

class HalamanKendaraanView extends StatelessWidget {
  const HalamanKendaraanView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KendaraanBloc(
        apiService: locator<ApiService>(),
      )..add(LoadInitialData()),
      child: const _KendaraanCheckScreen(),
    );
  }
}

class _KendaraanCheckScreen extends StatefulWidget {
  const _KendaraanCheckScreen();

  @override
  State<_KendaraanCheckScreen> createState() => __KendaraanCheckScreenState();
}

class __KendaraanCheckScreenState extends State<_KendaraanCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kilometerController = TextEditingController();
  final _armadaController = TextEditingController();
  final _karyawanController = TextEditingController();
  final _keteranganLainController = TextEditingController(); 

  final ImagePicker _picker = ImagePicker();

  List<File> _fotoLuar = [];
  List<File> _fotoDalam = [];
  List<File> _fotoSurat = [];
  List<File> _fotoPenanggungJawab = []; // <-- TAMBAHAN BARU

  final Set<int> _processingSlotIndexes = {};
  bool _showKeteranganLain = false; 

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _kilometerController.dispose();
    _armadaController.dispose();
    _karyawanController.dispose();
    _keteranganLainController.dispose(); 
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    
    String userFriendlyMessage;
    Color backgroundColor = Colors.red;

    if (message.startsWith('KONEKSI_GAGAL')) {
      userFriendlyMessage = 'Gagal memuat data! Periksa koneksi internet Anda.';
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    } else if (message.startsWith('KONEKSI_GAGAL_SIMPAN')) {
      userFriendlyMessage = 'Gagal menyimpan data karena masalah jaringan atau sinyal buruk. Coba lagi.';
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    } else {
      userFriendlyMessage = message; 
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFriendlyMessage), backgroundColor: backgroundColor, duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _pilihSumberGambar(int slotIndex) async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet(
        context: context,
        builder: (BuildContext sheetContext) {
          return SafeArea(
              child: Wrap(children: <Widget>[
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Pilih dari Galeri', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _ambilDanProsesGambar(ImageSource.gallery, slotIndex);
                }),
            ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Ambil dari Kamera', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _ambilDanProsesGambar(ImageSource.camera, slotIndex);
                })
          ]));
        });
  }

  Future<void> _ambilDanProsesGambar(ImageSource source, int slotIndex) async {
    List<XFile> pickedFiles = [];
    if (source == ImageSource.gallery) {
      pickedFiles = await _picker.pickMultiImage();
    } else {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) pickedFiles.add(pickedFile);
    }

    if (pickedFiles.isEmpty || !mounted) return;

    setState(() => _processingSlotIndexes.add(slotIndex));

    for (final pickedFile in pickedFiles) {
      File? sourceFileCopy;
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String safePath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        sourceFileCopy = await File(pickedFile.path).copy(safePath);

        final XFile safeXFile = XFile(sourceFileCopy.path);
        final File watermarkedFile = await processAndWatermarkImage(safeXFile);

        if (!mounted) continue;
        setState(() {
          if (slotIndex == 1) _fotoLuar.add(watermarkedFile);
          if (slotIndex == 2) _fotoDalam.add(watermarkedFile);
          if (slotIndex == 3) _fotoSurat.add(watermarkedFile);
          if (slotIndex == 4) _fotoPenanggungJawab.add(watermarkedFile); // <-- TAMBAHAN BARU
        });
      } catch (e) {
        _showError(e.toString().replaceAll('Exception: ', ''));
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

    if (mounted) setState(() => _processingSlotIndexes.remove(slotIndex));
  }

  Future<void> _hapusFoto(int slotIndex, int fileIndex) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Foto?', style: GoogleFonts.poppins()),
        content:
            Text('Anda yakin ingin menghapus foto ini?', style: GoogleFonts.poppins()),
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

    File fileToDelete;

    if (slotIndex == 1) {
      fileToDelete = _fotoLuar.removeAt(fileIndex);
    } else if (slotIndex == 2) {
      fileToDelete = _fotoDalam.removeAt(fileIndex);
    } else if (slotIndex == 3) {
      fileToDelete = _fotoSurat.removeAt(fileIndex);
    } else {
      fileToDelete = _fotoPenanggungJawab.removeAt(fileIndex); // <-- TAMBAHAN BARU
    }

    setState(() {});

    try {
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
      }
    } catch (e) {
      print('[KendaraanForm] Gagal menghapus file dari cache: $e');
    }
  }

  void _simpanData() {
    FocusScope.of(context).unfocus();
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      _showError('Mohon lengkapi semua data dengan benar.');
      return;
    }
    // UPDATE: Validasi penambahan kategori foto baru
    if (_fotoLuar.isEmpty || _fotoDalam.isEmpty || _fotoSurat.isEmpty || _fotoPenanggungJawab.isEmpty) {
      _showError('Mohon unggah minimal satu foto untuk setiap kategori.');
      return;
    }

    context.read<KendaraanBloc>().add(SubmitData(
          kilometer: _kilometerController.text,
          fotoLuar: _fotoLuar,
          fotoDalam: _fotoDalam,
          fotoSurat: _fotoSurat,
          fotoPenanggungJawab: _fotoPenanggungJawab, // <-- TAMBAHAN BARU
          keteranganLain:
              _showKeteranganLain ? _keteranganLainController.text : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);
    return BlocListener<KendaraanBloc, KendaraanState>(
      listener: (context, state) {
        if (state.status == KendaraanStatus.submissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Data berhasil disimpan!"),
                backgroundColor: Colors.green),
          );

          if (mounted) Navigator.of(context).pop();
        }
        if (state.status == KendaraanStatus.submissionFailure ||
            state.status == KendaraanStatus.failure) {
          if (state.errorMessage != null) _showError(state.errorMessage!);
        }
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
          title: Text('Cek Kendaraan',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.white)),
          centerTitle: true,
        ),
        body: SafeArea( 
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
                              blurRadius: 10)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Kendaraan Inven',
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: navyColor)),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildArmadaDropdown(),
                          const SizedBox(height: 16),
                          _buildKaryawanDropdown(),
                          const SizedBox(height: 24),
                          
                          Text('Status Pengecekan',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          BlocBuilder<KendaraanBloc, KendaraanState>(
                            buildWhen: (p, c) =>
                                p.statusPilihan != c.statusPilihan,
                            builder: (context, state) {
                              return SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<String>(
                                  segments: const <ButtonSegment<String>>[
                                    ButtonSegment<String>(
                                        value: 'Masuk',
                                        label: Text('Masuk', style: TextStyle(fontSize: 13))), 
                                    ButtonSegment<String>(
                                        value: 'Keluar',
                                        label: Text('Keluar', style: TextStyle(fontSize: 13))), 
                                  ],
                                  selected: {state.statusPilihan},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    final status = newSelection.first;
                                    context.read<KendaraanBloc>().add(
                                        StatusPilihanChanged(status: status));
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
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _kilometerController,
                            decoration: _buildInputDecoration(
                                label: 'Kilometer Kendaraan',
                                icon: Icons.speed_outlined),
                            keyboardType: TextInputType.number,
                            validator: (value) => AppValidators.validate(
                                value, 'Kilometer Kendaraan'),
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<KendaraanBloc, KendaraanState>(
                            buildWhen: (p, c) => p.sisaBBM != c.sisaBBM,
                            builder: (context, state) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sisa BBM: ${state.sisaBBM.round()}%',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600)),
                                  Slider(
                                      value: state.sisaBBM, 
                                      min: 0,
                                      max: 100,
                                      divisions: 100,
                                      label: '${state.sisaBBM.round()}%',
                                      activeColor: navyColor,
                                      onChanged: (double value) {
                                        context
                                            .read<KendaraanBloc>()
                                            .add(BbmChanged(bbmValue: value));
                                      }),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildImagePickerList(
                      title: 'Foto Kendaraan Luar',
                      files: _fotoLuar,
                      onAddPhoto: () => _pilihSumberGambar(1),
                      onDeletePhoto: (index) => _hapusFoto(1, index),
                      isLoading: _processingSlotIndexes.contains(1),
                    ),
                    const SizedBox(height: 12),
                    _buildImagePickerList(
                      title: 'Foto Kendaraan Dalam',
                      files: _fotoDalam,
                      onAddPhoto: () => _pilihSumberGambar(2),
                      onDeletePhoto: (index) => _hapusFoto(2, index),
                      isLoading: _processingSlotIndexes.contains(2),
                    ),
                    const SizedBox(height: 12),
                    _buildImagePickerList(
                      title: 'Foto Surat-Surat',
                      files: _fotoSurat,
                      onAddPhoto: () => _pilihSumberGambar(3),
                      onDeletePhoto: (index) => _hapusFoto(3, index),
                      isLoading: _processingSlotIndexes.contains(3),
                    ),
                    const SizedBox(height: 12),
                    _buildImagePickerList( // <-- TAMBAHAN WIDGET BARU
                      title: 'Foto Penanggung Jawab',
                      files: _fotoPenanggungJawab,
                      onAddPhoto: () => _pilihSumberGambar(4),
                      onDeletePhoto: (index) => _hapusFoto(4, index),
                      isLoading: _processingSlotIndexes.contains(4),
                    ),
  
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
                    BlocBuilder<KendaraanBloc, KendaraanState>(
                      builder: (context, state) {
                        final isSaving =
                            state.status == KendaraanStatus.submitting;
                        return ElevatedButton(
                          onPressed: isSaving ? null : _simpanData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: navyColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('SIMPAN DATA',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
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

  Widget _buildImagePickerList({
    required String title,
    required List<File> files,
    required VoidCallback onAddPhoto,
    required Function(int) onDeletePhoto,
    required bool isLoading,
  }) {
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
            title,
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
          if (files.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
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
                        onTap: () => onDeletePhoto(index),
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
          if (files.isNotEmpty) const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text('Tambah Foto',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onPressed: isLoading ? null : onAddPhoto,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: const Color(0xFF001f3f),
              side: const BorderSide(color: Color(0xFF001f3f)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildArmadaDropdown() {
    return BlocBuilder<KendaraanBloc, KendaraanState>(
      buildWhen: (p, c) =>
          p.daftarArmada != c.daftarArmada ||
          p.armadaTerpilih != c.armadaTerpilih,
      builder: (context, state) {
        if (state.status == KendaraanStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == KendaraanStatus.failure) {
          return const Center(
              child: Text('Gagal memuat NOPOL',
                  style: TextStyle(color: Colors.red)));
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
              decoration: _buildInputDecoration(
                  label: 'Nomor Polisi Kendaraan', icon: Icons.pin_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Mohon pilih nomor polisi kendaraan.";
                }
                final isValid =
                    state.daftarArmada.any((a) => a.nopol == value);
                if (!isValid) return "Pilih nomor polisi dari daftar.";
                return null;
              },
            );
          },
          suggestionsCallback: (pattern) => state.daftarArmada
              .where(
                  (a) => a.nopol.toLowerCase().contains(pattern.toLowerCase()))
              .toList(),
          itemBuilder: (context, armada) => ListTile(
              title: Text(armada.nopol, style: GoogleFonts.poppins())),
          onSelected: (armada) {
            _armadaController.text = armada.nopol;
            context
                .read<KendaraanBloc>()
                .add(ArmadaChanged(armadaId: armada.id));

            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  Widget _buildKaryawanDropdown() {
    return BlocBuilder<KendaraanBloc, KendaraanState>(
      buildWhen: (p, c) =>
          p.daftarKaryawan != c.daftarKaryawan ||
          p.karyawanTerpilih != c.karyawanTerpilih,
      builder: (context, state) {
        if (state.status == KendaraanStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == KendaraanStatus.failure) {
          return const Center(
              child: Text('Gagal memuat Karyawan',
                  style: TextStyle(color: Colors.red)));
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
              decoration: _buildInputDecoration(
                  label: 'Nama Karyawan', icon: Icons.person_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Mohon pilih nama karyawan.";
                }
                final isValid =
                    state.daftarKaryawan.any((k) => k.nama == value);
                if (!isValid) return "Pilih nama karyawan dari daftar.";
                return null;
              },
            );
          },
          suggestionsCallback: (pattern) => state.daftarKaryawan
              .where((k) =>
                  k.nama.toLowerCase().contains(pattern.toLowerCase()) ||
                  k.alias.toLowerCase().contains(pattern.toLowerCase()))
              .toList(),
          itemBuilder: (context, karyawan) => ListTile(
            title: Text(karyawan.nama, style: GoogleFonts.poppins()),
            subtitle: karyawan.alias.isNotEmpty
                ? Text(karyawan.alias,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600]))
                : null,
          ),
          onSelected: (karyawan) {
            _karyawanController.text = karyawan.nama;
            context
                .read<KendaraanBloc>()
                .add(KaryawanChanged(karyawanId: karyawan.id));

            FocusScope.of(context).unfocus();
          },
        );
      },
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
          borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF001f3f), width: 2)),
    );
  }
}