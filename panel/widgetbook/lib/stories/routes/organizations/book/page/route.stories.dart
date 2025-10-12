import "package:flutter/material.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/pages/page_type_extensions.dart";
import "package:typewriter_panel/routes/organization/book/page/route.dart";
import "package:typewriter_panel/routes/organization/book/route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/widgetbook_utils.dart";

Widget _buildPagePageUseCase(BuildContext context, PageType pageType) {
  final pagesState = context.knobs.displayState(
    label: "Pages State",
    initialOption: DisplayState.manyItems,
  );
  final entriesState = context.knobs.displayState(
    label: "Entries State",
    initialOption: DisplayState.manyItems,
  );

  return FakeApp(
    overrides: [
      ...entryProviderOverrides(),
      ...pageEntriesProviderOverrides(
        state: entriesState,
        direction: pageType.direction,
      ),
      ...bookPagesProviderOverrides(state: pagesState),
      ...pagesProviderOverrides(pageType: pageType),
      ...pageIdProviderOverrides(pageId: "example-page-id"),
      ...bookIdProviderOverrides(bookId: "example-book-id"),
      ...booksProviderOverrides(state: pagesState),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(
        state: DisplayState.manyItems,
      ),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: BookScaffold(
      child: PagePage(pageId: "example-page-id"),
    ),
  );
}

@widgetbook.UseCase(name: "Sequence", type: PagePage)
Widget pagePageSequenceUseCase(BuildContext context) {
  return _buildPagePageUseCase(context, PageType.PAGE_TYPE_SEQUENCE);
}

@widgetbook.UseCase(name: "Static", type: PagePage)
Widget pagePageStaticUseCase(BuildContext context) {
  return _buildPagePageUseCase(context, PageType.PAGE_TYPE_STATIC);
}

@widgetbook.UseCase(name: "Cinematic", type: PagePage)
Widget pagePageCinematicUseCase(BuildContext context) {
  return _buildPagePageUseCase(context, PageType.PAGE_TYPE_SCENE);
}

@widgetbook.UseCase(name: "Manifest", type: PagePage)
Widget pagePageManifestUseCase(BuildContext context) {
  return _buildPagePageUseCase(context, PageType.PAGE_TYPE_MANIFEST);
}
