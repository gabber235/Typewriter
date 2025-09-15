import "package:flutter/material.dart" hide Page;
import "package:mocktail/mocktail.dart";
import "package:pub_semver/pub_semver.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/manuals/manuals.dart";
import "package:typewriter_panel/logic/module_version/module_version.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/pages.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

export "appearance.mock.dart";
export "auth.mock.dart";
export "books.mock.dart";
export "manuals.mock.dart";
export "mock_utils.dart";
export "modules.mock.dart";
export "organization.mock.dart";
export "pages.mock.dart";
export "tag.mock.dart";

void registerFallbackValues() {
  registerFallbackValue(ThemeMode.system);
  registerFallbackValue(
    TestSelectableIdentifier(
      id: "",
      dataBlueprint: ObjectBlueprint(fields: {}),
    ),
  );
  registerFallbackValue(Book(id: "", title: "", icon: ""));
  registerFallbackValue(Module(id: "", name: "", type: ModuleType.extension));
  registerFallbackValue(Version.none);
  registerFallbackValue(ModuleVersionState.developing);
  registerFallbackValue(Manual(id: "", name: "", platforms: [], modules: []));
  registerFallbackValue(<PlatformTarget>[]);
  registerFallbackValue(<ManualModuleReference>[]);
  registerFallbackValue(DynamicData({}));
  registerFallbackValue(
    Page(
      id: "",
      pageName: "",
      type: PageType.sequence,
    ),
  );
  registerFallbackValue(
    EntryDefinition(
      id: "",
      name: "",
      blueprint: EntryBlueprint(
        id: "",
        name: "",
        description: "",
        extension: "",
        dataBlueprint: ObjectBlueprint(fields: {}),
      ),
      data: DynamicData({}),
    ),
  );
  registerFallbackValue(
    EntryBlueprint(
      id: "",
      name: "",
      description: "",
      extension: "",
      dataBlueprint: ObjectBlueprint(fields: {}),
    ),
  );
  registerFallbackValue(
    EntryIdentifier(""),
  );
  registerFallbackValue(PageType.sequence);
}
