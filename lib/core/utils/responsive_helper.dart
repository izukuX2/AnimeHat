import 'package:flutter/material.dart';

/// Utility class for responsive design and adaptive layouts
class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Get responsive grid column count
  static int getGridColumns(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }

  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 16;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
        return 48;
    }
  }

  /// Get responsive card size
  static double getCardWidth(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 140;
      case DeviceType.tablet:
        return 160;
      case DeviceType.desktop:
        return 180;
    }
  }

  /// Get responsive font size multiplier
  static double getFontScale(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
    }
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  /// Get screen size
  static Size getScreenSize(BuildContext context) =>
      MediaQuery.of(context).size;

  /// Calculate responsive value based on screen width
  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.2;
      case DeviceType.desktop:
        return desktop ?? mobile * 1.4;
    }
  }
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop }

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper.getDeviceType(context));
  }
}

/// Widget that shows different children based on device type
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final type = ResponsiveHelper.getDeviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Adaptive grid view that adjusts columns based on screen size
class AdaptiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const AdaptiveGridView({
    super.key,
    required this.children,
    this.spacing = 12,
    this.childAspectRatio,
    this.padding,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final type = ResponsiveHelper.getDeviceType(context);
    int columns;
    switch (type) {
      case DeviceType.mobile:
        columns = mobileColumns ?? 2;
        break;
      case DeviceType.tablet:
        columns = tabletColumns ?? 3;
        break;
      case DeviceType.desktop:
        columns = desktopColumns ?? 4;
        break;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding:
          padding ??
          EdgeInsets.all(ResponsiveHelper.getHorizontalPadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio ?? 0.65,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Extension on BuildContext for easy access
extension ResponsiveExtension on BuildContext {
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  bool get isLandscape => ResponsiveHelper.isLandscape(this);
  Size get screenSize => ResponsiveHelper.getScreenSize(this);
}
