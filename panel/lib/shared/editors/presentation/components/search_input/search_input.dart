import "dart:async";

import "package:flutter/material.dart" hide SearchController;
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "search_input_body.dart";
part "search_input_navigation.dart";
part "search_input_results.dart";
part "search_input_row.dart";

typedef PresentationSearchSourceBuilder =
    SearchSource Function(
      Ref ref,
      Stream<PresentationSearchSelectionEvent> selections,
    );

class PresentationSearchInput extends HookConsumerWidget {
  const PresentationSearchInput({
    required this.element,
    required this.binding,
    required this.scope,
    required this.maximumExtent,
    this.sourceBuilder,
    super.key,
  });

  final SearchInputElement element;
  final ResolvedBinding binding;
  final PresentationRenderScope scope;
  final double maximumExtent;
  final PresentationSearchSourceBuilder? sourceBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputController = useInputFieldController(
      inputDebugLabel: "Search input query",
      surroundingDebugLabel: "Search input",
    );
    final editing = useState(false);
    final original = useRef(binding.value);
    final explicitExit = useRef(false);
    final selectingWithPointer = useRef(false);
    final validationMessage = useState<String?>(null);
    final selections = useMemoized(
      () => StreamController<PresentationSearchSelectionEvent>.broadcast(
        sync: true,
      ),
    );
    useEffect(() => selections.close, [selections]);
    final historyStorage = useMemoized(
      () => PresentationSearchHistoryStorage(
        namespace: scope.historyNamespace,
        expressions: scope.expressions,
        registry: scope.registry,
      ),
      [scope.historyNamespace, scope.registry],
    );

    void restoreOriginal() {
      if (binding.value != original.value) {
        scope.update(binding.reference, original.value);
      }
    }

