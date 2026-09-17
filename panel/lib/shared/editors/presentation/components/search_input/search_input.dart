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
part "search_input_types.dart";

/// Renders a presentation search control and applies selections to its binding.
///
/// The enclosing [PresentationRenderScope] remains authoritative for the
/// value and edit interaction. This widget owns only query state, the value
/// captured at entry, validation feedback, and selection events consumed by
/// search history. A single selection previews and commits immediately.
/// Multiple selection toggles list members while keeping the search surface
/// open. Dismiss commits the interaction; cancel restores the captured value.
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
  final InspectedBinding binding;
  final PresentationRenderScope scope;
  final double maximumExtent;

  /// Optional source factory for callers that need a source different from
  /// the standard provider materialization.
  ///
  /// It receives the search subtree's provider reference and a synchronous
  /// stream of committed selections. The returned source is owned by the
  /// [SearchController] created for this widget and must follow the
  /// [SearchSource] disposal contract.
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

    final interaction = useEditorFieldInteraction(scope, binding.reference);

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
      final current = binding.value.valueOrNull;
      final previous = original.value.valueOrNull;
      if (current != previous && previous != null) {
        scope.update(binding.reference, previous);
      }
    }

    void finish({bool restoreFocus = true, bool cancel = false}) {
      explicitExit.value = true;
      if (interaction.active) {
        if (cancel) {
          interaction.cancel();
        } else {
          interaction.commit();
        }
      } else if (cancel) {
        restoreOriginal();
      }
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
      final current = binding.value.valueOrNull;
      final values = current is ListValue ? [...current.values] : <DataValue>[];

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
      bool finishAfterUpdate = false,
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

      scope.update(binding.reference, next);

      if (finishAfterUpdate) finish();
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
        finishAfterUpdate: close,
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

    bool acceptCustom(SearchController<dynamic> controller) {
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
        finishAfterUpdate: element.selectionMode == SearchSelectionMode.single,
      );

      if (accepted && element.selectionMode == SearchSelectionMode.multiple) {
        finish();
      }

      return accepted;
    }

    String initialQuery() {
      final expression = element.initialQuery;
      if (expression == null) {
        return binding.value.valueOrNull?.expressionDisplayText ?? "";
      }
      final result = scope.evaluate(expression);
      if (result.valueOrNull case StringValue(:final value)) return value;
      validationMessage.value =
          result.diagnostics.firstOrNull?.message ??
          "Search initial query must evaluate to text";
      return "";
    }

    return SearchRoot(
      create: (searchRef) {
        final source =
            sourceBuilder?.call(searchRef, selections.stream) ??
            PresentationSearchSourceFactory(
              client: searchRef.valued(panelHttpClientProvider),
              expressions: scope.expressions,
              registry: scope.registry,
              budget: scope.budget,
              queryBindingId: element.queryBindingId,
              selections: selections.stream,
              historyStorage: historyStorage,
              collections: scope.collections,
              realmSourceBuilder: scope.realmSearchSourceBuilder,
            ).build(element.provider);
        return SearchController(
          session: SearchSession<void>(
            source: source,
            interaction: SearchInteraction<void>(
              activation: SearchActivation.custom(
                dependencies: const [],
                evaluate: (context, result) =>
                    result.payload is PresentationSearchResultPayload
                    ? const SearchActivationState.enabled()
                    : const SearchActivationState.hidden(),
                activate: (context, result) async {
                  selectResult(result, commit: true);
                  return const SearchActivationResult.keepOpen();
                },
              ),
              selectionMode: element.selectionMode,
            ),
          ),
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
          interaction.begin();
          explicitExit.value = false;

          validationMessage.value = null;
          if (element.selectionMode == SearchSelectionMode.single) {
            controller.updateQuery(initialQuery());
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
            controller.activate(result);
            return;
          }
          acceptCustom(controller);
        },
        onDismiss: () {
          explicitExit.value = true;
          validationMessage.value = null;
          finish();
        },
        onCancel: () {
          explicitExit.value = true;
          validationMessage.value = null;
          finish(cancel: true);
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
          if (!acceptCustom(controller)) {
            finish();
            return;
          }
          finish();
        },
        onAcceptTraversal: (controller, {required backwards}) {
          final preview = controller.currentPreview;
          if (element.selectionMode == SearchSelectionMode.single &&
              preview != null) {
            selectResult(preview, commit: true);
          } else if (element.selectionMode == SearchSelectionMode.single &&
              !acceptCustom(controller)) {
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
