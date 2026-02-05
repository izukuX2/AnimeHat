import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/animeify_api_client.dart';
import '../models/anime_model.dart';
import '../services/supabase_archive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatus { idle, syncing, error, success }

class SyncState {
  final SyncStatus status;
  final String message;
  final double progress; // 0.0 to 1.0, or -1 if indeterminate

  const SyncState({
    required this.status,
    required this.message,
    this.progress = -1,
  });
}

class DataSyncService {
  // Singleton Pattern
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final AnimeifyApiClient _apiClient = AnimeifyApiClient();

  // Stream Controller for UI updates (Broadcast so multiple listeners can verify)
  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateController.stream;

  // Internal State
  SyncState _currentState =
      const SyncState(status: SyncStatus.idle, message: '');
  SyncState get currentState => _currentState;

  // Logs
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  void _updateState(SyncStatus status, String message, [double progress = -1]) {
    _currentState =
        SyncState(status: status, message: message, progress: progress);
    _stateController.add(_currentState);

    // Auto-log important messages
    if (status == SyncStatus.error ||
        status == SyncStatus.success ||
        message.startsWith('[BATCH]')) {
      _addLog(status == SyncStatus.error ? '[ERROR] $message' : message);
    }
  }

  void _addLog(String log) {
    // Keep logs reasonable size
    if (_logs.length > 500) _logs.removeAt(0);
    _logs.add(
        '[${DateTime.now().toIso8601String().split('T')[1].split('.')[0]}] $log');
  }

  // --- Public Methods ---

