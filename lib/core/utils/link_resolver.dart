import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class LinkResolver {
  /// Resolves a MediaFire link to a direct download/stream link.
  /// Returns the original URL if it's not a MediaFire link or if resolution fails.
  static Future<String> resolve(String url) async {
    if (!url.contains('mediafire.com')) {
      return url;
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode != 200) {
        return url;
      }

      final document = parse(response.body);

      // Look for the download button which has the direct link
      final downloadBtn = document.getElementById('downloadButton');
      if (downloadBtn != null) {
        final directLink = downloadBtn.attributes['href'];
        if (directLink != null && directLink.isNotEmpty) {
          return directLink;
        }
      }

      // Fallback: search for any link with "download" in class or typical mediafire download patterns
      final links = document.getElementsByTagName('a');
      for (final link in links) {
        final href = link.attributes['href'];
        if (href != null &&
            href.contains('download') &&
            href.contains('mediafire.com')) {
          return href;
        }
      }

      return url;
    } catch (e) {
      print('Error resolving MediaFire link: $e');
      return url;
    }
  }
}
