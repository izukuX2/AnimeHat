import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/anime_model.dart';

class AnimeFirestoreRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveAnime(Anime anime, [AnimeDetails? details]) async {
    if (anime.animeId.isEmpty) return;
    await _db.collection('anime').doc(anime.animeId).set({
      'metadata': anime.toMap(),
      if (details != null)
        'details': {
          'plot': details.plot,
          'synopsis': details.synopsis,
          'background': details.background,
          'popularity': details.popularity,
          'members': details.members,
          'favorites': details.favorites,
          'statistics': {
            'userRate': details.statistics.userRate,
            'views': details.statistics.views,
            'rates': details.statistics.rates,
          },
        },
      'cachedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAnimesBatch(List<Anime> animes) async {
    if (animes.isEmpty) return;
    final batch = _db.batch();
    for (var anime in animes) {
      if (anime.animeId.isEmpty) continue;
      final docRef = _db.collection('anime').doc(anime.animeId);
      batch.set(docRef, {
        'metadata': anime.toMap(),
        'cachedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getCachedAnime(String animeId) async {
    if (animeId.isEmpty) return null;
    final doc = await _db.collection('anime').doc(animeId).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<void> saveEpisodes(String animeId, List<Episode> episodes) async {
    if (animeId.isEmpty || episodes.isEmpty) return;
    final batch = _db.batch();
    final collection = _db
        .collection('anime')
        .doc(animeId)
        .collection('episodes');

    for (var ep in episodes) {
      if (ep.episodeNumber.isEmpty) continue;
      batch.set(collection.doc(ep.episodeNumber), {
        'eId': ep.eId,
        'animeId': ep.animeId,
        'episodeNumber': ep.episodeNumber,
        'okLink': ep.okLink,
        'maLink': ep.maLink,
        'frLink': ep.frLink,
        'gdLink': ep.gdLink,
        'svLink': ep.svLink,
        'released': ep.released,
      });
    }
    await batch.commit();
  }

  Future<List<Episode>?> getCachedEpisodes(String animeId) async {
    if (animeId.isEmpty) return null;
    final snapshot = await _db
        .collection('anime')
        .doc(animeId)
        .collection('episodes')
        .orderBy('episodeNumber')
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.map((doc) => Episode.fromJson(doc.data())).toList();
  }

  Future<void> saveServers(
    String animeId,
    String episodeNumber,
    List<StreamingServer> servers,
  ) async {
    if (animeId.isEmpty || episodeNumber.isEmpty) return;
    await _db
        .collection('anime')
        .doc(animeId)
        .collection('episodes')
        .doc(episodeNumber)
        .set({
          'servers': servers
              .map((s) => {'name': s.name, 'url': s.url, 'quality': s.quality})
              .toList(),
          'serversCachedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<List<StreamingServer>?> getCachedServers(
    String animeId,
    String episodeNumber,
  ) async {
    if (animeId.isEmpty || episodeNumber.isEmpty) return null;
    final doc = await _db
        .collection('anime')
        .doc(animeId)
        .collection('episodes')
        .doc(episodeNumber)
        .get();

    if (doc.exists && doc.data()?.containsKey('servers') == true) {
      final List<dynamic> serversJson = doc.data()!['servers'];
      return serversJson
          .map(
            (s) => StreamingServer(
              name: s['name'],
              url: s['url'],
              quality: s['quality'],
            ),
          )
          .toList();
    }
    return null;
  }

  // --- Global Sync Coordination ---

  Future<Map<String, dynamic>?> getGlobalSyncStatus() async {
    final doc = await _db.collection('sync').doc('global_status').get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> claimGlobalSyncLock(String userId) async {
    await _db.collection('sync').doc('global_status').set({
      'isSyncing': true,
      'startedBy': userId,
      'lastHeartbeat': FieldValue.serverTimestamp(),
      'status': 'Starting sync...',
      'currentCategory': 'None',
      'processedCount': 0,
    }, SetOptions(merge: true));
  }

  Future<void> updateSyncHeartbeat({
    required String category,
    required int processed,
    String? status,
  }) async {
    await _db.collection('sync').doc('global_status').set({
      'lastHeartbeat': FieldValue.serverTimestamp(),
      'currentCategory': category,
      'processedCount': processed,
      if (status != null) 'status': status,
    }, SetOptions(merge: true));
  }

  Future<void> releaseGlobalSyncLock() async {
    await _db.collection('sync').doc('global_status').set({
      'isSyncing': false,
      'lastHeartbeat': FieldValue.serverTimestamp(),
      'status': 'Idle',
    }, SetOptions(merge: true));
  }
}
