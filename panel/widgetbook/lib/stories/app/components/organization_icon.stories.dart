import "package:flutter/material.dart";
import "package:typewriter_panel/logic/organization/organization.dart";
import "package:typewriter_panel/widgets/app/components/organization_icon.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: OrganizationLogo)
Widget organizationLogoUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    label: "Size",
    initialValue: 40,
    min: 20,
    max: 100,
  );
  final borderRadius = context.knobs.double.slider(
    label: "Border Radius",
    initialValue: 8,
    min: 0,
    max: 20,
  );
  final seed = context.knobs.string(label: "Seed", initialValue: "test");

  return FakeApp(
    child: Center(
      child: OrganizationLogo(
        logoUrl: generateOrganizationIconUrl(seed),
        size: size,
        borderRadius: borderRadius,
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Placeholder", type: OrganizationLogo)
Widget organizationLogoPlaceholderUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    label: "Size",
    initialValue: 40,
    min: 20,
    max: 100,
  );
  final borderRadius = context.knobs.double.slider(
    label: "Border Radius",
    initialValue: 8,
    min: 0,
    max: 20,
  );

  return FakeApp(
    child: Center(
      child: OrganizationLogo(size: size, borderRadius: borderRadius),
    ),
  );
}
