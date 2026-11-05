import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// [Surface]s filled with the colors authors give Books, Tags and Pages:
/// their icons and text take the readable foreground of each fill.
@widgetbook.UseCase(name: "Domain colors", type: Surface)
Widget surfaceUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          for (final (kind, icon, color, title) in const [
            ("Book", Icons.book, Color(0xff3f51b5), "The Lost Village"),
            ("Tag", Icons.label, Color(0xff009688), "Main story"),
            ("Page", Icons.description, Color(0xffffdd66), "Arrival"),
          ])
            _Tile(kind: kind, icon: icon, color: color, title: title),
        ],
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.kind,
    required this.icon,
    required this.color,
    required this.title,
  });

  final String kind;
  final IconData icon;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: context.shapes.largeBorderRadius,
      child: Surface(
        color: color,
        child: Builder(
          builder: (context) {
            return Padding(
              padding: EdgeInsets.all(context.spacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Icon(icon),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Text(
                    kind,
                    style: TextStyle(
                      color: Surface.secondaryForegroundOf(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
