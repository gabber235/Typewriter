import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

NotificationBubbleAnchor _anchorKnob(BuildContext context) {
  return context.knobs.object.dropdown<NotificationBubbleAnchor>(
    label: "Anchor",
    initialOption: NotificationBubbleAnchor.topRight,
    options: NotificationBubbleAnchor.values,
    labelBuilder: (o) => o.name,
  );
}

Widget _demoTarget(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.blueGrey.shade100,
      borderRadius: BorderRadius.circular(size * 0.25),
      border: Border.all(color: Colors.blueGrey.shade300, width: 1.5),
    ),
    alignment: Alignment.center,
    child: Icon(
      Icons.notifications,
      size: size * 0.55,
      color: Colors.blueGrey.shade700,
    ),
  );
}

@widgetbook.UseCase(name: "Dot", type: NotificationBubble)
Widget notificationBubbleDotUseCase(BuildContext context) {
  final anchor = _anchorKnob(context);
  final overlap = context.knobs.double.slider(
    label: "Overlap",
    initialValue: 6,
    min: 0,
    max: 24,
  );
  final dotSize = context.knobs.double.slider(
    label: "Dot Size",
    initialValue: 10,
    min: 6,
    max: 24,
  );
  final childSize = context.knobs.double.slider(
    label: "Child Size",
    initialValue: 56,
    min: 32,
    max: 128,
  );
  final bg = context.knobs.color(
    label: "Bubble Color",
    initialValue: Colors.red,
  );
  final semantics = context.knobs.string(
    label: "Semantics Label",
    initialValue: "Notifications available",
  );

  return FakeApp(
    child: Center(
      child: HookBuilder(
        builder: (context) {
          final visible = useState<bool>(true);
          return GestureDetector(
            onTap: () => visible.value = !visible.value,
            child: NotificationBubble.dot(
              anchor: anchor,
              overlap: overlap,
              dotSize: dotSize,
              color: bg,
              semanticsLabel: semantics,
              show: visible.value,
              child: _demoTarget(childSize),
            ),
          );
        },
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Count", type: NotificationBubble)
Widget notificationBubbleCountUseCase(BuildContext context) {
  final anchor = _anchorKnob(context);
  final overlap = context.knobs.double.slider(
    label: "Overlap",
    initialValue: 6,
    min: 0,
    max: 24,
  );
  final count = context.knobs.int.input(label: "Count", initialValue: 7);
  final maxCount = context.knobs.int.input(
    label: "Max Count",
    initialValue: 99,
  );
  final hideZero = context.knobs.boolean(
    label: "Hide When Zero",
    initialValue: true,
  );
  final childSize = context.knobs.double.slider(
    label: "Child Size",
    initialValue: 56,
    min: 32,
    max: 128,
  );
  final bg = context.knobs.color(
    label: "Bubble Color",
    initialValue: Colors.red,
  );
  final fg = context.knobs.color(
    label: "Text Color",
    initialValue: Colors.white,
  );

  return FakeApp(
    child: Center(
      child: HookBuilder(
        builder: (context) {
          final visible = useState<bool>(true);
          return GestureDetector(
            onTap: () => visible.value = !visible.value,
            child: NotificationBubble.count(
              count: count,
              anchor: anchor,
              overlap: overlap,
              maxCount: maxCount,
              hideWhenZero: hideZero,
              backgroundColor: bg,
              foregroundColor: fg,
              show: visible.value,
              child: _demoTarget(childSize),
            ),
          );
        },
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Custom", type: NotificationBubble)
Widget notificationBubbleCustomUseCase(BuildContext context) {
  final anchor = _anchorKnob(context);
  final overlap = context.knobs.double.slider(
    label: "Overlap",
    initialValue: 6,
    min: 0,
    max: 24,
  );
  final childSize = context.knobs.double.slider(
    label: "Child Size",
    initialValue: 56,
    min: 32,
    max: 128,
  );

  final label = context.knobs.string(label: "Label", initialValue: "NEW");
  final bg = context.knobs.color(
    label: "Bubble Color",
    initialValue: Colors.green,
  );
  final fg = context.knobs.color(
    label: "Text Color",
    initialValue: Colors.white,
  );

  final bubble = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: ShapeDecoration(color: bg, shape: StadiumBorder()),
    child: Text(
      label,
      style: TextStyle(
        color: fg,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    ),
  );

  return FakeApp(
    child: Center(
      child: HookBuilder(
        builder: (context) {
          final visible = useState<bool>(true);
          return GestureDetector(
            onTap: () => visible.value = !visible.value,
            child: NotificationBubble.custom(
              bubble: bubble,
              anchor: anchor,
              overlap: overlap,
              show: visible.value,
              child: _demoTarget(childSize),
            ),
          );
        },
      ),
    ),
  );
}
