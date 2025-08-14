import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/routes/organization/modules/route.dart";
import "package:typewriter_panel/routes/organization/route.dart"
    show OrganizationScaffold;
import "package:typewriter_panel/widgets/generic/components/app_required.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/logic/appearance.mock.dart";
import "package:widgetbook_workspace/logic/auth.mock.dart";
import "package:widgetbook_workspace/logic/modules.mock.dart";
import "package:widgetbook_workspace/logic/organization.mock.dart";

@widgetbook.UseCase(name: "ModulesPage", type: ModulesPage)
Widget modulesPageUseCase(BuildContext context) {
  final state = context.knobs.list(
    label: "State",
    initialOption: MockModulesState.fewModules,
    options: MockModulesState.values,
    labelBuilder: (option) => option.name,
  );

  return ProviderScope(
    overrides: [
      ...modulesProviderOverrides(state: state),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(
        state: MockOrganizationsState.manyOrganizations,
      ),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: const AppRequiredWidgets(
      child: OrganizationScaffold(child: ModulesPage()),
    ),
  );
}
