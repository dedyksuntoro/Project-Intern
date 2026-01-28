import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/serah_terima_history.dart';
import '../../../models/sopir.dart';
import '../../../widgets/widget_riwayat_item.dart';
import '../bloc/sim_history_bloc.dart';
import '../../../services/api_service.dart';
import '../../../service_locator.dart';

class HalamanRiwayatSim extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatSim({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimHistoryBloc()..add(SimHistoryFetched()),
      child: HalamanRiwayatSimView(
        searchController: searchController,
        selectedDate: selectedDate,
      ),
    );
  }
}

class HalamanRiwayatSimView extends StatefulWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatSimView({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  State<HalamanRiwayatSimView> createState() => _HalamanRiwayatSimViewState();
}

class _HalamanRiwayatSimViewState extends State<HalamanRiwayatSimView> {
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
  void didUpdateWidget(covariant HalamanRiwayatSimView oldWidget) {
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

  void _showImageGallery(BuildContext context, List<String> imageUrls) async {
    final apiService = locator<ApiService>();
    final token = await apiService.getToken();

    if (token == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi berakhir. Silakan login ulang.')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: BlocBuilder<SimHistoryBloc, SimHistoryState>(
        builder: (context, state) {
          if (state.status == SimHistoryStatus.loading ||
              state.status == SimHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == SimHistoryStatus.failure) {
            return _buildErrorState(context, state.errorMessage);
          }

          final List<SerahTerimaHistory> simList = state.simHistoryList;
          final List<Sopir> sopirList = state.sopirList;

          final filteredListBySearch = _filterList(simList, sopirList);

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

          final bool hasMore = finalFilteredList.length > _displayLimit;
          final displayedList = finalFilteredList.take(_displayLimit).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SimHistoryBloc>().add(SimHistoryFetched());
              _resetLimit();
            },
            child: _buildHistoryList(
              displayedList,
              sopirList,
              hasMore: hasMore,
              remainingCount: finalFilteredList.length - displayedList.length,
            ),
          );
        },
      ),
    );
  }

  List<SerahTerimaHistory> _filterList(
      List<SerahTerimaHistory> history, List<Sopir> sopir) {
    final query = widget.searchController.text.toLowerCase().trim();

    if (query.isEmpty) return history;

    final Map<String, String> sopirMap = {
      for (var item in sopir) item.id: item.nama
    };

    return history.where((item) {
      final statusSim = (item.statusSim ?? '').toLowerCase();
      final namaSopir =
          sopirMap[item.idSopir?.toString()]?.toLowerCase() ?? '';
      final keterangan = (item.keterangan ?? '').toLowerCase();
      final tanggal =
          DateFormat('dd MMM yyyy').format(item.createdAt).toLowerCase();

      return statusSim.contains(query) ||
          namaSopir.contains(query) ||
          keterangan.contains(query) ||
          tanggal.contains(query);
    }).toList();
  }

  Widget _buildHistoryList(
    List<SerahTerimaHistory> historyItems,
    List<Sopir> sopirItems, {
    required bool hasMore,
    required int remainingCount,
  }) {
    final Map<String, String> sopirMap = {
      for (var sopir in sopirItems) sopir.id: sopir.nama
    };

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

        final String statusText = (item.statusSim ?? 'N/A').trim();
        final String namaSopir = sopirMap[item.idSopir?.toString()] ??
            'Sopir #${item.idSopir ?? "N/A"}';
        final String? keterangan = item.keterangan;

        return WidgetRiwayatItem(
          judulBaris1: statusText.toUpperCase(),
          judulBaris2: 'SIM',
          subJudul: namaSopir,
          ikon: _getIconForStatus(statusText),
          warnaIkon: _getColorForStatus(statusText),
          waktu: DateFormat('HH:mm').format(item.createdAt),
          tanggal: DateFormat('dd MMM yyyy').format(item.createdAt),
          itemKey: 'sim_${item.id}',
          onLihatLampiran: item.attachment.isNotEmpty
              ? () => _showImageGallery(context, item.attachment)
              : null,
          onHapus: () {
            _confirmDelete(context, item.id);
          },
          detailChildren: [
            buildDetailRow(
                icon: Icons.badge_outlined, title: 'Status', value: statusText),
            const Divider(color: Colors.white24),
            buildDetailRow(
                icon: Icons.person_outlined,
                title: 'Nama Sopir',
                value: namaSopir),
            if (keterangan != null && keterangan.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              buildDetailRow(
                  icon: Icons.notes_outlined,
                  title: 'Keterangan',
                  value: keterangan),
            ],
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

  IconData _getIconForStatus(String status) {
    final statusLower = status.toLowerCase().trim();
    if (statusLower == 'diterima') {
      return Icons.arrow_circle_down_outlined;
    } else if (statusLower == 'diserahkan') {
      return Icons.arrow_circle_up_outlined;
    }
    return Icons.sim_card_outlined;
  }

  Color _getColorForStatus(String status) {
    final statusLower = status.toLowerCase().trim();
    if (statusLower == 'diterima') {
      return Colors.green;
    } else if (statusLower == 'diserahkan') {
      return Colors.orange;
    }
    return Colors.blueGrey;
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Hapus', style: GoogleFonts.poppins()),
        content: Text('Anda yakin ingin menghapus riwayat SIM ini?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(true);
                context.read<SimHistoryBloc>().add(SimHistoryDeleted(id: id));
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyList(bool isSearching) {
    String title = isSearching ? 'Tidak Ditemukan' : 'Belum Ada Riwayat SIM';
    String message = isSearching
        ? 'Tidak ada data yang cocok dengan pencarian Anda.'
        : 'Data riwayat serah terima SIM akan muncul di sini.';

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
              context.read<SimHistoryBloc>().add(SimHistoryFetched());
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