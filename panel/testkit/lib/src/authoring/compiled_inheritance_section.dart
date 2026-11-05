import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The compiled inheritance section of a shown resource inspector: the
/// effective Tags of a Book, or the inheritance of a Tag when [book] is
/// false.
///
/// Its layout tests read what semantics cannot carry: the size of each tag
/// card, the disclosure toggles of collapsed branches and the colors the
/// hierarchy lines are stroked in.
final class CompiledInheritanceSection {
  CompiledInheritanceSection({bool book = true})
    : finder = find.byKey(ValueKey(book ? "effective-tags" : "inheritance"));

  /// The section itself.
  final Finder finder;

  /// Every visible label reading [name] inside the section.
  Finder label(String name) =>
      find.descendant(of: finder, matching: find.text(name));

  /// The first card showing the tag [name].
  Finder card(String name) => find
      .ancestor(
        of: label(name),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is PortablePresentationNodeRenderer &&
              widget.node.element is skir.PresentationElement_containerWrapper,
        ),
      )
      .first;

  /// The toggles that expand or collapse an inherited branch.
  Finder get disclosures => find.descendant(
    of: finder,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          (widget.tooltip == "Expand" || widget.tooltip == "Collapse"),
    ),
  );

  /// The surfaces that draw the lines between inherited tags.
  Finder get hierarchies => find.descendant(
    of: finder,
    matching: find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == "_HierarchyRenderSurface",
    ),
  );

  /// The color of every hierarchy line drawn in the section.
  List<Color> get strokeColors => [
    for (final element in hierarchies.evaluate())
      for (final dynamic stroke
          in (element.findRenderObject() as dynamic).debugStrokes)
        stroke.style.color as Color,
  ];
}
