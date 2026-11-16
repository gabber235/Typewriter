import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/support/story.dart";

/// A realm in the primary search: its host's name, its runtime status, or
/// Host offline when its host does not answer, and the shortcut that
/// opens it.
@widgetbook.UseCase(name: "Default", type: RealmSearchResultItem)
Widget realmSearchResultItemUseCase(BuildContext context) {
  final realms = completeTopologyScenario().topology.realms.toList();
  final picked = context.knobs.object.dropdown(
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
  final long = context.knobs.boolean(label: "Long name");
  final width = context.knobs.width(const {"Wide": 560, "Narrow": 280});
  final realm = long
      ? (picked.toMutable()
              ..ownerHost = skir.OwnerHost(
                id: picked.ownerHost.id,
                name: "northern_survival_realm_with_seasonal_quests_and_events",
              ))
            .toFrozen()
      : picked;
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: RealmSearchResultItem.realm(
          realm: realm,
          focused: row == "Focused",
          selected: row == "Selected",
          loading: row == "Loading",
          shortcutActivator: AdaptiveSingleActivator(
            LogicalKeyboardKey.digit1,
            control: true,
          ),
          onTap: () {},
        ),
      ),
    ),
  );
}
