import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/widget_riwayat_item.dart';
import '../bloc/tugas_umum_history_bloc.dart';

class HalamanRiwayatTugasUmum extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatTugasUmum({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TugasUmumHistoryBloc()..add(TugasUmumHistoryFetched()),
      child: _HalamanRiwayatTugasUmumView(
        searchController: searchController,
        selectedDate: selectedDate,
      ),
    );
  }
}

class _HalamanRiwayatTugasUmumView extends StatefulWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const _HalamanRiwayatTugasUmumView({
    required this.searchController,
    required this.selectedDate,
  });

  @override
  State<_HalamanRiwayatTugasUmumView> createState() =>
      _HalamanRiwayatTugasUmumViewState();
}

class _HalamanRiwayatTugasUmumViewState
    extends State<_HalamanRiwayatTugasUmumView> {
  int _displayLimit = 10;
  final int _limitIncrement = 10;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      _resetLimit();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant _HalamanRiwayatTugasUmumView oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      child: BlocListener<TugasUmumHistoryBloc, TugasUmumHistoryState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: BlocBuilder<TugasUmumHistoryBloc, TugasUmumHistoryState>(
          builder: (context, state) {
            if (state.status == TugasUmumHistoryStatus.loading ||
                state.status == TugasUmumHistoryStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == TugasUmumHistoryStatus.failure) {
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
                            .read<TugasUmumHistoryBloc>()
                            .add(TugasUmumHistoryFetched());
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

            // --- FILTERING LIST ---
            final filteredList = state.historyList.where((item) {
              final query = widget.searchController.text.toLowerCase();
              final matchesSearch =
                  item.namaKaryawan.toLowerCase().contains(query) ||
                      item.keperluan.toLowerCase().contains(query) ||
                      (item.nopol ?? '').toLowerCase().contains(query);

              bool matchesDate = true;
              if (widget.selectedDate != null) {
                matchesDate = _isSameDay(item.createdAt, widget.selectedDate!);
              }
              return matchesSearch && matchesDate;
            }).toList();

            filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (filteredList.isEmpty) {
              bool isSearching = widget.searchController.text.isNotEmpty ||
                  widget.selectedDate != null;
              return _buildEmptyList(isSearching);
            }

            // --- PAGINATION LOGIC ---
            final bool hasMore = filteredList.length > _displayLimit;
            final displayedList = filteredList.take(_displayLimit).toList();
            final remainingCount = filteredList.length - displayedList.length;

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TugasUmumHistoryBloc>()
                    .add(TugasUmumHistoryFetched());
                _resetLimit();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: displayedList.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
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
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
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

                  final item = displayedList[index];
                  final jamSubmit = DateFormat('HH:mm').format(item.createdAt);
                  final tglSubmit =
                      DateFormat('dd MMM yyyy').format(item.createdAt);

                  String displayJamBerangkat = item.jamBerangkat;
                  try {
                    final parsedDate = DateTime.parse(item.jamBerangkat);
                    displayJamBerangkat =
                        DateFormat('HH:mm').format(parsedDate);
                  } catch (_) {}

                  bool isSelesai = false;
                  String displayJamSelesai = '-';

                  if (item.jamSelesai != null && item.jamSelesai!.isNotEmpty) {
                    isSelesai = true;
                    try {
                      final parsedSelesai = DateTime.parse(item.jamSelesai!);
                      displayJamSelesai =
                          DateFormat('HH:mm').format(parsedSelesai);
                    } catch (_) {
                      displayJamSelesai = item.jamSelesai!;
                    }
                  }

                  final isPribadi = item.statusKendaraan == 'PRIBADI';
                  String subJudulText =
                      isPribadi ? "Kendaraan Pribadi" : (item.nopol ?? '-');

                  return WidgetRiwayatItem(
                    judulBaris1: item.namaKaryawan,
                    subJudul: subJudulText,
                    ikon: Icons.assignment_ind,
                    warnaIkon: const Color(0xFF0D47A1),
                    waktu: jamSubmit,
                    tanggal: tglSubmit,
                    itemKey: 'tumum_${item.id}',
                    onLihatLampiran: item.attachment.isNotEmpty
                        ? () => _showImageGallery(context, item.attachment)
                        : null,
                    onHapus: () {
                      showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: const Text(
                                    'Anda yakin ingin menghapus riwyat tugas umum ini?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Batal')),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        context
                                            .read<TugasUmumHistoryBloc>()
                                            .add(TugasUmumHistoryDeleted(
                                                id: item.id));
                                      },
                                      child: const Text('Hapus',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ));
                    },
                    detailChildren: [
                      buildDetailRow(
                          icon: Icons.description_outlined,
                          title: 'Keperluan',
                          value: item.keperluan),
                      const Divider(color: Colors.white24),
                      buildDetailRow(
                          icon: Icons.access_time_filled,
                          title: 'Jam Berangkat',
                          value: displayJamBerangkat),
                      const Divider(color: Colors.white24),
                      if (isSelesai)
                        buildDetailRow(
                            icon: Icons.check_circle_outline,
                            title: 'Jam Selesai',
                            value: displayJamSelesai)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .read<TugasUmumHistoryBloc>()
                                    .add(TugasUmumHistorySelesai(item: item));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 20),
                              label: Text(
                                'Tandai Selesai',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
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
      ),
    );
  }

  Widget _buildEmptyList(bool isSearching) {
    String title = isSearching ? 'Tidak Ditemukan' : 'Belum Ada Riwayat';
    String message = isSearching
        ? 'Tidak ada data yang cocok dengan pencarian Anda.'
        : 'Data riwayat tugas umum akan muncul di sini.';

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