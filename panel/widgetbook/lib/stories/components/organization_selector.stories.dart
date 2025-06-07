import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:typewriter_panel/widgets/generic/components/organization_selector.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/logic/organization.mock.dart";

@widgetbook.UseCase(name: "OrganizationSelector", type: OrganizationSelector)
Widget organizationSelectorUseCase(BuildContext context) {
  return ProviderScope(
    overrides: [
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(
        state: MockOrganizationsState.manyOrganizations,
      ),
    ],
    child: const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: OrganizationSelector(),
      ),
    ),
  );
}