    void finish({bool restoreFocus = true}) {
      explicitExit.value = true;
      inputController.endInteraction();
      inputController.inputFocusNode.unfocus();
      editing.value = false;
      if (restoreFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          inputController.requestSurroundingFocus();
        });
      }
    }

    DataValue? nextValue(DataValue selected, {required bool toggle}) {
      if (element.selectionMode == SearchSelectionMode.single) return selected;
      final current = binding.value;
      if (current is! ListValue) return null;
      final values = [...current.values];
      final index = values.indexOf(selected);
      if (toggle && index >= 0) {
        values.removeAt(index);
      } else if (index < 0) {
        values.add(selected);
      }
      return ListValue(values);
    }

    bool applyValue(
      DataValue selected, {
      required bool toggle,
      bool finishBeforeUpdate = false,
    }) {
      final next = nextValue(selected, toggle: toggle);
      if (next == null) return false;
      final diagnostics = next.validateAgainst(
        binding.type,
        registry: scope.registry,
      );
      if (diagnostics.isNotEmpty) {
        validationMessage.value = diagnostics.first.message;
        return false;
      }
      validationMessage.value = null;
      if (finishBeforeUpdate) finish();
      scope.update(binding.reference, next);
      return true;
    }

    void selectResult(SearchResult result, {required bool commit}) {
      final payload = result.payload;
      if (payload is! PresentationSearchResultPayload) return;
      final toggle = element.selectionMode == SearchSelectionMode.multiple;
      final close =
          commit && element.selectionMode == SearchSelectionMode.single;
      if (!applyValue(
        payload.selectedValue,
        toggle: toggle,
        finishBeforeUpdate: close,
      )) {
        return;
      }
      if (!commit) return;
      selections.add(
        PresentationSearchSelectionEvent(
          result: result,
          historyNamespace: payload.providerKey,
        ),
      );
    }

    bool acceptCustom(SearchController controller) {
      final custom = element.customValue;
      if (custom == null) return false;
      final expressions = presentationSearchContext(
        base: scope.expressions,
        queryBindingId: element.queryBindingId,
        query: controller.queryContext,
        selectors: element.provider.searchSelectors,
      );
      final result = custom.evaluate(
        expressions,
        registry: scope.registry,
        budget: scope.budget,
      );
      if (result case TypeFailure(:final diagnostics)) {
        validationMessage.value = diagnostics.first.message;
        return false;
      }
      final accepted = applyValue(
        result.valueOrNull!,
        toggle: false,
        finishBeforeUpdate: element.selectionMode == SearchSelectionMode.single,
      );
      if (accepted && element.selectionMode == SearchSelectionMode.multiple) {
        finish();
      }
      return accepted;
    }

    final buildSource = sourceBuilder;
    return SearchRoot(
      create: (searchRef) {
        final source =
            buildSource?.call(searchRef, selections.stream) ??
            PresentationSearchSourceFactory(
              client: searchRef.read(panelHttpClientProvider),
              expressions: scope.expressions,
              registry: scope.registry,
              budget: scope.budget,
              queryBindingId: element.queryBindingId,
              selections: selections.stream,
              historyStorage: historyStorage,
              realmSourceBuilder: scope.realmSearchSourceBuilder,
            ).build(element.provider);
        return SearchController(
          source: source,
          baseSelectors: const [],
          onCloseRequested: finish,
        );
      },
      child: _PresentationSearchInputBody(
        element: element,
        binding: binding,
        scope: scope,
        maximumExtent: maximumExtent,
        editing: editing.value,
        inputController: inputController,
        validationMessage: validationMessage.value,
        onStartEditing: (controller) {
          if (!scope.enabled || scope.readOnly || !binding.writable) return;
          original.value = binding.value;
          explicitExit.value = false;
          validationMessage.value = null;
          if (element.selectionMode == SearchSelectionMode.single) {
            controller.updateQuery(binding.value.expressionDisplayText);
          }
          inputController.inputFocusNode.unfocus();
          editing.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!editing.value) return;
            inputController.beginInteraction();
          });
        },
        onPreview: (result) {
          if (element.selectionMode == SearchSelectionMode.single) {
            selectResult(result, commit: false);
          }
        },
        onSelect: (result) => selectResult(result, commit: true),
        onSelectionPointerDown: () {
          selectingWithPointer.value = true;
        },
        onSelectionPointerEnd: () {
          selectingWithPointer.value = false;
          if (element.selectionMode != SearchSelectionMode.multiple) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (editing.value) inputController.requestInputFocus();
          });
        },
        onSubmit: (controller) {
          final result =
              controller.currentPreview ??
              controller.snapshot.nodes
                  .walk()
                  .whereType<SearchResultNode>()
                  .firstOrNull
                  ?.result;
          if (result != null) {
            selectResult(result, commit: true);
            return;
          }
          acceptCustom(controller);
        },
        onDismiss: () {
          explicitExit.value = true;
          validationMessage.value = null;
          restoreOriginal();
          finish();
        },
        onDone: (controller) {
          if (selectingWithPointer.value) return;
          if (explicitExit.value) {
            explicitExit.value = false;
            return;
          }
          if (element.selectionMode == SearchSelectionMode.multiple) {
            finish();
            return;
          }
          if (controller.currentPreview case final result?) {
            selectResult(result, commit: true);
            return;
          }
          if (!acceptCustom(controller)) restoreOriginal();
          finish();
        },
        onAcceptTraversal: (controller, {required backwards}) {
          final preview = controller.currentPreview;
          if (element.selectionMode == SearchSelectionMode.single &&
              preview != null) {
            selectResult(preview, commit: true);
          } else if (element.selectionMode == SearchSelectionMode.single &&
              !acceptCustom(controller)) {
            restoreOriginal();
            finish(restoreFocus: false);
          } else {
            finish(restoreFocus: false);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            inputController.requestSurroundingFocus();
            if (backwards) {
              inputController.surroundingFocusNode.previousFocus();
            } else {
              inputController.surroundingFocusNode.nextFocus();
            }
          });
        },
      ),
    );
  }
}
