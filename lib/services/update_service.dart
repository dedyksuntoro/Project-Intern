import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
      // Request storage permission for Android < 13
      // For Android 13+, notification permission might be needed but ota_update handles basic intents
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // On Android 13+, this permission might be permanently denied or not applicable (as scoped storage is used)
      // We proceed anyway as ota_update uses DownloadManager or similar which might not need strict WRITE_EXTERNAL_STORAGE on newer Androids

      // Request install packages permission (usually handled by system dialog on first try, but good to check)
      // Note: This often requires opening settings manually if not granted, but let's try execute first.

      OtaUpdate().execute(url, destinationFilename: 'app-release.apk').listen((
        OtaEvent event,
      ) {
        if (event.status == OtaStatus.DOWNLOADING) {
          // You could show a progress dialog here
          debugPrint('Downloading: ${event.value}%');
        } else if (event.status == OtaStatus.INSTALLING) {
          debugPrint('Installing...');
        } else {
          debugPrint('OTA Status: ${event.status}');
        }
      });
    } catch (e) {
      debugPrint('OTA Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memulai update: $e')));
      }
    }
  }
}
