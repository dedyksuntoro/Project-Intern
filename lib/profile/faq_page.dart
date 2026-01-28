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
      question: 'Apa itu aplikasi ini?',
      answer:
          'Aplikasi ini adalah sebuah platform luar biasa yang dirancang untuk mempermudah Security. Kami menyediakan berbagai fitur canggih untuk memenuhi kebutuhan oprasional perusahaan sehari-hari.',
    ),
    FaqItem(
      question: 'Bagaimana cara mereset password saya?',
      answer:
          'Untuk mereset password, Login terlebih dahulu ke Mandala Security App, kemudian ke menu profile, click pada button ubah password. Isi passwrod sesuai dengan kebutuhan.',
    ),
    FaqItem(
      question: 'Apakah data saya aman?',
      answer:
          'Tentu saja. Keamanan data pengguna adalah prioritas utama kami. Kami menggunakan enkripsi end-to-end dan praktik keamanan standar industri untuk melindungi semua informasi Anda.',
    ),
    FaqItem(
      question: 'Bagaimana cara menghubungi layanan pelanggan?',
      answer:
          'Anda bisa menghubungi kami melalui telepon perusahaan depatermen IT , atau langsung mendatangi ruangan Departemen IT.',
    ),
    FaqItem(
      question: 'Bagaimana cara mengatasi aplikasi terasa berat?',
      answer:
          'Pengguna diwajibkan menghapus cache aplikasi jika aplikasi terasa berat. Dengan cara klik tahan pada aplikasi dan akan di arahkan ke detail aplikasi , pilih hapus cache.',
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
                      style: TextStyle(
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
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