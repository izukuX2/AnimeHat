import 'package:flutter/material.dart';

/// Enhanced shimmer loading widget with beautiful gradient animations
/// A scope that provides a synchronized animation for all shimmers
class ShimmerScope extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerScope({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
  });

  static Animation<double>? of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ShimmerScopeInherited>();
    return scope?.animation;
  }

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScopeInherited(animation: _animation, child: widget.child);
  }
}

class _ShimmerScopeInherited extends InheritedWidget {
  final Animation<double> animation;

  const _ShimmerScopeInherited({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_ShimmerScopeInherited oldWidget) =>
      animation != oldWidget.animation;
}

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
    this.child,
  });

  factory ShimmerLoading.circular({Key? key, required double size}) {
    return ShimmerLoading(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  factory ShimmerLoading.text({
    Key? key,
    double width = 100,
    double height = 16,
  }) {
    return ShimmerLoading(
      key: key,
      width: width,
      height: height,
      borderRadius: 6,
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;
  Animation<double>? _localAnimation;

  @override
  void initState() {
    super.initState();
    // Only create local controller if no scope exists
  }

  void _ensureLocalController() {
    if (_localController == null) {
      _localController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
      _localAnimation = Tween<double>(begin: -2.5, end: 2.5).animate(
        CurvedAnimation(parent: _localController!, curve: Curves.easeInOut),
      );
      _localController!.repeat();
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scopeAnimation = ShimmerScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200;
    final highlightColor =
        isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100;

    if (scopeAnimation == null) {
      _ensureLocalController();
    }

    final animation = scopeAnimation ?? _localAnimation!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(animation.value - 1, -0.3),
              end: Alignment(animation.value + 1, 0.3),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerAnimeCard extends StatelessWidget {
  const ShimmerAnimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, // More compact width
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster - Adjusted height to fit within 240-250px total
          const ShimmerLoading(width: 150, height: 200, borderRadius: 20),
          const SizedBox(height: 10),
          // Title
          ShimmerLoading.text(width: 130, height: 14),
          const SizedBox(height: 6),
          // Subtitle
          ShimmerLoading.text(width: 80, height: 12),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for list items
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Thumbnail
          const ShimmerLoading(width: 90, height: 130, borderRadius: 16),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.text(width: double.infinity, height: 18),
                const SizedBox(height: 10),
                ShimmerLoading.text(width: 180, height: 14),
                const SizedBox(height: 12),
                ShimmerLoading.text(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer grid for anime sections
class ShimmerAnimeGrid extends StatelessWidget {
  final int itemCount;
  final double aspectRatio;

  const ShimmerAnimeGrid({
    super.key,
    this.itemCount = 6,
    this.aspectRatio = 0.58, // Adjusted for new card ratio
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: ShimmerLoading(borderRadius: 20)),
            const SizedBox(height: 10),
            ShimmerLoading.text(width: double.infinity, height: 12),
            const SizedBox(height: 4),
            ShimmerLoading.text(width: 60, height: 10),
          ],
        );
      },
    );
  }
}

/// Shimmer for profile header
class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner
        const ShimmerLoading(
          width: double.infinity,
          height: 180,
          borderRadius: 0,
        ),
        Transform.translate(
          offset: const Offset(0, -50),
          child: Column(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ShimmerLoading.circular(size: 110),
              ),
              const SizedBox(height: 16),
              // Name
              ShimmerLoading.text(width: 180, height: 22),
              const SizedBox(height: 10),
              // Bio
              ShimmerLoading.text(width: 240, height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer for horizontal carousel
class ShimmerCarousel extends StatelessWidget {
  final int itemCount;
  final double height;

  const ShimmerCarousel({super.key, this.itemCount = 4, this.height = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const ShimmerAnimeCard();
        },
      ),
    );
  }
}

/// Skeleton loader wrapper
class SkeletonLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? skeleton;

  const SkeletonLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.skeleton,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return skeleton ?? const ShimmerLoading();
    }
    return child;
  }
}
