import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _repoOwner = 'dedyksuntoro';
  static const String _repoName = 'Project-Intern';

  // URL to check for latest release
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  // Check for updates
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch latest release info from GitHub
      final response = await http.get(Uri.parse(_latestReleaseUrl));

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final String tagName = releaseData['tag_name'];
        final String latestVersion = tagName.replaceAll(
          'v',
          '',
        ); // Remove 'v' prefix if present

        // 3. Compare versions
        if (_isNewVersionAvailable(currentVersion, latestVersion)) {
          // 4. Construct download URL
          // Pattern: https://github.com/dedyksuntoro/Project-Intern/releases/download/1.2.0/app-release.apk
          final downloadUrl =
              'https://github.com/$_repoOwner/$_repoName/releases/download/$tagName/app-release.apk';

          if (context.mounted) {
            _showUpdateDialog(
              context,
              latestVersion,
              releaseData['body'] ?? '',
              downloadUrl,
            );
          }
        }
      } else {
        debugPrint('Failed to fetch release info: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }

  // Helper to compare versions
  bool _isNewVersionAvailable(String current, String latest) {
    try {
      // Simple semantic version comparison
      // Assumes format x.y.z
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true; // Latest has more parts
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error parsing versions: $e');
      return false; // Fallback
    }
  }

  // Show update dialog
  void _showUpdateDialog(
    BuildContext context,
    String version,
    String notes,
    String url,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Update Tersedia: v$version'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versi baru tersedia. Apakah Anda ingin mengupdate sekarang?',
              ),
              SizedBox(height: 10),
              Text(
                'Catatan Rilis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(notes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(context, url);
            },
            child: Text('Update Sekarang'),
          ),
        ],
      ),
    );
  }

  // Download and install
  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    try {
      if (!context.mounted) return;

      // Show a dialog to indicate download progress and handle potential errors visually
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return _DownloadDialog(url: url);
        },
      );
    } catch (e) {
      debugPrint('Update Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memulai update: $e')));
      }
    }
  }
}

class _DownloadDialog extends StatefulWidget {
  final String url;
  const _DownloadDialog({Key? key, required this.url}) : super(key: key);

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0.0;
  String _status = 'Menyiapkan unduhan...';
  bool _isDownloading = true;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      final dio = Dio();

      // Use getExternalStorageDirectory for Android to avoid WRITE_EXTERNAL_STORAGE permission
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        if (mounted) {
          setState(() {
            _status = 'Gagal mengakses penyimpanan internal.';
            _isDownloading = false;
          });
        }
        return;
      }

      final savePath = '${dir.path}/app-release.apk';

      if (mounted) {
        setState(() {
          _status = 'Mengunduh...';
        });
      }

      await dio.download(
        widget.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _progress = received / total;
              _status = 'Mengunduh: ${(_progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _status = 'Membuka installer aplikasi...';
          _isDownloading = false;
        });
      }

      // Open the downloaded APK using open_filex
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done && mounted) {
        setState(() {
          _status = 'Gagal membuka APK:\n${result.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Gagal mengunduh:\n$e';
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mengunduh Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading) const CircularProgressIndicator(),
          if (_isDownloading) const SizedBox(height: 16),
          Text(_status, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final uri = Uri.parse(widget.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('Unduh Manual'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