  Future<void> startSyncAnime({bool syncContent = false}) async {
    if (_isSyncing) {
      _addLog('Sync already in progress.');
      return;
    }

    _isSyncing = true;
    _logs.clear();
    _updateState(SyncStatus.syncing, 'Starting Anime Sync...');

    // Run in a microtask/zone to ensure it continues even if the caller awaits and leaves?
    // Actually, making it async detached from UI await is handled by the caller not awaiting,
    // or us managing the future. We will execute logic here.

    try {
      await _executeAnimeSync(syncContent);
      _updateState(SyncStatus.success, 'Sync Completed Successfully.');
    } catch (e, stack) {
      debugPrint('Sync Error: $e\n$stack');
      _updateState(SyncStatus.error, 'Sync Failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> startSyncCharacters() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _logs.clear();
    _updateState(SyncStatus.syncing, 'Starting Character Sync...');

    try {
      await _executeCharacterSync();
      _updateState(SyncStatus.success, 'Characters Sync Completed.');
    } catch (e) {
      _updateState(SyncStatus.error, 'Character Sync Failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void clearLogs() {
    _logs.clear();
    // trigger update if needed, or just let UI pull logs
  }

  Future<void> stopSync() async {
    _isSyncing = false;
    _updateState(SyncStatus.idle, 'Sync Stopped by User.');
    _addLog('Sync process stopped.');
  }

  // --- Internal Logic ---

  Future<void> _executeAnimeSync(bool syncContent) async {
    final prefs = await SharedPreferences.getInstance();
    int from = prefs.getInt('last_anime_sync_offset') ?? 0;

    // Determine total needed or just go until empty?
    // User complaint: "Starts from beginning". Resuming from 'from' solves this.
    // If 'from' is > 0, we are resuming.
    if (from > 0) {
      _addLog('Resuming sync from index $from');
    }

    int totalSynced = 0;
    bool hasMore = true;

    while (hasMore) {
      if (!_isSyncing) break;

      _updateState(SyncStatus.syncing, 'Fetching batch from $from...');

      final List<Anime> batch = await _apiClient.getAnimeList(
        type: 'SERIES',
        from: from,
      );

      if (batch.isEmpty) {
        hasMore = false;
        // Reset offset when fully done?
        // Or keep it so it doesn't re-scan old stuff even if restart?
        // User probably expects "Check for NEW stuff" -> getting from latest is tricky if API doesn't support "Since".
        // But for "Mass Upload", resuming is correct.
        // Once completed, maybe we shouldn't reset automatically unless we want to re-scan.
        _addLog('No more anime found. Sync finished.');
        break;
      }

      _updateState(SyncStatus.syncing,
          '[BATCH] Processing ${batch.length} animes (From: $from)...');

      // ... Process Batch ...
      int processedInBatch = 0;
      const int concurrency = 3;
      for (var i = 0; i < batch.length; i += concurrency) {
        if (!_isSyncing) break; // Check cancellation inner loop

        final end =
            (i + concurrency < batch.length) ? i + concurrency : batch.length;
        final subChunk = batch.sublist(i, end);

        await Future.wait(subChunk.map((anime) async {
          // Check if exists to avoid redundant upload
          final exists =
              await SupabaseArchiveService.doesAnimeExist(anime.animeId);
          if (exists) {
            // Only skip if we are NOT blindly syncing content?
            // User wants to skip re-uploading basic info.
            // We might still want to check episodes if syncContent is true.
            // But usually if anime exists, we assume it's done or we rely on a different update mechanism.
            // For "Mass Upload" logic, jumping over existing is what user wants.
            // We'll log it.
            if (!syncContent) {
              // If we are just archiving anime, skip entirely.
              _addLog('Skipped ${anime.enTitle} (Already exists)');
              return;
            } else {
              // If syncing content, we might want to check episodes even if anime exists.
              // But user said: "It re-uploads everything".
              // Let's assume skipping anime upsert is safe.
              // We still need to check episodes.
              // _addLog('Checking content for ${anime.enTitle}...');
            }
          } else {
            await SupabaseArchiveService.archiveAnime(anime);
          }

          if (syncContent) {
            await _syncEpisodesForAnime(anime);
          }
        }));

        processedInBatch += subChunk.length;
        _updateState(SyncStatus.syncing,
            'Processed $processedInBatch/${batch.length} in current batch');
      }

      totalSynced += batch.length;
      from += batch.length;

      // Save progress
      await prefs.setInt('last_anime_sync_offset', from);

      _updateState(SyncStatus.syncing,
          'Total Synced Session: $totalSynced (Total Offset: $from)');

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> resetSyncProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_anime_sync_offset');
    _addLog('Sync progress reset to 0.');
    _updateState(SyncStatus.idle, 'Progress Reset.');
  }

  Future<void> _syncEpisodesForAnime(Anime anime) async {
    try {
      final episodesData = await _apiClient.getEpisodes(anime.animeId);
      final episodes = episodesData.map((e) => Episode.fromJson(e)).toList();

      if (episodes.isEmpty) return;

      // 1. Archive Episode Metadata (Fast, ensures latest links/dates are updated)
      await SupabaseArchiveService.archiveEpisodes(anime.animeId, episodes);

      // 2. Determine which episodes need Server Sync (Slow)
      // We only fetch servers for episodes that are NOT in Supabase yet.
      final existingEpNums =
          await SupabaseArchiveService.getExistingEpisodeNumbers(anime.animeId);
      final newEpisodes = episodes
          .where((e) => !existingEpNums.contains(e.episodeNumber))
          .toList();

      if (newEpisodes.isEmpty) {
        // _addLog('No new episodes for ${anime.enTitle}');
        return;
      }

      _addLog(
          'Found ${newEpisodes.length} new episodes for ${anime.enTitle}. Syncing servers...');

      // 3. Fetch Servers for NEW episodes only
      const int serverConcurrency = 5;
      for (var i = 0; i < newEpisodes.length; i += serverConcurrency) {
        if (!_isSyncing) break;

        final end = (i + serverConcurrency < newEpisodes.length)
            ? i + serverConcurrency
            : newEpisodes.length;
        final chunk = newEpisodes.sublist(i, end);

        await Future.wait(
            chunk.map((ep) => _syncServers(anime.animeId, ep.episodeNumber)));
      }
    } catch (e) {
      _addLog('Error syncing episodes for ${anime.enTitle}: $e');
    }
  }

  Future<void> _syncServers(String animeId, String episodeNumber) async {
    try {
      final response = await _apiClient.loadServers(
        animeId: animeId,
        episode: episodeNumber,
      );

      final currentEpisode =
          response['CurrentEpisode'] as Map<String, dynamic>? ?? {};
      final servers = <StreamingServer>[];

      final serverMap = {
        'OKLink': 'OK.ru',
        'MALink': 'MyCloud',
        'SVLink': 'Internal 1',
        'LBLink': 'Internal 2',
        'FHLink': 'Full HD',
        'GDLink': 'G-Drive',
        'FRLink': 'MediaFire',
        'SFLink': 'SuperFast',
        'FDLink': 'Internal 3',
      };

      serverMap.forEach((baseKey, name) {
        // Check standard HD quality
        _addServerIfValid(
          servers,
          currentEpisode,
          baseKey,
          name,
          'HD',
          animeId,
          episodeNumber,
        );

        // Check Low quality (SD)
        final lowKey = baseKey.replaceAll('Link', 'LowQ');
        _addServerIfValid(
          servers,
          currentEpisode,
          lowKey,
          name,
          'SD',
          animeId,
          episodeNumber,
        );

        // Check Full HD quality (FHD)
        final fhdKey = baseKey.replaceAll('Link', 'FhdQ');
        _addServerIfValid(
          servers,
          currentEpisode,
          fhdKey,
          name,
          'FHD',
          animeId,
          episodeNumber,
        );
      });

      if (servers.isNotEmpty) {
        await SupabaseArchiveService.archiveServers(
          animeId,
          episodeNumber,
          servers,
        );
      }
    } catch (e) {
      // Silent error for individual server fetch to keep process going
    }
  }

  void _addServerIfValid(
    List<StreamingServer> servers,
    Map<String, dynamic> data,
    String key,
    String name,
    String quality,
    String animeId,
    String episode,
  ) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      if (value == '0') return;

      String url = value;

      if (!url.startsWith('http')) {
        if (key.contains('OK')) {
          url = 'https://ok.ru/videoembed/$value';
        } else if (key.contains('FR')) {
          url = 'https://www.mediafire.com/file/$value';
        } else if (key.contains('MA')) {
          url = 'https://mycloud.click/v/$value';
        } else if (key.contains('SV') ||
            key.contains('LB') ||
            key.contains('FD') ||
            key.contains('FH')) {
          final serverType = key.substring(0, 2);
          url =
              'https://animeify.net/animeify/player/player.php?v=$value&t=$serverType&id=$animeId&ep=$episode';
        }
      }

      servers.add(StreamingServer(name: name, url: url, quality: quality));
    }
  }

  Future<void> _executeCharacterSync() async {
    int from = 0;
    int totalSynced = 0;
    bool hasMore = true;

    while (hasMore) {
      if (!_isSyncing) break;

      _updateState(SyncStatus.syncing, 'Fetching characters from $from...');
      final batch = await _apiClient.loadCharacters(from: from);

      if (batch.isEmpty) {
        hasMore = false;
        break;
      }

      await SupabaseArchiveService.archiveCharacters(batch);

      totalSynced += batch.length;
      from += batch.length;
      _updateState(SyncStatus.syncing, 'Total Characters: $totalSynced');

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
