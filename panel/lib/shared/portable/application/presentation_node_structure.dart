import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The structural walk over a presentation tree: nested nodes, the body, and
/// the decorations around it.
extension PresentationNodeStructure on skir.PresentationNode {
  Iterable<skir.PresentationNode> get nestedPresentationNodes =>
      _nestedPresentationNodes(this);

  Iterable<skir.PresentationNode> get presentationBodyNodes =>
      _presentationBodyNodes(this);

  Iterable<skir.PresentationNode> presentationDecorationNodes({
    bool includeControlPrefix = true,
  }) => _presentationDecorationNodes(
    this,
    includeControlPrefix: includeControlPrefix,
  );

  skir.BoundControl? get boundControl => switch (element) {
    skir.PresentationElement_textInputWrapper(:final value) => value.control,
    skir.PresentationElement_numericInputWrapper(:final value) => value.control,
    skir.PresentationElement_defaultPresentationWrapper(:final value) =>
      value.control,
    skir.PresentationElement_toggleInputWrapper(:final value) => value.control,
    skir.PresentationElement_durationInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_bytesInputWrapper(:final value) => value.control,
    skir.PresentationElement_enumInputWrapper(:final value) => value.control,
    skir.PresentationElement_selectInputWrapper(:final value) => value.control,
    skir.PresentationElement_sliderInputWrapper(:final value) => value.control,
    skir.PresentationElement_dateTimeInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_colorInputWrapper(:final value) => value.control,
    skir.PresentationElement_namedInputWrapper(:final value) => value.control,
    skir.PresentationElement_listInputWrapper(:final value) => value.control,
    skir.PresentationElement_setInputWrapper(:final value) => value.control,
    skir.PresentationElement_mapInputWrapper(:final value) => value.control,
    skir.PresentationElement_recordInputWrapper(:final value) => value.control,
    skir.PresentationElement_polymorphicInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_searchInputWrapper(:final value) => value.control,
    skir.PresentationElement_nullableInputWrapper(:final value) =>
      value.control,
    skir.PresentationElement_linkInputWrapper(:final value) => value.control,
    skir.PresentationElement_resourcesWrapper(:final value) => value.control,
    _ => null,
  };
}

Iterable<skir.PresentationNode> _nestedPresentationNodes(
  skir.PresentationNode node,
) sync* {
  yield* node.presentationDecorationNodes();
  yield* node.presentationBodyNodes;
}

Iterable<skir.PresentationNode> _presentationDecorationNodes(
  skir.PresentationNode node, {
  bool includeControlPrefix = true,
}) sync* {
  final title = node.header?.title;
  if (title case skir.PresentationHeaderTitle_presentationWrapper(
    :final value,
  )) {
    yield value;
  }
  final element = node.element;
  final inputContent = switch (element) {
    skir.PresentationElement_textInputWrapper(:final value) => value.content,
    skir.PresentationElement_numericInputWrapper(:final value) => value.content,
    skir.PresentationElement_durationInputWrapper(:final value) =>
      value.content,
    skir.PresentationElement_dateTimeInputWrapper(:final value) =>
      value.content,
    skir.PresentationElement_colorInputWrapper(:final value) => value.content,
    skir.PresentationElement_bytesInputWrapper(:final value) => value.content,
    skir.PresentationElement_enumInputWrapper(:final value) => value.content,
    skir.PresentationElement_selectInputWrapper(:final value) => value.content,
    skir.PresentationElement_searchInputWrapper(:final value) => value.content,
    skir.PresentationElement_linkInputWrapper(:final value) =>
      value.inputContent,
    skir.PresentationElement_polymorphicInputWrapper(:final value) =>
      value.inputContent,
    _ => null,
  };
  if (inputContent?.leading case skir.InputAdornment_contentWrapper(
    :final value,
  )) {
    yield value;
  }
  if (inputContent?.suffix case final child?) yield child;
  final collectionContent = switch (element) {
    skir.PresentationElement_listInputWrapper(:final value) => value.content,
    skir.PresentationElement_setInputWrapper(:final value) => value.content,
    skir.PresentationElement_mapInputWrapper(:final value) => value.content,
    skir.PresentationElement_recordInputWrapper(:final value) => value.content,
    skir.PresentationElement_linkInputWrapper(:final value) => value.content,
    skir.PresentationElement_polymorphicInputWrapper(:final value) =>
      value.content,
    _ => null,
  };
  if (collectionContent != null) {
    for (final child in [
      collectionContent.empty,
      collectionContent.addIcon,
      collectionContent.removeIcon,
      collectionContent.reorderIcon,
      collectionContent.chooseIcon,
      collectionContent.unlinkIcon,
    ]) {
      if (child != null) yield child;
    }
  }
  if (includeControlPrefix) {
    if (node.boundControl?.prefix case final prefix?) yield prefix;
  }
  final displayAppearances = switch (element) {
    skir.PresentationElement_badgeWrapper(:final value) => [value.options],
    skir.PresentationElement_chipWrapper(:final value) => [value.options],
    skir.PresentationElement_dateTimeWrapper(:final value) => [value.options],
    skir.PresentationElement_relativeTimeWrapper(:final value) => [
      value.options,
    ],
    skir.PresentationElement_statusWrapper(:final value) => [
      for (final item in value.cases) item.appearance.options,
      value.fallback?.options,
    ],
    _ => const <skir.DisplayAppearance?>[],
  };
  for (final appearance in displayAppearances) {
    if (appearance?.icon case skir.InputAdornment_contentWrapper(
      :final value,
    )) {
      yield value;
    }
  }
}

