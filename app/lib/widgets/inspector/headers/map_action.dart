import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/headers/add_action.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class AddMapHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      dataBlueprint is MapBlueprint;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      HeaderActionLocation.actions;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      AddMapHeaderAction(
        path: path,
        mapBlueprint: dataBlueprint as MapBlueprint,
      );
}

class AddMapHeaderAction extends HookConsumerWidget {
  const AddMapHeaderAction({
    required this.path,
    required this.mapBlueprint,
    super.key,
  }) : super();

  final String path;
  final MapBlueprint mapBlueprint;

  void _addNew(PassingRef ref) {
    final value = stringMap(
      ref.read(fieldValueProvider(path, mapBlueprint.defaultValue())),
    );

    final key = switch (mapBlueprint.key) {
      EnumBlueprint(values: final values) =>
        values.firstWhereOrNull((e) => !value.containsKey(e)),
      CustomBlueprint(editor: "ref") => "",
      _ => mapBlueprint.key.defaultValue(),
    };
    if (key == null) return;

    final val = mapBlueprint.value.defaultValue();
    ref.read(inspectingEntryDefinitionProvider)?.updateField(
      ref,
      path,
      {
        ...value.map(MapEntry.new),
        key: val,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AddHeaderAction(path: path, onAdd: () => _addNew(ref.passing));
  }
}
