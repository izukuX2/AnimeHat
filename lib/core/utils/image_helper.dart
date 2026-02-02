class ImageHelper {
  static const String baseUrl = 'https://animeify.net/animeify/files';

  static String buildUrl(String? path, String category) {
    if (path == null || path.isEmpty) return '';

    // If it's already a full URL, return it
    if (path.startsWith('http')) return path;

    // Remove leading slash if exists
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Some categories might have different subpaths
    String subpath = category;
    if (category == 'characters') {
      subpath = 'characters/photos';
    } else if (category == 'profiles') {
      subpath = 'profiles';
    } else if (category == 'news') {
      subpath = 'news';
    } else if (category == 'sliders') {
      subpath = 'sliders';
    } else if (category == 'thumbnails') {
      subpath = 'thumbnails';
    }

    return '$baseUrl/$subpath/$cleanPath';
  }
}
