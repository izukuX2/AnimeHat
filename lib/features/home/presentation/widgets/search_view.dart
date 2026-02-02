import 'package:flutter/material.dart';
import '../../../../core/models/anime_model.dart';
import '../../data/home_repository.dart';
import 'anime_card.dart';

class SearchView extends StatefulWidget {
  final HomeRepository repository;
  final Future<AppConfiguration> configFuture;

  const SearchView({
    super.key,
    required this.repository,
    required this.configFuture,
  });

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  Future<List<Anime>>? _resultsFuture;
  bool _hasSearched = false;

  String? _selectedYear;
  String? _selectedStudio;

  void _onSearch() {
    final query = _controller.text.trim();

    setState(() {
      if (query.isNotEmpty) {
        _resultsFuture = widget.repository.searchAnime(query);
      } else if (_selectedYear != null || _selectedStudio != null) {
        // Handle filter-only search if query is empty
        _resultsFuture = widget.repository.getFilteredAnime(
          year: _selectedYear,
          studio: _selectedStudio,
        );
      } else {
        return;
      }
      _hasSearched = true;
    });
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _onSearch(),
        decoration: InputDecoration(
          hintText: 'Search anime...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send_rounded),
            onPressed: _onSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          _buildSearchField(isDark),
          const SizedBox(height: 16),
          _buildFilters(isDark),
          const SizedBox(height: 20),
          Expanded(child: _buildResultsView()),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return FutureBuilder<AppConfiguration>(
      future: widget.configFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final config = snapshot.data!;

        return Column(
          children: [
            _buildFilterRow(
              title: "Year",
              items: config.years,
              selectedItem: _selectedYear,
              onSelected: (val) {
                setState(
                  () => _selectedYear = val == _selectedYear ? null : val,
                );
                _onSearch();
              },
            ),
            const SizedBox(height: 12),
            _buildFilterRow(
              title: "Studio",
              items: config.studios,
              selectedItem: _selectedStudio,
              onSelected: (val) {
                setState(
                  () => _selectedStudio = val == _selectedStudio ? null : val,
                );
                _onSearch();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow({
    required String title,
    required List<String> items,
    required String? selectedItem,
    required Function(String) onSelected,
  }) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selectedItem;
          return FilterChip(
            label: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87),
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(item),
            selectedColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildResultsView() {
    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Find your favorite anime",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Anime>>(
      future: _resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        final results = snapshot.data!;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final anime = results[index];
            return AnimeCard(
              title: anime.enTitle,
              imageUrl:
                  'https://animeify.net/animeify/files/thumbnails/${anime.thumbnail}',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/anime-details',
                  arguments: anime,
                );
              },
            );
          },
        );
      },
    );
  }
}
