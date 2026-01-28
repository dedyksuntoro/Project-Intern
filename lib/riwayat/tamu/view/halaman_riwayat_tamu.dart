import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/tamu_history.dart';
import '../../../widgets/widget_riwayat_item.dart';
import '../bloc/tamu_history_bloc.dart';

class HalamanRiwayatTamu extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatTamu({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TamuHistoryBloc()..add(TamuHistoryFetched()),
      child: HalamanRiwayatTamuView(
        searchController: searchController,
        selectedDate: selectedDate,
      ),
    );
  }
}

class HalamanRiwayatTamuView extends StatefulWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatTamuView({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  State<HalamanRiwayatTamuView> createState() => _HalamanRiwayatTamuViewState();
}

class _HalamanRiwayatTamuViewState extends State<HalamanRiwayatTamuView> {
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
  void didUpdateWidget(covariant HalamanRiwayatTamuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _resetLimit();
    }
  }

  void _resetLimit() {
    _displayLimit = 10;
  }

  void _showImageGallery(
      BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
            imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }

  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: BlocBuilder<TamuHistoryBloc, TamuHistoryState>(
        builder: (context, state) {
          if (state.status == TamuHistoryStatus.loading ||
              state.status == TamuHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TamuHistoryStatus.failure) {
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
                      state.errorMessage ?? 'Terjadi kesalahan koneksi.',
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
                      context.read<TamuHistoryBloc>().add(TamuHistoryFetched());
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

          final filteredListBySearch = state.tamuHistoryList.where((item) {
            final query = widget.searchController.text.toLowerCase();
            return item.nama.toLowerCase().contains(query) ||
                item.instansi.toLowerCase().contains(query);
          }).toList();

          final List<TamuHistory> filteredList;
          if (widget.selectedDate != null) {
            filteredList = filteredListBySearch.where((item) {
              return _isSameDay(item.createdAt, widget.selectedDate!);
            }).toList();
          } else {
            filteredList = filteredListBySearch;
          }

          if (filteredList.isEmpty) {
            bool isSearching = widget.searchController.text.isNotEmpty ||
                widget.selectedDate != null;
            return _buildEmptyList(isSearching);
          }

          final bool hasMore = filteredList.length > _displayLimit;
          final displayedList = filteredList.take(_displayLimit).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TamuHistoryBloc>().add(TamuHistoryFetched());
              _resetLimit();
            },
            child: _buildHistoryList(
              displayedList,
              hasMore: hasMore,
              remainingCount: filteredList.length - displayedList.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(
    List<TamuHistory> historyItems, {
    required bool hasMore,
    required int remainingCount,
  }) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: historyItems.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == historyItems.length) {
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          );
        }

        final item = historyItems[index];

        return WidgetRiwayatItem(
          judulBaris1: item.nama,
          subJudul: item.instansi,
          ikon: Icons.person_outline,
          warnaIkon: Colors.deepPurpleAccent,
          waktu: DateFormat('HH:mm').format(item.createdAt),
          tanggal: DateFormat('dd MMM yyyy').format(item.createdAt),
          itemKey: 'tamu_${item.id}',
          onLihatLampiran: item.attachment.isNotEmpty
              ? () => _showImageGallery(context, item.attachment, 0)
              : null,
          onHapus: () {
            showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Konfirmasi Hapus', style: GoogleFonts.poppins()),
                content: Text('Anda yakin ingin menghapus riwayat tamu ini?',
                    style: GoogleFonts.poppins()),
                actions: [
                  TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.of(ctx).pop(false)),
                  TextButton(
                      child: const Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.of(ctx).pop(true)),
                ],
              ),
            ).then((confirmed) {
              if (confirmed == true) {
                context
                    .read<TamuHistoryBloc>()
                    .add(TamuHistoryDeleted(id: item.id));
              }
            });
          },
          detailChildren: [
            buildDetailRow(
                icon: Icons.support_agent_outlined,
                title: 'Menemui',
                value: item.menemui),
            const Divider(color: Colors.white24),
            buildDetailRow(
                icon: Icons.comment_outlined,
                title: 'Keperluan',
                value: item.keperluan),
            const Divider(color: Colors.white24),
            buildDetailRow(
                icon: Icons.attachment,
                title: 'Lampiran',
                value: '${item.countAttachment} file'),
          ],
        );
      },
    );
  }

  Widget _buildEmptyList(bool isSearching) {
    String title = isSearching ? 'Tidak Ditemukan' : 'Belum Ada Riwayat';
    String message = isSearching
        ? 'Tidak ada data yang cocok dengan pencarian Anda.'
        : 'Data riwayat tamu akan muncul di sini.';

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