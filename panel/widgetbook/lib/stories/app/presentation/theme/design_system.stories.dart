import "package:flutter/material.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Foundation", type: FoundationShowcase)
Widget foundationShowcase(BuildContext context) =>
    const FakeApp(child: FoundationShowcase());

@widgetbook.UseCase(name: "Controls", type: ControlsShowcase)
Widget controlsShowcase(BuildContext context) =>
    const FakeApp(child: ControlsShowcase());

@widgetbook.UseCase(name: "Domain colors", type: DomainColorShowcase)
Widget domainColorShowcase(BuildContext context) =>
    const FakeApp(child: DomainColorShowcase());
