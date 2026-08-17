import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/tags/presentation/tag_inheritance_presentation.stories.dart";

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
      await tester.pumpWidget(Builder(builder: story));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("Inheritance"), findsOneWidget);
    });
  }
}
