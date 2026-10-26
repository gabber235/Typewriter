import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/data.dart";

import "realm_showcase_story.dart";

@widgetbook.UseCase(name: "Owner chain", type: ResourceBreadcrumbs)
Widget resourceBreadcrumbsUseCase(BuildContext context) => RealmShowcaseStory(
  routed: fixtureShowcasePage,
  child: const Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: EdgeInsets.all(16), child: ResourceBreadcrumbs()),
    ),
  ),
);
