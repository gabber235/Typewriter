import "package:flutter/material.dart";

import "package:typewriter_panel/routes/organization/book/route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/widgetbook_utils.dart";

@widgetbook.UseCase(name: "BookPage", type: BookPage)
Widget bookPageUseCase(BuildContext context) {
  final pagesState = context.knobs.displayState(label: "Pages State");
  final entriesState = context.knobs.displayState(label: "Entries State");
  final selectedPageId = context.knobs.stringOrNull(
    label: "Selected Page ID",
    initialValue: null,
  );
  final bookId = context.knobs.string(
    label: "Book ID",
    initialValue: "example-book-id",
  );

  return FakeApp(
    overrides: [
      ...allPagesProviderOverrides(
        pagesState: pagesState,
        entriesState: entriesState,
        selectedPageId: selectedPageId,
        currentBookId: bookId,
      ),
      ...booksProviderOverrides(state: pagesState),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(
        state: DisplayState.manyItems,
      ),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(child: EmptyBookPage()),
  );
}
