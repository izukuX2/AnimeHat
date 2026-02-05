import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  String? _taskId;

  Future<void> init() async {
    await FlutterDownloader.initialize(
      debug: kDebugMode,
      ignoreSsl: true,
    );

    // Optional: register callback if needed globally, but we might handle it in UI
    // FlutterDownloader.registerCallback(downloadCallback);
  }

  // Static callback for background isolation
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<String?> downloadUpdate(String url, String fileName) async {
    final dir = await getExternalStorageDirectory();
    // Use visible dir for user or internal for auto-install?
    // External allows user to see file.

    debugPrint('Downloading update to ${dir?.path}/$fileName');

    _taskId = await FlutterDownloader.enqueue(
      url: url,
      headers: {}, // optional: header send with url (auth token etc)
      savedDir: dir?.path ?? '',
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true, // Click to install
      saveInPublicStorage: true,
    );

    return _taskId;
  }

  Future<void> pauseDownload() async {
    if (_taskId != null) await FlutterDownloader.pause(taskId: _taskId!);
  }

  Future<void> resumeDownload() async {
    if (_taskId != null) await FlutterDownloader.resume(taskId: _taskId!);
  }

  Future<void> cancelDownload() async {
    if (_taskId != null) await FlutterDownloader.cancel(taskId: _taskId!);
    _taskId = null;
  }

  Future<void> openFile() async {
    if (_taskId != null) {
      await FlutterDownloader.open(taskId: _taskId!);
    }
  }
}
