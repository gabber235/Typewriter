import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final exemptions = <Exemption>[
  Exemption(
    "lib/shared/theme/color_scheme.dart",
    RegExp(r"Color\(0xFF(?:12151C|F8F9FC|FF7043)\)|Colors\.orange"),
    "design-system palette seeds",
  ),
  Exemption(
    "lib/features/services/application/service_projection.dart",
    RegExp(r"Colors\.(?:blue|deepPurple|deepOrangeAccent|green)"),
    "service-role identity colors",
  ),
  Exemption(
    "lib/shared/interaction_mode/application/modes/insert_mode.dart",
    RegExp(r"Colors\.green"),
    "editor mode identity color",
  ),
  Exemption(
    "lib/shared/selectables/operations/unbind_operation.dart",
    RegExp(r"Colors\."),
    "editor operation identity color",
  ),
  for (final path in [
    "lib/shared/editors/presentation/portable_renderer/expression_resolution.dart",
  ])
    Exemption(
      path,
      RegExp(r"TextStyle\s*\("),
      "protocol or state supplied text styling",
    ),
  Exemption(
    "lib/shared/editors/presentation/components/color_picker/color_picker_surface.dart",
    RegExp(r"Color\(0x"),
    "intrinsic color spectrum",
  ),
  Exemption(
    "lib/shared/editors/presentation/components/color_picker/color_area.dart",
    RegExp(r"Colors\.(?:white|black|black54|transparent)"),
    "intrinsic color field geometry",
  ),
  Exemption(
    "lib/shared/editors/presentation/components/color_picker/color_slider.dart",
    RegExp(r"Colors\.(?:white|black54)"),
    "contrast over arbitrary colors",
  ),
  Exemption(
    "lib/shared/editors/presentation/components/color_picker/checkerboard.dart",
    RegExp(r"Color\(0x"),
    "alpha checkerboard colors",
  ),
  Exemption(
    "lib/shared/editors/presentation/components/color_picker/color_value.dart",
    RegExp(r"Color\.fromARGB\("),
    "color value conversion",
  ),
  Exemption(
    "lib/shared/ui/components/surface_container.dart",
    RegExp(r"Colors\.transparent"),
    "transparent fill lets the inherited surface show through",
  ),
  Exemption(
    "lib/shared/ui/components/admonition.dart",
    RegExp(r"Colors\.transparent"),
    "transparent material preserves the admonition surface",
  ),
  Exemption(
    "lib/shared/ui/components/surface.dart",
    RegExp(r"TextStyle\s*\(\s*color:\s*selectedForeground\s*\)"),
    "computed foreground is supplied by the surface state",
  ),
  Exemption(
    "lib/shared/editors/presentation/portable_renderer/appearance.dart",
    RegExp(r"Colors\.transparent"),
    "missing presentation fill preserves inherited appearance",
  ),
  Exemption(
    "lib/shared/editors/presentation/presentation_color.dart",
    RegExp(r"Colors\.(?:white|black)"),
    "focus outline and monochrome colors are defined by the presentation protocol",
  ),
  Exemption(
    "lib/shared/graph/presentation/graph.dart",
    RegExp(r"Colors\.grey"),
    "custom graph painter geometry",
  ),
  Exemption(
    "lib/shared/ui/components/shimmer.dart",
    RegExp(r"BorderRadius\.circular\(8\)"),
    "constructor fallback without a build context",
  ),
  for (final path in [
    "lib/shared/shell/custom_appbar.dart",
    "lib/shared/shell/sidebar.dart",
    "lib/shared/shell/sidebar_links.dart",
    "lib/shared/graph/presentation/resizable_element.dart",
    "lib/shared/editors/presentation/timeline/presentation/timeline_plane.dart",
    "lib/features/members/join_codes/presentation/join_code_table.dart",
    "lib/features/members/join_codes/presentation/preset_chip.dart",
    "lib/features/members/presentation/member_table.dart",
    "lib/features/members/presentation/role_multiselect_chips.dart",
    "lib/features/services/presentation/route.dart",
    "lib/features/organizations/presentation/join_organization.dart",
    "lib/shared/ui/components/grid_selectable_card.dart",
    "lib/shared/mutations/presentation/mutation_activity_button.dart",
    "lib/shared/ui/components/depth_box.dart",
    "lib/shared/search/presentation/search_body.dart",
    "lib/features/realms/presentation/realm_suspension.dart",
    "lib/shared/editors/presentation/components/date_time_picker/date_time_calendar.dart",
    "lib/shared/editors/presentation/components/date_time_picker/date_time_calendar_selection_grid.dart",
    "lib/shared/search/presentation/search_result_card.dart",
    "lib/authoring/presentation/resource_drop_target.dart",
  ])
    Exemption(path, RegExp(r"Colors\.transparent"), "intentional transparency"),
  for (final path in [
    "lib/shared/shell/custom_appbar.dart",
    "lib/shared/ui/components/panes.dart",
    "lib/shared/editors/presentation/timeline/presentation/timeline_segment_surface.dart",
    "lib/shared/editors/presentation/timeline/presentation/timeline_plane.dart",
    "lib/features/members/join_codes/presentation/preset_chip.dart",
    "lib/shared/ui/components/countdown_badge.dart",
    "lib/shared/search/presentation/search_body.dart",
  ])
    Exemption(
      path,
      RegExp(r"(?:Radius|BorderRadius)\.(?:circular|all)"),
      "specialized geometry",
    ),
];

