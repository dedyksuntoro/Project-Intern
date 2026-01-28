import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WidgetRiwayatItem extends StatelessWidget {
  final String judulBaris1;
  final String? judulBaris2;
  final String subJudul;
  final IconData ikon;
  final Color warnaIkon;
  final String waktu;
  final String tanggal;
  final List<Widget> detailChildren;
  final VoidCallback? onHapus;
  final String itemKey;
  final VoidCallback? onLihatLampiran;

  const WidgetRiwayatItem({
    super.key,
    required this.judulBaris1,
    this.judulBaris2,
    required this.subJudul,
    required this.ikon,
    required this.warnaIkon,
    required this.waktu,
    required this.tanggal,
    required this.detailChildren,
    this.onHapus,
    required this.itemKey,
    this.onLihatLampiran,
  });

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF001f3f);

    final judulStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final subJudulStyle = GoogleFonts.poppins(
      fontSize: 13,
      color: Colors.white.withOpacity(0.8)
    );
    final judul2Style = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.9),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: navyColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      color: navyColor,
      child: ExpansionTile(
        key: PageStorageKey(itemKey),
        maintainState: true,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: warnaIkon,
          child: Icon(ikon, color: Colors.white, size: 22),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: judulBaris1,
              child: Text(
                judulBaris1,
                style: judulStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Tooltip(
              message: subJudul,
              child: Text(
                subJudul,
                style: subJudulStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (judulBaris2 != null && judulBaris2!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Tooltip(
                  message: judulBaris2!,
                  child: Text(
                    judulBaris2!,
                    style: judul2Style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              waktu,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              tanggal,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        children: [
          Container(
            color: Colors.black.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                ...detailChildren,
                if (onHapus != null || onLihatLampiran != null) ...[
                  const Divider(color: Colors.white24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row( 
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onLihatLampiran != null)
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined),
                            color: Colors.blueAccent,
                            tooltip: 'Lihat Lampiran',
                            onPressed: onLihatLampiran,
                          ),
                        if (onHapus != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.redAccent,
                            tooltip: 'Hapus Data',
                            onPressed: onHapus,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Fungsi pembantu untuk membuat baris detail dalam riwayat
Widget buildDetailRow({required IconData icon, required String title, required String value}) {
  final titleStyle = GoogleFonts.poppins(color: Colors.white70);
  final valueStyle = GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 16),
        Text(title, style: titleStyle),
        const SizedBox(width: 16),
        Expanded(
          child: Tooltip(
            message: value,
            child: Text(
              value,
              style: valueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    ),
  );
}