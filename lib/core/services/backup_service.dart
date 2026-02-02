import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  static const String _backupFileName = 'animehat_backup.db';

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // On Android 11 (API 30) and above, backup usually requires "All Files Access"
      // if we are copying files to arbitrary user-selected folders.

      // We check for manageExternalStorage for Android 11+
      var status = await Permission.manageExternalStorage.status;

      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (status.isGranted) return true;

      // Fallback/Legacy for older Android versions
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  Future<String?> pickDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    return selectedDirectory;
  }

  Future<String?> pickBackupFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // SQLite files can have various extensions or none
    );
    return result?.files.single.path;
  }

  Future<bool> exportDatabase(String targetFolderPath) async {
    try {
      final dbPath = join(await getDatabasesPath(), 'anime_hat.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        print('DB file does not exist at $dbPath');
        return false;
      }

      final targetPath = join(targetFolderPath, _backupFileName);
      await dbFile.copy(targetPath);
      return true;
    } catch (e) {
      print('Export failed: $e');
      return false;
    }
  }

  Future<bool> importDatabase(String sourceFilePath) async {
    try {
      final dbPath = join(await getDatabasesPath(), 'anime_hat.db');
      final sourceFile = File(sourceFilePath);

      // Verify it's at least a valid file
      if (!await sourceFile.exists()) return false;

      // Overwrite the current DB
      await sourceFile.copy(dbPath);
      return true;
    } catch (e) {
      print('Import failed: $e');
      return false;
    }
  }
}
