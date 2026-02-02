/// Performance optimization utilities for AnimeHat
/// Uses algorithms and data structures for faster loading and caching
library;

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// LRU (Least Recently Used) Cache implementation for efficient memory management
/// Uses a doubly linked list + HashMap for O(1) access and eviction
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache({this.maxSize = 100});

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    // Move to end (most recently used)
    final value = _cache.remove(key);
    _cache[key] = value as V;
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void remove(K key) => _cache.remove(key);
  void clear() => _cache.clear();
  int get size => _cache.length;
  bool containsKey(K key) => _cache.containsKey(key);
}

/// Request deduplication - prevents duplicate API calls for same resource
class RequestDeduplicator<T> {
  final Map<String, Completer<T>> _pending = {};

  /// Execute a function only once per key while request is in flight
  Future<T> execute(String key, Future<T> Function() fetcher) async {
    if (_pending.containsKey(key)) {
      return _pending[key]!.future;
    }

    final completer = Completer<T>();
    _pending[key] = completer;

    try {
      final result = await fetcher();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pending.remove(key);
    }
  }

  bool isPending(String key) => _pending.containsKey(key);
}

/// Batch loader for efficient bulk loading with debouncing
class BatchLoader<K, V> {
  final Duration batchWindow;
  final Future<Map<K, V>> Function(Set<K> keys) batchFetcher;
  final LRUCache<K, V> _cache = LRUCache(maxSize: 200);

  final Set<K> _pendingKeys = {};
  Timer? _batchTimer;
  Completer<void>? _batchCompleter;

  BatchLoader({
    this.batchWindow = const Duration(milliseconds: 50),
    required this.batchFetcher,
  });

  Future<V?> load(K key) async {
    // Check cache first
    final cached = _cache.get(key);
    if (cached != null) return cached;

    // Add to pending batch
    _pendingKeys.add(key);

    // Schedule batch fetch
    _batchCompleter ??= Completer<void>();
    _batchTimer?.cancel();
    _batchTimer = Timer(batchWindow, _executeBatch);

    await _batchCompleter!.future;
    return _cache.get(key);
  }

  Future<void> _executeBatch() async {
    if (_pendingKeys.isEmpty) return;

    final keysToFetch = Set<K>.from(_pendingKeys);
    _pendingKeys.clear();

    try {
      final results = await batchFetcher(keysToFetch);
      for (final entry in results.entries) {
        _cache.put(entry.key, entry.value);
      }
    } catch (e) {
      debugPrint('BatchLoader error: $e');
    }

    _batchCompleter?.complete();
    _batchCompleter = null;
  }

  void preload(Iterable<K> keys) {
    for (final key in keys) {
      if (!_cache.containsKey(key)) {
        _pendingKeys.add(key);
      }
    }
    _batchTimer?.cancel();
    _batchTimer = Timer(batchWindow, _executeBatch);
  }

  void clear() {
    _cache.clear();
    _pendingKeys.clear();
  }
}

/// Priority queue for loading resources in order of importance
class PriorityLoadingQueue<T> {
  final SplayTreeMap<int, Queue<_QueueItem<T>>> _queues = SplayTreeMap();
  bool _isProcessing = false;
  final int concurrentLimit;

  PriorityLoadingQueue({this.concurrentLimit = 3});

  /// Add item to queue with priority (lower = higher priority)
  Future<T> add(int priority, Future<T> Function() task) {
    final completer = Completer<T>();
    _queues.putIfAbsent(priority, () => Queue());
    _queues[priority]!.add(_QueueItem(task, completer));
    _processQueue();
    return completer.future;
  }

  void _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queues.isNotEmpty) {
      // Get highest priority queue (lowest number)
      final highestPriority = _queues.firstKey()!;
      final queue = _queues[highestPriority]!;

      if (queue.isEmpty) {
        _queues.remove(highestPriority);
        continue;
      }

      final item = queue.removeFirst();
      try {
        final result = await item.task();
        item.completer.complete(result);
      } catch (e) {
        item.completer.completeError(e);
      }
    }

    _isProcessing = false;
  }
}

class _QueueItem<T> {
  final Future<T> Function() task;
  final Completer<T> completer;

  _QueueItem(this.task, this.completer);
}

/// Connection quality monitor for adaptive loading
class ConnectionQualityMonitor {
  double _avgLatencyMs = 100;
  int _requestCount = 0;
  DateTime _lastCheck = DateTime.now();

  ConnectionQuality get quality {
    if (_avgLatencyMs < 100) return ConnectionQuality.excellent;
    if (_avgLatencyMs < 300) return ConnectionQuality.good;
    if (_avgLatencyMs < 700) return ConnectionQuality.fair;
    return ConnectionQuality.poor;
  }

  void recordLatency(Duration latency) {
    _requestCount++;
    // Exponential moving average for smooth updates
    const alpha = 0.3;
    _avgLatencyMs =
        alpha * latency.inMilliseconds + (1 - alpha) * _avgLatencyMs;
    _lastCheck = DateTime.now();
  }

  /// Get recommended image quality based on connection
  ImageQuality get recommendedImageQuality {
    switch (quality) {
      case ConnectionQuality.excellent:
        return ImageQuality.high;
      case ConnectionQuality.good:
        return ImageQuality.medium;
      case ConnectionQuality.fair:
      case ConnectionQuality.poor:
        return ImageQuality.low;
    }
  }

  /// Get recommended batch size for API calls
  int get recommendedBatchSize {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 30;
      case ConnectionQuality.good:
        return 20;
      case ConnectionQuality.fair:
        return 10;
      case ConnectionQuality.poor:
        return 5;
    }
  }
}

enum ConnectionQuality { excellent, good, fair, poor }

enum ImageQuality { low, medium, high }

/// Prefetching manager for intelligent preloading
class PrefetchManager {
  final int maxConcurrent;
  int _currentActive = 0;
  final Queue<Future<void> Function()> _queue = Queue();

  PrefetchManager({this.maxConcurrent = 2});

  void prefetch(Future<void> Function() task) {
    if (_currentActive < maxConcurrent) {
      _executeTask(task);
    } else {
      _queue.add(task);
    }
  }

  Future<void> _executeTask(Future<void> Function() task) async {
    _currentActive++;
    try {
      await task();
    } catch (e) {
      // Silently fail prefetch
    } finally {
      _currentActive--;
      if (_queue.isNotEmpty) {
        _executeTask(_queue.removeFirst());
      }
    }
  }

  void clear() {
    _queue.clear();
  }
}

/// Global performance optimizer instance
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._();
  static PerformanceOptimizer get instance => _instance;

  PerformanceOptimizer._();

  final requestDeduplicator = RequestDeduplicator<dynamic>();
  final connectionMonitor = ConnectionQualityMonitor();
  final prefetchManager = PrefetchManager();
  final LRUCache<String, dynamic> dataCache = LRUCache(maxSize: 500);

  /// Measure and record API call latency
  Future<T> measureRequest<T>(Future<T> Function() request) async {
    final start = DateTime.now();
    try {
      return await request();
    } finally {
      connectionMonitor.recordLatency(DateTime.now().difference(start));
    }
  }

  /// Get cached data or fetch with deduplication
  Future<T> getCachedOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? maxAge,
  }) async {
    final cached = dataCache.get(key);
    if (cached != null) return cached as T;

    final result = await requestDeduplicator.execute(key, fetcher);
    dataCache.put(key, result);
    return result;
  }
}
