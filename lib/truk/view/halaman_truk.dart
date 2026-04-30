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
  penanggungJawab,
}

class TruckPage extends StatelessWidget {
  const TruckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TrukBloc(apiService: locator<ApiService>())..add(TrukDataLoaded()),
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

  final _armadaKey = GlobalKey();
  final _sopirKey = GlobalKey();
  final _pengecekanKey = GlobalKey();
  final _kernetKey = GlobalKey();
  final _namaKernetKey = GlobalKey();
  final _stnkKey = GlobalKey();
  final _stnkTanggalKey = GlobalKey();
  final _kirKey = GlobalKey();
  final _kirTanggalKey = GlobalKey();
  final _kirBetKey = GlobalKey();
  final _kirTanggalBetKey = GlobalKey();
  final _noLambungKey = GlobalKey();
  final _kilometerKey = GlobalKey();
  final _kondisiKey = GlobalKey();
  final _keteranganServisKey = GlobalKey();
  final _fotoSIMKey = GlobalKey();
  final _fotoTrukDepanKey = GlobalKey();
  final _fotoTrukSampingKey = GlobalKey();
  final _fotoTrukBelakangKey = GlobalKey();
  final _fotoBanSerepKey = GlobalKey();
  final _fotoSopirSuratKey = GlobalKey();
  final _fotoPenanggungJawabKey = GlobalKey();
  final _armadaController = TextEditingController();
  final _sopirController = TextEditingController();
  final _namaKernetController = TextEditingController();
  final _stnkTanggalController = TextEditingController();
  final _kirTanggalController = TextEditingController();
  final _kirTanggalBetController = TextEditingController();
  final _noLambungController = TextEditingController();
  final _kilometerController = TextEditingController();
  final _keteranganServisController = TextEditingController();
  final _keteranganLainController = TextEditingController();

  String _statusKondisi = '';
  final ImagePicker _picker = ImagePicker();

  List<File> _fotoSIM = [];
  List<File> _fotoTrukDepan = [];
  List<File> _fotoTrukSamping = [];
  List<File> _fotoTrukBelakang = [];
  List<File> _fotoBanSerep = [];
  List<File> _fotoSopirSurat = [];
  List<File> _fotoPenanggungJawab = [];

  final Set<PhotoSlot> _processingSlotIndexes = {};

  String _statusPengecekan = '';
  double _sisaBBM = 50.0;
  String _statusKernet = '';
  bool _showKeteranganLain = false;

  String _statusKIR = '';
  String _statusKIRBet = '';
  String _statusSTNK = '';

