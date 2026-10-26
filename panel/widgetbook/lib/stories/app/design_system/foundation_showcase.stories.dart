import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/data.dart";

@widgetbook.UseCase(
  name: "Default",
  type: FoundationShowcase,
  path: "app/design_system",
)
Widget foundationShowcaseUseCase(BuildContext context) =>
    const FakeApp(child: FoundationShowcase());
