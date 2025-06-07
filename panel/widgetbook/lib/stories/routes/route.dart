import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:typewriter_panel/routes/route.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/logic/organization.mock.dart";

@widgetbook.UseCase(name: "IndexPage", type: IndexPage)
Widget indexPageUseCase(BuildContext context) {
  final state = context.knobs.list(
    label: "State",
    initialOption: MockOrganizationsState.loading,
    options: MockOrganizationsState.values,
    labelBuilder: (option) => option.name,
  );

  return ProviderScope(
    overrides: [...organizationsProviderOverrides(state: state)],
    child: IndexPage(),
  );
}
