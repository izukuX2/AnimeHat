class GithubRelease {
  final String tagName;
  final String name;
  final String body;
  final String publishedAt;
  final String htmlUrl;
  final List<GithubAsset> assets;

  GithubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    return GithubRelease(
      tagName: json['tag_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      htmlUrl: json['html_url']?.toString() ?? '',
      assets: (json['assets'] as List?)
              ?.map((e) => GithubAsset.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get version => tagName.replaceAll('v', '');
}

class GithubAsset {
  final String name;
  final String browserDownloadUrl;
  final int size;
  final int downloadCount;

  GithubAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
    required this.downloadCount,
  });

  factory GithubAsset.fromJson(Map<String, dynamic> json) {
    return GithubAsset(
      name: json['name']?.toString() ?? '',
      browserDownloadUrl: json['browser_download_url']?.toString() ?? '',
      size: int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      downloadCount:
          int.tryParse(json['download_count']?.toString() ?? '0') ?? 0,
    );
  }
}
