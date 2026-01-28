import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/widget_riwayat_item.dart';
import '../bloc/tugas_ob_history_bloc.dart';

class HalamanRiwayatTugasOb extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatTugasOb({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TugasObHistoryBloc()..add(TugasObHistoryFetched()),
      child: _HalamanRiwayatTugasObView(
        searchController: searchController,
        selectedDate: selectedDate,
      ),
    );
  }
}

class _HalamanRiwayatTugasObView extends StatefulWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const _HalamanRiwayatTugasObView({
    required this.searchController,
    required this.selectedDate,
  });

  @override
  State<_HalamanRiwayatTugasObView> createState() =>
      _HalamanRiwayatTugasObViewState();
}

class _HalamanRiwayatTugasObViewState
    extends State<_HalamanRiwayatTugasObView> {
  int _displayLimit = 10; // Default limit tampilan
  final int _limitIncrement = 10; // Jumlah penambahan data

  @override
  void initState() {
    super.initState();
    // Tambahkan listener untuk reset limit saat mengetik search
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  //reset limit
  void _onSearchChanged() {
    if (mounted) {
      _resetLimit();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant _HalamanRiwayatTugasObView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset limit jika tanggal filter berubah
    if (widget.selectedDate != oldWidget.selectedDate) {
      _resetLimit();
    }
  }

  void _resetLimit() {
    _displayLimit = 10;
  }

  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  void _showImageGallery(BuildContext context, List<String> imageUrls) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(imageUrls: imageUrls),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: BlocBuilder<TugasObHistoryBloc, TugasObHistoryState>(
        builder: (context, state) {
          if (state.status == TugasObHistoryStatus.loading ||
              state.status == TugasObHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          // ui errror handling
          if (state.status == TugasObHistoryStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal Terhubung',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40.0, vertical: 8.0),
                    child: Text(
                      state.errorMessage ??
                          'Gagal memuat data. Periksa koneksi internet Anda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text('Coba Lagi',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onPressed: () {
                      context
                          .read<TugasObHistoryBloc>()
                          .add(TugasObHistoryFetched());
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          // FILTERING LOGIC
          final filteredList = state.historyList.where((item) {
            final query = widget.searchController.text.toLowerCase();

            final matchesSearch =
                item.namaKaryawan.toLowerCase().contains(query) ||
                    item.namaArea.toLowerCase().contains(query) ||
                    item.namaTugas.toLowerCase().contains(query);

            bool matchesDate = true;
            if (widget.selectedDate != null) {
              matchesDate = _isSameDay(item.createdAt, widget.selectedDate!);
            }
            return matchesSearch && matchesDate;
          }).toList();

          // --- LOGIKA TAMPILAN KOSONG ---
          if (filteredList.isEmpty) {
            bool isSearching = widget.searchController.text.isNotEmpty ||
                widget.selectedDate != null;
            return _buildEmptyList(isSearching);
          }

          // pagination via ui
          final bool hasMore = filteredList.length > _displayLimit;
          final displayedList = filteredList.take(_displayLimit).toList();
          final remainingCount = filteredList.length - displayedList.length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TugasObHistoryBloc>().add(TugasObHistoryFetched());
              _resetLimit(); // Reset limit saat refresh
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              // Tambah 1 jika ada tombol load more
              itemCount: displayedList.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // button load more
                if (index == displayedList.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _displayLimit += _limitIncrement;
                          });
                        },
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: Text(
                          "Tampilkan Lebih Banyak ($remainingCount lagi)",
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.blue[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // RENDER ITEM BIASA
                final item = displayedList[index];

                final tglSubmit =
                    DateFormat('dd MMM yyyy').format(item.createdAt);
                final jamSubmit = DateFormat('HH:mm').format(item.createdAt);
                final jamMulaiKerja = DateFormat('HH:mm').format(item.jamMulai);
                final jamSelesaiKerja =
                    DateFormat('HH:mm').format(item.jamSelesai);

                return WidgetRiwayatItem(
                  judulBaris1: item.namaKaryawan,
                  subJudul: item.namaArea,
                  ikon: Icons.cleaning_services_outlined,
                  warnaIkon: const Color(0xFF001f3f),
                  tanggal: tglSubmit,
                  waktu: jamSubmit,
                  itemKey: 'ob_${item.id}',
                  onLihatLampiran: item.attachment.isNotEmpty
                      ? () => _showImageGallery(context, item.attachment)
                      : null,
                  onHapus: () {
                    showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: const Text('Konfirmasi Hapus'),
                              content:
                                  const Text('Anda yakin ingin menghapus riwayat tugas OB?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal')),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.read<TugasObHistoryBloc>().add(
                                          TugasObHistoryDeleted(id: item.id));
                                    },
                                    child: const Text('Hapus',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ));
                  },
                  detailChildren: [
                    buildDetailRow(
                        icon: Icons.task_alt,
                        title: 'Pekerjaan',
                        value: item.namaTugas),
                    const Divider(color: Colors.white24),
                    buildDetailRow(
                        icon: Icons.timer,
                        title: 'Durasi Kerja',
                        value: '$jamMulaiKerja - $jamSelesaiKerja'),
                    if (item.keterangan != null &&
                        item.keterangan!.isNotEmpty &&
                        item.keterangan != 'null') ...[
                      const Divider(color: Colors.white24),
                      buildDetailRow(
                          icon: Icons.notes,
                          title: 'Keterangan',
                          value: item.keterangan!),
                    ],
                    const Divider(color: Colors.white24),
                    buildDetailRow(
                        icon: Icons.image,
                        title: 'Bukti',
                        value: '${item.countAttachment} Foto'),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // tampilan ksosong/tidak ditemukan
  Widget _buildEmptyList(bool isSearching) {
    String title = isSearching ? 'Tidak Ditemukan' : 'Belum Ada Riwayat';
    String message = isSearching
        ? 'Tidak ada data yang cocok dengan pencarian Anda.'
        : 'Data riwayat tugas kebersihan akan muncul di sini.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSearching ? Icons.search_off : Icons.history_toggle_off,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(message,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }
}

// Reuse ImageGalleryScreen (Disertakan agar file mandiri)
class ImageGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late int currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${currentIndex + 1} dari ${widget.imageUrls.length}',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: false,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 80));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}