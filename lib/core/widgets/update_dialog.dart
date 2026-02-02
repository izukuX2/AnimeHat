import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> releaseData;

  const UpdateDialog({super.key, required this.releaseData});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();
  double _progress = 0;
  bool _isDownloading = false;
  String? _error;

  void _startDownload() async {
    final assets = widget.releaseData['assets'] as List<dynamic>;
    final url = await _updateService.getCompatibleApkUrl(assets);

    if (url == null) {
      setState(() => _error = 'No compatible APK found for your device.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _error = null;
    });

    await _updateService.downloadAndInstall(
      url: url,
      onProgress: (p) => setState(() => _progress = p),
      onError: (e) => setState(() {
        _isDownloading = false;
        _error = e;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestVersion = widget.releaseData['tag_name'];
    final body = widget.releaseData['body'] ?? 'No release notes available.';

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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.right,
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white10,
                color: Colors.amber,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'لاحقاً',
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
