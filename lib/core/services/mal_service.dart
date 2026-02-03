import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MalService {
  static const String clientId = 'e727d66e561a4b88586ba6c695f4e05f';
  static const String redirectUri = 'animehat://auth';

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.myanimelist.net/v2'));

  Future<void> login() async {
    final url = Uri.parse(
      'https://myanimelist.net/v1/oauth2/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> handleCallback(String code) async {
    // This would typically involve exchanging code for tokens
    // For now, it's a placeholder for the logic
  }

  Future<void> updateAnimeStatus(String malId, String status, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('mal_access_token');
    if (token == null) return;

    try {
      await _dio.patch(
        '/anime/$malId/my_list_status',
        data: {'status': status, 'score': score},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      // Handle error
    }
  }
}
