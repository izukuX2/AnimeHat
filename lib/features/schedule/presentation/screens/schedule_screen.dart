import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../data/schedule_repository.dart';
import '../../../../core/models/anime_model.dart';
import '../../../home/presentation/widgets/anime_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScheduleRepository _repository = ScheduleRepository(
    apiClient: AnimeifyApiClient(),
  );
  Map<String, List<Anime>> _schedule = {};
  bool _isLoading = true;
  Timer? _countdownTimer;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadSchedule();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadSchedule() async {
    final data = await _repository.getWeeklySchedule();
    if (mounted) {
      setState(() {
        _schedule = data;
        _isLoading = false;
      });
      // Set to current day
      final now = DateTime.now();
      final currentDay = (now.weekday - 1) % 7;
      _tabController.animateTo(currentDay);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.broadcastSchedule),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days
              .map((day) => Tab(text: _getDayLabel(day, context)))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _days
                  .map((day) => _buildDayList(_schedule[day] ?? []))
                  .toList(),
            ),
    );
  }

  String _getDayLabel(String day, BuildContext context) {
    switch (day) {
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  Widget _buildDayList(List<Anime> animes) {
    if (animes.isEmpty) {
      return const Center(child: Text("No anime scheduled for this day"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: animes.length,
      itemBuilder: (context, index) {
        final anime = animes[index];
        final countdown = _getCountdown(anime.broadcast);

        return Stack(
          children: [
            AnimeCard(
              title: anime.enTitle,
              imageUrl: anime.thumbnail,
              onTap: () => Navigator.pushNamed(
                context,
                '/anime-details',
                arguments: anime,
              ),
            ),
            if (countdown != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        countdown,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String? _getCountdown(String broadcast) {
    if (broadcast.isEmpty || broadcast == 'Unknown') return null;

    // Simplified parsing: "Tuesdays at 23:30 (JST)"
    // Extraction of time only for simple display if we can't do full countdown easily
    final timeMatch = RegExp(r'(\d{2}:\d{2})').firstMatch(broadcast);
    if (timeMatch == null) return null;

    final timeStr = timeMatch.group(1)!;
    return timeStr; // Return the time for now, or I can implement diff logic if needed
  }
}
