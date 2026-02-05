import 'package:flutter/foundation.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../../../core/models/anime_model.dart';

class ScheduleRepository {
  final AnimeifyApiClient apiClient;

  ScheduleRepository({required this.apiClient});

  Future<Map<String, List<Anime>>> getWeeklySchedule() async {
    final Map<String, List<Anime>> schedule = {
      'monday': [],
      'tuesday': [],
      'wednesday': [],
      'thursday': [],
      'friday': [],
      'saturday': [],
      'sunday': [],
    };

    try {
      // Map keys to API broadcast values
      final apiDays = {
        'monday': 'MONDAY',
        'tuesday': 'TUESDAY',
        'wednesday': 'WEDNESDAY',
        'thursday': 'THURSDAY',
        'friday': 'FRIDAY',
        'saturday': 'SATURDAY',
        'sunday': 'SUNDAY',
      };

      for (var day in schedule.keys) {
        try {
          final broadcastValue = apiDays[day]!;
          // Using loadExplore because it's more specialized for this kind of filtering
          // Premiere can be empty or we can pass a reasonable default if needed
          final data = await apiClient.loadExplore(
            broadcast: broadcastValue,
            premiere: '',
          );

          final List? list = data['Schedule'] ??
              data['AnimeList'] ??
              data['Broadcast'] ??
              data['Anime'];
          if (list != null) {
            schedule[day] = list.map((item) => Anime.fromJson(item)).toList();
            debugPrint(
              'DEBUG: App Schedule for $day returned ${schedule[day]!.length} items',
            );
          } else {
            debugPrint(
              'DEBUG: App Schedule for $day - no list found in keys: ${data.keys.toList()}',
            );
          }
        } catch (e) {
          debugPrint('DEBUG: Error fetching App schedule for $day: $e');
        }
        // Small delay to be safe, though our own API usually has higher limits
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return schedule;
    } catch (e) {
      debugPrint('DEBUG: ScheduleRepository Overall Error: $e');
      return schedule;
    }
  }
}
