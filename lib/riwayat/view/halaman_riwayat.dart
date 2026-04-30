import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../kendaraan/view/halaman_riwayat_kendaraan.dart';
import '../tamu/view/halaman_riwayat_tamu.dart';
import '../truk/view/halaman_riwayat_truk.dart';
import '../dokumen/view/halaman_riwayat_serah_terima.dart';
import '../sim/view/halaman_riwayat_sim.dart';
import '../tugas_umum/view/halaman_riwayat_tugas_umum.dart';
import '../tugas_ob/view/halaman_riwayat_tugas_ob.dart'; 
import '../bloc/history_bloc.dart'; 

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryBloc(), 
      child: const HistoryScreenView(),
    );
  }
}

class HistoryScreenView extends StatefulWidget {
  const HistoryScreenView({super.key});

  @override
  State<HistoryScreenView> createState() => _HistoryScreenViewState();
}

class _HistoryScreenViewState extends State<HistoryScreenView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // panjang tab 
    _tabController = TabController(length: 7, vsync: this); 

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _searchFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<HistoryBloc>().add(HistoryFetched());
    
    return WillPopScope(
      onWillPop: () async {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Riwayat Aktivitas',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100.0),
              child: Column(
                children: [
                  _buildSearchBar(),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true, 
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.amber,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Inventaris'),
                      Tab(text: 'Truk'),
                      Tab(text: 'Tamu'),
                      Tab(text: 'Dokumen'), 
                      Tab(text: 'SIM'), 
                      Tab(text: 'Tugas Umum'),
                      Tab(text: 'Tugas OB'), 
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              HalamanRiwayatKendaraan(
                searchController: _searchController,
                selectedDate: _selectedDate,
              ),
              HalamanRiwayatTruk(
                searchController: _searchController,
                selectedDate: _selectedDate,
              ),
              HalamanRiwayatTamu(
                searchController: _searchController,
                selectedDate: _selectedDate,
              ),
              HalamanRiwayatSerahTerima(
                searchController: _searchController,
                selectedDate: _selectedDate,
              ),
              HalamanRiwayatSim( 
                searchController: _searchController,
                selectedDate: _selectedDate,
              ),
              HalamanRiwayatTugasUmum(
                searchController: _searchController,
                selectedDate: _selectedDate,
              ),
              // 4. TAMBAH VIEW HALAMAN TUGAS OB
              HalamanRiwayatTugasOb(
                searchController: _searchController,
                selectedDate: _selectedDate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari NOPOL, Nama, Dokumen, SIM...', 
                  hintStyle:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildDateFilterButton(),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton() {
    final bool hasFilter = _selectedDate != null;
    const Color primaryColor = Color(0xFF0D47A1);
    const Color headerColor = Color(0xFF1976D2);

    return IconButton(
      icon: Icon(
        hasFilter ? Icons.event_busy : Icons.calendar_month_outlined,
        color: hasFilter ? Colors.amber : Colors.white,
      ),
      onPressed: () async {
        _searchFocusNode.unfocus(); // Tutup keyboard

        if (hasFilter) {
          // Jika sudah ada filter, klik lagi untuk clear
          setState(() {
            _selectedDate = null;
          });
        } else {
          // Jika belum ada filter, tampilkan date picker
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020), 
            lastDate: DateTime.now(), 

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
            setState(() {
              _selectedDate = picked;
            });
          }
        }
      },
    );
  }
}