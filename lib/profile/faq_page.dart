import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<FaqItem> _faqList = [
    FaqItem(
      question: 'Untuk apa aplikasi ini?',
      answer:
          'Aplikasi MPPM General Affair dirancang untuk mempermudah operasional harian tim Security, Office Boy (OB), dan Staff Tugas Umum. Aplikasi ini menyediakan fitur pencatatan tamu, kendaraan inventaris, cek truk, serah terima dokumen, serah terima SIM sopir, laporan tugas umum, serta laporan tugas OB.',
    ),
    FaqItem(
      question: 'Apa saja fitur yang tersedia di aplikasi ini?',
      answer:
          'Aplikasi ini memiliki 7 menu utama:\n'
          '1. Formulir Tamu — mencatat data tamu yang berkunjung.\n'
          '2. Kendaraan Inventaris — mencatat kendaraan inventaris keluar/masuk.\n'
          '3. Cek Truk — mencatat kondisi truk masuk dan keluar.\n'
          '4. Dokumen — serah terima paket, dokumen, dan surat.\n'
          '5. Serah SIM — serah terima SIM sopir.\n'
          '6. Tugas Umum — mencatat tugas umum dan pemakaian inventaris.\n'
          '7. Tugas OB — mencatat pekerjaan Office Boy.',
    ),
    FaqItem(
      question: 'Bagaimana cara melihat riwayat aktivitas saya?',
      answer:
          'Anda dapat melihat seluruh riwayat aktivitas melalui menu "Riwayat" yang tersedia di navigasi bawah aplikasi. Di halaman tersebut, Anda bisa melihat catatan aktivitas yang telah dilakukan sebelumnya.',
    ),
    FaqItem(
      question: 'Bagaimana cara menghubungi bantuan teknis?',
      answer:
          'Jika mengalami kendala, Anda dapat menghubungi Departemen IT melalui telepon internal perusahaan atau langsung mendatangi ruangan Departemen IT untuk mendapatkan bantuan.',
    ),
    FaqItem(
      question: 'Bagaimana cara mengatasi aplikasi yang terasa lambat?',
      answer:
          'Jika aplikasi terasa lambat, silakan hapus cache aplikasi dengan cara: tekan dan tahan ikon aplikasi → pilih "Info Aplikasi" atau "Detail Aplikasi" → pilih "Penyimpanan" → ketuk "Hapus Cache". Pastikan juga perangkat Anda memiliki koneksi internet yang stabil.',
    ),
    FaqItem(
      question: 'Apakah data saya aman di aplikasi ini?',
      answer:
          'Ya, aplikasi ini menggunakan sistem autentikasi token untuk menjaga keamanan akun Anda. Setiap sesi login diamankan dan data Anda hanya dapat diakses oleh akun yang berwenang. Jangan pernah membagikan informasi login Anda kepada orang lain.',
    ),
    FaqItem(
      question: 'Bagaimana jika aplikasi meminta pembaruan?',
      answer:
          'Aplikasi akan secara otomatis memeriksa ketersediaan versi terbaru saat dibuka. Jika tersedia pembaruan, ikuti petunjuk yang muncul di layar untuk mengunduh dan menginstal versi terbaru agar fitur dan performa aplikasi tetap optimal.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'FAQ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        itemCount: _faqList.length,
        itemBuilder: (context, index) {
          final item = _faqList[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 0.5),
            color: Colors.white,
            child: ExpansionTile(
              onExpansionChanged: (bool expanded) {
                setState(() {
                  item.isExpanded = expanded;
                });
              },
              title: Text(
                item.question,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,

                  color: Colors.black,
                ),
              ),
              children: <Widget>[
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.answer,
                      textAlign: TextAlign.justify,
                      style: TextStyle(color: Colors.grey[800], height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
