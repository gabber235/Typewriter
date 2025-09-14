import "package:flutter/material.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/widgets/app/components/custom_appbar.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: CustomAppBar)
Widget customAppBarUseCase(BuildContext context) {
  return FakeApp(
    overrides: [organizationIdProvider.overrideWithValue("1")],
    child: Material(child: CustomAppBar()),
  );
}
