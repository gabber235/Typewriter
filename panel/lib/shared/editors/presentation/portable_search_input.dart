part of "portable_presentation_renderer.dart";

final class PortableSearchInput extends HookWidget {
  const PortableSearchInput({
    required this.control,
    required this.scope,
    this.client,
    super.key,
  });

  final skir.SearchControl control;
  final PortablePresentationScope scope;
  final Client? client;

  @override
  Widget build(BuildContext context) {
    final summaryFocus = useFocusNode(debugLabel: "Portable search summary");
    useListenable(summaryFocus);
    final tapRegionGroup = useMemoized(Object.new);
    final editing = useState(false);
    final http = useMemoized(() => client ?? Client(), [client]);
    useEffect(() => client == null ? http.close : null, [http]);
    void closeSearch({bool restoreFocus = true}) {
      if (!context.mounted || !editing.value) return;
      editing.value = false;
      if (restoreFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && !editing.value) summaryFocus.requestFocus();
        });
      }
    }

    void openSearch() {
      if (!editing.value && scope.enabled && !scope.readOnly) {
        editing.value = true;
      }
    }

    final host = scope.host;
    final catalog = scope.catalog ?? host?.document.catalog;
    if (host == null || catalog == null) {
      throw StateError("Portable search requires a checked presentation host");
    }
    final picker = useMemoized(
      () {
        final environment = PortableSearchEnvironment(
          catalog: catalog,
          budget: scope.budget,
          context: scope.invocation,
          http: http,
          historyStorage: scope.searchHistoryNamespace == null
              ? _EphemeralSearchHistoryStorage()
              : PortableLocalSearchHistoryStorage(catalog: catalog),
          historyNamespace: scope.searchHistoryNamespace ?? "ephemeral",
          watchRealm: scope.watchSearch,
          collectionHost: host is PortableCollectionProjectionHost
              ? host as PortableCollectionProjectionHost
              : null,
          material: scope.material,
        );
        return const PortableSearchCompiler().bindControl(
          control: control,
          environment: environment,
          host: host,
        );
      },
      [
        http,
        control,
        scope.bindings,
        host,
        scope.material,
        catalog,
        scope.searchHistoryNamespace,
        scope.budget,
        scope.watchSearch,
      ],
    );
    useEffect(() => picker.dispose, [picker]);
    final controller = useMemoized(() {
      final expression = control.initialQuery;
      final initialQuery = expression == null
          ? ""
          : switch (scope.evaluate(expression)) {
                  PortableExpressionAvailable(:final value) =>
                    value.authoredString,
                  _ => null,
                } ??
                "";
      return SearchController<void>(
        session: picker.session(initialQuery: initialQuery),
        baseSelectors: const [],
        onCloseRequested: closeSearch,
        onCompleted: (_) => closeSearch(),
      );
    }, [picker]);
    useEffect(() => controller.dispose, [controller]);
    final style = _controlStyle(context, scope, control.appearance);
    final inputContent = control.content;
    final popup = control.popup;
    final constraints = _popupConstraints(scope, popup);
    final shape = _popupShape(context, scope, popup);
    final placeholder =
        _entryPlaceholder(inputContent, scope) ??
        (control.placeholder == null
            ? "Search"
            : switch (scope.evaluate(control.placeholder!)) {
                    PortableExpressionAvailable(:final value) =>
                      value.authoredString,
                    _ => null,
                  } ??
                  "Search");
    final maximum = switch (scope.evaluate(control.maximumExtent)) {
      PortableExpressionAvailable(
        value: skir.DataValue_integerWrapper(:final value),
      ) =>
        double.tryParse(value),
      PortableExpressionAvailable(
        value: skir.DataValue_floatWrapper(:final value),
      ) =>
        value,
      PortableExpressionAvailable(
        value: skir.DataValue_decimalWrapper(:final value),
      ) =>
        double.tryParse(value),
      _ => null,
    };
    final editable = scope.enabled && !scope.readOnly;
    final content = _controlFrame(
      control.control,
      control.appearance == null
          ? scope
          : scope.withAppearance(control.appearance!),
      _entryComposition(
        leading: _entryLeading(
          context,
          control.control,
          inputContent,
          scope,
          style,
          Icons.search,
        ),
        trailing: _entrySuffix(inputContent, scope),
        child: TapRegion(
          groupId: tapRegionGroup,
          onTapOutside: (_) => closeSearch(restoreFocus: false),
          child: AnchoredOverlayPortal(
            visible: editing.value,
            config: AnchoredOverlayConfig(
              preferredSide: control.popupSide == skir.PopupSide.above
                  ? AnchoredOverlaySide.top
                  : AnchoredOverlaySide.bottom,
              spacing: 6,
              maxHeight: constraints?.maxHeight.isFinite == true
                  ? constraints!.maxHeight
                  : (maximum ?? 320).clamp(80, 800),
            ),
            overlayBuilder: (context, anchorSize) => TapRegion(
              groupId: tapRegionGroup,
              child: Material(
                elevation: 8,
                shape: shape,
                borderRadius: shape == null
                    ? context.shapes.mediumBorderRadius
                    : null,
                color: popup?.fill == null
                    ? null
                    : PresentationColorEnvironment.of(context)
                          .resolve(popup!.fill!, scope),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: constraints ?? const BoxConstraints(),
                  child: Padding(
                    padding: popup?.padding == null
                        ? EdgeInsets.zero
                        : _presentationInsets(popup!.padding),
                    child: SizedBox(
                      width: (constraints ?? const BoxConstraints())
                          .constrainWidth(max(anchorSize.width, 420)),
                      child: SearchRoot.borrowed(
                        controller: controller,
                        child: _PortableSearchSurface(
                          placeholder: placeholder,
                          picker: picker,
                          scope: scope,
                          control: control,
                          style: style,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: Semantics(
              button: true,
              enabled: editable,
              label: "Activate search input",
              child: InkWell(
                key: const ValueKey("authored_search_summary"),
                focusNode: summaryFocus,
                canRequestFocus: editable,
                onTap: editable ? openSearch : null,
                borderRadius: context.shapes.mediumBorderRadius,
                child: InputDecorator(
                  isEmpty: false,
                  isFocused: editing.value || summaryFocus.hasFocus,
                  decoration: style.decoration.copyWith(enabled: editable),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.spacing.space2,
                    ),
                    child: DefaultTextStyle.merge(
                      style: style.valueStyle,
                      child: IgnorePointer(child: _summary(placeholder)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (PortableDiagnosticScope.maybeOf(context) != null) return content;
    final document = host.document;
    return _PortableDiagnosticBoundary(
      key: ValueKey(document.catalog.snapshot.generation),
      operations: scope.operations,
      observations: document.diagnosticObservations,
      diagnostics: document.diagnostics,
      child: PortablePresentationChrome(role: scope.role, child: content),
    );
  }

  Widget _summary(String placeholder) {
    final current = scope.read(control.control.binding);
    if (current == null ||
        current.authoredPayload == skir.DataValue.unfilled ||
        current.authoredPayload == skir.DataValue.null_) {
      return const Text("No value");
    }
    final text = current.authoredString;
    if (text != null && text.trim().isEmpty) return Text(placeholder);
    final summary = control.summary;
    if (summary != null) {
      return PortablePresentationNodeRenderer(
        node: summary,
        scope: scope
            .withValues({control.summaryBindingId: current})
            .withReadOnly(true),
      );
    }
    final items = current.authoredItems;
    if (items != null) return Text("${items.length} selected");
    return Text(text ?? "Selected value");
  }
}

final class _EphemeralSearchHistoryStorage implements SearchHistoryStorage {
  final Map<String, List<SearchResult>> _results = {};

  @override
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  }) async => _results[key]?.take(capacity).toList(growable: false) ?? const [];

  @override
  Future<void> replaceResults({
    required String key,
    required List<SearchResult> results,
  }) async {
    _results[key] = List.unmodifiable(results);
  }
}

final class _PortableSearchSurface extends StatelessWidget {
  const _PortableSearchSurface({
    required this.placeholder,
    required this.picker,
    required this.scope,
    required this.control,
    required this.style,
  });

  final skir.SearchControl control;
  final _PortableControlStyle style;
  final String placeholder;
  final PortableSearchBinding picker;
  final PortablePresentationScope scope;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: picker.feedback,
      builder: (context, feedback, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (feedback != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: EdgeInsets.all(context.spacing.space2),
                child: Text(
                  feedback,
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
            ),
          Flexible(
            child: SearchModalBody(
              searchHint: placeholder,
              queryStyle: style.valueStyle,
              queryAlignment: style.alignment,
              queryDecoration: style.decoration,
              useDefaultQueryIcon:
                  control.content?.leading != skir.InputAdornment.none,
              empty: control.empty == null
                  ? (control.emptyText == null
                        ? null
                        : Center(
                            child: Text(
                              _operationText(
                                scope,
                                control.emptyText,
                                "No results",
                              ),
                            ),
                          ))
                  : PortablePresentationNodeRenderer(
                      node: control.empty!,
                      scope: scope,
                    ),
              loading: control.loading == null
                  ? (control.loadingText == null
                        ? null
                        : Center(
                            child: Text(
                              _operationText(
                                scope,
                                control.loadingText,
                                "Loading",
                              ),
                            ),
                          ))
                  : PortablePresentationNodeRenderer(
                      node: control.loading!,
                      scope: scope,
                    ),
              rowRenderers: {
                portableSearchResultType.rowRendererId: (row) {
                  final payload = row.result.payload;
                  if (payload is! PortableSearchPayload) {
                    return MissingSearchResultRendererRow(result: row.result);
                  }
                  return switch (payload) {
                    PortableMappedSearchPayload(:final mapping) => ListTile(
                      selected: row.selected,
                      title: PortablePresentationNodeRenderer(
                        node: mapping.presentation,
                        scope: picker
                            .resultScope(row.result, scope)
                            .withReadOnly(true),
                      ),
                      onTap: row.onTap,
                    ),
                    PortableCustomSearchPayload() => ListTile(
                      selected: row.selected,
                      title: Text(row.result.title ?? "Use custom value"),
                      subtitle: const Text("Use this custom value"),
                      onTap: row.onTap,
                    ),
                  };
                },
              },
            ),
          ),
        ],
      ),
    );
  }
}
