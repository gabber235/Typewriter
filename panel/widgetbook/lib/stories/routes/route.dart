import "package:flutter/material.dart";
import "package:typewriter_panel/routes/route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/widgetbook_utils.dart";

@widgetbook.UseCase(name: "IndexPage", type: IndexPage)
Widget indexPageUseCase(BuildContext context) {
  final displayState = context.knobs.displayState();

  return FakeApp(
    overrides: [...organizationsProviderOverrides(state: displayState)],
    child: IndexPage(),
  );
}
