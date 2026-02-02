import 'package:flutter/material.dart';
import '../../../../core/models/anime_model.dart';
import '../../data/home_repository.dart';
import 'anime_card.dart';

class SeriesView extends StatefulWidget {
  final HomeRepository repository;
  final VoidCallback onRefresh;

  const SeriesView({
    super.key,
    required this.repository,
    required this.onRefresh,
  });

  @override
  State<SeriesView> createState() => _SeriesViewState();
}

class _SeriesViewState extends State<SeriesView> {
  final List<Anime> _series = [];
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final newSeries = await widget.repository.getSeries(_currentPage * 20);
      if (!mounted) return;
      setState(() {
        _series.addAll(newSeries);
        _currentPage++;
        _isLoading = false;
        if (newSeries.length < 20) _hasMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading series: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _series.clear();
          _currentPage = 0;
          _hasMore = true;
        });
        await _loadMore();
        widget.onRefresh();
      },
      child: _series.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemCount: _series.length + (_isLoading && _hasMore ? 3 : 0),
              itemBuilder: (context, index) {
                if (index < _series.length) {
                  final anime = _series[index];
                  return AnimeCard(
                    title: anime.enTitle,
                    imageUrl: anime.thumbnail,
                    isCompact: true,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/anime-details',
                        arguments: anime,
                      );
                    },
                  );
                } else {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
