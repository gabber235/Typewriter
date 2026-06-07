import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/widgets/components/general/admonition.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/editors/field.dart";
import "package:typewriter/widgets/inspector/header.dart";
import "package:typewriter/widgets/inspector/inspector.dart";
import "package:url_launcher/url_launcher_string.dart";

class GenericEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint is CustomBlueprint && dataBlueprint.editor == "generic";

  @override
  Widget build(String path, DataBlueprint dataBlueprint) => GenericEditor(
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
    final blueprint = context.genericBlueprint ??
        ref.watch(inspectingEntryProvider)?.genericBlueprint;

    if (blueprint == null) return (const HeaderActions(), []);

    // We want don't want to make the generic the parent for the child context as it should be transparent.
    return headerActionsFor(ref, path, blueprint, context);
  }
}

class GenericEditor extends HookConsumerWidget {
  const GenericEditor({
    required this.path,
    required this.customBlueprint,
    super.key,
  });

  final String path;
  final CustomBlueprint customBlueprint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We want to memoize this because when dragging in a list, the Generic.maybeOf is no longer available.
    // But we still want to show the correct editor.
    // Since the blueprint will stay the same, we can memoize it.
    final blueprint = useMemoized(() {
      final generic = Generic.maybeOf(context);
      if (generic != null) return generic.dataBlueprint;

      return ref.read(inspectingEntryProvider)?.genericBlueprint;
    });

    if (blueprint == null) return GenericNotFoundWidget();

    return FieldEditor(path: path, dataBlueprint: blueprint);
  }
}

class GenericNotFoundWidget extends HookConsumerWidget {
  const GenericNotFoundWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return Admonition.danger(
      onTap: () => launchUrlString("https://discord.gg/uYfnzJAFZN"),
      child: Text.rich(
        TextSpan(
          text: l10n.genericNotFound,
          children: [
            TextSpan(
              text: l10n.genericNotFoundDescription,
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

class Generic extends InheritedWidget {
  const Generic({
    required this.dataBlueprint,
    required super.child,
    super.key,
  });

  final DataBlueprint dataBlueprint;

  @override
  bool updateShouldNotify(covariant Generic oldWidget) {
    return dataBlueprint != oldWidget.dataBlueprint;
  }

  static Generic? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Generic>();
}
