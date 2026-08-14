import "package:flutter/material.dart" hide SearchController;
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "icon_selector_results.dart";
part "icon_selector_row.dart";
part "icon_selector_body.dart";

typedef IconSelectorIconBuilder =
    Widget Function(
      BuildContext context,
      IconValue icon,
      double size,
      Color? color,
    );

final iconSelectorIconBuilderProvider = Provider<IconSelectorIconBuilder>(
  (ref) =>
      (context, icon, size, color) =>
          Icones.value(icon, size: size, color: color),
);

class IconSelector extends HookConsumerWidget {
  const IconSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.sourceBuilder,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool readOnly;
  final SearchSource Function(Ref ref, IconSearchSelection onSelected)?
  sourceBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputController = useInputFieldController(
      inputDebugLabel: "Icon selector query",
      surroundingDebugLabel: "Icon selector",
    );
    final editing = useState(false);
    final original = useRef(value);
    final explicitExit = useRef(false);
    final suppressNextStart = useRef(false);
    final validationMessage = useState<String?>(null);

    void restoreOriginal() {
      if (value != original.value) {
        onChanged(original.value);
      }
    }

    void finish({bool restoreFocus = true}) {
      explicitExit.value = true;
      suppressNextStart.value = true;
      inputController.endInteraction();
      if (restoreFocus) {
        inputController.requestSurroundingFocus();
      }
      editing.value = false;
      if (restoreFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) inputController.requestSurroundingFocus();
        });
      }
    }

    bool acceptDirect(String text, {bool restoreFocus = true}) {
      final icon = IconValue.from(text);
      final diagnostics = icon.validate();
      if (diagnostics.isNotEmpty) {
        validationMessage.value = diagnostics.first.message;
        return false;
      }
      validationMessage.value = null;
      onChanged(text);
      if (icon case IconifyIconValue(:final value)) {
        ref.read(iconLibraryProvider.notifier).recordRecent(value);
      }
      finish(restoreFocus: restoreFocus);
      return true;
    }

    void acceptResult(String identifier) {
      validationMessage.value = null;
      onChanged(identifier);
      ref.read(iconLibraryProvider.notifier).recordRecent(identifier);
      finish();
    }

    final buildSource = sourceBuilder;
    return SearchRoot(
      create: (searchRef) {
        final source =
            buildSource?.call(searchRef, acceptResult) ??
            IconifySearchSource(
              client: searchRef.read(panelHttpClientProvider),
              recentIdentifiers: () => searchRef.read(iconLibraryProvider),
              onSelected: acceptResult,
            ).debounced(150.ms).cached();
        return SearchController(
          source: source,
          baseSelectors: const [],
          initialQuery: value,
          onCloseRequested: finish,
        );
      },
      child: _IconSelectorBody(
        value: value,
        enabled: enabled,
        readOnly: readOnly,
        editing: editing.value,
        inputController: inputController,
        validationMessage: validationMessage.value,
        onStartEditing: () {
          if (!enabled || readOnly || editing.value) return;
          if (suppressNextStart.value) {
            suppressNextStart.value = false;
            return;
          }
          original.value = value;
          explicitExit.value = false;
          validationMessage.value = null;
          editing.value = true;
        },
        onPreview: (identifier) {
          validationMessage.value = null;
          onChanged(identifier);
        },
        onSubmit: (text, controller) {
          if (acceptDirect(text, restoreFocus: false)) return;
          final result =
              controller?.currentPreview ??
              controller?.snapshot.nodes
                  .walk()
                  .whereType<SearchResultNode>()
                  .firstOrNull
                  ?.result;
          if (result == null) return;
          final payload = result.payload;
          if (payload is IconSearchResultPayload) {
            acceptResult(payload.identifier);
            return;
          }
          controller?.executeAction(
            SelectIconSearchAction,
            resultId: result.id,
          );
        },
        onDismiss: () {
          explicitExit.value = true;
          validationMessage.value = null;
          restoreOriginal();
          finish();
        },
        onDone: (text) {
          if (explicitExit.value) {
            explicitExit.value = false;
            return;
          }
          if (acceptDirect(text)) return;
          restoreOriginal();
          validationMessage.value = null;
          editing.value = false;
        },
        onAcceptTraversal: (controller, {required backwards}) {
          final text = controller.query;
          if (!acceptDirect(text, restoreFocus: false)) {
            restoreOriginal();
            finish(restoreFocus: false);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            inputController.requestSurroundingFocus();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (backwards) {
                inputController.surroundingFocusNode.previousFocus();
              } else {
                inputController.surroundingFocusNode.nextFocus();
              }
            });
          });
        },
      ),
    );
  }
}

ActionShortcut _navigationShortcut(
  String id,
  List<ShortcutActivator> activators,
  VoidCallback invoke,
) => ActionShortcut(
  id: id,
  label: "Navigate icon results",
  description: "Navigate icon results",
  activators: activators,
  priority: 2100,
  show: false,
  onInvoke: (_) => invoke(),
);

class _IconFieldPreview extends ConsumerWidget {
  const _IconFieldPreview({required this.icon});

  final IconValue icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: EdgeInsets.all(context.spacing.space2),
    child: ref.read(iconSelectorIconBuilderProvider)(context, icon, 18, null),
  );
}

class _IconSearchStatus extends StatelessWidget {
  const _IconSearchStatus({required this.controller});

  final SearchController controller;

  @override
  Widget build(BuildContext context) => switch (controller.snapshot.status) {
    SearchSourceStatus.loading => const Padding(
      padding: EdgeInsets.all(14),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    SearchSourceStatus.error => InputIconButton(
      icon: const Icon(Icons.refresh_rounded),
      tooltip: "Retry icon search",
      onPressed: controller.refresh,
    ),
    _ => const SizedBox.shrink(),
  };
}
