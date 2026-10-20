import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

import "compiled_sdk_control_fixture.dart";

/// The display Realm publishes for elements, which names a resource by its
/// `name` field, retargeted to [target] so a test catalog names its resources
/// exactly as Realm does.
skir.ResourceDisplayFormulas nameResourceDisplay(skir.TypeTemplate target) {
  final element = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "kotlin",
      name: "com.typewritermc.elements.Element",
    ),
    revision: 1,
  );
  final display = compiledSdkControlCatalog.resourceDisplays.singleWhere(
    (display) => switch (display.target) {
      skir.ResourceTarget_typeWrapper(
        value: skir.TypeTemplate_namedWrapper(:final value),
      ) =>
        value.definition == element,
      _ => false,
    },
  );
  return skir.ResourceDisplayFormulas(
    target: skir.ResourceTarget.wrapType(target),
    label: display.label,
    accent: display.accent,
    icon: display.icon,
  );
}
