import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/routes/organization/library/route.dart";
import "package:typewriter_panel/routes/organization/route.dart"
    show OrganizationScaffold;
import "package:typewriter_panel/widgets/generic/components/app_required.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/logic/appearance.mock.dart";
import "package:widgetbook_workspace/logic/auth.mock.dart";
import "package:widgetbook_workspace/logic/books.mock.dart";
import "package:widgetbook_workspace/logic/organization.mock.dart";

@widgetbook.UseCase(name: "LibraryPage", type: LibraryPage)
Widget libraryPageUseCase(BuildContext context) {
  final state = context.knobs.list(
    label: "State",
    initialOption: MockBooksState.fewBooks,
    options: MockBooksState.values,
    labelBuilder: (option) => option.name,
  );

  return ProviderScope(
    overrides: [
      ...booksProviderOverrides(state: state),
      // Required for the sidebar and the app bar
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(
        state: MockOrganizationsState.manyOrganizations,
      ),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: AppRequiredWidgets(
      child: OrganizationScaffold(child: LibraryPage()),
    ),
  );
}
