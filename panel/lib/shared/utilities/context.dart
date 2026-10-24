import "package:typewriter_panel/typewriter_panel.dart";

/// Theme and responsive layout queries bound to a widget context.
extension BuildContextX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Named responsive breakpoints configured by the panel application.
enum Breakpoint {
  mobile("MOBILE"),
  tablet("TABLET"),
  desktop("DESK"),
  fourK("4K");

  const Breakpoint(this.name);

  final String name;
}

/// Selects layout behavior from the nearest responsive framework scope.
extension ResponsiveBreakpointsX on BuildContext {
  bool get isMobile => ResponsiveBreakpoints.of(this).isMobile;
  bool get isTablet => ResponsiveBreakpoints.of(this).isTablet;
  bool get isDesktop => ResponsiveBreakpoints.of(this).isDesktop;
  bool get is4K => ResponsiveBreakpoints.of(this).breakpoint.name == "4K";

  bool isSmallerThan(Breakpoint breakpoint) {
    return ResponsiveBreakpoints.of(this).smallerThan(breakpoint.name);
  }

  bool isSmallerThanOrEqualTo(Breakpoint breakpoint) {
    return ResponsiveBreakpoints.of(this).smallerOrEqualTo(breakpoint.name);
  }

  bool isLargerThan(Breakpoint breakpoint) {
    return ResponsiveBreakpoints.of(this).largerThan(breakpoint.name);
  }

  bool isLargerThanOrEqualTo(Breakpoint breakpoint) {
    return ResponsiveBreakpoints.of(this).largerOrEqualTo(breakpoint.name);
  }

  bool smallerThan(double width) {
    return ResponsiveBreakpoints.of(this).screenWidth < width;
  }

  bool smallerThanOrEqualTo(double width) {
    return ResponsiveBreakpoints.of(this).screenWidth <= width;
  }

  bool largerThan(double width) {
    return ResponsiveBreakpoints.of(this).screenWidth > width;
  }

  bool largerThanOrEqualTo(double width) {
    return ResponsiveBreakpoints.of(this).screenWidth >= width;
  }

  /// Selects the value for this context's breakpoint.
  ///
  /// Missing larger breakpoint values fall back toward [mobile].
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

  bool get debugShowCheckedModeBanner =>
      kDebugMode &&
      (findAncestorWidgetOfExactType<WidgetsApp>()
              ?.debugShowCheckedModeBanner ??
          false);
}

/// Operations on theme brightness values.
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
