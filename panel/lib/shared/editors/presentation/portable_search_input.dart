part of "portable_presentation_renderer.dart";

/// Owns an inline search binding and controller for the current lexical inputs.
/// A pending activation retains its invocation across host notifications, then
/// subsequent sessions use refreshed bindings. A supplied HTTP client is borrowed.
/// Hiding the search surface keeps this mounted controller and query alive.
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
    final choosing = useState(false);
    // A pending selection owns its invocation until completion. Its own host
    // notification must not dispose the controller awaiting that write.
    final sessionScope = useRef(scope);
    if (!choosing.value) sessionScope.value = scope;
    final searchScope = sessionScope.value;
    final searchFocus = useFocusNode(
      debugLabel: "Portable inline search",
      canRequestFocus: false,
    );
    final query = useRef<String?>(null);
    final http = useMemoized(() => client ?? Client(), [client]);
    useEffect(() => client == null ? http.close : null, [http]);
    void closeSearch({bool restoreFocus = true}) {
      if (!context.mounted || !editing.value) return;
      editing.value = false;
      if (restoreFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && !editing.value) {
            summaryFocus.requestFocus();
          }
        });
      }
    }

    final host = scope.host;
    final catalog = scope.catalog ?? host?.document.catalog;
    if (host == null || catalog == null) {
      throw StateError("Portable search requires a checked presentation host");
    }
    final history = useMemoized<SearchHistoryStorage>(
      () => scope.searchHistoryNamespace == null
          ? _EphemeralSearchHistoryStorage()
          : PortableLocalSearchHistoryStorage(catalog: catalog),
      [catalog, scope.searchHistoryNamespace],
    );
    final picker = useMemoized(
      () {
        final environment = PortableSearchEnvironment(
          catalog: catalog,
          budget: searchScope.budget,
          context: searchScope.invocation,
          http: http,
          historyStorage: history,
          historyNamespace: scope.searchHistoryNamespace ?? "ephemeral",
          watchRealm: searchScope.watchSearch,
          collectionHost: host is PortableCollectionProjectionHost
              ? host as PortableCollectionProjectionHost
              : null,
          material: searchScope.material,
        );
        return const PortableSearchCompiler().bindControl(
          control: control,
          environment: environment,
          host: host,
        );
      },
      [
        http,
        history,
        control,
        searchScope.bindings,
        searchScope.queries,
        host,
        searchScope.material,
        catalog,
        scope.searchHistoryNamespace,
        searchScope.budget,
        searchScope.watchSearch,
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
        session: picker.session(initialQuery: query.value ?? initialQuery),
        baseSelectors: const [],
        onCloseRequested: closeSearch,
        onCompleted: (_) => closeSearch(),
      );
    }, [picker]);
    useEffect(() {
      void rememberQuery() {
        query.value = controller.query;
        choosing.value = controller.activationRunning;
      }

      controller.addListener(rememberQuery);
      return controller.dispose;
    }, [controller]);
    void openSearch() {
      if (!editing.value && scope.enabled && !scope.readOnly) {
        final initial = control.initialQuery;
        controller
          ..updateQuery(
            initial == null
                ? ""
                : switch (scope.evaluate(initial)) {
                    PortableExpressionAvailable(:final value) =>
                      value.authoredString ?? "",
                    _ => "",
                  },
          )
          ..preview(null)
          ..refresh();
        editing.value = true;
      }
    }

    final style = _controlStyle(context, scope, control.appearance);
    final inputContent = control.content;
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
    final leading = _entryLeading(
      context,
      control.control,
      inputContent,
      scope,
      style,
      null,
    );
    final suffix = _entrySuffix(inputContent, scope);
    final summary = _entryComposition(
      leading: leading,
      trailing: suffix,
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
            isFocused: summaryFocus.hasFocus,
            decoration: style.decoration.copyWith(
              enabled: editable,
              focusedBorder:
                  (style.decoration.focusedBorder ??
                          style.decoration.border ??
                          context.theme.inputDecorationTheme.border ??
                          OutlineInputBorder(
                            borderRadius: context.shapes.mediumBorderRadius,
                          ))
                      .copyWith(
                        borderSide: FocusHighlight.focusBorder(
                          context,
                          FocusType.focus,
                        ),
                      ),
              suffixIcon: inputContent?.leading == skir.InputAdornment.none
                  ? null
                  : Icon(
                      Icons.search,
                      size: style.iconSize,
                      color: style.iconColor,
                    ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.spacing.space2),
              child: DefaultTextStyle.merge(
                style: style.valueStyle,
                child: IgnorePointer(child: _summary(placeholder)),
              ),
            ),
          ),
        ),
      ),
    );
    final content = _controlFrame(
      control.control,
      control.appearance == null
          ? scope
          : scope.withAppearance(control.appearance!),
      TapRegion(
        groupId: tapRegionGroup,
        onTapOutside: (_) => closeSearch(restoreFocus: false),
        child: Focus(
          focusNode: searchFocus,
          canRequestFocus: false,
          onFocusChange: (focused) {
            if (!focused && editing.value) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted && !searchFocus.hasFocus) {
                  closeSearch(restoreFocus: false);
                }
              });
            }
          },
          child: ManagedActionSet(
            shortcuts: [
              if (editable && !editing.value && summaryFocus.hasPrimaryFocus)
                ActionShortcut(
                  id: "activate_search_input",
                  label: "Search",
                  description: "Edit the selected value",
                  activators: [
                    const SingleActivator(LogicalKeyboardKey.enter),
                    const SingleActivator(LogicalKeyboardKey.numpadEnter),
                    const SingleActivator(LogicalKeyboardKey.space),
                  ],
                  priority: 100,
                  onInvoke: (_) => openSearch(),
                ),
            ],
            child: AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : 300.ms,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: editing.value && editable
                  ? TextFieldTapRegion(
                      child: SearchRoot.borrowed(
                        controller: controller,
                        child: _PortableSearchSurface(
                          placeholder: placeholder,
                          picker: picker,
                          scope: scope,
                          control: control,
                          style: style,
                          maximumExtent: (maximum ?? 320).clamp(80, 800),
                        ),
                      ),
                    )
                  : summary,
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
      diagnosticFallback: document.diagnosticFallback,
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
            .withValues(
              {control.summaryBindingId: current},
              schemas: {
                if (scope.expectedType(control.control.binding) case final use?)
                  control.summaryBindingId: CompletePortablePresentationBinding(
                    use,
                  ),
              },
            )
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

final class _PortableSearchSurface extends ConsumerWidget {
  const _PortableSearchSurface({
    required this.placeholder,
    required this.picker,
    required this.scope,
    required this.control,
    required this.style,
    required this.maximumExtent,
  });

  final skir.SearchControl control;
  final double maximumExtent;
  final _PortableControlStyle style;
  final String placeholder;
  final PortableSearchBinding picker;
  final PortablePresentationScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final popup = control.popup;
    final constraints = _popupConstraints(scope, popup);
    final shape = _popupShape(context, scope, popup);
    final fill =
        style.decoration.fillColor ??
        context.theme.inputDecorationTheme.fillColor ??
        context.colors.surface;
    final resultFill = popup?.fill == null
        ? fill
        : PresentationValueEnvironment.of(context).resolve(popup!.fill!, scope);
    final leading = _entryLeading(
      context,
      control.control,
      control.content,
      scope,
      style,
      Icons.search,
    );
    final suffix = _entrySuffix(control.content, scope);
    final outsideLeading = _interactiveAdornment(
      switch (control.content?.leading) {
        skir.InputAdornment_contentWrapper(:final value) => value,
        _ => scope.associationFor(control.control).prefix?.node,
      },
    );
    final outsideSuffix = _interactiveAdornment(control.content?.suffix);
    void navigate(int direction) {
      final results = controller.snapshot.nodes
          .walk()
          .whereType<SearchResultNode>()
          .map((node) => node.result)
          .toList();
      if (results.isEmpty) return;
      final current = results.indexWhere(
        (r) => r.id == controller.currentPreview?.id,
      );
      final next = current < 0
          ? (direction > 0 ? 0 : results.length - 1)
          : (current + direction).clamp(0, results.length - 1);
      controller.preview(results[next]);
    }

    Widget frame({
      required Widget queryBar,
      required Widget searchResults,
      Widget? actionBar,
      Widget? preview,
    }) {
      final results = LayoutBuilder(
        builder: (context, available) {
          final requested = constraints ?? const BoxConstraints();
          return Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: requested.enforce(
                BoxConstraints(
                  maxWidth: available.maxWidth,
                  maxHeight: maximumExtent,
                ),
              ),
              child: Material(
                color: resultFill,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: popup?.padding == null
                      ? EdgeInsets.zero
                      : _presentationInsets(popup!.padding),
                  child: searchResults,
                ),
              ),
            ),
          );
        },
      );
      final divider = Divider(
        height: 1,
        thickness: 1,
        color: context.theme.colorScheme.outlineVariant,
      );
      return Material(
        color: fill,
        shape:
            style.decoration.border ??
            RoundedRectangleBorder(
              borderRadius: context.shapes.mediumBorderRadius,
            ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (control.popupSide == skir.PopupSide.above) ...[
              results,
              divider,
            ],
            _entryComposition(
              child: queryBar,
              leading: outsideLeading ? leading : null,
              trailing: outsideSuffix ? suffix : null,
            ),
            if (control.popupSide != skir.PopupSide.above) ...[
              divider,
              results,
            ],
            ?preview,
          ],
        ),
      );
    }

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
            child: SearchBody(
              searchHint: placeholder,
              frameBuilder: frame,
              shrinkWrap: true,
              surfaceStyle: SearchSurfaceStyle(fill: resultFill),
              onQueryDismiss: controller.close,
              selectAllOnFocus: true,
              textFieldActions: [
                for (final direction in [-1, 1])
                  ActionShortcut(
                    id: direction < 0
                        ? "previous_search_result"
                        : "next_search_result",
                    label: direction < 0 ? "Previous result" : "Next result",
                    description: "Highlight a result without applying it",
                    priority: 100,
                    activators: [
                      SingleActivator(
                        direction < 0
                            ? LogicalKeyboardKey.arrowUp
                            : LogicalKeyboardKey.arrowDown,
                      ),
                    ],
                    show: false,
                    onInvoke: (_) => navigate(direction),
                  ),
              ],
              queryStyle: style.valueStyle,
              queryAlignment: style.alignment,
              queryDecoration: style.decoration.copyWith(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: style.dense ?? true,
                prefixIcon: outsideLeading ? null : leading,
                suffixIcon: outsideSuffix ? null : suffix,
              ),
              useDefaultQueryIcon:
                  !outsideLeading &&
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
                  final current = scope.read(control.control.binding);
                  final selectedValue = switch (payload) {
                    PortableMappedSearchPayload(:final selectedValue) =>
                      selectedValue,
                    PortableCustomSearchPayload(:final selectedValue) =>
                      selectedValue,
                  };
                  final selected =
                      control.selectionMode == skir.SearchSelectionMode.multiple
                      ? current?.authoredItems?.any(
                              (item) => item.value == selectedValue,
                            ) ??
                            false
                      : current == selectedValue;
                  final result = switch (payload) {
                    PortableMappedSearchPayload(:final mapping) =>
                      PortableResultContent(
                        node: mapping.presentation,
                        // A resource result shows its name, accent and icon
                        // like every other resource result.
                        appearance: _resourceAppearance(selectedValue, scope),
                        scope: picker.resultScope(row.result, scope),
                        row: row.copyWith(
                          selected: selected,
                          onTap: controller.isBusy
                              ? null
                              : () => controller.activate(row.result),
                        ),
                        // A search input opens a dropdown, so its rows are compact.
                        density: SearchResultDensity.compact,
                      ),
                    PortableCustomSearchPayload() => SearchResultRow(
                      row: row.copyWith(
                        selected: selected,
                        onTap: controller.isBusy
                            ? null
                            : () => controller.activate(row.result),
                      ),
                      density: SearchResultDensity.compact,
                      body: Text(
                        row.result.title ?? "Use custom value",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      footer: const Text("Use this custom value"),
                    ),
                  };
                  return _PortableSearchResult(
                    highlighted: row.focused,
                    child: Tooltip(
                      message: row.result.title ?? "",
                      child: result,
                    ),
                  );
                },
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The appearance of the resource [value] links to, or null when it links to
/// no resource the host can project.
ResourceAppearance? _resourceAppearance(
  skir.DataValue value,
  PortablePresentationScope scope,
) {
  final resource = value.authoredLink?.target.resource;
  final host = switch (scope.host) {
    final PortableCollectionProjectionHost projection => projection,
    _ => null,
  };
  if (resource == null || host == null) return null;
  return host.projectResource(resource, context: scope.invocation)?.appearance;
}

/// Keeps keyboard navigation visible while the query retains focus.
final class _PortableSearchResult extends HookWidget {
  const _PortableSearchResult({required this.highlighted, required this.child});
  final bool highlighted;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    useEffect(() {
      if (highlighted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            unawaited(
              Scrollable.ensureVisible(
                context,
                alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
              ),
            );
          }
        });
      }
      return null;
    }, [highlighted]);
    return child;
  }
}
