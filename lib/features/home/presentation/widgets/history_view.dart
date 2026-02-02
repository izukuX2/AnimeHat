import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/theme/app_colors.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Center(child: Text("Please login to view history"));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No history found"));
        }

        final appUser = AppUser.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
        );
        final history = appUser.history;

        if (history.isEmpty) {
          return const Center(child: Text("Your watch history is empty"));
        }

        // Sort by most recently watched
        history.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _navigateToAnime(context, item.animeId);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppNetworkImage(
                          path: item.imageUrl,
                          category: 'thumbnails',
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Episode ${item.episodeNumber}",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: item.totalDurationInMs > 0
                                  ? item.positionInMs / item.totalDurationInMs
                                  : 0,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_formatDuration(item.positionInMs)} / ${_formatDuration(item.totalDurationInMs)}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow_rounded),
                        color: AppColors.primary,
                        onPressed: () {
                          _navigateToAnime(context, item.animeId);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToAnime(BuildContext context, String animeId) {
    final dummyAnime = Anime(
      id: '',
      animeId: animeId,
      enTitle: "Loading...",
      jpTitle: "",
      arTitle: "",
      synonyms: "",
      genres: "",
      season: "",
      premiered: "",
      aired: "",
      broadcast: "",
      duration: "",
      thumbnail: "",
      trailer: "",
      ytTrailer: "",
      creators: "",
      status: "",
      episodes: "",
      score: "",
      rank: "",
      popularity: "",
      rating: "",
      type: "",
      views: "",
      malId: "0",
    );
    Navigator.pushNamed(context, '/anime-details', arguments: dummyAnime);
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return "00:00";
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
