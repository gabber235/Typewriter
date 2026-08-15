import "package:flutter/material.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: DomainColorShowcase)
Widget domainColorShowcaseUseCase(BuildContext context) =>
    const FakeApp(child: DomainColorShowcase());
