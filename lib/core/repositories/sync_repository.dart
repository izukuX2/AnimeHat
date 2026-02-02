import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api/animeify_api_client.dart';
import '../models/anime_model.dart';
import '../models/sync_settings.dart';
import 'anime_firestore_repository.dart';

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
  SyncRepository._internal();

  final AnimeifyApiClient _apiClient = AnimeifyApiClient();
  // final AnimeFirestoreRepository _firestore = AnimeFirestoreRepository(); // Disabled

  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get syncProgress => _syncProgressController.stream;

  SyncSettings _settings = SyncSettings();
  SyncSettings get settings => _settings;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  void updateSettings(SyncSettings newSettings) {
    _settings = newSettings;
    print(
      'DEBUG: Sync settings updated: Enabled=${_settings.isEnabled}, Speed=${_settings.speed.label}',
    );
  }

  /// Syncs immediately relevant content (Latest, Home data)
  Future<void> syncLatestContent() async {
    print(
      'DEBUG: Sync is permanently disabled by user request (External Server Planned).',
    );
    return;
  }

  /// Efficiently syncs the library using batching and parallel processing
  Future<void> startIncrementalSync({bool force = false}) async {
    print(
      'DEBUG: Incremental Sync is permanently disabled by user request (External Server Planned).',
    );
    return;
  }

  void dispose() {
    _syncProgressController.close();
  }
}
