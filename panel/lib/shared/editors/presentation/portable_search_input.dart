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
  late final TextEditingController _query;
  final FocusNode _focus = FocusNode();
  final FocusNode _summaryFocus = FocusNode(
    debugLabel: "Portable search summary",
  );
  final Object _tapRegionGroup = Object();
  List<_AuthoredSearchCandidate> _results = const [];
  List<String> _guidance = const [];
  String? _failure;
  Timer? _debounce;
  late Client _httpClient;
  late bool _ownsHttpClient;
  StreamIterator<skir.RealmPresentationSearchUpdate>? _realmUpdates;
  var _revision = 0;
  var _activeIndex = 0;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _installHttpClient();
    _query = TextEditingController(text: _initialQuery());
  }

  @override
  void didUpdateWidget(covariant PortableSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.control.provider != widget.control.provider ||
        oldWidget.scope.bindings != widget.scope.bindings) {
      if (_editing) _scheduleSearch(immediate: true);
    }
    if (!identical(oldWidget.client, widget.client)) {
      if (_ownsHttpClient) _httpClient.close();
      _installHttpClient();
    }
  }

  @override
  void dispose() {
    _revision++;
    _debounce?.cancel();
    unawaited(_realmUpdates?.cancel());
    _realmUpdates = null;
    if (_ownsHttpClient) _httpClient.close();
    _query.dispose();
    _focus.dispose();
    _summaryFocus.dispose();
    super.dispose();
  }

  void _installHttpClient() {
    _ownsHttpClient = widget.client == null;
    _httpClient = widget.client ?? Client();
  }

  String _initialQuery() {
    final expression = widget.control.initialQuery;
    if (expression == null) return "";
    return _expressionText(widget.scope.evaluate(expression)) ?? "";
  }

  void _scheduleSearch({bool immediate = false}) {
    _revision++;
    _debounce?.cancel();
    unawaited(_realmUpdates?.cancel());
    _realmUpdates = null;
    final duration = immediate
        ? Duration.zero
        : _providerDebounce(widget.control.provider);
    _debounce = Timer(duration, _search);
  }

  Future<void> _search() async {
    final revision = ++_revision;
    final previousUpdates = _realmUpdates;
    _realmUpdates = null;
    await previousUpdates?.cancel();
    if (!mounted || revision != _revision) return;
    final query = _authoredSearchQuery(
      widget.control.provider,
      widget.control.queryBindingId,
      _query.text,
      widget.scope,
    );
    if (!mounted || revision != _revision) return;
    setState(() {
      _failure = query.failure;
      _guidance = const [];
      _results = const [];
      _activeIndex = 0;
    });
    if (query.failure != null) return;
    final result = await _loadProvider(
      widget.control.provider,
      query,
      widget.scope,
      revision,
    );
    if (!mounted || revision != _revision) return;
    setState(() {
      _results = result.candidates;
      _guidance = result.guidance;
      _failure = result.failure;
      _activeIndex = _results.isEmpty
          ? 0
          : _activeIndex.clamp(0, _results.length - 1);
    });
  }

  Future<_AuthoredSearchBatch> _loadProvider(
    skir.SearchProvider provider,
    _AuthoredSearchQuery query,
    PortablePresentationScope scope,
    int revision,
  ) async {
    switch (provider) {
      case skir.SearchProvider_staticValuesWrapper(:final value):
        final evaluated = query.scope.evaluate(value.values);
        if (evaluated case PortableExpressionFailed(:final message)) {
          return _AuthoredSearchBatch.failure(message);
        }
        if (evaluated case PortableExpressionUnavailable()) {
          return _AuthoredSearchBatch.failure(
            "Static search values are unavailable",
          );
        }
        final data = (evaluated as PortableExpressionAvailable).value;
        final items = data.authoredItems;
        if (items == null) {
          return _AuthoredSearchBatch.failure(
            "Static search values must evaluate to a collection",
          );
        }
        return _mapCandidates(
          items.map((item) => item.value),
          value.result,
          query.scope,
        );
      case skir.SearchProvider_realmCallbackWrapper(:final value):
        return _loadRealm(value, query, scope, revision);
      case skir.SearchProvider_gateWrapper(:final value):
        final condition = query.scope.evaluate(value.condition);
        if (condition case PortableExpressionAvailable(
          value: skir.DataValue_booleanWrapper(value: true),
        )) {
          return _loadProvider(value.child, query, scope, revision);
        }
        final guidance = value.guidance == null
            ? "Search is unavailable for the current value"
            : _expressionText(query.scope.evaluate(value.guidance!)) ??
                  "Search is unavailable for the current value";
        return _AuthoredSearchBatch(guidance: [guidance]);
      case skir.SearchProvider_debounceWrapper(:final value):
        return _loadProvider(value.child, query, scope, revision);
      case skir.SearchProvider_cacheWrapper(:final value):
        return _loadProvider(value.child, query, scope, revision);
      case skir.SearchProvider_rankWrapper(:final value):
        final child = await _loadProvider(value.child, query, scope, revision);
        if (child.failure != null) return child;
        final ranked = [...child.candidates]
          ..sort((left, right) {
            final rightScore = _rank(right, value.fields, query.normalized);
            final leftScore = _rank(left, value.fields, query.normalized);
            final score = rightScore.compareTo(leftScore);
            return score != 0 ? score : left.key.compareTo(right.key);
          });
        return child.copyWith(candidates: ranked);
      case skir.SearchProvider_limitWrapper(:final value):
        final child = await _loadProvider(value.child, query, scope, revision);
        final maximum = _expressionInteger(query.scope.evaluate(value.maximum));
        if (maximum == null) {
          return _AuthoredSearchBatch.failure(
            "Search result limit must evaluate to an integer",
          );
        }
        return child.copyWith(
          candidates: child.candidates.take(maximum.clamp(0, 100000)).toList(),
        );
      case skir.SearchProvider_distinctWrapper(:final value):
        final child = await _loadProvider(value.child, query, scope, revision);
        final seen = <String>{};
        return child.copyWith(
          candidates: child.candidates
              .where((candidate) => seen.add(candidate.key))
              .toList(),
        );
      case skir.SearchProvider_historyWrapper(:final value):
        return _loadProvider(value.child, query, scope, revision);
      case skir.SearchProvider_sectionWrapper(:final value):
        final child = await _loadProvider(value.child, query, scope, revision);
        final label = _expressionText(query.scope.evaluate(value.label));
        return child.copyWith(
          candidates: [
            for (final candidate in child.candidates)
              candidate.copyWith(section: label),
          ],
        );
      case skir.SearchProvider_mergeWrapper(:final value):
        final batches = await Future.wait([
          for (final child in value.children)
            _loadProvider(child, query, scope, revision),
        ]);
        return _AuthoredSearchBatch(
          candidates: [for (final batch in batches) ...batch.candidates],
          guidance: [for (final batch in batches) ...batch.guidance],
          failure: batches
              .map((batch) => batch.failure)
              .whereType<String>()
              .firstOrNull,
        );
      case skir.SearchProvider_httpJsonWrapper(:final value):
        return _loadHttp(value, query, scope);
      case skir.SearchProvider_collectionWrapper():
        return _AuthoredSearchBatch.failure(
          "Collection search is waiting for its checked row source",
        );
      case skir.SearchProvider_unknown():
        return _AuthoredSearchBatch.failure("The search provider is unknown");
    }
  }

  Future<_AuthoredSearchBatch> _loadRealm(
    skir.RealmCallbackSearchProvider provider,
    _AuthoredSearchQuery query,
    PortablePresentationScope scope,
    int revision,
  ) async {
    final watch = scope.watchSearch;
    final catalog = scope.catalog;
    if (watch == null || catalog == null) {
      return _AuthoredSearchBatch.failure("Realm search is unavailable");
    }
    final definition = catalog.snapshot.capabilities
        .whereType<skir.CapabilityDefinition_searchWrapper>()
        .map((entry) => entry.value)
        .where((entry) => entry.capabilityId == provider.capabilityId)
        .firstOrNull;
    if (definition == null) {
      return _AuthoredSearchBatch.failure("The Realm search is not published");
    }
    final payload = query.scope.evaluate(provider.payload);
    if (payload case PortableExpressionFailed(:final message)) {
      return _AuthoredSearchBatch.failure(message);
    }
    if (payload is! PortableExpressionAvailable) {
      return _AuthoredSearchBatch.failure(
        "The Realm search payload is unavailable",
      );
    }
    final subscriptionId = "panel:search:${const Uuid().v4()}";
    final request = skir.RealmPresentationSearchRequest(
      subscriptionId: subscriptionId,
      generation: catalog.snapshot.generation,
      capabilityId: provider.capabilityId,
      payload: payload.value,
      resultType: _typeUseTemplate(definition.resultType),
      query: query.wire,
    );
    final updates = StreamIterator(watch(request));
    _realmUpdates = updates;
    try {
      while (await updates.moveNext()) {
        final update = updates.current;
        if (!mounted || revision != _revision) {
          return const _AuthoredSearchBatch();
        }
        switch (update) {
          case skir.RealmPresentationSearchUpdate_snapshotWrapper(:final value):
            if (value.subscriptionId != subscriptionId) continue;
            final mapped = _mapCandidates(
              value.values,
              provider.result,
              query.scope,
            );
            if (value.status == skir.RealmPresentationSearchStatus.loading) {
              if (mounted && revision == _revision) {
                setState(() {
                  _results = mapped.candidates;
                  _guidance = value.guidance.toList();
                });
              }
              continue;
            }
            return mapped.copyWith(guidance: value.guidance.toList());
          case skir.RealmPresentationSearchUpdate_unavailableWrapper(
            :final value,
          ):
            if (value.subscriptionId != subscriptionId) continue;
            return _AuthoredSearchBatch.failure(
              value.diagnostics
                      .map((diagnostic) => diagnostic.message)
                      .firstOrNull ??
                  "Realm search is unavailable",
            );
          case skir.RealmPresentationSearchUpdate_unknown():
            return _AuthoredSearchBatch.failure(
              "Realm search returned an unknown update",
            );
        }
      }
      return _AuthoredSearchBatch.failure("Realm search ended before a result");
    } on Object catch (error) {
      if (!mounted || revision != _revision) {
        return const _AuthoredSearchBatch();
      }
      return _AuthoredSearchBatch.failure("Realm search failed: $error");
    } finally {
      if (identical(_realmUpdates, updates)) {
        _realmUpdates = null;
      }
      await updates.cancel();
    }
  }

  Future<_AuthoredSearchBatch> _loadHttp(
    skir.HttpJsonSearchProvider provider,
    _AuthoredSearchQuery query,
    PortablePresentationScope scope,
  ) async {
    final catalog = scope.catalog;
    if (catalog == null) {
      return _AuthoredSearchBatch.failure(
        "HTTP search needs the checked editor catalog",
      );
    }
    try {
      final uriText = _expressionText(query.scope.evaluate(provider.uri));
      if (uriText == null) {
        throw const FormatException("Search URI must evaluate to text");
      }
      final originalUri = Uri.parse(uriText);
      if (originalUri.scheme != "https" || originalUri.host.isEmpty) {
        throw const FormatException("Search URI must use HTTPS");
      }
      final parameters = Map<String, String>.of(originalUri.queryParameters);
      for (final parameter in provider.parameters) {
        final evaluated = query.scope.evaluate(parameter.value);
        if (evaluated case PortableExpressionFailed(:final message)) {
          throw FormatException(message);
        }
        if (evaluated is! PortableExpressionAvailable) {
          throw FormatException(
            "Search parameter ${parameter.name} is unavailable",
          );
        }
        final text = _dataValueText(evaluated.value) ?? "";
        if (parameter.omitIfEmpty && text.isEmpty) continue;
        parameters[parameter.name] = text;
      }
      final uri = parameters.isEmpty
          ? originalUri
          : originalUri.replace(queryParameters: parameters);
      final timeout = Duration(
        milliseconds: provider.timeoutMilliseconds.clamp(1, 60000),
      );
      final response = await _httpClient
          .get(uri, headers: const {"Accept": "application/json"})
          .timeout(timeout);
      final responseUri = response.request?.url ?? uri;
      if (responseUri.scheme != "https") {
        throw const FormatException("Search redirects must remain on HTTPS");
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          "Search request returned status ${response.statusCode}",
        );
      }
      final document = jsonDecode(utf8.decode(response.bodyBytes));
      var resultScope = query.scope;
      for (final context in provider.contextBindings) {
        final values = JsonPath(context.path).readValues(document).toList();
        final source = values.length == 1 ? values.single : values;
        final expected = catalog.concreteType(context.valueType);
        if (expected == null) {
          throw FormatException(
            "Search context ${context.bindingId.value} has an incomplete type",
          );
        }
        resultScope = resultScope.withValues({
          context.bindingId: _decodeAuthoredJson(
            source,
            expected,
            catalog,
            r"$",
          ),
        });
      }
      final expected = catalog.concreteType(provider.resultType);
      if (expected == null) {
        throw const FormatException("Search result type is incomplete");
      }
      final values = <skir.DataValue>[];
      String? warning;
      for (final (index, source) in JsonPath(
        provider.resultPath,
      ).readValues(document).indexed) {
        try {
          values.add(
            _decodeAuthoredJson(
              source,
              expected,
              catalog,
              r"$.results"
              "[$index]",
            ),
          );
        } on FormatException catch (error) {
          warning ??= error.message;
        }
      }
      final mapped = _mapCandidates(values, provider.result, resultScope);
      return warning == null || mapped.failure != null
          ? mapped
          : _AuthoredSearchBatch(
              candidates: mapped.candidates,
              guidance: [warning],
            );
    } on TimeoutException {
      return _AuthoredSearchBatch.failure("Search request timed out");
    } on FormatException catch (error) {
      return _AuthoredSearchBatch.failure(error.message);
    } on Object catch (error) {
      return _AuthoredSearchBatch.failure("Search provider failed: $error");
    }
  }

  _AuthoredSearchBatch _mapCandidates(
    Iterable<skir.DataValue> values,
    skir.SearchResultMapping mapping,
    PortablePresentationScope scope,
  ) {
    final candidates = <_AuthoredSearchCandidate>[];
    String? failure;
    for (final value in values) {
      final candidateScope = scope.withValues({mapping.bindingId: value});
      final key = candidateScope.evaluate(mapping.key);
      final selected = candidateScope.evaluate(mapping.selectedValue);
      if (key is! PortableExpressionAvailable ||
          selected is! PortableExpressionAvailable) {
        failure ??= "A search result could not be mapped";
        continue;
      }
      final label = mapping.label == null
          ? _dataValueText(selected.value)
          : _expressionText(candidateScope.evaluate(mapping.label!));
      candidates.add(
        _AuthoredSearchCandidate(
          key: canonicalAuthoredValue(key.value),
          selected: selected.value,
          label: label ?? "Result",
          node: mapping.presentation,
          scope: candidateScope,
        ),
      );
    }
    return _AuthoredSearchBatch(candidates: candidates, failure: failure);
  }

  int _rank(
    _AuthoredSearchCandidate candidate,
    Iterable<skir.SearchRankingField> fields,
    String query,
  ) {
    if (query.isEmpty) return 0;
    final needle = query.toLowerCase();
    var score = 0;
    for (final field in fields) {
      final text = _expressionText(candidate.scope.evaluate(field.expression));
      if (text == null) continue;
      final normalized = text.toLowerCase();
      if (normalized == needle) {
        score += field.weight * 4;
      } else if (normalized.startsWith(needle)) {
        score += field.weight * 2;
      } else if (normalized.contains(needle)) {
        score += field.weight;
      }
    }
    return score;
  }

  void _select(_AuthoredSearchCandidate candidate) {
    if (!widget.scope.enabled || widget.scope.readOnly) return;
    if (widget.control.selectionMode == skir.SearchSelectionMode.single) {
      widget.scope.writePayload(
        widget.control.control.binding,
        candidate.selected,
      );
      _closeSearch();
      return;
    }
    final current = widget.scope.read(widget.control.control.binding);
    final items = current?.authoredItems?.toList() ?? const <skir.ListItem>[];
    final selectedKey = canonicalAuthoredValue(candidate.selected);
    final existing = items
        .where((item) => canonicalAuthoredValue(item.value) == selectedKey)
        .firstOrNull;
    widget.scope._editList(widget.control.control.binding, (location, draft) {
      if (existing != null) return draft.remove(location, existing.id);
      return draft.insert(
        location,
        items.lastOrNull?.id,
        skir.ListItem(
          id: skir.ItemId(value: const Uuid().v4()),
          value: candidate.selected,
        ),
      );
    });
    setState(() {});
  }

  bool _selected(_AuthoredSearchCandidate candidate) {
    final current = widget.scope.read(widget.control.control.binding);
    final key = canonicalAuthoredValue(candidate.selected);
    if (widget.control.selectionMode == skir.SearchSelectionMode.single) {
      return current != null &&
          canonicalAuthoredValue(current.authoredPayload) == key;
    }
    return current?.authoredItems?.any(
          (item) => canonicalAuthoredValue(item.value) == key,
        ) ??
        false;
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeSearch();
      return KeyEventResult.handled;
    }
    if (_results.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _activeIndex = (_activeIndex + 1) % _results.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _activeIndex =
            (_activeIndex - 1 + _results.length) % _results.length,
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _select(_results[_activeIndex]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openSearch() {
    if (_editing || !widget.scope.enabled || widget.scope.readOnly) return;
    setState(() {
      _editing = true;
      _activeIndex = 0;
    });
    _scheduleSearch(immediate: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _focus.requestFocus();
    });
  }

  void _closeSearch({bool restoreFocus = true}) {
    if (!_editing) return;
    _revision++;
    _debounce?.cancel();
    _debounce = null;
    final updates = _realmUpdates;
    _realmUpdates = null;
    unawaited(updates?.cancel());
    _focus.unfocus();
    if (mounted) setState(() => _editing = false);
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
        : _expressionText(widget.scope.evaluate(widget.control.placeholder!)) ??
              "Search";
    final maximum =
        _expressionNumber(
          widget.scope.evaluate(widget.control.maximumExtent),
        ) ??
        320;
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
              maxHeight: maximum.clamp(80, 800),
            ),
            overlayBuilder: (context, anchorSize) => TapRegion(
              groupId: _tapRegionGroup,
              child: Material(
                elevation: 8,
                borderRadius: context.shapes.mediumBorderRadius,
                clipBehavior: Clip.antiAlias,
                child: Focus(
                  onKeyEvent: _handleKey,
                  child: _searchSurface(context, placeholder),
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

  Widget _searchSurface(BuildContext context, String placeholder) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const ValueKey("authored_search_query"),
        controller: _query,
        focusNode: _focus,
        autofocus: true,
        enabled: widget.scope.enabled && !widget.scope.readOnly,
        decoration: InputDecoration(
          hintText: placeholder,
          errorText: _failure,
          suffixIcon: const Icon(Icons.search),
        ),
        onChanged: (_) => _scheduleSearch(),
        onSubmitted: (_) {
          if (_results.isNotEmpty) {
            _select(_results[_activeIndex]);
            return;
          }
          _acceptCustom();
        },
      ),
      for (final guidance in _guidance)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(guidance, style: Theme.of(context).textTheme.bodySmall),
        ),
      if (_results.isNotEmpty)
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final candidate = _results[index];
              final sectionChanged =
                  index == 0 ||
                  _results[index - 1].section != candidate.section;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sectionChanged && candidate.section != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.spacing.space3,
                        10,
                        context.spacing.space3,
                        context.spacing.space1,
                      ),
                      child: Text(
                        candidate.section!,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  Semantics(
                    label: candidate.label,
                    child: Material(
                      color: index == _activeIndex
                          ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                          : context.colors.surface.withValues(alpha: 0),
                      child: ListTile(
                        selected: _selected(candidate),
                        title: PortablePresentationNodeRenderer(
                          node: candidate.node,
                          scope: candidate.scope.withReadOnly(true),
                        ),
                        onTap: widget.scope.enabled && !widget.scope.readOnly
                            ? () => _select(candidate)
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
    ],
  );

  Widget _summary(String placeholder) {
    final current = widget.scope.read(widget.control.control.binding);
    if (current == null ||
        current.authoredPayload == skir.DataValue.unfilled ||
        current.authoredPayload == skir.DataValue.null_) {
      return const Text("No value");
    }
    final text = _dataValueText(current);
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

  void _acceptCustom() {
    final custom = widget.control.customValue;
    if (custom == null) return;
    final query = _authoredSearchQuery(
      widget.control.provider,
      widget.control.queryBindingId,
      _query.text,
      widget.scope,
    );
    final result = query.scope.evaluate(custom);
    if (result case PortableExpressionAvailable(:final value)) {
      widget.scope.writePayload(widget.control.control.binding, value);
      _closeSearch();
    }
  }
}

final class _AuthoredSearchCandidate {
  const _AuthoredSearchCandidate({
    required this.key,
    required this.selected,
    required this.label,
    required this.node,
    required this.scope,
    this.section,
  });

  final String key;
  final skir.DataValue selected;
  final String label;
  final skir.PresentationNode node;
  final PortablePresentationScope scope;
  final String? section;

  _AuthoredSearchCandidate copyWith({String? section}) =>
      _AuthoredSearchCandidate(
        key: key,
        selected: selected,
        label: label,
        node: node,
        scope: scope,
        section: section ?? this.section,
      );
}

final class _AuthoredSearchBatch {
  const _AuthoredSearchBatch({
    this.candidates = const [],
    this.guidance = const [],
    this.failure,
  });

  factory _AuthoredSearchBatch.failure(String message) =>
      _AuthoredSearchBatch(failure: message);

  final List<_AuthoredSearchCandidate> candidates;
  final List<String> guidance;
  final String? failure;

  _AuthoredSearchBatch copyWith({
    List<_AuthoredSearchCandidate>? candidates,
    List<String>? guidance,
  }) => _AuthoredSearchBatch(
    candidates: candidates ?? this.candidates,
    guidance: guidance ?? this.guidance,
    failure: failure,
  );
}

final class _AuthoredSearchQuery {
  const _AuthoredSearchQuery({
    required this.normalized,
    required this.scope,
    required this.wire,
    this.failure,
  });

  final String normalized;
  final PortablePresentationScope scope;
  final skir.RealmSearchQuery wire;
  final String? failure;
}

_AuthoredSearchQuery _authoredSearchQuery(
  skir.SearchProvider provider,
  skir.ExpressionBindingId queryBindingId,
  String raw,
  PortablePresentationScope scope,
) {
  final definitions = _providerSelectors(provider);
  final queryDefinitions = definitions.map(_querySelector).toList();
  final parsed = Query(queryDefinitions).parse(raw);
  final hardFailure = parsed.issues
      .where((issue) => issue.severity == QuerySeverity.error)
      .map((issue) => issue.message)
      .firstOrNull;
  final byId = {
    for (final definition in definitions) definition.selectorId: definition,
  };
  final selectors = parsed.selectors
      .whereType<QueryLexerKeyValueSelectorToken>()
      .map(
        (token) => skir.RealmSearchSelector(
          selectorId: token.selectorId,
          key: byId[token.selectorId]?.key ?? "",
          value: token.value,
        ),
      )
      .toList();
  var queryScope = scope.withValues({
    queryBindingId: skir.DataValue.wrapStringValue(parsed.query),
  });
  for (final definition in definitions) {
    final values = selectors
        .where((selector) => selector.selectorId == definition.selectorId)
        .map((selector) => selector.value)
        .whereType<String>()
        .toList();
    queryScope = queryScope.withValues({
      definition.valueBindingId:
          definition.multiplicity == skir.SearchSelectorMultiplicity.multiple
          ? skir.DataValue.createListValue(
              items: [
                for (final value in values)
                  skir.ListItem(
                    id: skir.ItemId(value: const Uuid().v4()),
                    value: skir.DataValue.wrapStringValue(value),
                  ),
              ],
            )
          : skir.DataValue.wrapStringValue(values.firstOrNull ?? ""),
    });
  }
  final terms = RegExp(
    r"[\p{L}\p{N}_]+",
    unicode: true,
  ).allMatches(parsed.query).map((match) => match.group(0)!).toList();
  return _AuthoredSearchQuery(
    normalized: parsed.query,
    scope: queryScope,
    failure: hardFailure,
    wire: skir.RealmSearchQuery(
      normalizedQuery: parsed.query,
      selectors: selectors,
      selectorExpression: _wireSelectorExpression(parsed.expression, byId),
      terms: terms,
    ),
  );
}

List<skir.SearchSelectorDefinition> _providerSelectors(
  skir.SearchProvider provider,
) => switch (provider) {
  skir.SearchProvider_staticValuesWrapper(:final value) =>
    value.selectors.toList(),
  skir.SearchProvider_httpJsonWrapper(:final value) => value.selectors.toList(),
  skir.SearchProvider_realmCallbackWrapper(:final value) =>
    value.selectors.toList(),
  skir.SearchProvider_collectionWrapper(:final value) =>
    value.selectors.toList(),
  skir.SearchProvider_gateWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_debounceWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_cacheWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_rankWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_limitWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_distinctWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_historyWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_sectionWrapper(:final value) => _providerSelectors(
    value.child,
  ),
  skir.SearchProvider_mergeWrapper(:final value) => _mergeProviderSelectors(
    value.children,
  ),
  skir.SearchProvider_unknown() => const [],
};

List<skir.SearchSelectorDefinition> _mergeProviderSelectors(
  Iterable<skir.SearchProvider> providers,
) {
  final result = <String, skir.SearchSelectorDefinition>{};
  for (final provider in providers) {
    for (final definition in _providerSelectors(provider)) {
      result.putIfAbsent(definition.selectorId, () => definition);
    }
  }
  return result.values.toList();
}

QuerySelectorDefinition _querySelector(
  skir.SearchSelectorDefinition definition,
) => KeyValueSelectorDefinition(
  id: definition.selectorId,
  key: definition.key,
  caseSensitive: definition.caseSensitive,
  multiplicity:
      definition.multiplicity == skir.SearchSelectorMultiplicity.single
      ? QueryMultiplicity.single
      : QueryMultiplicity.multiple,
  color: definition.color == null ? null : Color(definition.color!),
  value: switch (definition.values) {
    skir.SearchSelectorValues_enumerationWrapper(:final value) =>
      QuerySelectorValue.enumValue(value.values.toList()),
    _ => const QuerySelectorValue.freeText(),
  },
);

skir.RealmSearchSelectorExpression? _wireSelectorExpression(
  QueryLexerToken? token,
  Map<String, skir.SearchSelectorDefinition> definitions,
) => switch (token) {
  null => null,
  QueryLexerKeyValueSelectorToken(:final selectorId, :final value) =>
    skir.RealmSearchSelectorExpression.createSelector(
      selectorId: selectorId,
      key: definitions[selectorId]?.key ?? "",
      value: value,
    ),
  QueryLexerOperatorToken(:final type, :final left, :final right) =>
    skir.RealmSearchSelectorExpression.createBinary(
      operator_: type == QueryLexerOperatorType.and
          ? skir.RealmSearchSelectorOperator.and
          : skir.RealmSearchSelectorOperator.or,
      left: _wireSelectorExpression(left, definitions)!,
      right: _wireSelectorExpression(right, definitions)!,
    ),
  QueryLexerNegationToken(:final token) =>
    skir.RealmSearchSelectorExpression.createNot(
      expression: _wireSelectorExpression(token, definitions)!,
    ),
  QueryLexerSelectorToken() => null,
};

Duration _providerDebounce(skir.SearchProvider provider) => switch (provider) {
  skir.SearchProvider_debounceWrapper(:final value) => Duration(
    milliseconds: value.durationMilliseconds.clamp(0, 60000),
  ),
  skir.SearchProvider_gateWrapper(:final value) => _providerDebounce(
    value.child,
  ),
  skir.SearchProvider_cacheWrapper(:final value) => _providerDebounce(
    value.child,
  ),
  skir.SearchProvider_rankWrapper(:final value) => _providerDebounce(
    value.child,
  ),
  skir.SearchProvider_limitWrapper(:final value) => _providerDebounce(
    value.child,
  ),
  skir.SearchProvider_distinctWrapper(:final value) => _providerDebounce(
    value.child,
  ),
  skir.SearchProvider_historyWrapper(:final value) => _providerDebounce(
    value.child,
  ),
  skir.SearchProvider_sectionWrapper(:final value) => _providerDebounce(
    value.child,
  ),
  skir.SearchProvider_mergeWrapper(:final value) =>
    value.children
        .map(_providerDebounce)
        .fold(
          Duration.zero,
          (maximum, next) => next > maximum ? next : maximum,
        ),
  _ => Duration.zero,
};

skir.TypeTemplate _typeUseTemplate(skir.TypeUse type) => switch (type) {
  skir.TypeUse_scalarWrapper(:final value) => skir.TypeTemplate.wrapScalar(
    value,
  ),
  skir.TypeUse_nullableWrapper(:final value) =>
    skir.TypeTemplate.createNullable(value: _typeUseTemplate(value.value)),
  skir.TypeUse_namedWrapper(:final value) => skir.TypeTemplate.createNamed(
    definition: value.definition,
    arguments: value.arguments.map(_typeUseTemplate),
  ),
  skir.TypeUse_unknown() => skir.TypeTemplate.unknown,
};

String? _expressionText(PortableExpressionResult result) => switch (result) {
  PortableExpressionAvailable(:final value) => _dataValueText(value),
  _ => null,
};

String? _dataValueText(skir.DataValue value) => switch (value.authoredPayload) {
  skir.DataValue_stringValueWrapper(:final value) => value,
  skir.DataValue_integerWrapper(:final value) => value,
  skir.DataValue_decimalWrapper(:final value) => value,
  skir.DataValue_floatWrapper(:final value) => value.toString(),
  skir.DataValue_booleanWrapper(:final value) => value.toString(),
  skir.DataValue_enumCaseWrapper(:final value) => value,
  _ => null,
};

int? _expressionInteger(PortableExpressionResult result) => switch (result) {
  PortableExpressionAvailable(
    value: skir.DataValue_integerWrapper(:final value),
  ) =>
    int.tryParse(value),
  _ => null,
};

double? _expressionNumber(PortableExpressionResult result) => switch (result) {
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

skir.DataValue _decodeAuthoredJson(
  Object? source,
  skir.TypeUse expected,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (expected case skir.TypeUse_nullableWrapper(:final value)) {
    if (source == null) return skir.DataValue.null_;
    return _decodeAuthoredJson(source, value.value, catalog, path);
  }
  return switch (expected) {
    skir.TypeUse_scalarWrapper(:final value) => _decodeJsonScalar(
      source,
      value,
      path,
    ),
    skir.TypeUse_namedWrapper(:final value) => _decodeJsonNamed(
      source,
      value,
      catalog,
      path,
    ),
    _ => throw FormatException("Expected a complete authored type at $path"),
  };
}

skir.DataValue _decodeJsonNamed(
  Object? source,
  skir.NamedTypeUse expected,
  CheckedEditorCatalog catalog,
  String path,
) {
  final published = catalog.published(expected.definition);
  if (published == null || published.status != skir.DeclarationStatus.ready) {
    throw FormatException("Expected an available named type at $path");
  }
  final containing = skir.TypeSelection.wrapComplete(expected);
  final payload = switch (published.definition.representation) {
    skir.RepresentationTemplate_scalarWrapper(:final value) =>
      _decodeJsonScalar(source, value.kind, path),
    skir.RepresentationTemplate_recordWrapper() => _decodeJsonRecord(
      source,
      containing,
      catalog,
      path,
    ),
    skir.RepresentationTemplate_sequenceWrapper(:final value) =>
      _decodeJsonSequence(source, value, containing, catalog, path),
    skir.RepresentationTemplate_mappingWrapper(:final value) =>
      _decodeJsonMapping(source, value, containing, catalog, path),
    skir.RepresentationTemplate_enumerationWrapper(:final value) =>
      _decodeJsonEnumeration(source, value, path),
    skir.RepresentationTemplate_linkWrapper(:final value) => _decodeJsonLink(
      source,
      value,
      path,
    ),
    _ => throw FormatException("Expected a supported named type at $path"),
  };
  return skir.DataValue.createNamed(actualType: expected, payload: payload);
}

skir.DataValue _decodeJsonScalar(
  Object? source,
  skir.ScalarKind kind,
  String path,
) {
  if (kind == skir.ScalarKind.unit) {
    if (source == null) return skir.DataValue.unit;
    throw _invalidJsonValue(path, "null", source);
  }
  if (kind == skir.ScalarKind.boolean) {
    if (source case final bool value) {
      return skir.DataValue.wrapBoolean(value);
    }
    throw _invalidJsonValue(path, "a boolean", source);
  }
  if (kind == skir.ScalarKind.text) {
    if (source case final String value) {
      return skir.DataValue.wrapStringValue(value);
    }
    throw _invalidJsonValue(path, "a string", source);
  }
  if (kind == skir.ScalarKind.bytes) {
    if (source is! String) {
      throw _invalidJsonValue(path, "a base64 string", source);
    }
    try {
      return skir.DataValue.wrapBytes(
        skir.ByteString.copy(base64Decode(source)),
      );
    } on FormatException {
      throw _invalidJsonValue(path, "a valid base64 string", source);
    }
  }
  if (kind case skir.ScalarKind_integerWrapper()) {
    if (source is! int && source is! String) {
      throw _invalidJsonValue(path, "an integer", source);
    }
    final value = admitPortableNumericInput(
      current: null,
      expected: skir.TypeUse.wrapScalar(kind),
      text: source.toString(),
    );
    if (value == null) {
      throw _invalidJsonValue(path, "an integer in range", source);
    }
    return value;
  }
  if (kind case skir.ScalarKind_floatWrapper()) {
    if (source is! num) {
      throw _invalidJsonValue(path, "a finite number", source);
    }
    final value = admitPortableNumericInput(
      current: null,
      expected: skir.TypeUse.wrapScalar(kind),
      text: source.toString(),
    );
    if (value == null) {
      throw _invalidJsonValue(path, "a finite number in range", source);
    }
    return value;
  }
  if (kind == skir.ScalarKind.decimal) {
    if (source is! num && source is! String) {
      throw _invalidJsonValue(path, "a canonical decimal", source);
    }
    final value = admitPortableNumericInput(
      current: null,
      expected: skir.TypeUse.wrapScalar(kind),
      text: source.toString(),
    );
    if (value == null) {
      throw _invalidJsonValue(path, "a canonical decimal", source);
    }
    return value;
  }
  if (kind == skir.ScalarKind.timestamp) {
    if (source is! String) {
      throw _invalidJsonValue(path, "an ISO 8601 timestamp", source);
    }
    final value = DateTime.tryParse(source);
    if (value == null) {
      throw _invalidJsonValue(path, "an ISO 8601 timestamp", source);
    }
    return skir.DataValue.wrapTimestamp(value);
  }
  if (kind == skir.ScalarKind.duration) {
    if (source is! int) {
      throw _invalidJsonValue(path, "integer milliseconds", source);
    }
    return skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: source),
    );
  }
  throw FormatException("Expected a supported scalar type at $path");
}

skir.DataValue _decodeJsonRecord(
  Object? source,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! Map<String, Object?>) {
    throw _invalidJsonValue(path, "an object", source);
  }
  final fields = catalog.fields(containing);
  final declared = fields.map((field) => field.template.key).toSet();
  final unknown = source.keys.where((key) => !declared.contains(key));
  if (unknown.isNotEmpty) {
    final key = unknown.first;
    throw FormatException(
      "Expected a declared field at ${_jsonPropertyPath(path, key)}",
    );
  }
  return skir.DataValue.createRecord(
    fields: [
      for (final field in fields)
        skir.FieldValue(
          name: field.template.key,
          value: _decodeJsonField(source, field, catalog, path),
        ),
    ],
  );
}

skir.DataValue _decodeJsonField(
  Map<String, Object?> source,
  AppliedEditorField field,
  CheckedEditorCatalog catalog,
  String path,
) {
  final type = field.type;
  final fieldPath = _jsonPropertyPath(path, field.template.key);
  if (type == null) {
    throw FormatException("Expected an available field type at $fieldPath");
  }
  if (!source.containsKey(field.template.key)) {
    if (type is skir.TypeUse_nullableWrapper) return skir.DataValue.null_;
    throw FormatException("Expected a required field at $fieldPath");
  }
  return _decodeAuthoredJson(
    source[field.template.key],
    type,
    catalog,
    fieldPath,
  );
}

skir.DataValue _decodeJsonSequence(
  Object? source,
  skir.SequenceRepresentationTemplate representation,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! List<Object?>) {
    throw _invalidJsonValue(path, "a list", source);
  }
  final itemType = catalog.applyTemplate(representation.item, containing);
  if (itemType == null) {
    throw FormatException("Expected a complete item type at $path");
  }
  final items = [
    for (final (index, item) in source.indexed)
      skir.ListItem(
        id: skir.ItemId(value: "http:$path:item:$index"),
        value: _decodeAuthoredJson(item, itemType, catalog, "$path[$index]"),
      ),
  ];
  return representation.kind == skir.CollectionKind.list
      ? skir.DataValue.createListValue(items: items)
      : skir.DataValue.createSetValue(items: items);
}

