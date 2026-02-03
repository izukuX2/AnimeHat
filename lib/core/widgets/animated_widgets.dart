import 'package:flutter/material.dart';

/// A card widget with beautiful hover/tap animations
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final Duration animationDuration;
  final double scaleOnTap;
  final bool enableGlow;
  final Color? glowColor;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevation = 4,
    this.borderRadius = 16,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleOnTap = 0.98,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnTap,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.cardColor;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                  if (widget.enableGlow)
                    BoxShadow(
                      color: (widget.glowColor ?? theme.primaryColor)
                          .withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Material(color: bgColor, child: widget.child),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A fade-in animation wrapper
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset? slideOffset;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.slideOffset,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset ?? const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Staggered list animation
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: List.generate(children.length, (index) {
        return FadeInWidget(
          delay: Duration(milliseconds: itemDelay.inMilliseconds * index),
          duration: itemDuration,
          child: children[index],
        );
      }),
    );
  }
}

/// Pulse animation for loading indicators
class PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Hero-like animated container for smooth transitions
class AnimatedHeroCard extends StatelessWidget {
  final String tag;
  final Widget child;
  final double borderRadius;

  const AnimatedHeroCard({
    super.key,
    required this.tag,
    required this.child,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      borderRadius * (1 - animation.value * 0.5),
                    ),
                    child: child,
                  ),
                );
              },
            );
          },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
