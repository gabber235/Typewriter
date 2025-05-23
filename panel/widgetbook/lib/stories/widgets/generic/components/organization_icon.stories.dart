import "package:flutter/material.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/widgets/generic/components/organization_icon.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: OrganizationIcon)
Widget organizationIconUseCase(BuildContext context) {
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

  return Center(
    child: OrganizationIcon(
      iconUrl: OrganizationData.generateIconUrl(seed),
      size: size,
      borderRadius: borderRadius,
    ),
  );
}

@widgetbook.UseCase(name: "Placeholder", type: OrganizationIcon)
Widget organizationIconPlaceholderUseCase(BuildContext context) {
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

  return Center(
    child: OrganizationIcon(size: size, borderRadius: borderRadius),
  );
}
