import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_helper.dart';

class AppNetworkImage extends StatefulWidget {
  final String? path;
  final String category;
  final String? fallbackCategory;
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
    this.fallbackCategory,
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
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  bool _useFallback = false;

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.category != widget.category) {
      setState(() => _useFallback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _useFallback && widget.fallbackCategory != null
        ? widget.fallbackCategory!
        : widget.category;
    final url = ImageHelper.buildUrl(widget.path, currentCategory);

    if (url.isEmpty) {
      return widget.borderRadius != null
          ? ClipRRect(
              borderRadius: widget.borderRadius!,
              child: _buildError(currentCategory),
            )
          : _buildError(currentCategory);
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      placeholder: (context, url) =>
          widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.withValues(alpha: 0.1),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) {
        debugPrint('DEBUG: Image Load Error ($currentCategory): $url - $error');
        if (!_useFallback && widget.fallbackCategory != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useFallback = true);
          });
          return widget.placeholder ?? const SizedBox.shrink();
        }
        return _buildError(currentCategory);
      },
    );

    if (widget.borderRadius != null) {
      image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildError(String category) {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey.withValues(alpha: 0.1),
          child: Icon(
            _getFallbackIcon(category),
            size: (widget.width != null && widget.width! < 30) ? 12 : 30,
            color: Colors.grey,
          ),
        );
  }

  IconData _getFallbackIcon(String category) {
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
