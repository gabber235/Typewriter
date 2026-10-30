import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/shared/shell/appbar.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("choosing another organization from the app bar breadcrumbs "
      "opens it", (tester) async {
    final panel = await tester.pumpStory(customAppBarUseCase);

    await panel.tapOn(find.text("Acme").first);
    await panel.tapOn(find.text("Globex").last);

    await panel.eventually(
      () => expect(panel.path, startsWith("/organization/globex")),
    );
    expect(find.text("Globex"), findsWidgets);
  });
}
