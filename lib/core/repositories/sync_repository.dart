import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sync_settings.dart';
import '../services/data_sync_service.dart';

class SyncProgress {
  final String currentCategory;
  final int syncedCount;
  final int totalCount;
  final String status;
  final bool isComplete;

  SyncProgress({
    required this.currentCategory,
    required this.syncedCount,
    required this.totalCount,
    this.status = 'Syncing...',
    this.isComplete = false,
  });

  double get percent => totalCount > 0 ? syncedCount / totalCount : 0;
}

class SyncRepository {
  static final SyncRepository _instance = SyncRepository._internal();
  factory SyncRepository() => _instance;
  SyncRepository._internal() {
    // Bridge DataSyncService state to SyncProgress
    DataSyncService().stateStream.listen((state) {
      _syncProgressController.add(SyncProgress(
          currentCategory: 'Updating...',
          syncedCount: (state.progress * 100).toInt(),
          totalCount: 100,
          status: state.message,
          isComplete: state.status == SyncStatus.success));
    });
  }

  // final AnimeifyApiClient _apiClient = AnimeifyApiClient();
  // final AnimeFirestoreRepository _firestore = AnimeFirestoreRepository();

  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get syncProgress => _syncProgressController.stream;

  SyncSettings _settings = SyncSettings();
  SyncSettings get settings => _settings;

  bool get isSyncing => DataSyncService().isSyncing;

  void updateSettings(SyncSettings newSettings) {
    _settings = newSettings;
    debugPrint(
      'DEBUG: Sync settings updated: Enabled=${_settings.isEnabled}, Speed=${_settings.speed.label}',
    );
  }

  /// Syncs immediately relevant content (Latest, Home data)
  Future<void> syncLatestContent() async {
    debugPrint('DEBUG: Starting Latest Content Sync via DataSyncService');
    await DataSyncService().startSyncAnime(syncContent: true);
  }

  /// Efficiently syncs the library using batching and parallel processing
  Future<void> startIncrementalSync({bool force = false}) async {
    debugPrint('DEBUG: Starting Incremental Sync via DataSyncService');
    await DataSyncService().startSyncAnime(syncContent: true);
  }

  void dispose() {
    _syncProgressController.close();
  }
}
