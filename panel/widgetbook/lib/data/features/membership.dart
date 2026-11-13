/// Hosts and knobs the membership component stories share: the rows a
/// membership tab owns, the scroll view its slivers live in, and the window
/// and motion knobs.
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

  /// Which rows start selected: none, the first two, or all.
  String selection() => object.segmented(
    label: "Selection",
    options: const ["None", "Some", "All"],
    initialOption: "None",
  );

  /// The window the panel renders in: desktop, compact or phone.
  List<Trait> windows() => traits("Window", {
    "Desktop": const [],
    "Compact": const [compact],
    "Phone": [window(phoneWindow)],
  });

  /// Full or reduced motion.
  List<Trait> motion() => traits("Motion", {
    "Full": const [],
    "Reduced": const [reducedMotion],
  });
}

/// The ids of [items] a selection knob value picks: none, the first two, or
/// all.
Set<skir.RecordId> selectedOf<T>(
  String selection,
  List<T> items,
  skir.RecordId Function(T item) id,
) => switch (selection) {
  "Some" => items.take(2).map(id).toSet(),
  "All" => items.map(id).toSet(),
  _ => const {},
};

/// A story of one membership table or list: [make] generates as many items
/// as the [label] knob asks for, the Selection knob picks which start
/// selected, and [builder] renders them in a pane as their page does.
///
/// [traits] gives the world for the items, such as their membership; the
/// Motion knob, and the [windows] knob when given, follow it.
Widget selectableRowsStory<T>(
  BuildContext context, {
  required String label,
  required List<T> Function(Generator generator, int count) make,
  required skir.RecordId Function(T item) identity,
  required List<Trait> Function(List<T> items) traits,
  required Widget Function(SelectableRows<T> selection) builder,
  Map<String, List<Trait>>? windows,
}) {
  final items = make(
    Generator(context.knobs.seed()),
    context.knobs.rowCount(label: label),
  );
  final selected = selectedOf(context.knobs.selection(), items, identity);
  return Story(
    [
      ...traits(items),
      if (windows != null) ...context.knobs.traits("Window", windows),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StorySliverPane(
        slivers: [
          StoryRows(
            items: items,
            identity: identity,
            selected: selected,
            builder: (context, selection) => builder(selection),
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

/// The rows of [items] and the ids selected among them, owned here the way a
/// membership tab owns them, handed to [builder]. Selection starts at
/// [selected] and then follows clicks and keys.
class StoryRows<T> extends HookWidget {
  const StoryRows({
    required this.items,
    required this.identity,
    required this.builder,
    this.selected = const {},
    super.key,
  });

  final List<T> items;
  final skir.RecordId Function(T item) identity;
  final Set<skir.RecordId> selected;
  final Widget Function(BuildContext context, SelectableRows<T> selection)
  builder;

  @override
  Widget build(BuildContext context) {
    final rows = useAnimatedRows(items: items, identity: identity);
    final selectedIds = useState(selected);
    return builder(
      context,
      SelectableRows(rows: rows, selectedIds: selectedIds),
    );
  }
}

/// A primary pane scrolling [slivers], padded the way a membership page pads
/// its tab, so a story shows a tab, table or list as its page does.
class StorySliverPane extends StatelessWidget {
  const StorySliverPane({required this.slivers, super.key});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "story",
      primary: true,
      openFocus: PaneOpenFocus.firstItem,
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
