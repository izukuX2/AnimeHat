import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_helper.dart';

class AppNetworkImage extends StatelessWidget {
  final String? path;
  final String category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppNetworkImage({
    super.key,
    required this.path,
    required this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final url = ImageHelper.buildUrl(path, category);

    if (url.isEmpty) {
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: _buildError())
          : _buildError();
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) {
        print('DEBUG: Image Load Error ($category): $url - $error');
        return _buildError();
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.withOpacity(0.1),
          child: Icon(
            _getFallbackIcon(),
            size: (width != null && width! < 30) ? 12 : 30,
            color: Colors.grey,
          ),
        );
  }

  IconData _getFallbackIcon() {
    switch (category) {
      case 'profiles':
        return LucideIcons.user;
      case 'characters':
        return LucideIcons.smile;
      case 'news':
        return LucideIcons.newspaper;
      case 'sliders':
      case 'thumbnails':
      default:
        return LucideIcons.film;
    }
  }
}
