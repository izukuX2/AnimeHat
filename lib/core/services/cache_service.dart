import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Centralized caching service for the application
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};

  // Cache duration constants
  static const Duration shortCache = Duration(minutes: 5);
  static const Duration mediumCache = Duration(hours: 1);
  static const Duration longCache = Duration(days: 1);

  /// Initialize the cache service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get data from cache (memory first, then disk)
  T? get<T>(String key) {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key] as _CacheEntry<T>?;
      if (cached != null && !cached.isExpired) {
        return cached.data;
      }
      _memoryCache.remove(key);
    }

    // Check disk cache
    final diskData = _prefs?.getString('cache_$key');
    if (diskData != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(diskData);
        final expiryTime = DateTime.parse(json['expiry'] as String);
        if (DateTime.now().isBefore(expiryTime)) {
          final data = json['data'] as T;
          // Restore to memory cache
          _memoryCache[key] = _CacheEntry<T>(data, expiryTime);
          return data;
        }
        // Expired, remove it
        _prefs?.remove('cache_$key');
      } catch (e) {
        _prefs?.remove('cache_$key');
      }
    }

    return null;
  }

  /// Store data in cache
  Future<void> set<T>(
    String key,
    T data, {
    Duration duration = const Duration(hours: 1),
  }) async {
    final expiryTime = DateTime.now().add(duration);

    // Store in memory
    _memoryCache[key] = _CacheEntry<T>(data, expiryTime);

    // Store on disk for persistence
    try {
      final json = jsonEncode({
        'data': data,
        'expiry': expiryTime.toIso8601String(),
      });
      await _prefs?.setString('cache_$key', json);
    } catch (e) {
      // JSON encoding failed, only keep in memory
    }
  }

  /// Remove specific key from cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove('cache_$key');
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    final keys = _prefs?.getKeys().where((k) => k.startsWith('cache_')) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }

  /// Clear expired entries
  Future<void> clearExpired() async {
    // Clear expired memory cache
    _memoryCache.removeWhere((_, entry) => (entry as _CacheEntry).isExpired);

    // Clear expired disk cache
    final keys = _prefs?.getKeys().where((k) => k.startsWith('cache_')) ?? [];
    for (final key in keys) {
      final data = _prefs?.getString(key);
      if (data != null) {
        try {
          final json = jsonDecode(data);
          final expiry = DateTime.parse(json['expiry'] as String);
          if (DateTime.now().isAfter(expiry)) {
            await _prefs?.remove(key);
          }
        } catch (e) {
          await _prefs?.remove(key);
        }
      }
    }
  }

  /// Cache with fetch function - returns cached data or fetches and caches new data
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration duration = const Duration(hours: 1),
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = get<T>(key);
      if (cached != null) {
        return cached;
      }
    }

    final data = await fetcher();
    await set<T>(key, data, duration: duration);
    return data;
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime expiryTime;

  _CacheEntry(this.data, this.expiryTime);

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

/// Widget for displaying cached network images with shimmer placeholder and error handling
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) =>
          placeholder ?? _buildShimmerPlaceholder(isDark),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 40,
            ),
          ),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildShimmerPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!]
              : [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[300]!],
        ),
      ),
      child: _ShimmerEffect(
        isDark: isDark,
        child: Container(color: isDark ? Colors.grey[700] : Colors.grey[200]),
      ),
    );
  }
}

/// Shimmer animation effect widget
class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const _ShimmerEffect({required this.child, required this.isDark});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [Colors.grey[800]!, Colors.grey[600]!, Colors.grey[800]!]
                  : [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
