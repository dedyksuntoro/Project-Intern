import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/armada.dart';
import '../../models/sopir.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';
import '../../utils/validasi.dart';
import '../../utils/image_processor.dart';
import '../../widgets/image_detail.dart';
import '../bloc/truk_bloc.dart';

enum PhotoSlot {
  sim,
  trukDepan,
  trukSamping,
  trukBelakang,
  banSerep,
  sopirSurat,
  penanggungJawab
}

class TruckPage extends StatelessWidget {
  const TruckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrukBloc(
        apiService: locator<ApiService>(),
      )..add(TrukDataLoaded()),
      child: const TruckCheckScreen(),
    );
  }
}

class TruckCheckScreen extends StatefulWidget {
  const TruckCheckScreen({super.key});

  @override
  State<TruckCheckScreen> createState() => _TruckCheckScreenState();
}

class _TruckCheckScreenState extends State<TruckCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _armadaController = TextEditingController();
  final _sopirController = TextEditingController();
  final _namaKernetController = TextEditingController();
  final _stnkTanggalController = TextEditingController();
  final _kirTanggalController = TextEditingController();
  final _kirBetController = TextEditingController();
  final _noLambungController = TextEditingController();
  final _kilometerController = TextEditingController();
  final _keteranganServisController = TextEditingController();
  final _keteranganLainController = TextEditingController();

  Set<String> _statusKondisi = {'Ready'};
  final ImagePicker _picker = ImagePicker();

  List<File> _fotoSIM = [];
  List<File> _fotoTrukDepan = [];
  List<File> _fotoTrukSamping = [];
  List<File> _fotoTrukBelakang = [];
  List<File> _fotoBanSerep = [];
  List<File> _fotoSopirSurat = [];
  List<File> _fotoPenanggungJawab = [];

  final Set<PhotoSlot> _processingSlotIndexes = {};

  String _statusPengecekan = 'Masuk';
  double _sisaBBM = 50.0;
  String _statusKernet = 'Tidak Ada';
  bool _showKeteranganLain = false;

  String _statusKIR = 'Ada';
  String _statusSTNK = 'Ada';

  @override
  void dispose() {
    _armadaController.dispose();
    _sopirController.dispose();
    _keteranganServisController.dispose();
    _namaKernetController.dispose();
    _stnkTanggalController.dispose();
    _kirTanggalController.dispose();
    _kirBetController.dispose();
    _noLambungController.dispose();
    _kilometerController.dispose();
    _keteranganLainController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;

    String userFriendlyMessage;
    Color backgroundColor = Colors.red;

    if (message.startsWith('KONEKSI_GAGAL:')) {
      userFriendlyMessage = 'Gagal memuat data! Periksa koneksi internet Anda.';
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    } else if (message.startsWith('KONEKSI_GAGAL_SIMPAN:')) {
      userFriendlyMessage =
          'Gagal menyimpan data karena masalah jaringan atau sinyal buruk. Coba lagi.';
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    } else {
      userFriendlyMessage = message;
      backgroundColor = const Color.fromRGBO(244, 67, 54, 1);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(userFriendlyMessage),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4)),
    );
  }

  void _simpanData() {
    FocusScope.of(context).unfocus();

    if (_armadaController.text.isEmpty ||
        _sopirController.text.isEmpty ||
        _noLambungController.text.isEmpty ||
        _kilometerController.text.isEmpty) {
      _showError('Mohon lengkapi data Armada, Sopir, No Lambung, dan KM.');
      return;
    }

    if (_statusKernet == 'Ada' && _namaKernetController.text.isEmpty) {
      _showError('Nama Kernet wajib diisi jika status Kernet Ada.');
      return;
    }

    if (_statusSTNK != 'Tidak Ada' && _stnkTanggalController.text.isEmpty) {
      _showError('Mohon isi Tanggal STNK jika statusnya Ada/Mati.');
      return;
    }

    if (_statusKIR != 'Tidak Ada' &&
        (_kirTanggalController.text.isEmpty ||
            _kirBetController.text.isEmpty)) {
      _showError(
          'Mohon lengkapi Tanggal KIR dan KIR BET jika status KIR Ada/Mati.');
      return;
    }

    if (_fotoSIM.isEmpty ||
        _fotoTrukDepan.isEmpty ||
        _fotoTrukSamping.isEmpty ||
        _fotoTrukBelakang.isEmpty ||
        _fotoBanSerep.isEmpty ||
        _fotoSopirSurat.isEmpty ||
        _fotoPenanggungJawab.isEmpty) {
      _showError(
          'Mohon unggah minimal satu foto untuk semua kategori (termasuk Penanggung Jawab).');
      return;
    }

    context.read<TrukBloc>().add(
          TrukDataSubmitted(
            namaSopir: _sopirController.text,
            statusPengecekan: _statusPengecekan,
            statusKernet: _statusKernet,
            namaKernet:
                _statusKernet == 'Ada' ? _namaKernetController.text : null,
            statusSTNK: _statusSTNK,
            stnkTanggal:
                _statusSTNK != 'Tidak Ada' ? _stnkTanggalController.text : '',
            statusKIR: _statusKIR,
            kirTanggal:
                _statusKIR != 'Tidak Ada' ? _kirTanggalController.text : '',
            kirBet: _statusKIR != 'Tidak Ada' ? _kirBetController.text : '',
            noLambung: _noLambungController.text,
            kilometer: _kilometerController.text,
            bbm: _sisaBBM,
            statusKondisi: _statusKondisi.first,
            keteranganServis: _statusKondisi.contains('Servis')
                ? _keteranganServisController.text
                : null,
            keteranganLain:
                _showKeteranganLain ? _keteranganLainController.text : null,
            attachments: [
              ..._fotoSIM,
              ..._fotoTrukDepan,
              ..._fotoTrukSamping,
              ..._fotoTrukBelakang,
              ..._fotoBanSerep,
              ..._fotoSopirSurat,
              ..._fotoPenanggungJawab,
            ],
          ),
        );
  }

  Future<void> _pilihSumberGambar(PhotoSlot slot) async {
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
                  _ambilDanProsesGambar(ImageSource.gallery, slot);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text('Ambil Foto dari Kamera',
                    style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  _ambilDanProsesGambar(ImageSource.camera, slot);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _ambilDanProsesGambar(ImageSource source, PhotoSlot slot) async {
    List<XFile> pickedFiles = [];
    if (source == ImageSource.gallery) {
      pickedFiles = await _picker.pickMultiImage();
    } else {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) pickedFiles.add(pickedFile);
    }

    if (pickedFiles.isEmpty || !mounted) return;

    setState(() => _processingSlotIndexes.add(slot));

    for (final pickedFile in pickedFiles) {
      File? sourceFileCopy;
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String safePath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        sourceFileCopy = await File(pickedFile.path).copy(safePath);

        final XFile safeXFile = XFile(sourceFileCopy.path);
        final File watermarkedFile = await processAndWatermarkImage(safeXFile);

        if (mounted) {
          setState(() {
            switch (slot) {
              case PhotoSlot.sim:
                _fotoSIM.add(watermarkedFile);
                break;
              case PhotoSlot.trukDepan:
                _fotoTrukDepan.add(watermarkedFile);
                break;
              case PhotoSlot.trukSamping:
                _fotoTrukSamping.add(watermarkedFile);
                break;
              case PhotoSlot.trukBelakang:
                _fotoTrukBelakang.add(watermarkedFile);
                break;
              case PhotoSlot.banSerep:
                _fotoBanSerep.add(watermarkedFile);
                break;
              case PhotoSlot.sopirSurat:
                _fotoSopirSurat.add(watermarkedFile);
                break;
              case PhotoSlot.penanggungJawab:
                _fotoPenanggungJawab.add(watermarkedFile);
                break;
            }
          });
        }
      } catch (e) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      } finally {
        if (sourceFileCopy != null && await sourceFileCopy.exists()) {
          await sourceFileCopy.delete();
        }
      }
    }

    if (mounted) setState(() => _processingSlotIndexes.remove(slot));
  }

  Future<void> _hapusFoto(PhotoSlot slot, int fileIndex) async {
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

    File fileToDelete;
    switch (slot) {
      case PhotoSlot.sim:
        fileToDelete = _fotoSIM.removeAt(fileIndex);
        break;
      case PhotoSlot.trukDepan:
        fileToDelete = _fotoTrukDepan.removeAt(fileIndex);
        break;
      case PhotoSlot.trukSamping:
        fileToDelete = _fotoTrukSamping.removeAt(fileIndex);
        break;
      case PhotoSlot.trukBelakang:
        fileToDelete = _fotoTrukBelakang.removeAt(fileIndex);
        break;
      case PhotoSlot.banSerep:
        fileToDelete = _fotoBanSerep.removeAt(fileIndex);
        break;
      case PhotoSlot.sopirSurat:
        fileToDelete = _fotoSopirSurat.removeAt(fileIndex);
        break;
      case PhotoSlot.penanggungJawab:
        fileToDelete = _fotoPenanggungJawab.removeAt(fileIndex);
        break;
    }

    setState(() {});

    try {
      if (await fileToDelete.exists()) await fileToDelete.delete();
    } catch (_) {}
  }

  Future<void> _pilihTanggal(
      BuildContext context, TextEditingController controller) async {
    const Color primaryColor = Color(0xFF0D47A1);
    const Color headerColor = Color(0xFF1976D2);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              headerBackgroundColor: headerColor,
              headerForegroundColor: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formattedDate = DateFormat('dd-MM-yyyy').format(picked);
      setState(() {
        controller.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);

    return BlocListener<TrukBloc, TrukState>(
      listener: (context, state) {
        if (state.status == TrukStatus.submissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Data berhasil disimpan!"),
                backgroundColor: Colors.green),
          );
          if (mounted) Navigator.of(context).pop();
        }
        if (state.status == TrukStatus.submissionFailure ||
            state.status == TrukStatus.failure) {
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
          title: Text('Formulir Cek Truk',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi Utama',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: navyColor)),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildArmadaDropdown(),
                        const SizedBox(height: 16),
                        _buildSopirDropdown(),
                        const SizedBox(height: 24),
                        Text('Status Pengecekan',
                            style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                  value: 'Masuk',
                                  label: Text('Masuk',
                                      style: TextStyle(fontSize: 13))),
                              ButtonSegment<String>(
                                  value: 'Keluar',
                                  label: Text('Keluar',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            selected: {_statusPengecekan},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _statusPengecekan = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  MaterialStateProperty.all(EdgeInsets.zero),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return navyColor;
                                  }
                                  return Colors.grey[200]!;
                                },
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.white;
                                  }
                                  return navyColor;
                                },
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Status Kernet',
                            style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                  value: 'Ada',
                                  label: Text('Ada',
                                      style: TextStyle(fontSize: 13))),
                              ButtonSegment<String>(
                                  value: 'Tidak Ada',
                                  label: Text('Tidak Ada',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            selected: {_statusKernet},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _statusKernet = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  MaterialStateProperty.all(EdgeInsets.zero),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return navyColor;
                                  }
                                  return Colors.grey[200]!;
                                },
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.white;
                                  }
                                  return navyColor;
                                },
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        if (_statusKernet == 'Ada')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextFormField(
                              controller: _namaKernetController,
                              decoration: _buildInputDecoration(
                                  label: 'Nama Kernet',
                                  icon: Icons.person_outline),
                              validator: (value) => _statusKernet == 'Ada'
                                  ? AppValidators.validate(value, 'Nama Kernet')
                                  : null,
                            ),
                          ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text('Status KIR',
                            style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                  value: 'Ada',
                                  label: Text('Ada',
                                      style: TextStyle(fontSize: 13))),
                              ButtonSegment<String>(
                                  value: 'Mati',
                                  label: Text('Mati',
                                      style: TextStyle(fontSize: 13))),
                              ButtonSegment<String>(
                                  value: 'Tidak Ada',
                                  label: Text('Tidak Ada',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            selected: {_statusKIR},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _statusKIR = newSelection.first;
                                if (_statusKIR == 'Tidak Ada') {
                                  _kirTanggalController.clear();
                                  _kirBetController.clear();
                                }
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  MaterialStateProperty.all(EdgeInsets.zero),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return navyColor;
                                  }
                                  return Colors.grey[200]!;
                                },
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.white;
                                  }
                                  return navyColor;
                                },
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        if (_statusKIR != 'Tidak Ada') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _kirTanggalController,
                            decoration: _buildInputDecoration(
                                label: 'KIR Tanggal',
                                icon: Icons.calendar_today_outlined),
                            readOnly: true,
                            onTap: () =>
                                _pilihTanggal(context, _kirTanggalController),
                            validator: (value) {
                              if (_statusKIR != 'Tidak Ada' &&
                                  (value == null || value.isEmpty)) {
                                return 'KIR Tanggal wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _kirBetController,
                            decoration: _buildInputDecoration(
                                label: 'KIR BET',
                                icon: Icons.confirmation_number_outlined),
                            validator: (value) {
                              if (_statusKIR != 'Tidak Ada' &&
                                  (value == null || value.isEmpty)) {
                                return 'KIR BET wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text('Status STNK',
                            style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                  value: 'Ada',
                                  label: Text('Ada',
                                      style: TextStyle(fontSize: 13))),
                              ButtonSegment<String>(
                                  value: 'Mati',
                                  label: Text('Mati',
                                      style: TextStyle(fontSize: 13))),
                              ButtonSegment<String>(
                                  value: 'Tidak Ada',
                                  label: Text('Tidak Ada',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            selected: {_statusSTNK},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _statusSTNK = newSelection.first;
                                if (_statusSTNK == 'Tidak Ada') {
                                  _stnkTanggalController.clear();
                                }
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  MaterialStateProperty.all(EdgeInsets.zero),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return navyColor;
                                  }
                                  return Colors.grey[200]!;
                                },
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.white;
                                  }
                                  return navyColor;
                                },
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        if (_statusSTNK != 'Tidak Ada') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _stnkTanggalController,
                            decoration: _buildInputDecoration(
                                label: 'STNK Tanggal',
                                icon: Icons.calendar_today_outlined),
                            readOnly: true,
                            onTap: () =>
                                _pilihTanggal(context, _stnkTanggalController),
                            validator: (value) {
                              if (_statusSTNK != 'Tidak Ada' &&
                                  (value == null || value.isEmpty)) {
                                return 'STNK Tanggal wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noLambungController,
                          decoration: _buildInputDecoration(
                              label: 'No. Lambung',
                              icon: Icons.looks_one_outlined),
                          validator: (value) =>
                              AppValidators.validate(value, 'No. Lambung'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _kilometerController,
                          decoration: _buildInputDecoration(
                              label: 'Kilometer Kendaraan',
                              icon: Icons.speed_outlined),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              AppValidators.validate(value, 'KM Masuk'),
                        ),
                        const SizedBox(height: 16),
                        StatefulBuilder(
                          builder: (BuildContext context,
                              StateSetter localSetState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sisa BBM: ${_sisaBBM.round()}%',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600)),
                                Slider(
                                  value: _sisaBBM,
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  label: '${_sisaBBM.round()}%',
                                  activeColor: navyColor,
                                  onChanged: (double value) {
                                    localSetState(() {
                                      _sisaBBM = value;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text('Status Kondisi',
                            style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                  value: 'Ready',
                                  label: Text('Ready',
                                      style: TextStyle(fontSize: 13))),
                              ButtonSegment<String>(
                                  value: 'Servis',
                                  label: Text('Servis',
                                      style: TextStyle(fontSize: 13))),
                            ],
                            selected: _statusKondisi,
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _statusKondisi = newSelection;
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  MaterialStateProperty.all(EdgeInsets.zero),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return navyColor;
                                  }
                                  return Colors.grey[200]!;
                                },
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.white;
                                  }
                                  return navyColor;
                                },
                              ),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        if (_statusKondisi.contains('Servis'))
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextFormField(
                              controller: _keteranganServisController,
                              decoration: _buildInputDecoration(
                                  label: 'Keterangan Servis',
                                  icon: Icons.comment_outlined),
                              maxLines: 3,
                              validator: (value) =>
                                  _statusKondisi.contains('Servis')
                                      ? AppValidators.validate(
                                          value, 'Keterangan Servis')
                                      : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildImagePickerList(
                    title: 'Upload Foto SIM & Sopir',
                    files: _fotoSIM,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.sim),
                    onDeletePhoto: (index) => _hapusFoto(PhotoSlot.sim, index),
                    isLoading: _processingSlotIndexes.contains(PhotoSlot.sim),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    title: 'Upload Foto Truk Depan',
                    files: _fotoTrukDepan,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.trukDepan),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.trukDepan, index),
                    isLoading:
                        _processingSlotIndexes.contains(PhotoSlot.trukDepan),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    title: 'Upload Foto Truk Samping',
                    files: _fotoTrukSamping,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.trukSamping),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.trukSamping, index),
                    isLoading:
                        _processingSlotIndexes.contains(PhotoSlot.trukSamping),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    title: 'Upload Foto Truk Belakang',
                    files: _fotoTrukBelakang,
                    onAddPhoto: () =>
                        _pilihSumberGambar(PhotoSlot.trukBelakang),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.trukBelakang, index),
                    isLoading:
                        _processingSlotIndexes.contains(PhotoSlot.trukBelakang),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    title: 'Upload Foto Ban Serep',
                    files: _fotoBanSerep,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.banSerep),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.banSerep, index),
                    isLoading:
                        _processingSlotIndexes.contains(PhotoSlot.banSerep),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    title: 'Upload foto Surat-surat',
                    files: _fotoSopirSurat,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.sopirSurat),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.sopirSurat, index),
                    isLoading:
                        _processingSlotIndexes.contains(PhotoSlot.sopirSurat),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    title: 'Upload Foto Penanggung Jawab',
                    files: _fotoPenanggungJawab,
                    onAddPhoto: () =>
                        _pilihSumberGambar(PhotoSlot.penanggungJawab),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.penanggungJawab, index),
                    isLoading: _processingSlotIndexes
                        .contains(PhotoSlot.penanggungJawab),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 30),
                  SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: BlocBuilder<TrukBloc, TrukState>(
                      builder: (context, state) {
                        final isSubmitting =
                            state.status == TrukStatus.submitting;
                        return ElevatedButton(
                          onPressed: isSubmitting ? null : _simpanData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: navyColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3, color: Colors.white),
                                )
                              : Text('SIMPAN DATA',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArmadaDropdown() {
    return BlocBuilder<TrukBloc, TrukState>(
      buildWhen: (p, c) => p.daftarArmada != c.daftarArmada,
      builder: (context, state) {
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
                if (value == null || value.isEmpty) return "Mohon pilih NOPOL.";
                final isValid = state.daftarArmada.any((a) => a.nopol == value);
                if (!isValid) return "Pilih NOPOL dari daftar.";
                return null;
              },
            );
          },
          suggestionsCallback: (pattern) => state.daftarArmada
              .where(
                  (a) => a.nopol.toLowerCase().contains(pattern.toLowerCase()))
              .toList(),
          itemBuilder: (context, armada) =>
              ListTile(title: Text(armada.nopol, style: GoogleFonts.poppins())),
          onSelected: (armada) {
            _armadaController.text = armada.nopol;
            context
                .read<TrukBloc>()
                .add(TrukArmadaChanged(armadaId: armada.id));
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  Widget _buildSopirDropdown() {
    return BlocBuilder<TrukBloc, TrukState>(
      buildWhen: (p, c) => p.daftarSopir != c.daftarSopir,
      builder: (context, state) {
        return TypeAheadField<Sopir>(
          controller: _sopirController,
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
                  label: 'Nama Sopir', icon: Icons.person_outline),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Mohon pilih nama sopir.";
                }
                final isValid = state.daftarSopir.any((s) => s.nama == value);
                if (!isValid) return "Pilih nama sopir dari daftar.";
                return null;
              },
            );
          },
          suggestionsCallback: (pattern) => state.daftarSopir
              .where((s) =>
                  s.nama.toLowerCase().contains(pattern.toLowerCase()) ||
                  s.alias.toLowerCase().contains(pattern.toLowerCase()))
              .toList(),
          itemBuilder: (context, sopir) => ListTile(
            title: Text(sopir.nama, style: GoogleFonts.poppins()),
            subtitle: Text("NIK: ${sopir.nik}",
                style: GoogleFonts.poppins(fontSize: 12)),
          ),
          onSelected: (sopir) {
            _sopirController.text = sopir.nama;
            context.read<TrukBloc>().add(TrukSopirChanged(sopirId: sopir.id));
            FocusScope.of(context).unfocus();
          },
        );
      },
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