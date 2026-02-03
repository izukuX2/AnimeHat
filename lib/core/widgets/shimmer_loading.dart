import 'package:flutter/material.dart';

/// Enhanced shimmer loading widget with beautiful gradient animations
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

  /// Creates a circular shimmer (for avatars)
  factory ShimmerLoading.circular({Key? key, required double size}) {
    return ShimmerLoading(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Creates a text-like shimmer
  factory ShimmerLoading.text({
    Key? key,
    double width = 100,
    double height = 16,
  }) {
    return ShimmerLoading(
      key: key,
      width: width,
      height: height,
      borderRadius: 4,
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
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

/// Shimmer card placeholder for anime cards
class ShimmerAnimeCard extends StatelessWidget {
  const ShimmerAnimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          const ShimmerLoading(width: 140, height: 200, borderRadius: 12),
          const SizedBox(height: 8),
          // Title
          ShimmerLoading.text(width: 120, height: 14),
          const SizedBox(height: 4),
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
          const ShimmerLoading(width: 80, height: 120, borderRadius: 8),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.text(width: double.infinity, height: 18),
                const SizedBox(height: 8),
                ShimmerLoading.text(width: 150, height: 14),
                const SizedBox(height: 12),
                ShimmerLoading.text(width: 100, height: 12),
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
    this.aspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ShimmerLoading(borderRadius: 12)),
            const SizedBox(height: 8),
            ShimmerLoading.text(width: double.infinity, height: 12),
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
          height: 150,
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
                ),
                child: ShimmerLoading.circular(size: 100),
              ),
              const SizedBox(height: 12),
              // Name
              ShimmerLoading.text(width: 150, height: 20),
              const SizedBox(height: 8),
              // Bio
              ShimmerLoading.text(width: 200, height: 14),
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

  const ShimmerCarousel({super.key, this.itemCount = 4, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 50,
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
