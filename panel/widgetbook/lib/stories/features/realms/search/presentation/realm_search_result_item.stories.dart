import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: RealmSearchResultItem)
Widget realmSearchResultItemUseCase(BuildContext context) {
  final realms = completeTopologyScenario().topology.realms.toList();
  final realm = context.knobs.object.dropdown(
    label: "Realm",
    options: realms,
    initialOption: realms.first,
    labelBuilder: (realm) => childRuntimeStatusLabel(realm.state.status),
  );
  final row = context.knobs.object.segmented(
    label: "Row",
    options: const ["Idle", "Focused", "Selected", "Loading"],
    initialOption: "Idle",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 560,
        child: RealmSearchResultItem.realm(
          realm: realm,
          focused: row == "Focused",
          selected: row == "Selected",
          loading: row == "Loading",
          onTap: () {},
        ),
      ),
    ),
  );
}
