import "package:flutter/material.dart";

import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "Default", type: BookPage)
Widget bookPageUseCase(BuildContext context) {
  final pagesState = context.knobs.displayState(
    label: "Pages State",
    initialOption: DisplayState.manyItems,
  );
  final connectionState = context.knobs.realmConnectionState();

  return FakeApp(
    overrides: [
      realmInteractionProvider.overrideWith(
        (ref) => RealmInteractionState(connectionState: connectionState),
      ),
      ...entryProviderOverrides(),
      ...bookPagesProviderOverrides(state: pagesState),
      ...pagesProviderOverrides(),
      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...booksProviderOverrides(state: pagesState),
      ...servicesProviderOverrides(state: DisplayState.manyItems),
      ...realmProviderOverrides(),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(child: EmptyBookPage()),
  );
}
