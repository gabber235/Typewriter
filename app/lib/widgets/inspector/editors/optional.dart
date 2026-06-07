import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/color_filter.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/field.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class OptionalEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "optional";

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => OptionalEditor(
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
    final shape = customBlueprint.shape;
    if (shape is! ObjectBlueprint) return (const HeaderActions(), []);
    if (!shape.fields.containsKey("value")) return (const HeaderActions(), []);
    final subBlueprint = shape.fields["value"];
    if (subBlueprint == null) return (const HeaderActions(), []);

    final actions = super.headerActions(ref, path, dataBlueprint, context);
    final child = headerActionsFor(
      ref,
      path.join("value"),
      subBlueprint,
      context.copyWith(parentBlueprint: dataBlueprint),
    );

    final enabled = ref.watch(fieldValueProvider(path.join("enabled"), false));

    return (
      actions.$1.merge(
        child.$1.mapWidgets((widget) {
          if (enabled) {
            return widget;
          }
          return _DisabledHeaderWidget(child: widget);
        }),
      ),
      actions.$2.followedBy(child.$2)
    );
  }
}

class OptionalEditor extends HookConsumerWidget {
  const OptionalEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  DataBlueprint? get subDataBlueprint {
    final shape = customBlueprint.shape;
    if (shape is! ObjectBlueprint) return null;
    if (!shape.fields.containsKey("value")) return null;
    return shape.fields["value"];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final enabled = ref.watch(fieldValueProvider(path.join("enabled"), false));

    final subDataBlueprint = useMemoized(() => this.subDataBlueprint);
    if (subDataBlueprint == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          l10n.invalidSubfield,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final subPath = path.join("value");

    final header = Header.maybeOf(context);

    return Row(
      children: [
        Checkbox(
          value: enabled,
          onChanged: (value) {
            ref.read(inspectingEntryDefinitionProvider)?.updateField(
                  ref.passing,
                  path.join("enabled"),
                  value ?? false,
                );
          },
        ),
        Expanded(
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.6,
            duration: 200.ms,
            curve: Curves.easeOut,
            child: MouseRegion(
              cursor:
                  enabled ? MouseCursor.defer : SystemMouseCursors.forbidden,
              child: AbsorbPointer(
                absorbing: !enabled,
                child: Header(
                  path: subPath,
                  expanded: header?.expanded ?? ValueNotifier(true),
                  canExpand: header?.canExpand ?? false,
                  depth: header?.depth ?? 0,
                  child: FieldEditor(
                    path: subPath,
                    dataBlueprint: subDataBlueprint,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DisabledHeaderWidget extends StatelessWidget {
  const _DisabledHeaderWidget({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.forbidden,
      child: AbsorbPointer(
        child: AnimatedOpacity(
          opacity: 0.6,
          duration: 200.ms,
          curve: Curves.easeOut,
          child: ColorFiltered(
            colorFilter: greyscale,
            child: child,
          ),
        ),
      ),
    );
  }
}
