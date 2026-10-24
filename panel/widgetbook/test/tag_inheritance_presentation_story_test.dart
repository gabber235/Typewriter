import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/tag_inheritance_presentation.stories.dart";

void main() {
  final stories = <String, WidgetBuilder>{
    "leaf": tagInheritanceLeafUseCase,
    "unary chain": tagInheritanceUnaryUseCase,
    "branching": tagInheritanceBranchingUseCase,
    "shared ancestor": tagInheritanceSharedUseCase,
    "keyboard interaction": tagInheritanceKeyboardUseCase,
    "narrow layout": tagInheritanceNarrowUseCase,
    "right to left": tagInheritanceRightToLeftUseCase,
  };

  for (final MapEntry(key: name, value: story) in stories.entries) {
    testWidgets("$name inheritance story renders", (tester) async {
      final state = WidgetbookState(root: WidgetbookRoot(children: const []));
      addTearDown(state.dispose);
      await tester.pumpWidget(
        WidgetbookScope(
          state: state,
          child: Builder(builder: story),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AuthoredResourceInspection), findsOneWidget);
      expect(find.byKey(const ValueKey("effective-tags")), findsOneWidget);
    });
  }
}
