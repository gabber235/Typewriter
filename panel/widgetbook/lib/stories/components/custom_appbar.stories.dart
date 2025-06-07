import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/widgets/generic/components/custom_appbar.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: CustomAppBar)
Widget customAppBarUseCase(BuildContext context) {
  return ProviderScope(
    overrides: [organizationIdProvider.overrideWithValue("1")],
    child: Material(child: CustomAppBar()),
  );
}