  @override
  void dispose() {
    _armadaController.dispose();
    _sopirController.dispose();
    _keteranganServisController.dispose();
    _namaKernetController.dispose();
    _stnkTanggalController.dispose();
    _kirTanggalController.dispose();
    _kirTanggalBetController.dispose();
    _noLambungController.dispose();
    _kilometerController.dispose();
    _keteranganLainController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;

    String userFriendlyMessage;
    Color backgroundColor = Colors.red.shade400;

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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _simpanData() {
    FocusScope.of(context).unfocus();

    bool isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      _showError('Mohon perbaiki field yang berwarna merah.');

      if (_armadaController.text.isEmpty) {
        _scrollTo(_armadaKey);
      } else if (_sopirController.text.isEmpty) {
        _scrollTo(_sopirKey);
      } else if (_statusPengecekan.isEmpty) {
        _scrollTo(_pengecekanKey);
      } else if (_statusKernet.isEmpty) {
        _scrollTo(_kernetKey);
      } else if (_statusKernet == 'Ada' && _namaKernetController.text.isEmpty) {
        _scrollTo(_namaKernetKey);
      } else if (_statusSTNK.isEmpty) {
        _scrollTo(_stnkKey);
      } else if (_statusSTNK != 'Tidak Ada' &&
          _statusSTNK != '' &&
          _stnkTanggalController.text.isEmpty) {
        _scrollTo(_stnkTanggalKey);
      } else if (_statusKIR.isEmpty) {
        _scrollTo(_kirKey);
      } else if (_statusKIR != 'Tidak Ada' &&
          _statusKIR != '' &&
          _kirTanggalController.text.isEmpty) {
        _scrollTo(_kirTanggalKey);
      } else if (_statusKIRBet.isEmpty) {
        _scrollTo(_kirBetKey);
      } else if (_statusKIRBet != 'Tidak Ada' &&
          _statusKIRBet != '' &&
          _kirTanggalBetController.text.isEmpty) {
        _scrollTo(_kirTanggalBetKey);
      } else if (_noLambungController.text.isEmpty) {
        _scrollTo(_noLambungKey);
      } else if (_kilometerController.text.isEmpty) {
        _scrollTo(_kilometerKey);
      } else if (_statusKondisi.isEmpty) {
        _scrollTo(_kondisiKey);
      } else if (_statusKondisi == 'Servis' &&
          _keteranganServisController.text.isEmpty) {
        _scrollTo(_keteranganServisKey);
      }
      return;
    }

    if (_fotoSIM.isEmpty ||
        _fotoTrukDepan.isEmpty ||
        _fotoTrukSamping.isEmpty ||
        _fotoTrukBelakang.isEmpty ||
        _fotoBanSerep.isEmpty ||
        _fotoSopirSurat.isEmpty ||
        _fotoPenanggungJawab.isEmpty) {
      _showError('Mohon tambahkan minimal satu foto untuk semua kategori.');
      if (_fotoSIM.isEmpty) {
        _scrollTo(_fotoSIMKey);
      } else if (_fotoTrukDepan.isEmpty) {
        _scrollTo(_fotoTrukDepanKey);
      } else if (_fotoTrukSamping.isEmpty) {
        _scrollTo(_fotoTrukSampingKey);
      } else if (_fotoTrukBelakang.isEmpty) {
        _scrollTo(_fotoTrukBelakangKey);
      } else if (_fotoBanSerep.isEmpty) {
        _scrollTo(_fotoBanSerepKey);
      } else if (_fotoSopirSurat.isEmpty) {
        _scrollTo(_fotoSopirSuratKey);
      } else if (_fotoPenanggungJawab.isEmpty) {
        _scrollTo(_fotoPenanggungJawabKey);
      }
      return;
    }

    context.read<TrukBloc>().add(
      TrukDataSubmitted(
        namaSopir: _sopirController.text,
        statusPengecekan: _statusPengecekan,
        statusKernet: _statusKernet,
        namaKernet: _statusKernet == 'Ada' ? _namaKernetController.text : null,
        statusSTNK: _statusSTNK,
        stnkTanggal: (_statusSTNK != 'Tidak Ada' && _statusSTNK != '')
            ? _stnkTanggalController.text
            : '',
        statusKIR: _statusKIR,
        statusKIRBet: _statusKIRBet,
        kirTanggal: (_statusKIR != 'Tidak Ada' && _statusKIR != '')
            ? _kirTanggalController.text
            : '',
        kirTanggalBet: (_statusKIRBet != 'Tidak Ada' && _statusKIRBet != '')
            ? _kirTanggalBetController.text
            : '',
        noLambung: _noLambungController.text,
        kilometer: _kilometerController.text,
        bbm: _sisaBBM,
        statusKondisi: _statusKondisi,
        keteranganServis: _statusKondisi == 'Servis'
            ? _keteranganServisController.text
            : null,
        keteranganLain: _showKeteranganLain
            ? _keteranganLainController.text
            : null,
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
                title: Text(
                  'Ambil Foto dari Kamera',
                  style: GoogleFonts.poppins(),
                ),
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
        content: Text(
          'Anda yakin ingin menghapus foto ini?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
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
    BuildContext context,
    TextEditingController controller,
  ) async {
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
              style: TextButton.styleFrom(foregroundColor: primaryColor),
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
              backgroundColor: Colors.green,
            ),
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
          title: Text(
            'Formulir Cek Truk',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: navyColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Informasi Utama',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: navyColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 8),
                        _buildArmadaDropdown(),
                        SizedBox(height: 16),
                        _buildSopirDropdown(),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: _pengecekanKey,
                          value: _statusPengecekan.isEmpty
                              ? null
                              : _statusPengecekan,
                          decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Status Pengecekan '),
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            prefixIcon: Icon(Icons.swap_horiz_outlined),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                          elevation: 4,
                          items: ['Masuk', 'Keluar']
                              .map(
                                (String opsi) => DropdownMenuItem(
                                  value: opsi,
                                  child: Text(opsi),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _statusPengecekan = value;
                              });
                            }
                          },
                          validator: (value) => value == null
                              ? 'Mohon pilih status pengecekan'
                              : null,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: _kernetKey,
                          value: _statusKernet.isEmpty ? null : _statusKernet,
                          decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Status Kernet '),
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                          elevation: 4,
                          items: ['Ada', 'Tidak Ada']
                              .map(
                                (String opsi) => DropdownMenuItem(
                                  value: opsi,
                                  child: Text(opsi),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _statusKernet = value;
                              });
                            }
                          },
                          validator: (value) => value == null
                              ? 'Mohon pilih status kernet'
                              : null,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _statusKernet == 'Ada'
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: TextFormField(
                                    key: _namaKernetKey,
                                    controller: _namaKernetController,
                                    decoration: const InputDecoration(
                                      label: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(text: 'Nama Kernet '),
                                            TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) => _statusKernet == 'Ada'
                                        ? AppValidators.validate(
                                            value,
                                            'Nama Kernet',
                                          )
                                        : null,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: _stnkKey,
                          value: _statusSTNK.isEmpty ? null : _statusSTNK,
                          decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Status STNK '),
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                          elevation: 4,
                          items: ['Ada', 'Foto Copy', 'Mati', 'Tidak Ada']
                              .map(
                                (String opsi) => DropdownMenuItem(
                                  value: opsi,
                                  child: Text(opsi),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _statusSTNK = value;
                                if (value == 'Tidak Ada') {
                                  _stnkTanggalController.clear();
                                }
                              });
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Mohon pilih status STNK' : null,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child:
                              (_statusSTNK != 'Tidak Ada' && _statusSTNK != '')
                              ? Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      key: _stnkTanggalKey,
                                      controller: _stnkTanggalController,
                                      decoration: const InputDecoration(
                                        label: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: 'STNK Tanggal '),
                                              TextSpan(
                                                text: '*',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                      ),
                                      readOnly: true,
                                      onTap: () => _pilihTanggal(
                                        context,
                                        _stnkTanggalController,
                                      ),
                                      validator: (value) {
                                        if (_statusSTNK != 'Tidak Ada' &&
                                            _statusSTNK != '' &&
                                            (value == null || value.isEmpty)) {
                                          return 'STNK Tanggal wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: _kirKey,
                          value: _statusKIR.isEmpty ? null : _statusKIR,
                          decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Status KIR '),
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            prefixIcon: Icon(Icons.verified_outlined),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                          elevation: 4,
                          items: ['Ada', 'Foto Copy', 'Mati', 'Tidak Ada']
                              .map(
                                (String opsi) => DropdownMenuItem(
                                  value: opsi,
                                  child: Text(opsi),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _statusKIR = value;
                                if (value == 'Tidak Ada') {
                                  _kirTanggalController.clear();
                                }
                              });
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Mohon pilih status KIR' : null,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: (_statusKIR != 'Tidak Ada' && _statusKIR != '')
                              ? Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      key: _kirTanggalKey,
                                      controller: _kirTanggalController,
                                      decoration: const InputDecoration(
                                        label: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: 'Tanggal KIR '),
                                              TextSpan(
                                                text: '*',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                      ),
                                      readOnly: true,
                                      onTap: () => _pilihTanggal(
                                        context,
                                        _kirTanggalController,
                                      ),
                                      validator: (value) {
                                        if (_statusKIR != 'Tidak Ada' &&
                                            _statusKIR != '' &&
                                            (value == null || value.isEmpty)) {
                                          return 'Tanggal KIR wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: _kirBetKey,
                          value: _statusKIRBet.isEmpty ? null : _statusKIRBet,
                          decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Status KIR Bet '),
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                          elevation: 4,
                          items: ['Ada', 'Foto Copy', 'Mati', 'Tidak Ada']
                              .map(
                                (String opsi) => DropdownMenuItem(
                                  value: opsi,
                                  child: Text(opsi),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _statusKIRBet = value;
                                if (value == 'Tidak Ada') {
                                  _kirTanggalBetController.clear();
                                }
                              });
                            }
                          },
                          validator: (value) => value == null
                              ? 'Mohon pilih status KIR Bet'
                              : null,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child:
                              (_statusKIRBet != 'Tidak Ada' &&
                                  _statusKIRBet != '')
                              ? Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      key: _kirTanggalBetKey,
                                      controller: _kirTanggalBetController,
                                      decoration: const InputDecoration(
                                        label: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Tanggal KIR Bet ',
                                              ),
                                              TextSpan(
                                                text: '*',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                      ),
                                      readOnly: true,
                                      onTap: () => _pilihTanggal(
                                        context,
                                        _kirTanggalBetController,
                                      ),
                                      validator: (value) {
                                        if (_statusKIRBet != 'Tidak Ada' &&
                                            _statusKIRBet != '' &&
                                            (value == null || value.isEmpty)) {
                                          return 'Tanggal KIR Bet wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      key: _noLambungKey,
                                      controller: _noLambungController,
                                      decoration: const InputDecoration(
                                        label: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: 'No. Lambung '),
                                              TextSpan(
                                                text: '*',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.looks_one_outlined,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_statusKIRBet != 'Tidak Ada' &&
                                            _statusKIRBet != '' &&
                                            (value == null || value.isEmpty)) {
                                          return 'No. Lambung wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          key: _kilometerKey,
                          controller: _kilometerController,
                          decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Kilometer Kendaraan '),
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            prefixIcon: Icon(Icons.speed_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              AppValidators.validate(value, 'KM Masuk'),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: _kondisiKey,
                          value: _statusKondisi.isEmpty ? null : _statusKondisi,
                          decoration: const InputDecoration(
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Status Kondisi '),
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            prefixIcon: Icon(Icons.build_circle_outlined),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_circle_outlined,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                          elevation: 4,
                          items: ['Ready', 'Servis']
                              .map(
                                (String opsi) => DropdownMenuItem(
                                  value: opsi,
                                  child: Text(opsi),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _statusKondisi = value;
                              });
                            }
                          },
                          validator: (value) => value == null
                              ? 'Mohon pilih status kondisi'
                              : null,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _statusKondisi == 'Servis'
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: TextFormField(
                                    key: _keteranganServisKey,
                                    controller: _keteranganServisController,
                                    decoration: const InputDecoration(
                                      label: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Keterangan Servis ',
                                            ),
                                            TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      prefixIcon: Icon(Icons.comment_outlined),
                                    ),
                                    maxLines: 3,
                                    validator: (value) =>
                                        _statusKondisi == 'Servis'
                                        ? AppValidators.validate(
                                            value,
                                            'Keterangan Servis',
                                          )
                                        : null,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: 16),
                        StatefulBuilder(
                          builder:
                              (
                                BuildContext context,
                                StateSetter localSetState,
                              ) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sisa BBM: ${_sisaBBM.round()}%',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    key: _fotoSIMKey,
                    title: 'Foto SIM & Sopir',
                    files: _fotoSIM,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.sim),
                    onDeletePhoto: (index) => _hapusFoto(PhotoSlot.sim, index),
                    isLoading: _processingSlotIndexes.contains(PhotoSlot.sim),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    key: _fotoTrukDepanKey,
                    title: 'Foto Truk Depan',
                    files: _fotoTrukDepan,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.trukDepan),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.trukDepan, index),
                    isLoading: _processingSlotIndexes.contains(
                      PhotoSlot.trukDepan,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    key: _fotoTrukSampingKey,
                    title: 'Foto Truk Samping',
                    files: _fotoTrukSamping,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.trukSamping),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.trukSamping, index),
                    isLoading: _processingSlotIndexes.contains(
                      PhotoSlot.trukSamping,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    key: _fotoTrukBelakangKey,
                    title: 'Foto Truk Belakang',
                    files: _fotoTrukBelakang,
                    onAddPhoto: () =>
                        _pilihSumberGambar(PhotoSlot.trukBelakang),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.trukBelakang, index),
                    isLoading: _processingSlotIndexes.contains(
                      PhotoSlot.trukBelakang,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    key: _fotoBanSerepKey,
                    title: 'Foto Ban Serep',
                    files: _fotoBanSerep,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.banSerep),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.banSerep, index),
                    isLoading: _processingSlotIndexes.contains(
                      PhotoSlot.banSerep,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    key: _fotoSopirSuratKey,
                    title: 'Foto Surat-surat',
                    files: _fotoSopirSurat,
                    onAddPhoto: () => _pilihSumberGambar(PhotoSlot.sopirSurat),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.sopirSurat, index),
                    isLoading: _processingSlotIndexes.contains(
                      PhotoSlot.sopirSurat,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePickerList(
                    key: _fotoPenanggungJawabKey,
                    title: 'Foto Penanggung Jawab',
                    files: _fotoPenanggungJawab,
                    onAddPhoto: () =>
                        _pilihSumberGambar(PhotoSlot.penanggungJawab),
                    onDeletePhoto: (index) =>
                        _hapusFoto(PhotoSlot.penanggungJawab, index),
                    isLoading: _processingSlotIndexes.contains(
                      PhotoSlot.penanggungJawab,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                            'Keterangan Lain-Lain',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF001f3f),
                            ),
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
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _showKeteranganLain
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 12.0,
                                    left: 8.0,
                                    right: 8.0,
                                  ),
                                  child: TextFormField(
                                    controller: _keteranganLainController,
                                    decoration: const InputDecoration(
                                      label: Text('Keterangan Lain-Lain'),
                                      prefixIcon: Icon(Icons.notes_outlined),
                                    ),
                                    maxLines: 4,
                                  ),
                                )
                              : const SizedBox.shrink(),
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
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: navyColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _simpanData,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              backgroundColor: navyColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'SIMPAN DATA',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
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
              key: _armadaKey,
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Nopol Kendaraan '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                prefixIcon: Icon(Icons.pin_outlined),
              ),
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
                (a) => a.nopol.toLowerCase().contains(pattern.toLowerCase()),
              )
              .toList(),
          itemBuilder: (context, armada) =>
              ListTile(title: Text(armada.nopol, style: GoogleFonts.poppins())),
          onSelected: (armada) {
            _armadaController.text = armada.nopol;
            context.read<TrukBloc>().add(
              TrukArmadaChanged(armadaId: armada.id),
            );
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
              key: _sopirKey,
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Nama Sopir '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                prefixIcon: Icon(Icons.person_outline),
              ),
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
              .where(
                (s) =>
                    s.nama.toLowerCase().contains(pattern.toLowerCase()) ||
                    s.alias.toLowerCase().contains(pattern.toLowerCase()),
              )
              .toList(),
          itemBuilder: (context, sopir) => ListTile(
            title: Text(sopir.nama, style: GoogleFonts.poppins()),
            subtitle: Text(
              "NIK: ${sopir.nik}",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
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
    required GlobalKey key,
    required String title,
    required List<File> files,
    required VoidCallback onAddPhoto,
    required Function(int) onDeletePhoto,
    required bool isLoading,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_outlined, color: Color(0xFF001f3f)),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$title '),
                      const TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF001f3f),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bisa tambah lebih dari satu foto.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
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
              itemCount: files.length + (isLoading ? 0 : 1),
              itemBuilder: (context, index) {
                if (index == files.length) {
                  return InkWell(
                    onTap: onAddPhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF001f3f).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF001f3f).withOpacity(0.2),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: const Color(0xFF001f3f).withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }
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
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => onDeletePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (files.isEmpty && !isLoading)
            InkWell(
              onTap: onAddPhoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF001f3f).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF001f3f).withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: const Color(0xFF001f3f).withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambah Foto',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF001f3f).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
}
