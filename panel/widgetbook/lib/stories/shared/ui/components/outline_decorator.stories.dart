import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/shared/ui/components/outline_decorator.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Showcase", type: OutlineDecorator)
Widget outlineDecoratorShowcaseUseCase(BuildContext context) {
  final outerColor = context.knobs.color(
    label: "Outer color",
    initialValue: Colors.blue,
  );
  final hasInner =
      context.knobs.boolean(label: "Inner outline", initialValue: true);
  final innerColor = hasInner
      ? context.knobs.color(
          label: "Inner color",
          initialValue: const Color(0xFF121212),
        )
      : null;

  final outerThickness = context.knobs.double.slider(
    label: "Outer thickness",
    initialValue: 5.5,
    min: 0,
    max: 12,
    divisions: 24,
  );
  final innerThickness = context.knobs.double.slider(
    label: "Inner thickness",
    initialValue: 2.5,
    min: 0,
    max: 8,
    divisions: 16,
  );

  Widget tile({
    required Size size,
    required Widget child,
  }) {
    return HookBuilder(
      builder: (context) {
        final hovering = useState(false);
        return MouseRegion(
          onEnter: (_) => hovering.value = true,
          onExit: (_) => hovering.value = false,
          child: OutlineDecorator(
            show: !hovering.value,
            outerColor: outerColor,
            innerColor: innerColor,
            outerThickness: outerThickness,
            innerThickness: innerThickness,
            builder: (context) => SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        );
      },
    );
  }

  final tiles = <Widget>[
    tile(
      size: const Size(80, 80),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    tile(
      size: const Size(80, 80),
      child: ClipOval(
        child: ColoredBox(color: Colors.grey.shade400),
      ),
    ),
    tile(
      size: const Size(140, 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(Icons.star, color: Colors.white, size: 28),
        ),
      ),
    ),
    tile(
      size: const Size(140, 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade500,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "Hello World",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),
    tile(
      size: const Size(100, 60),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: FlutterLogo(size: 36)),
      ),
    ),
    tile(
      size: const Size(140, 40),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "Badge",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
    tile(
      size: const Size(120, 48),
      child: Center(
        child: Icon(
          Icons.favorite,
          color: Colors.white.withValues(alpha: 0.9),
          size: 28,
        ),
      ),
    ),
    tile(
      size: const Size(120, 80),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
    ),
    tile(
      size: const Size(540, 40),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
    tile(
      size: const Size(40, 540),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
  ];

  return FakeApp(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tiles
              .map(
                (w) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}
