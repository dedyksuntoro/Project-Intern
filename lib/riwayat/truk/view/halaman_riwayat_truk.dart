import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../../../models/armada.dart';
import '../../../models/sopir.dart'; 
import '../../../models/kendaraan_history.dart';
import '../../../widgets/widget_riwayat_item.dart';
import '../bloc/truk_history_bloc.dart';

class HalamanRiwayatTruk extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const HalamanRiwayatTruk({
    super.key,
    required this.searchController,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrukHistoryBloc()..add(TrukHistoryFetched()),
      child: _HalamanRiwayatTrukView(
        searchController: searchController,
        selectedDate: selectedDate,
      ),
    );
  }
}

class _HalamanRiwayatTrukView extends StatefulWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;

  const _HalamanRiwayatTrukView({
    required this.searchController,
    required this.selectedDate,
  });

  @override
  State<_HalamanRiwayatTrukView> createState() =>
      _HalamanRiwayatTrukViewState();
}

class _HalamanRiwayatTrukViewState extends State<_HalamanRiwayatTrukView> {
  int _displayLimit = 10;
  final int _limitIncrement = 10;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant _HalamanRiwayatTrukView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _resetLimit();
    }
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

  void _resetLimit() {
    _displayLimit = 10;
  }

  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  String _translateStatus(String? code) {
    if (code == 'A') return 'Ada';
    if (code == 'M') return 'Mati';
    if (code == 'T') return 'Tidak Ada';
    return '-';
  }

  // Helper untuk mendapatkan nama sopir (API String atau Lookup ID)
  String _getSopirName(KendaraanHistory item, Map<String, String> sopirMap) {
    // Cek API sudah mengirimkan nama 
    if (item.sopir != null && item.sopir!.isNotEmpty) {
      return item.sopir!;
    }
    if (item.idSopir != null) {
      return sopirMap[item.idSopir.toString()] ?? 'Sopir tidak terdata';
    }
    return 'Sopir tidak tercatat';
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
      child: BlocBuilder<TrukHistoryBloc, TrukHistoryState>(
        builder: (context, state) {
          if (state.status == TrukHistoryStatus.loading ||
              state.status == TrukHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TrukHistoryStatus.failure) {
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
                      context.read<TrukHistoryBloc>().add(TrukHistoryFetched());
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

          // Pass list sopir ke filter
          final filteredListBySearch =
              _filterList(state.historyList, state.armadaList, state.sopirList);

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
              context.read<TrukHistoryBloc>().add(TrukHistoryFetched());
              _resetLimit();
            },
            child: _buildHistoryList(
              displayedList,
              state.armadaList,
              state.sopirList, // Pass sopirList
              hasMore: hasMore,
              remainingCount: filteredList.length - displayedList.length,
            ),
          );
        },
      ),
    );
  }

  // Update signature untuk menerima list sopir
  List<KendaraanHistory> _filterList(
      List<KendaraanHistory> history, List<Armada> armada, List<Sopir> sopirList) {
    final query = widget.searchController.text.toLowerCase();
    final listByTruk = history.where((item) => item.inventaris == 'N').toList();

    if (query.isEmpty) return listByTruk;

    final Map<String, String> armadaMap = {
      for (var item in armada) item.id: item.nopol
    };

    // Buat Map ID Sopir -> Nama Sopir untuk lookup cepat
    final Map<String, String> sopirMap = {
      for (var s in sopirList) s.id: s.nama
    };

    return listByTruk.where((item) {
      final nopol = armadaMap[item.idArmada.toString()]?.toLowerCase() ?? '';
      
      // Gunakan helper logic yang sama untuk nama sopir
      final sopirName = _getSopirName(item, sopirMap).toLowerCase();
      
      final tanggal = DateFormat('dd MMM yyyy', 'id_ID')
          .format(item.createdAt)
          .toLowerCase();

      return nopol.contains(query) ||
          sopirName.contains(query) ||
          tanggal.contains(query);
    }).toList();
  }

  Widget _buildHistoryList(
    List<KendaraanHistory> historyItems,
    List<Armada> armadaItems,
    List<Sopir> sopirItems, { // Terima sopirItems
    required bool hasMore,
    required int remainingCount,
  }) {
    final Map<String, String> armadaMap = {
      for (var armada in armadaItems) armada.id: armada.nopol
    };

    // Buat Map ID Sopir -> Nama untuk lookup di item widget
    final Map<String, String> sopirMap = {
      for (var s in sopirItems) s.id: s.nama
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
        
        // GUNAKAN HELPER DISINI
        final String displayNameSopir = _getSopirName(item, sopirMap);

        return WidgetRiwayatItem(
          judulBaris1:
              armadaMap[item.idArmada.toString()] ?? 'Nopol tidak tersedia',
          judulBaris2: isMasuk ? 'Masuk' : 'Keluar',
          
          // Ganti 'item.sopir' dengan 'displayNameSopir'
          subJudul: displayNameSopir, 
          
          ikon: isMasuk ? Icons.login : Icons.logout,
          warnaIkon: isMasuk ? Colors.blueAccent : Colors.green,
          waktu: DateFormat('HH:mm').format(item.createdAt),
          tanggal: DateFormat('dd MMM yyyy', 'id_ID').format(item.createdAt),
          itemKey: 'truk_${item.id}',
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
                    .read<TrukHistoryBloc>()
                    .add(TrukHistoryDeleted(id: item.id));
              }
            });
          },
          detailChildren: [
            if (item.kernet != null && item.kernet!.isNotEmpty) ...[
              buildDetailRow(
                  icon: Icons.person,
                  title: 'Nama Kernet',
                  value: item.kernet!),
              const Divider(color: Colors.white24),
            ],

             if (item.statusStnk != null) ...[
              buildDetailRow(
                  icon: Icons.assignment_outlined,
                  title: 'Status STNK',
                  value: _translateStatus(item.statusStnk)),
              const Divider(color: Colors.white24),
            ],
            if (item.stnkTanggal != null) ...[
              buildDetailRow(
                  icon: Icons.calendar_today,
                  title: 'STNK Tanggal',
                  value: DateFormat('dd MMM yyyy').format(item.stnkTanggal!)),
              const Divider(color: Colors.white24),
            ],
            if (item.statusKir != null) ...[
              buildDetailRow(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Status KIR',
                  value: _translateStatus(item.statusKir)),
              const Divider(color: Colors.white24),
            ],
            if (item.kirTanggal != null) ...[
              buildDetailRow(
                  icon: Icons.calendar_today,
                  title: 'KIR Tanggal',
                  value: DateFormat('dd MMM yyyy').format(item.kirTanggal!)),
              const Divider(color: Colors.white24),
            ],
            if (item.kirBet != null && item.kirBet!.isNotEmpty) ...[
              buildDetailRow(
                  icon: Icons.confirmation_number_outlined,
                  title: 'KIR BET',
                  value: item.kirBet!),
              const Divider(color: Colors.white24),
            ],
            if (item.noLambung != null && item.noLambung!.isNotEmpty) ...[
              buildDetailRow(
                  icon: Icons.looks_one_outlined,
                  title: 'No. Lambung',
                  value: item.noLambung!),
              const Divider(color: Colors.white24),
            ],
            buildDetailRow(
                icon: Icons.speed,
                title: 'Kilometer',
                value: '${item.kilometer.toStringAsFixed(0)} Km'),
            const Divider(color: Colors.white24),
            buildDetailRow(
                icon: Icons.local_gas_station,
                title: 'Sisa BBM',
                value: '${item.bbm.round()}%'),
            const Divider(color: Colors.white24),
            buildDetailRow(
              icon: item.statusArmada == 'Y'
                  ? Icons.check_circle_outline
                  : Icons.build_outlined,
              title: 'Status Truk',
              value: item.statusArmada == 'Y' ? 'Ready' : 'Servis',
            ),
            if (item.statusArmada == 'N' &&
                item.keteranganArmada != null &&
                item.keteranganArmada!.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              buildDetailRow(
                  icon: Icons.comment_outlined,
                  title: 'Keterangan Servis',
                  value: item.keteranganArmada!),
            ],
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
    String title = isSearching ? 'Tidak Ditemukan' : 'Belum Ada Riwayat Truk';
    String message = isSearching
        ? 'Tidak ada data yang cocok dengan pencarian Anda.'
        : 'Data riwayat truk akan muncul di sini.';

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