import "dart:math";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "sidebar_controller.dart";
part "sidebar_links.dart";
part "sidebar_shell.dart";
part "sidebar_state.dart";
part "sidebar_user_menu.dart";
part "sidebar.g.dart";

const double kSidebarResizeSmallStep = 10;
const double kSidebarResizeLargeStep = 50;

const double kSidebarMinSize = 150;
const double kSidebarDefaultSize = 220;
const double kSidebarMaxFactor = 1 / 3;