Iterable<skir.PresentationNode> _presentationBodyNodes(
  skir.PresentationNode node,
) sync* {
  final element = node.element;
  switch (element) {
    case skir.PresentationElement_partWrapper(:final value):
      if (value.body case final body?) yield body;
    case skir.PresentationElement_childrenWrapper(:final value):
      yield* _childrenNodes(value);
    case skir.PresentationElement_appearanceDefaultsWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_sectionWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_paddingWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_tabsWrapper(:final value):
      for (final tab in value.tabs) {
        yield tab.child;
        if (tab.icon case final child?) yield child;
      }
    case skir.PresentationElement_typedFieldWrapper(:final value):
      if (value.presentation case final child?) yield child;
    case skir.PresentationElement_conditionalWrapper(:final value):
      yield value.whenTrue;
      if (value.whenFalse case final child?) yield child;
    case skir.PresentationElement_repeatedWrapper(:final value):
      yield* _sequenceNodes(value.presentation);
    case skir.PresentationElement_scopedBindingWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_selectInputWrapper(:final value):
      for (final option in value.options) {
        if (option.content case final child?) yield child;
      }
      for (final option
          in value.optionsConfig?.optionOverrides ??
              const <skir.ChoiceOptionAppearance>[]) {
        if (option.content case final child?) yield child;
      }
    case skir.PresentationElement_enumInputWrapper(:final value):
      for (final option
          in value.options?.optionOverrides ??
              const <skir.ChoiceOptionAppearance>[]) {
        if (option.content case final child?) yield child;
      }
    case skir.PresentationElement_namedInputWrapper(:final value):
      if (value.payloadPresentation case final child?) yield child;
    case skir.PresentationElement_buttonWrapper(:final value):
      if (value.icon case final child?) yield child;
    case skir.PresentationElement_menuWrapper(:final value):
      for (final item in value.items) {
        if (item.icon case final child?) yield child;
      }
    case skir.PresentationElement_tooltipWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_listInputWrapper(:final value):
      if (value.itemPresentation case final child?) yield child;
    case skir.PresentationElement_setInputWrapper(:final value):
      if (value.itemPresentation case final child?) yield child;
    case skir.PresentationElement_resourcesWrapper(
      value: skir.ResourcesElement(
        layout: skir.ResourcesLayout_treeWrapper(:final value),
      ),
    ):
      if (value.group case final child?) yield child;
    case skir.PresentationElement_mapInputWrapper(:final value):
      if (value.keyPresentation case final child?) yield child;
      if (value.valuePresentation case final child?) yield child;
    case skir.PresentationElement_recordInputWrapper(:final value):
      if (value.fieldPresentation case final child?) yield child;
    case skir.PresentationElement_polymorphicInputWrapper(:final value):
      for (final option in value.concreteTypes) {
        if (option.presentation case final child?) yield child;
      }
    case skir.PresentationElement_searchInputWrapper(:final value):
      if (value.summary case final child?) yield child;
      if (value.empty case final child?) yield child;
      if (value.loading case final child?) yield child;
      yield* _searchProviderNodes(value.provider);
    case skir.PresentationElement_collectionLookupWrapper(:final value):
      yield value.found;
      yield value.missing;
      if (value.loading case final child?) yield child;
    case skir.PresentationElement_collectionGraphWrapper(:final value):
      yield* _sequenceNodes(value.rootSequence);
      yield value.node;
      yield* _sequenceNodes(value.children);
    case skir.PresentationElement_alignWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_containerWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_sizeWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_transformWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_anchorWrapper(:final value):
      yield value.child;
    case skir.PresentationElement_connectionLayerWrapper(:final value):
      yield value.child;
      for (final connection in value.connections) {
        yield* _connectionNodes(connection);
      }
    case skir.PresentationElement_polymorphicMatchWrapper(:final value):
      for (final item in value.cases) {
        yield item.child;
      }
      if (value.fallback case final child?) yield child;
    case skir.PresentationElement_adaptiveLeadingWrapper(:final value):
      yield value.leading;
      if (value.center case final child?) yield child;
      if (value.suffix case final child?) yield child;
    case skir.PresentationElement_nullableInputWrapper(:final value):
      if (value.valuePresentation case final child?) yield child;
    default:
      break;
  }
}

