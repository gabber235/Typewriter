/// Hosts and knobs the membership component stories share: the rows a
/// membership tab owns, the selection surface and scroll view its slivers
/// live in, and the selection, window and motion knobs.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The window of a phone, where membership lists stack their controls.
const phoneWindow = Size(400, 900);

/// Knobs every membership component story offers.
extension MembershipStoryKnobs on KnobsBuilder {
  /// How many rows a list story shows: none, a few with one long name, or
  /// many. Returns the count.
  int rowCount({String label = "Rows"}) {
    final amount = object.dropdown(
      label: label,
      options: const ["None", "Few", "Many"],
      initialOption: "Few",
    );
    return switch (amount) {
      "None" => 0,
      "Many" => 60,
      _ => 6,
    };
  }

  /// Which rows start selected: none, one as after a click, or the first
  /// two or all of them added one by one, in select mode.
  String selection({String initial = "None"}) => object.segmented(
    label: "Selection",
    options: const ["None", "One", "Some", "All"],
    initialOption: initial,
  );

  /// The window the panel renders in: desktop, compact or phone.
  List<Trait> windows() => traits("Window", {
    "Desktop": const [],
    "Compact": const [compact],
    "Phone": [window(phoneWindow)],
  });
}

/// The selection a knob value starts with among [items]: none, the first as
/// after a click, or the first two or all of them added one by one, so the
/// rows are in select mode.
List<Trait> selectionOf<T>(
  String selection,
  List<T> items,
  SelectableIdentifier Function(T item) selectable,
) => switch (selection) {
  "One" when items.isNotEmpty => [
    selected([selectable(items.first)]),
  ],
  "Some" => [selected(items.take(2).map(selectable).toList(), selecting: true)],
  "All" => [selected(items.map(selectable).toList(), selecting: true)],
  _ => const [],
};

/// A story of one membership table or list: [make] generates as many items
/// as the [label] knob asks for, the Selection knob picks which start
/// selected, and [builder] renders their rows in a pane as their page does.
///
/// [traits] gives the world for the items, such as their membership; the
/// Motion knob, and the [windows] knob when given, follow it.
Widget selectableRowsStory<T>(
  BuildContext context, {
  required String label,
  required List<T> Function(Generator generator, int count) make,
  required skir.RecordId Function(T item) identity,
  required SelectableIdentifier Function(T item) selectable,
  required List<Trait> Function(List<T> items) traits,
  required Widget Function(AnimatedRows<T> rows) builder,
  Map<String, List<Trait>>? windows,
}) {
  final items = make(
    Generator(context.knobs.seed()),
    context.knobs.rowCount(label: label),
  );
  return Story(
    [
      ...traits(items),
      ...selectionOf(context.knobs.selection(), items, selectable),
      if (windows != null) ...context.knobs.traits("Window", windows),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StorySliverPane(
        slivers: [
          StoryRows(
            items: items,
            identity: identity,
            builder: (context, rows) => builder(rows),
          ),
        ],
      ),
    ),
  );
}

/// The smaller windows a membership list shows in instead of its table.
final listWindows = {
  "Compact": const [compact],
  "Phone": [window(phoneWindow)],
};

/// The rows of [items], owned here the way a membership tab owns them,
/// handed to [builder].
class StoryRows<T> extends HookWidget {
  const StoryRows({
    required this.items,
    required this.identity,
    required this.builder,
    super.key,
  });

  final List<T> items;
  final skir.RecordId Function(T item) identity;
  final Widget Function(BuildContext context, AnimatedRows<T> rows) builder;

  @override
  Widget build(BuildContext context) {
    final rows = useAnimatedRows(items: items, identity: identity);
    return builder(context, rows);
  }
}

/// A primary pane scrolling [slivers] on one selection surface, padded the
/// way a membership page pads its tab, so a story shows a tab, table or list
/// as its page does.
class StorySliverPane extends StatelessWidget {
  const StorySliverPane({required this.slivers, super.key});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "story",
      primary: true,
      openFocus: PaneOpenFocus.firstItem,
      child: SelectionSurface(
        child: CustomScrollView(
          primary: true,
          slivers: [
            for (final sliver in slivers)
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space6,
                  vertical: context.spacing.space3,
                ),
                sliver: sliver,
              ),
          ],
        ),
      ),
    );
  }
}

/// [child] in a box [width] wide, centred on the stage, for a story of one
/// control or card.
class StoryBox extends StatelessWidget {
  const StoryBox({required this.width, required this.child, super.key});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(width: width, child: child),
    );
  }
}
