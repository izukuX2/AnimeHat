class Anime {
  final String id;
  final String animeId;
  final String enTitle;
  final String jpTitle;
  final String arTitle;
  final String synonyms;
  final String genres;
  final String season;
  final String premiered;
  final String aired;
  final String broadcast;
  final String duration;
  final String thumbnail;
  final String trailer;
  final String ytTrailer;
  final String creators;
  final String status;
  final String episodes;
  final String score;
  final String rank;
  final String popularity;
  final String rating;
  final String type;
  final String views;
  final String malId;

  Anime({
    required this.id,
    required this.animeId,
    required this.enTitle,
    required this.jpTitle,
    required this.arTitle,
    required this.synonyms,
    required this.genres,
    required this.season,
    required this.premiered,
    required this.aired,
    required this.broadcast,
    required this.duration,
    required this.thumbnail,
    required this.trailer,
    required this.ytTrailer,
    required this.creators,
    required this.status,
    required this.episodes,
    required this.score,
    required this.rank,
    required this.popularity,
    required this.rating,
    required this.type,
    required this.views,
    required this.malId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animeId': animeId,
      'enTitle': enTitle,
      'jpTitle': jpTitle,
      'arTitle': arTitle,
      'synonyms': synonyms,
      'genres': genres,
      'season': season,
      'premiered': premiered,
      'aired': aired,
      'broadcast': broadcast,
      'duration': duration,
      'thumbnail': thumbnail,
      'trailer': trailer,
      'ytTrailer': ytTrailer,
      'creators': creators,
      'status': status,
      'episodes': episodes,
      'score': score,
      'rank': rank,
      'popularity': popularity,
      'rating': rating,
      'type': type,
      'views': views,
      'malId': malId,
    };
  }

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      animeId: (json['AnimeId'] ?? json['animeId'] ?? json['anime_id'] ?? '')
          .toString(),
      enTitle: (json['EN_Title'] ?? json['enTitle'] ?? '').toString(),
      jpTitle: (json['JP_Title'] ?? json['jpTitle'] ?? '').toString(),
      arTitle: (json['AR_Title'] ?? json['arTitle'] ?? '').toString(),
      synonyms: (json['Synonyms'] ?? json['synonyms'] ?? '').toString(),
      genres: (json['Genres'] ?? json['genres'] ?? '').toString(),
      season: (json['Season'] ?? json['season'] ?? '').toString(),
      premiered: (json['Premiered'] ?? json['premiered'] ?? '').toString(),
      aired: (json['Aired'] ?? json['aired'] ?? '').toString(),
      broadcast: (json['Broadcast'] ?? json['broadcast'] ?? '').toString(),
      duration: (json['Duration'] ?? json['duration'] ?? '').toString(),
      thumbnail: (json['Thumbnail'] ?? json['thumbnail'] ?? '').toString(),
      trailer: (json['Trailer'] ?? json['trailer'] ?? '').toString(),
      ytTrailer: (json['YTTrailer'] ?? json['ytTrailer'] ?? '').toString(),
      creators: (json['Creators'] ?? json['creators'] ?? '').toString(),
      status: (json['Status'] ?? json['status'] ?? '').toString(),
      episodes: (json['Episodes'] ?? json['episodes'] ?? '').toString(),
      score: (json['Score'] ?? json['score'] ?? '0').toString(),
      rank: (json['Rank'] ?? json['rank'] ?? '0').toString(),
      popularity: (json['Popularity'] ?? json['popularity'] ?? '0').toString(),
      rating: (json['Rating'] ?? json['rating'] ?? '').toString(),
      type: (json['Type'] ?? json['type'] ?? '').toString(),
      views: (json['views'] ?? json['Views'] ?? '0').toString(),
      malId:
          (json['MalId'] ?? json['malId'] ?? json['mal_id'] ?? '0').toString(),
    );
  }
}

