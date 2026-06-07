import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/headers/add_action.dart";
import "package:typewriter/widgets/inspector/headers/delete_action.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class AddListHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      dataBlueprint is ListBlueprint;

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
      AddListHeaderAction(
        path: path,
        listBlueprint: dataBlueprint as ListBlueprint,
      );
}

class AddListHeaderAction extends HookConsumerWidget {
  const AddListHeaderAction({
    required this.path,
    required this.listBlueprint,
    super.key,
  }) : super();

  final String path;
  final ListBlueprint listBlueprint;

  void _addNew(PassingRef ref) {
    ref.read(inspectingEntryDefinitionProvider)?.updateField(
      ref,
      path,
      [..._get(ref), listBlueprint.type.defaultValue()],
    );
  }

  List<dynamic> _get(PassingRef ref) {
    return ref.read(fieldValueProvider(path)) as List<dynamic>? ?? [];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AddHeaderAction(path: path, onAdd: () => _addNew(ref.passing));
  }
}

class ReorderListHeaderActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      context.parentBlueprint is ListBlueprint;

  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      HeaderActionLocation.leading;

  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) {
    final index = path.split(".").last.asInt;
    if (index == null) return const SizedBox.shrink();
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: ReorderableDragStartListener(
        index: index,
        child: const Iconify(
          TWIcons.barsStaggered,
          size: 12,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class DuplicateListItemActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      context.parentBlueprint is ListBlueprint;

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
      DuplicateListItemAction(
        path: path,
        dataBlueprint: dataBlueprint,
      );
}

class DuplicateListItemAction extends HookConsumerWidget {
  const DuplicateListItemAction({
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

  void _duplicate(PassingRef ref) {
    final parentValue = ref.read(fieldValueProvider(parentPath, []));
    final value =
        ref.read(fieldValueProvider(path, dataBlueprint.defaultValue()));

    ref.read(inspectingEntryDefinitionProvider)?.updateField(
      ref,
      parentPath,
      [...parentValue, value],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final name = ref.watch(pathDisplayNameProvider(path)).singular;
    return IconButton(
      icon: const Iconify(TWIcons.duplicate, size: 12),
      color: Colors.green,
      tooltip: l10n.duplicateThis(name),
      onPressed: () => _duplicate(ref.passing),
    );
  }
}

class RemoveListItemActionFilter extends HeaderActionFilter {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
  ) =>
      context.parentBlueprint is ListBlueprint;

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
      RemoveListItemAction(path: path);
}

class RemoveListItemAction extends HookConsumerWidget {
  const RemoveListItemAction({
    required this.path,
    super.key,
  });

  final String path;

  void _remove(PassingRef ref) {
    final parts = path.split(".");
    final index = parts.removeLast().asInt!;
    final parentPath = parts.join(".");

    final value =
        ref.read(fieldValueProvider(parentPath)) as List<dynamic>? ?? [];
    ref.read(inspectingEntryDefinitionProvider)?.updateField(
          ref,
          parentPath,
          [...value]..removeAt(index),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RemoveHeaderAction(path: path, onRemove: () => _remove(ref.passing));
  }
}
