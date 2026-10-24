import "package:typewriter_panel/typewriter_panel.dart";

part "sidebar_controller.dart";
part "sidebar_links.dart";
part "sidebar_shell.dart";
part "sidebar_state.dart";
part "sidebar_user_menu.dart";
part "sidebar.g.dart";

/// Width change for an ordinary keyboard resize step, in logical pixels.
const double kSidebarResizeSmallStep = 10;

/// Width change for a modified keyboard resize step, in logical pixels.
const double kSidebarResizeLargeStep = 50;

/// Smallest width allowed by the sidebar controller, in logical pixels.
const double kSidebarMinSize = 150;

/// Initial sidebar width, in logical pixels.
const double kSidebarDefaultSize = 220;

/// Fraction of the viewport width available to the sidebar before clamping.
const double kSidebarMaxFactor = 1 / 3;