Iterable<skir.PresentationNode> _childrenNodes(
  skir.ChildrenElement children,
) sync* {
  switch (children) {
    case skir.ChildrenElement_columnWrapper(:final value) ||
        skir.ChildrenElement_rowWrapper(:final value):
      for (final child in value.children) {
        switch (child) {
          case skir.AxisChild_fixedWrapper(:final value):
            yield value;
          case skir.AxisChild_flexibleWrapper(:final value):
            yield value.child;
          default:
            break;
        }
      }
    case skir.ChildrenElement_wrapWrapper(:final value):
      yield* value.children;
    case skir.ChildrenElement_gridWrapper(:final value):
      yield* value.children;
    case skir.ChildrenElement_stackWrapper(:final value):
      for (final child in value.children) {
        switch (child) {
          case skir.StackChild_flowWrapper(:final value):
            yield value;
          case skir.StackChild_positionedWrapper(:final value):
            yield value.child;
          default:
            break;
        }
      }
    default:
      break;
  }
}

Iterable<skir.PresentationNode> _sequenceNodes(
  skir.SequencePresentation sequence,
) sync* {
  yield sequence.item;
  if (sequence.empty case final child?) yield child;
  if (sequence.separator case final child?) yield child;
}

Iterable<skir.PresentationNode> _connectionNodes(
  skir.PresentationConnection connection,
) sync* {
  final markers = switch (connection) {
    skir.PresentationConnection_connectionWrapper(:final value) =>
      value.markers,
    skir.PresentationConnection_bundleWrapper(:final value) => [
      ...value.trunkMarkers,
      ...value.branchMarkers,
    ],
    _ => const <skir.ConnectionMarker>[],
  };
  for (final marker in markers) {
    yield marker.node;
  }
}

Iterable<skir.PresentationNode> _searchResultNodes(
  skir.SearchResultMapping result,
) sync* {
  yield result.presentation;
}

Iterable<skir.PresentationNode> _searchProviderNodes(
  skir.SearchProvider provider,
) sync* {
  switch (provider) {
    case skir.SearchProvider_staticValuesWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_collectionWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_httpJsonWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_realmCallbackWrapper(:final value):
      yield* _searchResultNodes(value.result);
    case skir.SearchProvider_gateWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_debounceWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_cacheWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_rankWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_limitWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_distinctWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_historyWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_sectionWrapper(:final value):
      yield* _searchProviderNodes(value.child);
    case skir.SearchProvider_mergeWrapper(:final value):
      for (final child in value.children) {
        yield* _searchProviderNodes(child);
      }
    default:
      break;
  }
}
