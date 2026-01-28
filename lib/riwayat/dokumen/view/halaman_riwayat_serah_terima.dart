// File: lib/riwayat/dokumen/view/halaman_riwayat_serah_terima.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/serah_terima_history.dart'; 
import '../../../widgets/widget_riwayat_item.dart'; 
import '../bloc/serah_terima_history_bloc.dart'; 

// --- IMPOR DIBUTUHKAN UNTUK MENGAMBIL TOKEN ---
import '../../../services/api_service.dart'; 
import '../../../service_locator.dart'; 
// --- AKHIR IMPOR ---

class HalamanRiwayatSerahTerima extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatSerahTerima({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SerahTerimaHistoryBloc()..add(SerahTerimaHistoryFetched()),
      child: HalamanRiwayatSerahTerimaView(
        searchController: searchController,
        selectedDate: selectedDate,
      ),
    );
  }
}

class HalamanRiwayatSerahTerimaView extends StatefulWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatSerahTerimaView({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  State<HalamanRiwayatSerahTerimaView> createState() => _HalamanRiwayatSerahTerimaViewState();
}

class _HalamanRiwayatSerahTerimaViewState extends State<HalamanRiwayatSerahTerimaView> {
  int _displayLimit = 10; // Default limit tampilan
  final int _limitIncrement = 10; // Jumlah penambahan data

  @override
  void initState() {
    super.initState();
    // Listener untuk reset limit saat mengetik search
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }
  
  // reset limit
  void _onSearchChanged() {
    if (mounted) {
      _resetLimit();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant HalamanRiwayatSerahTerimaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset limit jika tanggal filter berubah
    if (widget.selectedDate != oldWidget.selectedDate) {
      _resetLimit();
    }
  }

  void _resetLimit() {
    _displayLimit = 10;
  }

  void _showImageGallery(BuildContext context, List<String> imageUrls) async {
    final apiService = locator<ApiService>();
    final token = await apiService.getToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi berakhir. Silakan login ulang.')),
        );
      }
      return;
    }
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageGalleryScreen(
            imageUrls: imageUrls,
            authHeaders: {'Authorization': 'Bearer $token'},
          ),
        ),
      );
    }
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
      child: BlocBuilder<SerahTerimaHistoryBloc, SerahTerimaHistoryState>(
        builder: (context, state) {
          if (state.status == SerahTerimaHistoryStatus.loading ||
              state.status == SerahTerimaHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == SerahTerimaHistoryStatus.failure) {
            return _buildErrorState(context, state.errorMessage);
          }

          // Filter hnya jenis dokumen/barang
          final List<SerahTerimaHistory> dokumenList = 
              state.serahTerimaList.where((item) {
            final jenis = item.jenis.toLowerCase(); 
            return jenis == 'surat' || jenis == 'dokumen' || jenis == 'paket';
          }).toList();


          // Filter berdasarkan search
          final filteredListBySearch = dokumenList.where((item) {
            final query = widget.searchController.text.toLowerCase();
            
            final dokumenDariText = item.dokumenDari?.toLowerCase() ?? '';
            final diterimaOlehText = item.diterimaOleh?.toLowerCase() ?? '';
            final jenisText = item.jenis.toLowerCase();

            return dokumenDariText.contains(query) ||
                   diterimaOlehText.contains(query) ||
                   jenisText.contains(query);
          }).toList();

          // Filter berdasarkan tggl
          final List<SerahTerimaHistory> finalFilteredList;
          if (widget.selectedDate != null) {
            finalFilteredList = filteredListBySearch.where((item) {
              return _isSameDay(item.createdAt, widget.selectedDate!);
            }).toList();
          } else {
            finalFilteredList = filteredListBySearch;
          }
    
          if (finalFilteredList.isEmpty) {
            bool isSearching = widget.searchController.text.isNotEmpty ||
                widget.selectedDate != null;
            return _buildEmptyList(isSearching);
          }

          // -logika pagination
          final bool hasMore = finalFilteredList.length > _displayLimit;
          final displayedList = finalFilteredList.take(_displayLimit).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SerahTerimaHistoryBloc>().add(SerahTerimaHistoryFetched());
              _resetLimit(); // Reset limit saat refresh
            },
            // Kirim hasMore dan remainingCount
            child: _buildHistoryList(
              displayedList,
              hasMore: hasMore,
              remainingCount: finalFilteredList.length - displayedList.length,
            ),
          );
        },
      ),
    );
  }

  //updtae list load more
  Widget _buildHistoryList(
    List<SerahTerimaHistory> historyItems, {
    required bool hasMore,
    required int remainingCount,
  }) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      // Tambah 1 jika ada tombol load more
      itemCount: historyItems.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        
        // jika item terakir load more
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          );
        }

        // render item
        final item = historyItems[index];

        final dokumenDariValue = item.dokumenDari ?? 'N/A';
        final diterimaOlehValue = item.diterimaOleh ?? 'N/A';

        return WidgetRiwayatItem(
          judulBaris1: item.jenis,
          subJudul: 'Dari: $dokumenDariValue',
          ikon: _getIconForJenis(item.jenis),
          warnaIkon: _getColorForJenis(item.jenis),
          waktu: DateFormat('HH:mm').format(item.createdAt),
          tanggal: DateFormat('dd MMM yyyy').format(item.createdAt),
          itemKey: 'serah_terima_${item.id}',
          onLihatLampiran: item.attachment.isNotEmpty
              ? () => _showImageGallery(context, item.attachment)
              : null,
          onHapus: () {
            _confirmDelete(context, item.id);
          },
          detailChildren: [
            buildDetailRow(
                icon: Icons.person_pin_circle_outlined,
                title: 'Diterima Oleh',
                value: diterimaOlehValue), 
            const Divider(color: Colors.white24),
            buildDetailRow(
                icon: Icons.person_search_outlined,
                title: 'Dari',
                value: dokumenDariValue), 
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

  IconData _getIconForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'surat':
        return Icons.mail_outline;
      case 'dokumen':
        return Icons.description_outlined;
      case 'paket':
        return Icons.inventory_2_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  Color _getColorForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'surat':
        return Colors.blue;
      case 'dokumen':
        return Colors.orange;
      case 'paket':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Hapus', style: GoogleFonts.poppins()),
        content: Text('Anda yakin ingin menghapus riwayat dokumen ini?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context
            .read<SerahTerimaHistoryBloc>()
            .add(SerahTerimaHistoryDeleted(id: id));
      }
    });
  }

  Widget _buildEmptyList(bool isSearching) {
    String title = isSearching ? 'Tidak Ditemukan' : 'Belum Ada Riwayat Dokumen';
    String message = isSearching
        ? 'Tidak ada data yang cocok dengan pencarian Anda.'
        : 'Data riwayat serah terima dokumen/barang akan muncul di sini.';

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

  Widget _buildErrorState(BuildContext context, String? errorMessage) {
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
            padding:
                const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
            child: Text(
              errorMessage ?? 'Terjadi kesalahan koneksi.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text('Coba Lagi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onPressed: () {
              context.read<SerahTerimaHistoryBloc>().add(SerahTerimaHistoryFetched());
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}


class ImageGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Map<String, String> authHeaders; 

  const ImageGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    required this.authHeaders,
  });
  
  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                headers: widget.authHeaders, 
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