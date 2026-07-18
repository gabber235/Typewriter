import "package:flutter/material.dart";
import "package:responsive_framework/responsive_framework.dart";

extension BuildContextX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

extension ResponsiveBreakpointsX on BuildContext {
  bool get isMobile => ResponsiveBreakpoints.of(this).isMobile;
  bool get isTablet => ResponsiveBreakpoints.of(this).isTablet;
  bool get isDesktop => ResponsiveBreakpoints.of(this).isDesktop;
  bool get is4K => ResponsiveBreakpoints.of(this).breakpoint.name == "4K";

  bool isSmallerThan(double width) {
    return ResponsiveBreakpoints.of(this).screenWidth < width;
  }

  T responsive<T>({required T mobile, T? tablet, T? desktop, T? fourK}) {
    if (isMobile) {
      return mobile;
    } else if (isTablet) {
      return tablet ?? mobile;
    } else if (isDesktop) {
      return desktop ?? tablet ?? mobile;
    }
    return fourK ?? desktop ?? tablet ?? mobile;
  }
}

extension BrightnessX on Brightness {
  Brightness get inverted {
    switch (this) {
      case Brightness.light:
        return Brightness.dark;
      case Brightness.dark:
        return Brightness.light;
    }
  }
}
