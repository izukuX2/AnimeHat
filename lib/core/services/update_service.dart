import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/izukuX2/AnimeHat/releases/latest';

  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final dio = Dio();
      final response = await dio.get(_githubApiUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('Error checking update: $e');
    }
    return null;
  }

  bool _isNewerVersion(String current, String latest) {
    List<int> currentV = current.split('.').map(int.parse).toList();
    List<int> latestV = latest.split('.').map(int.parse).toList();

    for (var i = 0; i < latestV.length; i++) {
      if (i >= currentV.length || latestV[i] > currentV[i]) {
        return true;
      } else if (latestV[i] < currentV[i]) {
        return false;
      }
    }
    return false;
  }

  Future<String?> getCompatibleApkUrl(List<dynamic> assets) async {
    final deviceInfo = DeviceInfoPlugin();
    String abi = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      abi = androidInfo.supportedAbis.first;
    }

    // common abis: arm64-v8a, armeabi-v7a, x86_64
    for (var asset in assets) {
      final String name = asset['name'].toString().toLowerCase();
      if (name.contains(abi)) {
        return asset['browser_download_url'];
      }
    }

    // fallback to universal if available or the first apk
    for (var asset in assets) {
      final String name = asset['name'].toString().toLowerCase();
      if (name.contains('universal') || name.endsWith('.apk')) {
        return asset['browser_download_url'];
      }
    }

    return null;
  }

  Future<void> downloadAndInstall({
    required String url,
    required Function(double) onProgress,
    required Function(String) onError,
  }) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        onError('Could not open APK: ${result.message}');
      }
    } catch (e) {
      onError('Download failed: $e');
    }
  }
}