skir.DataValue _decodeJsonMapping(
  Object? source,
  skir.MappingRepresentationTemplate representation,
  skir.TypeSelection containing,
  CheckedEditorCatalog catalog,
  String path,
) {
  if (source is! Map<String, Object?>) {
    throw _invalidJsonValue(path, "an object", source);
  }
  final keyType = catalog.applyTemplate(representation.key, containing);
  final valueType = catalog.applyTemplate(representation.value, containing);
  if (keyType == null || valueType == null) {
    throw FormatException("Expected complete map types at $path");
  }
  return skir.DataValue.createMapValue(
    rows: [
      for (final (index, entry) in source.entries.indexed)
        skir.MapRow(
          id: skir.ItemId(value: "http:$path:row:$index"),
          key: _decodeAuthoredJson(
            entry.key,
            keyType,
            catalog,
            "$path.keys[$index]",
          ),
          value: _decodeAuthoredJson(
            entry.value,
            valueType,
            catalog,
            _jsonPropertyPath(path, entry.key),
          ),
        ),
    ],
  );
}

skir.DataValue _decodeJsonEnumeration(
  Object? source,
  skir.EnumerationRepresentationTemplate representation,
  String path,
) {
  if (source is! String ||
      !representation.cases.any((candidate) => candidate.key == source)) {
    throw _invalidJsonValue(path, "a declared enum case", source);
  }
  return skir.DataValue.wrapEnumCase(source);
}

skir.DataValue _decodeJsonLink(
  Object? source,
  skir.LinkRepresentationTemplate representation,
  String path,
) {
  if (source is! String || source.isEmpty) {
    throw _invalidJsonValue(path, "a resource id string", source);
  }
  return skir.DataValue.createLink(
    endpoint: representation.endpoint,
    target: skir.LinkTarget(
      resource: skir.ResourceId(value: source),
      opposite: null,
    ),
  );
}

FormatException _invalidJsonValue(
  String path,
  String expected,
  Object? actual,
) => FormatException(
  "Expected $expected at $path, got ${_jsonValueShape(actual)}",
);

String _jsonPropertyPath(String path, String key) =>
    RegExp(r"^[A-Za-z_][A-Za-z0-9_]*$").hasMatch(key)
    ? "$path.$key"
    : "$path[${jsonEncode(key)}]";

String _jsonValueShape(Object? value) => switch (value) {
  null => "null",
  String() => "a string",
  bool() => "a boolean",
  int() => "an integer",
  double() => "a number",
  List<Object?>() => "a list",
  Map<Object?, Object?>() => "an object",
  _ => value.runtimeType.toString(),
};
