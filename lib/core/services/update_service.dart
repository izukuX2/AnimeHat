import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';

import '../models/github_release.dart';

class UpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/izukuX2/AnimeHat/releases';

  Future<List<GithubRelease>> getReleases() async {
    try {
      final dio = Dio();
      final response = await dio.get(_githubApiUrl);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => GithubRelease.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching releases: $e');
    }
    return [];
  }

  Future<GithubRelease?> checkUpdate() async {
    try {
      final releases = await getReleases();
      if (releases.isEmpty) return null;

      final latestRelease = releases.first;
      final latestVersion = latestRelease.version;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        return latestRelease;
      }
    } catch (e) {
      debugPrint('Error checking update: $e');
    }
    return null;
  }

  bool _isNewerVersion(String current, String latest) {
    try {
      List<int> currentV =
          current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> latestV =
          latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (var i = 0; i < latestV.length; i++) {
        final cur = (i < currentV.length) ? currentV[i] : 0;
        final lat = latestV[i];

        if (lat > cur) return true;
        if (lat < cur) return false;
      }
      // If we are here, versions are equal (or latest matches prefix of current)
      // e.g. 1.0 vs 1.0.0 -> equal
      // e.g. 1.0 vs 1.0.1 -> handled in loop
      // If equal, return false (do not update)
      return false;
    } catch (e) {
      debugPrint('Error parsing versions: $e');
    }
    return false;
  }

  Future<String?> getCompatibleApkUrl(List<GithubAsset> assets) async {
    final deviceInfo = DeviceInfoPlugin();
    String abi = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      abi = androidInfo.supportedAbis.first;
    }

    // common abis: arm64-v8a, armeabi-v7a, x86_64
    for (var asset in assets) {
      final String name = asset.name.toLowerCase();
      if (name.contains(abi)) {
        return asset.browserDownloadUrl;
      }
    }

    // fallback to universal if available or the first apk
    for (var asset in assets) {
      final String name = asset.name.toLowerCase();
      if (name.contains('universal') || name.endsWith('.apk')) {
        return asset.browserDownloadUrl;
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
