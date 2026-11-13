import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The [TopologyStatusIndicator] under a services graph node title: a dot in
/// the host's tone and its status, in the node's accent colour while the
/// node is highlighted.
@widgetbook.UseCase(name: "Tones", type: TopologyStatusIndicator)
Widget topologyStatusIndicatorUseCase(BuildContext context) {
  final tone = context.knobs.object.dropdown(
    label: "Tone",
    options: TopologyStatusTone.values,
    initialOption: TopologyStatusTone.active,
    labelBuilder: (tone) => tone.name,
  );
  final highlighted = context.knobs.boolean(label: "Highlighted");
  final long = context.knobs.boolean(label: "Long status");
  final width = context.knobs.width(const {"Node": 200, "Narrow": 90});
  final label = switch (tone) {
    TopologyStatusTone.active => "Active",
    TopologyStatusTone.warning => "Reconciling",
    TopologyStatusTone.error => "Failed",
    TopologyStatusTone.offline => "Offline",
  };
  const accent = Colors.indigo;
  return Story(
    const [],
    at: PanelLocation.component(
      Container(
        width: width,
        padding: const EdgeInsets.all(8),
        color: highlighted ? accent : null,
        child: TopologyStatusIndicator(
          label: long ? "$label since the last deploy of this host" : label,
          tone: tone,
          color: accent,
          highlighted: highlighted,
        ),
      ),
    ),
  );
}
