import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/ion.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";
import "package:typewriter_panel/widgets/app/components/inspector/headers/add_header.dart";
import "package:typewriter_panel/widgets/app/components/inspector/headers/remove_header.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class AddListHeaderAction extends HeaderAction {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      mode.canEdit && dataBlueprint is ListBlueprint;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      HeaderActionLocation.actions;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      AddListHeaderActionWidget(
        path: path,
        listBlueprint: dataBlueprint as ListBlueprint,
      );
}

class AddListHeaderActionWidget extends HookConsumerWidget {
  const AddListHeaderActionWidget({
    required this.path,
    required this.listBlueprint,
    super.key,
  }) : super();

  final String path;
  final ListBlueprint listBlueprint;

  void _addNew(WidgetRef ref) {
    final currentValue = _get(ref);
    final newValue = [...currentValue, listBlueprint.type.defaultValue()];
    ref.read(selectedProvider.notifier).updateFieldValue(path, newValue);
  }

  List<dynamic> _get(WidgetRef ref) {
    return ref.read(fieldValueProvider(path)).value([]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AddHeaderAction(path: path, onAdd: () => _addNew(ref));
  }
}

class ReorderListHeaderAction extends HeaderAction {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      mode.canEdit && context.parentBlueprint is ListBlueprint;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      HeaderActionLocation.leading;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) {
    final index = path.split(".").last.asInt;
    if (index == null) return const SizedBox.shrink();
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: ReorderableDragStartListener(
        index: index,
        child: const Icones(
          Fa6Solid.bars_staggered,
          color: Colors.grey,
          size: 14,
        ),
      ),
    );
  }
}

class DuplicateListItemAction extends HeaderAction {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      mode.canEdit && context.parentBlueprint is ListBlueprint;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      HeaderActionLocation.actions;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      DuplicateListItemActionWidget(
        path: path,
        dataBlueprint: dataBlueprint,
      );
}

class DuplicateListItemActionWidget extends HookConsumerWidget {
  const DuplicateListItemActionWidget({
    required this.path,
    required this.dataBlueprint,
    super.key,
  });

  final String path;
  final DataBlueprint dataBlueprint;

  String get parentPath {
    final parts = path.split(".")..removeLast();
    return parts.join(".");
  }

  void _duplicate(WidgetRef ref) {
    final parentValue = _get(ref, parentPath, []);
    final value = _get(ref, path, dataBlueprint.defaultValue());

    ref.read(selectedProvider.notifier).updateFieldValue(
      parentPath,
      [...parentValue, value],
    );
  }

  T _get<T>(WidgetRef ref, String path, T defaultValue) {
    return ref.read(fieldValueProvider(path)).value(defaultValue);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(pathDisplayNameProvider(path)).singular;
    return IconButton(
      icon: const Icones(Ion.duplicate),
      iconSize: 16,
      color: Colors.green,
      tooltip: "Duplicate $name",
      onPressed: () => _duplicate(ref),
    );
  }
}

class RemoveListItemAction extends HeaderAction {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      mode.canEdit && context.parentBlueprint is ListBlueprint;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      HeaderActionLocation.actions;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode mode,
  ) =>
      RemoveListItemActionWidget(path: path);
}

class RemoveListItemActionWidget extends HookConsumerWidget {
  const RemoveListItemActionWidget({
    required this.path,
    super.key,
  });

  final String path;

  void _remove(WidgetRef ref) {
    final parts = path.split(".");
    final index = parts.removeLast().asInt!;
    final parentPath = parts.join(".");

    final value = _get(ref, parentPath, []);
    ref.read(selectedProvider.notifier).updateFieldValue(
          parentPath,
          [...value]..removeAt(index),
        );
  }

  T _get<T>(WidgetRef ref, String path, T defaultValue) {
    return ref.read(fieldValueProvider(path)).value(defaultValue);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RemoveHeaderAction(path: path, onRemove: () => _remove(ref));
  }
}
