import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../../../models/armada.dart';
import '../../../models/karyawan.dart';
import '../../../models/kendaraan_history.dart';
import '../../../widgets/widget_riwayat_item.dart';
import '../bloc/kendaraan_history_bloc.dart';

class HalamanRiwayatKendaraan extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatKendaraan({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          KendaraanHistoryBloc()..add(KendaraanHistoryFetched()),
      child: _HistoryListView(
        searchController: searchController,
        selectedDate: selectedDate,
      ),
    );
  }
}

class _HistoryListView extends StatefulWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const _HistoryListView({
    required this.searchController,
    required this.selectedDate,
  });

  @override
  State<_HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<_HistoryListView> {
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
  void didUpdateWidget(covariant _HistoryListView oldWidget) {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('Lampiran',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
          body: PageView.builder(
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return PhotoView(
                imageProvider: NetworkImage(imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.grey, size: 50)),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: BlocBuilder<KendaraanHistoryBloc, KendaraanHistoryState>(
        builder: (context, state) {
          if (state.status == KendaraanHistoryStatus.loading ||
              state.status == KendaraanHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == KendaraanHistoryStatus.failure) {
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
                      context
                          .read<KendaraanHistoryBloc>()
                          .add(KendaraanHistoryFetched());
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

          final filteredListBySearch = _filterList(
              state.historyList, state.armadaList, state.karyawanList);

          final List<KendaraanHistory> filteredList;
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
              context
                  .read<KendaraanHistoryBloc>()
                  .add(KendaraanHistoryFetched());
              _resetLimit();
            },
            child: _buildHistoryList(
              displayedList,
              state.armadaList,
              state.karyawanList,
              hasMore: hasMore,
              remainingCount: filteredList.length - displayedList.length,
            ),
          );
        },
      ),
    );
  }

  List<KendaraanHistory> _filterList(List<KendaraanHistory> history,
      List<Armada> armada, List<Karyawan> karyawan) {
    final query = widget.searchController.text.toLowerCase();

    final listByInventaris =
        history.where((item) => item.inventaris == 'Y').toList();

    if (query.isEmpty) return listByInventaris;

    final Map<String, String> armadaMap = {
      for (var item in armada) item.id: item.nopol
    };
    final Map<String, String> karyawanMap = {
      for (var item in karyawan) item.id: item.nama
    };

    return listByInventaris.where((item) {
      final nopol = armadaMap[item.idArmada.toString()]?.toLowerCase() ?? '';
      final namaKaryawan =
          karyawanMap[item.idKaryawan.toString()]?.toLowerCase() ?? '';

      final tanggal =
          DateFormat('dd MMM yyyy').format(item.createdAt).toLowerCase();

      return nopol.contains(query) ||
          namaKaryawan.contains(query) ||
          tanggal.contains(query);
    }).toList();
  }

  Widget _buildHistoryList(
    List<KendaraanHistory> historyItems,
    List<Armada> armadaItems,
    List<Karyawan> karyawanItems, {
    required bool hasMore,
    required int remainingCount,
  }) {
    final Map<String, String> armadaMap = {
      for (var armada in armadaItems) armada.id: armada.nopol
    };
    final Map<String, String> karyawanMap = {
      for (var karyawan in karyawanItems) karyawan.id: karyawan.nama
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
        bool isMasuk = item.jenis == 'IN';

        String subJudulText = item.karyawan ??
            karyawanMap[item.idKaryawan.toString()] ??
            'Karyawan tidak tercatat';

        return WidgetRiwayatItem(
          judulBaris1:
              armadaMap[item.idArmada.toString()] ?? 'Nopol tidak tersedia',
          judulBaris2: isMasuk ? 'Masuk' : 'Keluar',
          subJudul: subJudulText,
          ikon: isMasuk ? Icons.login : Icons.logout,
          warnaIkon: isMasuk ? Colors.blueAccent : Colors.green,
          waktu: DateFormat('HH:mm').format(item.createdAt),
          tanggal: DateFormat('dd MMM yyyy').format(item.createdAt),
          itemKey: 'kendaraan_${item.id}',
          onLihatLampiran: item.attachment.isNotEmpty
              ? () => _showImageGallery(context, item.attachment)
              : null,
          onHapus: () {
            showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Konfirmasi Hapus', style: GoogleFonts.poppins()),
                content: Text('Anda yakin ingin menghapus riwayat ini?',
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
                    .read<KendaraanHistoryBloc>()
                    .add(KendaraanHistoryDeleted(id: item.id));
              }
            });
          },
          detailChildren: [
            buildDetailRow(
                icon: Icons.speed,
                title: 'Kilometer',
                value: '${item.kilometer.toStringAsFixed(0)} Km'),
            const Divider(color: Colors.white24),
            buildDetailRow(
                icon: Icons.local_gas_station,
                title: 'Sisa BBM',
                value: '${item.bbm.round()}%'),
            if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              buildDetailRow(
                  icon: Icons.notes_outlined,
                  title: 'Keterangan Lain-Lain',
                  value: item.keterangan!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyList(bool isSearching) {
    String title =
        isSearching ? 'Tidak Ditemukan' : 'Belum Ada Riwayat Inventaris';
    String message = isSearching
        ? 'Tidak ada data yang cocok dengan pencarian Anda.'
        : 'Data riwayat kendaraan inventaris akan muncul di sini.';

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