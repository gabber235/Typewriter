import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class Exemption {
  Exemption(this.path, this.pattern, this.reason);

  final String path;
  final RegExp pattern;
  final String reason;
}

final exemptions = <Exemption>[
  Exemption(
    "lib/app/presentation/theme/color_scheme.dart",
    RegExp(r"Color\(0xFF(?:12151C|F8F9FC|FF7043)\)|Colors\.orange"),
    "design-system palette seeds",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/domain/page_type_extensions.dart",
    RegExp(r"Colors\.(?:blue|green|red|purple|deepPurple|orange)"),
    "persisted page-type identity colors",
  ),
  Exemption(
    "lib/features/organizations/features/services/application/services.dart",
    RegExp(r"Colors\.(?:blue|deepPurple|deepOrangeAccent|green)"),
    "service-role identity colors",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/modes/insert_mode.dart",
    RegExp(r"Colors\.green"),
    "editor mode identity color",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations/entry_operations.dart",
    RegExp(r"Colors\.(?:red|orange|blue|green)"),
    "editor operation identity colors",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations/unbind_operation.dart",
    RegExp(r"Colors\."),
    "editor operation identity color",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/headers/list_header.dart",
    RegExp(r"Colors\.green"),
    "list validity indicator",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/graph.dart",
    RegExp(r"Colors\.grey"),
    "custom graph painter geometry",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/entry.dart",
    RegExp(r"Colors\.white"),
    "established entry-node focus treatment over arbitrary blueprint colors",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/scene/presentation/scene.dart",
    RegExp(r"Colors\.white"),
    "computed contrast and custom canvas geometry",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/tags/presentation/tag_node.dart",
    RegExp(r"Colors\.(black|white)"),
    "computed contrast over persisted tag colors",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/presentation/book.dart",
    RegExp(r"Colors\.white"),
    "contrast over data-colored book artwork",
  ),
  Exemption(
    "lib/features/organizations/features/realms/features/books/presentation/book/route.dart",
    RegExp(r"Colors\.white"),
    "contrast over page-type data colors",
  ),
  Exemption(
    "lib/shared/ui/components/shimmer.dart",
    RegExp(r"BorderRadius\.circular\(8\)"),
    "constructor fallback without a build context",
  ),
  for (final path in [
    "lib/app/presentation/shell/custom_appbar.dart",
    "lib/app/presentation/shell/sidebar.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/header.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/resizable_element.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/search/presentation/result_item/search_result_card.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/scene/presentation/scene.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline_plane.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/selector_popup.dart",
    "lib/features/organizations/features/realms/features/books/presentation/book/route.dart",
    "lib/features/organizations/features/realms/features/tags/presentation/tag_node.dart",
    "lib/features/organizations/features/members/features/join_codes/presentation/join_code_table.dart",
    "lib/features/organizations/features/members/features/join_codes/presentation/preset_chip.dart",
    "lib/features/organizations/features/members/presentation/member_table.dart",
    "lib/features/organizations/features/members/presentation/role_multiselect_chips.dart",
    "lib/features/organizations/features/services/presentation/route.dart",
    "lib/features/organizations/presentation/join_organization.dart",
    "lib/shared/ui/components/grid_selectable_card.dart",
    "lib/shared/ui/components/focus_highlight.dart",
    "lib/shared/ui/components/depth_box.dart",
    "lib/shared/search/presentation/search_modal_body.dart",
  ])
    Exemption(path, RegExp(r"Colors\.transparent"), "intentional transparency"),
  for (final path in [
    "lib/app/presentation/shell/custom_appbar.dart",
    "lib/app/presentation/shell/panes.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/graph_group.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline_segment_surface.dart",
    "lib/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline_plane.dart",
    "lib/features/organizations/features/realms/features/tags/presentation/tag_node.dart",
    "lib/features/organizations/features/members/features/join_codes/presentation/preset_chip.dart",
    "lib/shared/ui/components/countdown_badge.dart",
    "lib/shared/search/presentation/search_modal_body.dart",
  ])
    Exemption(
      path,
      RegExp(r"(?:Radius|BorderRadius)\.(?:circular|all)"),
      "specialized geometry",
    ),
];

void main() {
  test("handwritten UI uses design-system typography, colors, and shapes", () {
    final violations = <String>[];
    for (final file in Directory(
      "lib",
    ).listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(Platform.pathSeparator, "/");
      if (!path.endsWith(".dart") ||
          path.endsWith(".g.dart") ||
          path.endsWith(".freezed.dart")) {
        continue;
      }
      final isUi =
          path.contains("/presentation/") ||
          path.contains("/shared/ui/") ||
          path.contains("/application/services.dart") ||
          path.contains("/domain/page_type_extensions.dart");
      if (!isUi) {
        continue;
      }
      final source = file.readAsStringSync();
      final checks = <RegExp>[
        if (path != "lib/app/presentation/theme/typography.dart")
          RegExp(
            r"fontFamily\s*:|(?<![A-Za-z0-9_])(?<!Default)(?<!AnimatedDefault)TextStyle\s*\(",
          ),
        if (!path.contains("/theme/"))
          RegExp(
            r"Colors\.[A-Za-z_][A-Za-z0-9_]*|Color\s*\(\s*0x|Color\.from(?:ARGB|RGBO)\s*\(|Color\.from\s*\(",
          ),
        RegExp(
          r"(?:Radius|BorderRadius)\.(?:circular|all)\s*\(\s*(?:const\s+)?(?:Radius\.circular\s*\(\s*)?(?:4|8|12|16)(?:\.0)?\s*\)?\s*\)",
        ),
      ];
      for (final pattern in checks) {
        for (final match in pattern.allMatches(source)) {
          final allowed = exemptions.any(
            (entry) =>
                entry.path == path && entry.pattern.hasMatch(match.group(0)!),
          );
          if (!allowed) violations.add("$path: ${match.group(0)}");
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join("\n"));
  });

  test("domain showcase colors have accessible foregrounds", () {
    const domainColors = <Color>[
      Color(0xFF7E57C2),
      Color(0xFF00897B),
      Color(0xFFF4511E),
      Color(0xFF3949AB),
      Color(0xFFD81B60),
      Color(0xFF6D4C41),
    ];
    for (final brightness in Brightness.values) {
      for (final color in domainColors) {
        final foreground = color.onBrightness(brightness);
        final lighter = color.computeLuminance() + 0.05;
        final darker = foreground.computeLuminance() + 0.05;
        final contrast = lighter > darker ? lighter / darker : darker / lighter;
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    }
  });

  test("both themes expose all extensions and font families", () {
    for (final brightness in Brightness.values) {
      final theme = buildTheme(brightness);
      expect(
        theme.extensions.values,
        containsAll([
          isA<TypewriterColors>(),
          isA<TypewriterSpacing>(),
          isA<TypewriterShapes>(),
          isA<TypewriterStateTokens>(),
        ]),
      );
      final styles = [
        theme.textTheme.displayLarge,
        theme.textTheme.displayMedium,
        theme.textTheme.displaySmall,
        theme.textTheme.headlineLarge,
        theme.textTheme.headlineMedium,
        theme.textTheme.headlineSmall,
        theme.textTheme.titleLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.titleSmall,
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.textTheme.labelMedium,
        theme.textTheme.labelSmall,
      ];
      expect(styles.map((style) => style!.fontFamily), [
        ...List.filled(9, "JetBrainsMono"),
        ...List.filled(3, "Lilex"),
        ...List.filled(3, "JetBrainsMono"),
      ]);
    }
  });
}