class Episode {
  final String eId;
  final String animeId;
  final String episodeNumber;
  final String okLink;
  final String maLink;
  final String frLink;
  final String gdLink;
  final String svLink;
  final String released;

  Episode({
    required this.eId,
    required this.animeId,
    required this.episodeNumber,
    required this.okLink,
    required this.maLink,
    required this.frLink,
    required this.gdLink,
    required this.svLink,
    required this.released,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      eId: (json['eId'] ?? json['Id'] ?? '').toString(),
      animeId: (json['AnimeID'] ?? json['animeId'] ?? '').toString(),
      episodeNumber:
          (json['Episode'] ?? json['episodeNumber'] ?? '').toString(),
      okLink: (json['OKLink'] ?? json['okLink'] ?? '').toString(),
      maLink: (json['MALink'] ?? json['maLink'] ?? '').toString(),
      frLink: (json['FRLink'] ?? json['frLink'] ?? '').toString(),
      gdLink: (json['GDLink'] ?? json['gdLink'] ?? '').toString(),
      svLink: (json['SVLink'] ?? json['svLink'] ?? '').toString(),
      released: (json['Released'] ?? json['released'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eId': eId,
      'animeId': animeId,
      'episodeNumber': episodeNumber,
      'okLink': okLink,
      'maLink': maLink,
      'frLink': frLink,
      'gdLink': gdLink,
      'svLink': svLink,
      'released': released,
    };
  }
}

class AnimeStatistics {
  final String userRate;
  final String views;
  final Map<String, String> rates;

  AnimeStatistics({
    required this.userRate,
    required this.views,
    required this.rates,
  });

  factory AnimeStatistics.fromJson(Map<String, dynamic> json) {
    final rates = <String, String>{};
    for (int i = 1; i <= 10; i++) {
      rates[i.toString()] = json['rates_$i']?.toString() ?? '0';
    }
    return AnimeStatistics(
      userRate: json['UserRate']?.toString() ?? '0',
      views: json['views']?.toString() ?? '0',
      rates: rates,
    );
  }
}

class AnimeDetails {
  final String plot;
  final String synopsis;
  final String background;
  final String popularity;
  final String members;
  final String favorites;
  final AnimeStatistics statistics;
  final List<Anime> relatedAnime;

  AnimeDetails({
    required this.plot,
    required this.synopsis,
    required this.background,
    required this.popularity,
    required this.members,
    required this.favorites,
    required this.statistics,
    required this.relatedAnime,
  });

  factory AnimeDetails.fromJson(Map<String, dynamic> json) {
    final animeData = json['Anime'] ?? json;
    return AnimeDetails(
      plot: (animeData['Plot'] ?? animeData['synopsis'] ?? '').toString(),
      synopsis: (animeData['synopsis'] ?? '').toString(),
      background: (animeData['background'] ?? '').toString(),
      popularity: (animeData['popularity'] ?? '0').toString(),
      members: (animeData['members'] ?? '0').toString(),
      favorites: (animeData['favorites'] ?? '0').toString(),
      statistics: AnimeStatistics.fromJson(json['AnimeStatistics'] ?? json),
      relatedAnime: (json['RelatedAnime'] as List?)
              ?.map((e) => Anime.fromJson(e))
              .toList() ??
          [],
    );
  }

  AnimeDetails copyWith({
    String? plot,
    String? synopsis,
    String? background,
    String? popularity,
    String? members,
    String? favorites,
    AnimeStatistics? statistics,
    List<Anime>? relatedAnime,
  }) {
    return AnimeDetails(
      plot: plot ?? this.plot,
      synopsis: synopsis ?? this.synopsis,
      background: background ?? this.background,
      popularity: popularity ?? this.popularity,
      members: members ?? this.members,
      favorites: favorites ?? this.favorites,
      statistics: statistics ?? this.statistics,
      relatedAnime: relatedAnime ?? this.relatedAnime,
    );
  }
}

class StreamingServer {
  final String name;
  final String url;
  final String quality;

  StreamingServer({required this.name, required this.url, this.quality = 'HD'});
}

class AnimeWithEpisode {
  final Anime anime;
  final Episode episode;

  AnimeWithEpisode({required this.anime, required this.episode});

  factory AnimeWithEpisode.fromJson(Map<String, dynamic> json) {
    return AnimeWithEpisode(
      anime: Anime.fromJson(json['Anime'] ?? json),
      episode: Episode.fromJson(json['Episode'] ?? json),
    );
  }
}

class NewsItem {
  final String id;
  final String title;
  final String glance;
  final String date;
  final String thumbnail;
  final String views;
  final String editorName;
  final String editorImage;

  NewsItem({
    required this.id,
    required this.title,
    required this.glance,
    required this.date,
    required this.thumbnail,
    required this.views,
    required this.editorName,
    required this.editorImage,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final editor = json['Editor'] ?? {};
    return NewsItem(
      id: json['ID']?.toString() ?? '',
      title: json['Title']?.toString() ?? '',
      glance: json['Glance']?.toString() ?? '',
      date: json['Date']?.toString() ?? '',
      thumbnail: json['Thumbnail']?.toString() ?? '',
      views: json['Views']?.toString() ?? '0',
      editorName: editor['FullName']?.toString() ?? 'Admin',
      editorImage: editor['ProfileImage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'glance': glance,
      'date': date,
      'thumbnail': thumbnail,
      'views': views,
      'editorName': editorName,
      'editorImage': editorImage,
    };
  }
}

class AppConfiguration {
  final String currentSeason;
  final List<String> studios;
  final List<String> years;
  final String appDownloadUrl;

  AppConfiguration({
    required this.currentSeason,
    required this.studios,
    required this.years,
    required this.appDownloadUrl,
  });

  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    final config = json['Configurations'] ?? {};
    return AppConfiguration(
      currentSeason: config['current_season']?.toString() ?? '',
      studios: (config['collection_studios'] as String?)
              ?.split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      years: (config['collection_years'] as String?)
              ?.split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      appDownloadUrl: config['app_download_url']?.toString() ?? '',
    );
  }
}

class HomeData {
  final List<AnimeWithEpisode> latestEpisodes;
  final List<Anime> broadcast;
  final List<Anime> premiere;
  final List<NewsItem> latestNews;

  HomeData({
    required this.latestEpisodes,
    required this.broadcast,
    required this.premiere,
    required this.latestNews,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      latestEpisodes: (json['LatestEpisodes'] as List?)
              ?.map((e) => AnimeWithEpisode.fromJson(e))
              .toList() ??
          [],
      broadcast: (json['Broadcast'] as List?)
              ?.map((e) => Anime.fromJson(e))
              .toList() ??
          [],
      premiere:
          (json['Premiere'] as List?)?.map((e) => Anime.fromJson(e)).toList() ??
              [],
      latestNews: (json['LatestNews'] as List?)
              ?.map((e) => NewsItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TrendingItem {
  final String id;
  final String title;
  final String photo;
  final String type; // EPISODE or ANIME
  final Anime? anime;
  final Episode? episode;

  TrendingItem({
    required this.id,
    required this.title,
    required this.photo,
    required this.type,
    this.anime,
    this.episode,
  });

  factory TrendingItem.fromJson(Map<String, dynamic> json) {
    return TrendingItem(
      id: json['Id']?.toString() ?? '',
      title: json['Title']?.toString() ?? '',
      photo: json['Photo']?.toString() ?? '',
      type: json['Type']?.toString() ?? '',
      anime: json['Anime'] != null ? Anime.fromJson(json['Anime']) : null,
      episode:
          json['Episode'] != null ? Episode.fromJson(json['Episode']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'photo': photo,
      'type': type,
      'animeId': anime?.id,
      'episodeId': episode?.eId,
    };
  }
}
