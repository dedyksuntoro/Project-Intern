import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/karyawan.dart';
import '../../../models/cabang.dart';
import '../../../models/ob_area.dart';
import '../../../models/ob_tugas.dart';
import '../../../service_locator.dart';
import '../../../services/api_service.dart';
import '../../../utils/validasi.dart';
import '../../../utils/image_processor.dart';
import '../../../widgets/image_detail.dart';
import '../bloc/tugas_ob_bloc.dart';

class TugasObPage extends StatelessWidget {
  const TugasObPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TugasObBloc(
        apiService: locator<ApiService>(),
      )..add(TugasObDataLoaded()), 
      child: const TugasObFormScreen(),
    );
  }
}

class TugasObFormScreen extends StatefulWidget {
  const TugasObFormScreen({super.key});

  @override
  State<TugasObFormScreen> createState() => _TugasObFormScreenState();
}

class _TugasObFormScreenState extends State<TugasObFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final _cabangController = TextEditingController();
  final _areaController = TextEditingController();
  final _karyawanController = TextEditingController();
  final _tugasController = TextEditingController();
  final _jamMulaiController = TextEditingController();
  final _jamSelesaiController = TextEditingController();
  final _keteranganLainController = TextEditingController();

  // --- State Lokal ---
  final List<File> _fotoBukti = [];
  final ImagePicker _picker = ImagePicker();
  bool _showKeteranganLain = false;
  bool _isProcessingImage = false; 

  @override
  void dispose() {
    _cabangController.dispose();
    _areaController.dispose();
    _karyawanController.dispose();
    _tugasController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    _keteranganLainController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    
    String userFriendlyMessage;
    Color backgroundColor = const Color.fromRGBO(244, 67, 54, 1);

    if (message.startsWith('KONEKSI_GAGAL_SIMPAN')) {
      userFriendlyMessage = 'Gagal menyimpan data karena masalah jaringan atau sinyal buruk. Coba lagi.';
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

  Widget _buildCardContainer({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
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

  Future<void> _pilihJam(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF001f3f),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final now = DateTime.now();
      final dt = DateTime(
          now.year, now.month, now.day, picked.hour, picked.minute);
      controller.text = DateFormat('HH:mm').format(dt);
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
      try {
        final File watermarkedFile = await processAndWatermarkImage(pickedFile);
        if (mounted) {
          setState(() {
            _fotoBukti.add(watermarkedFile);
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

  void _hapusFoto(int index) {
    setState(() {
      _fotoBukti.removeAt(index);
    });
  }

  void _simpanData() {
    FocusScope.of(context).unfocus();
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final state = context.read<TugasObBloc>().state;

    if (!isFormValid) {
      _showError('Mohon lengkapi data wajib.');
      return;
    }
    
    if (state.selectedCabang == null ||
        state.selectedArea == null ||
        state.selectedTugas == null ||
        state.selectedKaryawan == null) {
      _showError('Pastikan Cabang, Area, Tugas, dan Karyawan dipilih dari daftar.');
      return;
    }

    if (_fotoBukti.isEmpty) {
      _showError('Mohon unggah minimal satu foto bukti.');
      return;
    }

    context.read<TugasObBloc>().add(
          TugasObSubmitted(
            cabangId: state.selectedCabang!.id,
            areaId: state.selectedArea!.id,
            tugasId: state.selectedTugas!.id,
            karyawanId: int.parse(state.selectedKaryawan!.id),
            jamMulai: _jamMulaiController.text,
            jamSelesai: _jamSelesaiController.text,
            keteranganLain:
                _showKeteranganLain ? _keteranganLainController.text : null,
            fotoBukti: List.from(_fotoBukti),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);

    return BlocListener<TugasObBloc, TugasObState>(
      listener: (context, state) {
        if (state.status == TugasObStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Laporan berhasil disimpan!"), backgroundColor: Colors.green),
          );
          if (mounted) Navigator.of(context).pop();
        } else if (state.status == TugasObStatus.failure) {
          _showError(state.errorMessage ?? "Gagal menyimpan data.");
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text('Laporan Tugas OB',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
          centerTitle: true,
        ),
        body: BlocBuilder<TugasObBloc, TugasObState>(
          builder: (context, state) {
            final isSubmitting = state.status == TugasObStatus.submitting;
            final bool isLoadingMaster = state.status == TugasObStatus.loading;

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detail Pekerjaan',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: navyColor)),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),

                            _buildCabangDropdown(state, isLoadingMaster),
                            const SizedBox(height: 16),

                            _buildAreaDropdown(state, isLoadingMaster),
                            const SizedBox(height: 16),

                            _buildKaryawanDropdown(state, isLoadingMaster),
                            const SizedBox(height: 16),

                            _buildTugasDropdown(state, isLoadingMaster),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _jamMulaiController,
                                    decoration: _buildInputDecoration(label: 'Mulai', icon: Icons.access_time),
                                    readOnly: true,
                                    onTap: () => _pilihJam(_jamMulaiController),
                                    validator: (val) => AppValidators.validate(val, 'Jam Mulai'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _jamSelesaiController,
                                    decoration: _buildInputDecoration(label: 'Selesai', icon: Icons.access_time_filled),
                                    readOnly: true,
                                    onTap: () => _pilihJam(_jamSelesaiController),
                                    validator: (val) => AppValidators.validate(val, 'Jam Selesai'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildImagePickerList(isSubmitting),
                      const SizedBox(height: 20),
                      
                      _buildKeteranganLainSection(),
                      const SizedBox(height: 20),

                      SafeArea(
                        top: false,
                        child: ElevatedButton(
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCabangDropdown(TugasObState state, bool isLoading) {
    return TypeAheadField<Cabang>(
      controller: _cabangController,
      hideOnUnfocus: true, 
      constraints: const BoxConstraints(maxHeight: 300), 
      decorationBuilder: (context, child) => Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
      builder: (context, controller, focusNode) {
        return Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildInputDecoration(label: 'Kantor Cabang', icon: Icons.store),
              validator: (value) {
                if (value == null || value.isEmpty) return "Pilih cabang.";
                if (!state.daftarCabang.any((c) => c.nama == value)) return "Pilih dari daftar.";
                return null;
              },
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        );
      },
      suggestionsCallback: (pattern) => state.daftarCabang
          .where((c) => c.nama.toLowerCase().contains(pattern.toLowerCase()))
          .toList(),
      itemBuilder: (context, cabang) => ListTile(title: Text(cabang.nama, style: GoogleFonts.poppins())),
      onSelected: (cabang) {
        _cabangController.text = cabang.nama;
        _areaController.clear();
        _tugasController.clear();
        context.read<TugasObBloc>().add(TugasObCabangChanged(selectedCabang: cabang));
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _buildAreaDropdown(TugasObState state, bool isLoading) {
    return TypeAheadField<ObArea>(
      key: ValueKey("Area_${state.selectedCabang?.id}"), 
      hideOnUnfocus: true, 
      constraints: const BoxConstraints(maxHeight: 300), 
      hideOnEmpty: false,
      hideOnLoading: false,
      controller: _areaController,
      decorationBuilder: (context, child) => Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
      builder: (context, controller, focusNode) {
        return Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildInputDecoration(label: 'Area Kerja', icon: Icons.map),
              validator: (value) {
                if (value == null || value.isEmpty) return "Pilih area.";
                if (!state.daftarArea.any((a) => a.nama == value)) return "Pilih dari daftar.";
                return null;
              },
              enabled: state.selectedCabang != null,
              onTap: () {
                if (controller.text.isEmpty) controller.text = "";
              }, 
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        );
      },
      suggestionsCallback: (pattern) {
        if (state.selectedCabang == null) return [];
        return state.daftarArea.where((a) {
          final matchCabang = a.cabangId == state.selectedCabang!.id;
          final matchPattern = a.nama.toLowerCase().contains(pattern.toLowerCase());
          return matchCabang && matchPattern;
        }).toList();
      },
      itemBuilder: (context, area) => ListTile(
        title: Text(area.nama, style: GoogleFonts.poppins()),
        subtitle: Text(area.kategori, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
      ),
      onSelected: (area) {
        _areaController.text = area.nama;
        _tugasController.clear(); 
        context.read<TugasObBloc>().add(TugasObAreaChanged(selectedArea: area));
        FocusScope.of(context).unfocus();
      },
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          state.selectedCabang == null ? 'Pilih cabang dulu.' : 'Area tidak ditemukan.', 
          style: GoogleFonts.poppins(color: Colors.grey)
        ),
      ),
    );
  }

  Widget _buildTugasDropdown(TugasObState state, bool isLoading) {
    return TypeAheadField<ObTugas>(
      key: ValueKey("Tugas_${state.selectedArea?.id ?? 'Global'}"),
      hideOnUnfocus: true, 
      constraints: const BoxConstraints(maxHeight: 300), 
      hideOnEmpty: false,
      controller: _tugasController,
      decorationBuilder: (context, child) => Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
      builder: (context, controller, focusNode) {
        return Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildInputDecoration(label: 'Jenis Pekerjaan', icon: Icons.cleaning_services),
              validator: (value) {
                if (value == null || value.isEmpty) return "Pilih pekerjaan.";
                if (!state.daftarTugas.any((t) => t.nama == value)) return "Pilih dari daftar.";
                return null;
              },
              enabled: true, 
              onTap: () {
                if (controller.text.isEmpty) controller.text = "";
              }, 
            ),
             if (isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        );
      },
      suggestionsCallback: (pattern) {
        var filteredList = state.daftarTugas.where((t) => 
            t.nama.toLowerCase().contains(pattern.toLowerCase())
        );
        if (state.selectedArea != null) {
           filteredList = filteredList.where((t) => 
              t.kategoriArea == state.selectedArea!.kategori
           );
        }
        return filteredList.toList();
      },
      itemBuilder: (context, tugas) => ListTile(
        title: Text(tugas.nama, style: GoogleFonts.poppins()),
        subtitle: Text("${tugas.kategoriArea} • ${tugas.periode}", 
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
      ),
      onSelected: (tugas) {
        _tugasController.text = tugas.nama;
        context.read<TugasObBloc>().add(TugasObTugasChanged(selectedTugas: tugas));
        FocusScope.of(context).unfocus();
      },
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          state.selectedArea == null ? 'Pekerjaan tidak ditemukan.' : 'Tidak ada tugas untuk kategori ${state.selectedArea!.kategori}.', 
          style: GoogleFonts.poppins(color: Colors.grey)
        ),
      ),
    );
  }

  Widget _buildKaryawanDropdown(TugasObState state, bool isLoading) {
    return TypeAheadField<Karyawan>(
      controller: _karyawanController,
      hideOnUnfocus: true, 
      constraints: const BoxConstraints(maxHeight: 300), 
      decorationBuilder: (context, child) => Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
      builder: (context, controller, focusNode) {
        return Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _buildInputDecoration(label: 'Nama Pelaksana', icon: Icons.person),
              validator: (value) {
                if (value == null || value.isEmpty) return "Pilih karyawan.";
                if (!state.daftarKaryawan.any((k) => k.nama == value)) return "Pilih dari daftar.";
                return null;
              },
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        );
      },
      suggestionsCallback: (pattern) => state.daftarKaryawan
          .where((k) => k.nama.toLowerCase().contains(pattern.toLowerCase()))
          .toList(),
      itemBuilder: (context, karyawan) => ListTile(title: Text(karyawan.nama, style: GoogleFonts.poppins())),
      onSelected: (karyawan) {
        _karyawanController.text = karyawan.nama;
        context.read<TugasObBloc>().add(TugasObKaryawanChanged(selectedKaryawan: karyawan));
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _buildKeteranganLainSection() {
    const Color navyColor = Color(0xFF001f3f);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text('Tambah Catatan',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: navyColor)),
            value: _showKeteranganLain,
            onChanged: (bool? newValue) {
              setState(() {
                _showKeteranganLain = newValue ?? false;
                if (!_showKeteranganLain) _keteranganLainController.clear();
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: navyColor,
            contentPadding: EdgeInsets.zero,
          ),
          if (_showKeteranganLain)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 8.0, right: 8.0),
              child: TextFormField(
                controller: _keteranganLainController,
                decoration: _buildInputDecoration(label: 'Keterangan', icon: Icons.notes),
                maxLines: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePickerList(bool isSubmitting) {
    const Color navyColor = Color(0xFF001f3f);

    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Foto Bukti',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: navyColor)),
          const SizedBox(height: 4),
          Text('Bisa tambah lebih dari satu foto.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
          
          if (_fotoBukti.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _fotoBukti.length,
              itemBuilder: (context, index) {
                final file = _fotoBukti[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ImageDetailScreen(imageFile: file))),
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
                        onTap: isSubmitting ? null : () => _hapusFoto(index),
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
          if (_fotoBukti.isNotEmpty) const SizedBox(height: 16),
          
          OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text('Tambah Foto', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onPressed: (isSubmitting || _isProcessingImage) ? null : _pilihSumberGambar,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: navyColor,
              side: const BorderSide(color: navyColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}