final layoutSpacingExemptions = <Exemption>[
  Exemption(
    "lib/shared/editors/presentation/portable_presentation_expressions.dart",
    RegExp("spacing: 8"),
    "portable layout data cannot depend on theme context",
  ),
  Exemption(
    "lib/shared/shell/custom_appbar.dart",
    RegExp(r"SizedBox\(width: 40\)"),
    "fixed app bar drag geometry",
  ),
  Exemption(
    "lib/shared/ui/components/panes.dart",
    RegExp(r"EdgeInsets\.all\(8\)"),
    "public component fallback without a build context",
  ),
  Exemption(
    "lib/shared/inspector/presentation/inspector.dart",
    RegExp(r"EdgeInsets\.only\(top: 8"),
    "public pane fallback without a build context",
  ),
  Exemption(
    "lib/shared/ui/components/grid_selectable_card.dart",
    RegExp(r"EdgeInsets\.fromLTRB\(14, 12, 14, 12\)"),
    "public card fallback without a build context",
  ),
  Exemption(
    "lib/shared/search/presentation/query_bar/query_bar_view.dart",
    RegExp("spacing: 4"),
    "anchored overlay placement geometry",
  ),
  Exemption(
    "lib/shared/ui/components/section.dart",
    RegExp(r"EdgeInsets\.all\(8\)"),
    "public section fallback without a build context",
  ),
];

void main() {
  test("every exemption names an existing source file", () {
    expect([
      for (final exemption in [...exemptions, ...layoutSpacingExemptions])
        if (!File(exemption.path).existsSync()) exemption.path,
    ], isEmpty);
  });

  test(
    "handwritten UI uses design system typography, colors, shapes, and spacing",
    () {
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
            path.contains("/application/services.dart");
        if (!isUi) {
          continue;
        }
        final source = file.readAsStringSync();
        final checks = <RegExp>[
          if (path != "lib/shared/theme/typography.dart")
            RegExp(
              r"fontFamily\s*:|(?<![A-Za-z0-9_])(?<!Default)(?<!AnimatedDefault)TextStyle\s*\([^)]*\)",
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
        violations.addAll(
          layoutSpacingViolations(path, source, layoutSpacingExemptions),
        );
      }
      expect(violations, isEmpty, reason: violations.join("\n"));
    },
  );

  test("the panel uses only Lilex and IBM Plex Sans", () {
    const allowed = {"Lilex", "IBMPlexSans"};
    for (final brightness in Brightness.values) {
      final theme = buildTheme(brightness);
      final t = theme.textTheme;
      final styles = [
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.headlineMedium,
        t.headlineSmall,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        t.labelSmall,
        theme.text.sentence,
        theme.text.sentenceSmall,
      ];
      expect({
        for (final style in styles) style!.fontFamily,
      }, everyElement(isIn(allowed)));
      expect(theme.text.sentence.fontFamily, "IBMPlexSans");
      expect(t.labelLarge!.fontFamily, "Lilex");
    }
    for (final pubspec in ["pubspec.yaml", "widgetbook/pubspec.yaml"]) {
      final families = RegExp(r"- family: (\w+)")
          .allMatches(File(pubspec).readAsStringSync())
          .map((match) => match.group(1));
      expect(families.toSet(), allowed, reason: pubspec);
    }
  });

  test("a foreground chosen for any color stays readable on it", () {
    // Presentation and search colors come from authored content, so any
    // color can be a background.
    final generator = Generator(235);
    for (final brightness in Brightness.values) {
      for (var index = 0; index < 500; index++) {
        final color = Color(0xFF000000 | generator.integer(0x1000000));
        final foreground = color.onBrightness(brightness);
        final lighter = color.computeLuminance() + 0.05;
        final darker = foreground.computeLuminance() + 0.05;
        final contrast = lighter > darker ? lighter / darker : darker / lighter;
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: "$color on ${brightness.name} (seed ${generator.seed})",
        );
      }
    }
  });
}
