part of "portable_presentation_renderer.dart";

final class PortableSearchInput extends StatefulWidget {
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
  State<PortableSearchInput> createState() => _PortableSearchInputState();
}

final class _PortableSearchInputState extends State<PortableSearchInput> {
  final FocusNode _summaryFocus = FocusNode(
    debugLabel: "Portable search summary",
  );
  final Object _tapRegionGroup = Object();
  late Client _http;
  late bool _ownsHttp;
  late PortableSearchBinding _picker;
  late SearchController<void> _controller;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _installHttp();
    _installSearch();
  }

  @override
  void didUpdateWidget(covariant PortableSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final clientChanged = !identical(oldWidget.client, widget.client);
    if (clientChanged) {
      if (_ownsHttp) _http.close();
      _installHttp();
    }
    if (clientChanged ||
        oldWidget.control != widget.control ||
        oldWidget.scope.bindings != widget.scope.bindings ||
        oldWidget.scope.host != widget.scope.host ||
        oldWidget.scope.material != widget.scope.material ||
        oldWidget.scope.catalog != widget.scope.catalog ||
        oldWidget.scope.searchHistoryNamespace !=
            widget.scope.searchHistoryNamespace) {
      _controller.dispose();
      _picker.dispose();
      _installSearch();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _picker.dispose();
    if (_ownsHttp) _http.close();
    _summaryFocus.dispose();
    super.dispose();
  }

  void _installHttp() {
    _ownsHttp = widget.client == null;
    _http = widget.client ?? Client();
  }

  void _installSearch() {
    final scope = widget.scope;
    final host = scope.host;
    final catalog = scope.catalog ?? host?.document.catalog;
    if (host == null || catalog == null) {
      throw StateError("Portable search requires a checked presentation host");
    }
    final environment = PortableSearchEnvironment(
      catalog: catalog,
      budget: scope.budget,
      context: scope.invocation,
      http: _http,
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
    _picker = const PortableSearchCompiler().bindControl(
      control: widget.control,
      environment: environment,
      host: host,
    );
    _controller = SearchController<void>(
      session: _picker.session(initialQuery: _initialQuery()),
      baseSelectors: const [],
      onCloseRequested: _closeSearch,
      onCompleted: (_) => _closeSearch(),
    );
  }

  String _initialQuery() {
    final expression = widget.control.initialQuery;
    if (expression == null) return "";
    return switch (widget.scope.evaluate(expression)) {
          PortableExpressionAvailable(:final value) => value.authoredString,
          _ => null,
        } ??
        "";
  }

  void _openSearch() {
    if (_editing || !widget.scope.enabled || widget.scope.readOnly) return;
    setState(() => _editing = true);
  }

  void _closeSearch({bool restoreFocus = true}) {
    if (!_editing) return;
    setState(() => _editing = false);
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_editing) _summaryFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.control.placeholder == null
        ? "Search"
        : switch (widget.scope.evaluate(widget.control.placeholder!)) {
                PortableExpressionAvailable(:final value) =>
                  value.authoredString,
                _ => null,
              } ??
              "Search";
    final maximum = switch (widget.scope.evaluate(
      widget.control.maximumExtent,
    )) {
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
    final editable = widget.scope.enabled && !widget.scope.readOnly;
    return _controlFrame(
      widget.control.control,
      widget.scope,
      _withControlPrefix(
        widget.control.control,
        widget.scope,
        TapRegion(
          groupId: _tapRegionGroup,
          onTapOutside: (_) => _closeSearch(restoreFocus: false),
          child: AnchoredOverlayPortal(
            visible: _editing,
            config: AnchoredOverlayConfig(
              preferredSide: AnchoredOverlaySide.bottom,
              spacing: 6,
              maxHeight: (maximum ?? 320).clamp(80, 800),
            ),
            overlayBuilder: (context, anchorSize) => TapRegion(
              groupId: _tapRegionGroup,
              child: Material(
                elevation: 8,
                borderRadius: context.shapes.mediumBorderRadius,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: max(anchorSize.width, 420),
                  child: SearchRoot.borrowed(
                    controller: _controller,
                    child: _PortableSearchSurface(
                      placeholder: placeholder,
                      picker: _picker,
                      scope: widget.scope,
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
                focusNode: _summaryFocus,
                canRequestFocus: editable,
                onTap: editable ? _openSearch : null,
                borderRadius: context.shapes.mediumBorderRadius,
                child: InputDecorator(
                  isEmpty: false,
                  isFocused: _editing || _summaryFocus.hasFocus,
                  decoration: InputDecoration(
                    isDense: true,
                    enabled: editable,
                    suffixIcon: const Icon(Icons.search),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.spacing.space2,
                    ),
                    child: IgnorePointer(child: _summary(placeholder)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(String placeholder) {
    final current = widget.scope.read(widget.control.control.binding);
    if (current == null ||
        current.authoredPayload == skir.DataValue.unfilled ||
        current.authoredPayload == skir.DataValue.null_) {
      return const Text("No value");
    }
    final text = current.authoredString;
    if (text != null && text.trim().isEmpty) return Text(placeholder);
    final summary = widget.control.summary;
    if (summary != null) {
      return PortablePresentationNodeRenderer(
        node: summary,
        scope: widget.scope
            .withValues({widget.control.summaryBindingId: current})
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
  });

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
