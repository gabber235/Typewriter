import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/widgets/app/components/custom_appbar.dart";
import "package:typewriter_panel/widgets/generic/components/app_required.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: CustomAppBar)
Widget customAppBarUseCase(BuildContext context) {
  return ProviderScope(
    overrides: [organizationIdProvider.overrideWithValue("1")],
    child: AppRequiredWidgets(child: Material(child: CustomAppBar())),
  );
}
