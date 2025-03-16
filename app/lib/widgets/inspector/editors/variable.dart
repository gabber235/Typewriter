import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/general/admonition.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/field.dart";
import "package:typewriter/widgets/inspector/editors/generic.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class VariableEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "var";

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => VariableEditor(
        path: path,
        customBlueprint: dataBlueprint as CustomBlueprint,
      );

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref<Object?> ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
  ) {
    final customBlueprint = dataBlueprint as CustomBlueprint;

    final value =
        ref.watch(fieldValueProvider(path, customBlueprint.defaultValue()));
    final data = variableData(value);
    final actions = super.headerActions(ref, path, dataBlueprint, context);

    if (data == null) {
      final child = headerActionsFor(
        ref,
        path,
        customBlueprint.shape,
        context.copyWith(parentBlueprint: dataBlueprint),
      );
      return (actions.$1.merge(child.$1), actions.$2.followedBy(child.$2));
    }

    final variableEntryId = data.ref;
    if (variableEntryId == null) return actions;
    final variableBlueprintId =
        ref.watch(entryBlueprintIdProvider(variableEntryId));
    if (variableBlueprintId == null) return actions;

    final variableBlueprint =
        ref.watch(entryBlueprintProvider(variableBlueprintId));
    if (variableBlueprint == null) return actions;

    final variableDataBlueprint = variableBlueprint.variableDataBlueprint;
    if (variableDataBlueprint == null) return actions;

    final child = headerActionsFor(
      ref,
      path.join("data"),
      variableDataBlueprint,
      context.copyWith(
        parentBlueprint: dataBlueprint,
        genericBlueprint: customBlueprint.shape,
      ),
    );

    return (actions.$1.merge(child.$1), actions.$2.followedBy(child.$2));
  }
}

class VariableEditor extends HookConsumerWidget {
  const VariableEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  void _removeVariable(PassingRef ref) {
    ref
        .read(inspectingEntryDefinitionProvider)
        ?.updateField(ref, path, customBlueprint.defaultValue());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value =
        ref.watch(fieldValueProvider(path, customBlueprint.defaultValue()));
    final data = variableData(value);
    if (data == null) {
      final child =
          FieldEditor(path: path, dataBlueprint: customBlueprint.shape);

      if (customBlueprint.shape.hasCustomLayout) {
        return child;
      }

      return FieldHeader(
        path: path,
        child: child,
      );
    }

    final variableEntryId = data.ref;
    if (variableEntryId == null) {
      return _buildError(ref.passing);
    }

    final variableBlueprintId =
        ref.watch(entryBlueprintIdProvider(variableEntryId));
    if (variableBlueprintId == null) {
      return _buildError(ref.passing);
    }
    final variableBlueprint =
        ref.watch(entryBlueprintProvider(variableBlueprintId));
    if (variableBlueprint == null) {
      return _buildError(ref.passing);
    }

    final variableDataBlueprint = variableBlueprint.variableDataBlueprint;
    final header = Header.maybeOf(context);

    return Generic(
      dataBlueprint: customBlueprint.shape,
      child: FieldHeader(
        path: path,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: DottedBorder(
            color: Colors.green,
            borderType: BorderType.RRect,
            strokeWidth: 2,
            dashPattern: const [5, 5],
            radius: const Radius.circular(4),
            child: Material(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    ContextMenuRegion(
                      builder: (context) => [
                        ContextMenuTile.button(
                          title: "Navigate to entry",
                          icon: TWIcons.pencil,
                          onTap: () {
                            ref
                                .read(inspectingEntryIdProvider.notifier)
                                .navigateAndSelectEntry(
                                  ref.passing,
                                  variableEntryId,
                                );
                          },
                        ),
                      ],
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                ref
                                    .read(inspectingEntryIdProvider.notifier)
                                    .navigateAndSelectEntry(
                                      ref.passing,
                                      variableEntryId,
                                    );
                              },
                              child: FakeEntryNode(entryId: variableEntryId),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (variableDataBlueprint != null) ...[
                      const SizedBox(height: 8),
                      Header(
                        expanded: header?.expanded ?? ValueNotifier(true),
                        canExpand: header?.canExpand ?? false,
                        depth: header?.depth ?? 0,
                        path: path.join("data"),
                        child: FieldEditor(
                          path: path.join("data"),
                          dataBlueprint: variableDataBlueprint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(PassingRef ref) {
    return Admonition.danger(
      onTap: () => _removeVariable(ref),
      child: Text.rich(
        TextSpan(
          text: "Could not find Variable Reference, ",
          children: [
            TextSpan(
              text: "click to reset to default",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

VariableData? variableData(dynamic value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }
  if (!value.containsKey("_kind")) {
    return null;
  }
  return VariableData.fromJson(value);
}

class VariableData {
  const VariableData(this._kind, this.ref, this.data);

  factory VariableData.fromJson(Map<String, dynamic> json) => VariableData(
        json["_kind"] as String,
        json["ref"] as String?,
        stringMap(json["data"]),
      );

  final String _kind;
  final String? ref;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
        "_kind": _kind,
        "ref": ref,
        "data": data,
      };
}
