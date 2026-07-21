import "package:flutter/material.dart";

import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "BookPage", type: BookPage)
Widget bookPageUseCase(BuildContext context) {
  final pagesState = context.knobs.displayState(
    label: "Pages State",
    initialOption: DisplayState.manyItems,
  );

  return FakeApp(
    overrides: [
      ...entryProviderOverrides(),
      ...bookPagesProviderOverrides(state: pagesState),
      ...pagesProviderOverrides(),
      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...booksProviderOverrides(state: pagesState),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(child: EmptyBookPage()),
  );
}
