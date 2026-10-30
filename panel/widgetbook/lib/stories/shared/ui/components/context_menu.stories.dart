import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A Book's [ContextMenuRegion]: a right click or long press opens its
/// entries, with shortcuts, a submenu, a divider and a disabled entry.
@widgetbook.UseCase(name: "Default", type: ContextMenuRegion)
Widget contextMenuRegionUseCase(BuildContext context) {
  return Story(
    const [],
    at: PanelLocation.component(
      ContextMenuRegion(
        items: [
          MenuItem(
            label: "Open",
            icon: const Icon(Icons.open_in_new),
            onPressed: () {},
            shortcuts: const [SingleActivator(LogicalKeyboardKey.enter)],
          ),
          MenuItem(
            label: "Duplicate",
            icon: const Icon(Icons.copy),
            onPressed: () {},
            shortcuts: const [
              SingleActivator(LogicalKeyboardKey.keyD, meta: true),
            ],
          ),
          MenuItem.submenu(
            label: "Move to",
            icon: const Icon(Icons.drive_file_move_outline),
            items: [
              MenuItem(label: "Library", onPressed: () {}),
              MenuItem(label: "Archive", onPressed: () {}),
            ],
          ),
          const MenuItem.divider(),
          const MenuItem(label: "Publish", icon: Icon(Icons.publish)),
          MenuItem(
            label: "Delete",
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            onPressed: () {},
            shortcuts: const [SingleActivator(LogicalKeyboardKey.delete)],
          ),
        ],
        child: const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text("The Lost Village"),
          ),
        ),
      ),
    ),
  );
}
