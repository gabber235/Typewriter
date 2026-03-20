import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/utils/fonts.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

class GraphGroup extends StatelessWidget {
  const GraphGroup({
    required this.title,
    required this.color,
    required this.data,
    this.titleStyle,
    this.titlePadding = const EdgeInsets.all(2),
    super.key,
  });

  final String title;
  final Color color;
  final GraphDragData data;
  final TextStyle? titleStyle;
  final EdgeInsets titlePadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final backgroundColor = Theme.of(
          context,
        ).colorScheme.surfaceContainerLowest;

        final child = SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CustomPaint(
            painter: GraphGroupPainter(
              title: title,
              color: color,
              backgroundColor: backgroundColor,
              titleStyle:
                  titleStyle ??
                  Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 11,
                    fontVariations: const [extraBoldWeight],
                  ),
              titlePadding: titlePadding,
            ),
          ),
        );

        final themes = InheritedTheme.capture(
          from: context,
          to: Navigator.of(context, rootNavigator: true).context,
        );

        final graphDrag = GraphDrag.maybeOf(context);

        return Draggable(
          data: data,
          feedback: HookBuilder(
            builder: (context) {
              useListenable(graphDrag?.draggingInsideGraph);
              return graphDrag?.draggingInsideGraph.value ?? false
                  ? SizedBox()
                  : Opacity(opacity: 0.5, child: themes.wrap(child));
            },
          ),
          child: Surface(color: backgroundColor, child: child),
        );
      },
    );
  }
}

class GraphGroupPainter extends CustomPainter {
  GraphGroupPainter({
    required this.title,
    required this.color,
    required this.backgroundColor,
    required this.titleStyle,
    required this.titlePadding,
  });

  final String title;
  final TextStyle titleStyle;
  final EdgeInsets titlePadding;
  final Color color;
  final Color backgroundColor;

  static const double strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final titleTextSpan = TextSpan(
      text: title,
      style: titleStyle.copyWith(
        color: Color.alphaBlend(color.withValues(alpha: 0.2), backgroundColor),
      ),
    );

    final titlePainter = TextPainter(
      text: titleTextSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - titlePadding.horizontal);

    final titleOffset = Offset(
      size.width / 2 - titlePainter.width / 2,
      titlePadding.top,
    );

    final titleHeight =
        titlePadding.vertical + titlePainter.height - strokeWidth;

    final titleBackgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, 0, size.width, titleHeight),
          Radius.circular(8),
        ),
        titleBackgroundPaint,
      )
      ..drawRect(
        Rect.fromLTRB(
          0,
          titleHeight / 2,
          strokeWidth,
          titleHeight + titleHeight / 2,
        ),
        titleBackgroundPaint,
      )
      ..drawRect(
        Rect.fromLTRB(1, titleHeight - 3, 4, titleHeight + 3),
        titleBackgroundPaint,
      )
      ..drawRect(
        Rect.fromLTRB(3, titleHeight - 1, 6, titleHeight + 1),
        titleBackgroundPaint,
      )
      ..drawRect(
        Rect.fromLTRB(
          size.width - 2,
          titleHeight / 2,
          size.width,
          titleHeight + titleHeight / 2,
        ),
        titleBackgroundPaint,
      )
      ..drawRect(
        Rect.fromLTRB(
          size.width - 4,
          titleHeight - 3,
          size.width - 1,
          titleHeight + 3,
        ),
        titleBackgroundPaint,
      )
      ..drawRect(
        Rect.fromLTRB(
          size.width - 6,
          titleHeight - 1,
          size.width - 3,
          titleHeight + 1,
        ),
        titleBackgroundPaint,
      );

    titlePainter.paint(canvas, titleOffset);

    final contentBackgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, titleHeight, size.width, size.height),
        Radius.circular(8),
      ),
      contentBackgroundPaint,
    );

    final contentOutlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          strokeWidth / 2,
          titleHeight,
          size.width - strokeWidth / 2,
          size.height - strokeWidth / 2,
        ),
        Radius.circular(8),
      ),
      contentOutlinePaint,
    );
  }

  @override
  bool shouldRepaint(GraphGroupPainter oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.titlePadding != titlePadding ||
        oldDelegate.titleStyle != titleStyle;
  }
}
