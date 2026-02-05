import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/download_service.dart';
import '../models/github_release.dart';

class UpdateDialog extends StatefulWidget {
  final GithubRelease release;

  const UpdateDialog({super.key, required this.release});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();
  bool _isDownloading = false;
  String? _message;

  void _startDownload() async {
    final assets = widget.release.assets;
    final url = await _updateService.getCompatibleApkUrl(assets);

    if (url == null) {
      setState(() => _message = 'No compatible APK found for your device.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _message = 'Starting background download...';
    });

    try {
      final fileName = 'AnimeHat_${widget.release.tagName}.apk';
      final taskId = await DownloadService().downloadUpdate(url, fileName);

      if (taskId != null) {
        setState(() {
          _message = 'Download started in background. Check notifications.';
        });
        // Close dialog after short delay or let user close
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Downloading update in background...')),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _isDownloading = false;
          _message = 'Failed to start download.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _message = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestVersion = widget.release.tagName;
    final body = widget.release.body;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'تحديث جديد متوفر: $latestVersion',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'مميزات التحديث:',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.right,
            ),
            if (_message != null) ...[
              // Use _message for status/errors
              const SizedBox(height: 16),
              Text(
                _message!,
                style: TextStyle(
                    color: _isDownloading ? Colors.white : Colors.redAccent),
                textAlign: TextAlign.right,
              ),
            ],
            // Show progress if available (even for background task if we can verify it)
            // Ideally we'd listen to the port here, but for now let's just show indeterminate if preparing
            /*
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Colors.amber,
              ),
              const SizedBox(height: 8),
              const Text(
                'Downloading in background...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            */
            // The progress indicator and percentage are removed as download is backgrounded
            // if (_isDownloading) ...[
            //   const SizedBox(height: 20),
            //   LinearProgressIndicator(
            //     value: _progress,
            //     backgroundColor: Colors.white10,
            //     color: Colors.amber,
            //   ),
            //   const SizedBox(height: 8),
            //   Text(
            //     '${(_progress * 100).toStringAsFixed(0)}%',
            //     style: const TextStyle(color: Colors.white),
            //   ),
            // ],
          ],
        ),
      ),
      actions: [
        if (!_isDownloading) // Only show 'Later' and 'Minimize' if not actively starting download
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'لاحقاً',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        if (!_isDownloading) // Add a 'Minimise' button
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update dialog minimized.')),
              );
            },
            child: const Text(
              'تصغير', // Minimise
              style: TextStyle(color: Colors.white54),
            ),
          ),
        if (!_isDownloading)
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'تحديث الآن',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
