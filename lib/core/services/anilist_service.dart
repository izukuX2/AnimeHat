import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnilistService {
  static const String clientId = '35518';
  static const String redirectUri = 'animehat://auth';

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://graphql.anilist.co'));

  Future<void> login() async {
    final url = Uri.parse(
      'https://anilist.co/api/v2/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&response_type=code',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> handleCallback(String code) async {
    // Exchange code for token logic placeholder
  }

  Future<void> updateAnimeStatus({
    required int mediaId,
    required String status,
    required int progress,
    int? score,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('anilist_access_token');
    if (token == null) return;

    const query = r'''
      mutation ($mediaId: Int, $status: MediaListStatus, $progress: Int, $score: Float) {
        SaveMediaListEntry (mediaId: $mediaId, status: $status, progress: $progress, score: $score) {
          id
          status
          progress
        }
      }
    ''';

    try {
      await _dio.post(
        '/',
        data: {
          'query': query,
          'variables': {
            'mediaId': mediaId,
            'status': status,
            'progress': progress,
            'score': score?.toDouble(),
          },
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('Anilist update error: $e');
    }
  }
}
