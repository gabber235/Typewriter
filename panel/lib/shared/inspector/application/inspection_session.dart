import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Composes the selected resources into one inspector presentation graph.
///
/// [EditorOwnerRegistry] is the authority for resource editor owners and keeps
/// those owners, drafts, and persistence state across graph refreshes. This
/// session owns only the current composite graph. Refreshes stage a new owner
/// set and graph, then commit both together; failed builds roll back staged
/// owners and preserve the installed graph.
///
/// Selection is read from [selectedProvider]. Focus is deliberately unrelated:
/// selectable surfaces own focus, while this session reacts only to selection
/// resolution and resource availability.
final class InspectionSession extends ChangeNotifier {
  InspectionSession(this.ref)
    : owners = EditorOwnerRegistry(
        workspace: ref.read(localWorkControllerProvider),
      ) {
    ref.listen(inspectedSelectionProvider, (_, next) {
      if (next.asError?.error case SelectableNotFoundException(:final id)) {
        owners.deleted(id);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) ref.read(selectionProvider.notifier).unselect(id);
        });
        SchedulerBinding.instance.ensureVisualUpdate();
      } else if (next.isLoading || next.hasError) {
        owners.unavailable(
          next.hasError
              ? "The selected resources could not be refreshed"
              : "The selected resources are refreshing",
        );
        notifyListeners();
      } else {
        _refresh();
      }
    });
    _refresh();
  }
  final Ref ref;
  bool _disposed = false;
  final EditorOwnerRegistry owners;
  InspectionBuildContext? _buildContext;

  Widget? header;
  PresentationModel? model;

  void _refresh() {
    final selection = ref.read(inspectedSelectionProvider).value;
    if (selection == null) return;

    final router = ref.read(appRouterProvider);
    final path = router.currentPath;
    final container = ref.container;

    owners.destinationFor = (identity) => InspectorDestination(
      container: container,
      router: router,
      path: path,
      identity: identity,
    );

    final refresh = owners.beginRefresh();
    final next = InspectionBuildContext(refresh);
    var committed = false;
    try {
      final content = _buildSelection(selection, next);
      final nextModel = content?.model.copyWith(ownerLabels: refresh.labels);

      refresh.commit();
      committed = true;
      final previous = _buildContext;
      _buildContext = next;
      header = content?.header;
      model = nextModel;
      previous?.dispose();
      notifyListeners();
    } on Object {
      if (!committed) {
        next.dispose();
        refresh.rollback();
      }
      rethrow;
    } finally {
      refresh.dispose();
    }
  }

  InspectionContent? _buildSelection(
    List<InspectableSelectable> selection,
    InspectionBuildContext context,
  ) {
    if (selection.isEmpty) return null;
    if (selection.length == 1) {
      return selection.single.buildInspection(context.owners);
    }

    final editable = selection.whereType<EditableSelectable>().toList();
    final definition = editable.length == selection.length
        ? editable.sharedMultiInspection
        : const TypeResult<MultiInspectionDefinition?>.success(null);
    if (definition.valueOrNull case final shared?) {
      final composed = context.compose(shared, editable);
      if (composed.valueOrNull case final content?) return content;
      return _buildStructural(
        selection,
        context,
        diagnostics: composed.diagnostics,
      );
    }
    return _buildStructural(
      selection,
      context,
      diagnostics: definition.diagnostics,
    );
  }

  InspectionContent _buildStructural(
    List<InspectableSelectable> selection,
    InspectionBuildContext context, {
    List<TypeDiagnostic> diagnostics = const [],
  }) {
    final contents = selection
        .map((item) => item.buildInspection(context.owners))
        .toList();
    final model = _combine(
      contents.map((content) => content.model).toList(),
      context,
    );
    return InspectionContent(
      model: model.copyWith(
        diagnostics: [...model.diagnostics, ...diagnostics],
      ),
    );
  }

  PresentationModel _combine(
    List<PresentationModel> models,
    InspectionBuildContext context,
  ) {
    final catalog = TypeCatalog(
      models.expand((model) => model.catalog.definitions).toSet().toList(),
    );
    final inputsBySelection = models
        .map(
          (model) => model.inputs.values
              .whereType<PresentationEditInput>()
              .map(
                (input) => input.path == DataPath.root
                    ? input.owner
                    : ProjectedEditOwner(input.owner, input.path),
              )
              .toSet()
              .toList(),
        )
        .toList();
    final combinations = <List<EditOwner>>[];
    if (inputsBySelection.every((inputs) => inputs.length == 1)) {
      combinations.add(
        inputsBySelection.map((inputs) => inputs.single).toSet().toList(),
      );
    } else {
      for (final first in inputsBySelection.first) {
        final matches = <EditOwner>[first];
        for (final candidates in inputsBySelection.skip(1)) {
          final match = candidates
              .where(
                (owner) => typeExpressionsEqual(owner.rootType, first.rootType),
              )
              .firstOrNull;
          if (match != null) matches.add(match);
        }
        if (matches.length == models.length) {
          combinations.add(matches.toSet().toList());
        }
      }
    }
    final inputs = <BindingId, PresentationInput>{};
    final children = <PresentationNode>[];
    for (final members in combinations) {
      final types = members
          .map(
            (owner) => owner.rootType is NamedType
                ? TypeRegistry(owner.typeCatalog)
                          .resolve(owner.rootType as NamedType)
                          .valueOrNull
                          ?.representation ??
                      owner.rootType
                : owner.rootType,
          )
          .toList();
      final common = types.commonEditableProjection().valueOrNull;
      if (common == null) continue;
      final owner = context.multiEditorForOwners(
        members,
        rootType: common,
        typeCatalog: catalog,
      );
      final id = BindingId(inputs.length);
      inputs[id] = PresentationInput.edit(owner);
      children.add(
        common.generateDefaultPresentation(
          binding: BindingReference(bindingId: id),
          nodeId: "selection.${id.value}",
        ),
      );
    }
    return PresentationModel(
      catalog: catalog,
      inputs: inputs,
      root: PresentationNode(
        id: "selection",
        element: ColumnElement(
          children: children.map(PresentationAxisChild.fixed).toList(),
        ),
      ),
    );
  }

  /// Flushes resource owners retained by the current graph.
  ///
  /// This persists the owners' local drafts according to their commit policy;
  /// it does not change selection or rebuild the presentation graph. When
  /// [failedOnly] is true, only resources reporting a retryable save state are
  /// submitted.
  Future<Map<Object, TypedMutationResult>> flush({bool failedOnly = false}) =>
      owners.flush(failedOnly: failedOnly);

  @override
  void dispose() {
    _disposed = true;
    _buildContext?.dispose();
    owners.dispose();
    super.dispose();
  }
}

/// Restores a resource selection and its route without retaining an inspector.
///
/// Editor resources use this destination after the inspector graph is rebuilt
/// or closed. It observes route and selection state, but owns neither; closing
/// it releases only those listeners.
final class InspectorDestination extends EditorDestination {
  InspectorDestination({
    required this.container,
    required this.router,
    required this.path,
    required this.identity,
  }) {
    router.addListener(notifyListeners);
    _selection = container.listen(
      selectionProvider,
      (_, _) => notifyListeners(),
    );
  }

  final ProviderContainer container;
  final AppRouter router;
  final String path;
  final Object identity;
  late final ProviderSubscription<List<SelectableIdentifier>> _selection;

  @override
  bool get isCurrent =>
      router.currentPath == path &&
      (identity is! SelectableIdentifier ||
          container.read(selectionProvider).contains(identity));

  /// Navigates to the saved route and selects the saved resource, if any.
  @override
  Future<void> open() async {
    if (router.currentPath != path) await router.navigatePath(path);
    if (identity case final SelectableIdentifier selected) {
      container.read(selectionProvider.notifier).selectAll([selected]);
    }
  }

  @override
  void dispose() {
    router.removeListener(notifyListeners);
    _selection.close();
    super.dispose();
  }
}
