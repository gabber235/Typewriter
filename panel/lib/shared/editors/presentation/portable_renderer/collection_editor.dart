part of "../portable_presentation_renderer.dart";

/// One resolved delegation boundary, retaining its lexical scope and guidance.
@freezed
sealed class EditorSelection with _$EditorSelection {
  const factory EditorSelection.ready({
    required skir.PresentationNode node,
    required PortablePresentationScope scope,
    ResolvedFieldAssociation? fieldAssociation,
    ScopedEditorGuidance? guidance,
  }) = ReadyEditorSelection;
  const factory EditorSelection.failed(String message) = FailedEditorSelection;
}

@freezed
abstract class ScopedEditorGuidance with _$ScopedEditorGuidance {
  const factory ScopedEditorGuidance({
    required skir.BoundControl control,
    required PortablePresentationScope scope,
  }) = _ScopedEditorGuidance;
  const ScopedEditorGuidance._();

  Widget wrap(Widget child) => _controlAssociation(control, scope, child);
}

extension EditorSelectionRendering on EditorSelection {
  Widget render() => switch (this) {
    FailedEditorSelection(:final message) => _diagnostic(message),
    ReadyEditorSelection(
      :final node,
      :final scope,
      :final fieldAssociation,
      :final guidance,
    ) =>
      guidance?.wrap(
            PortablePresentationNodeRenderer(
              node: node,
              scope: scope,
              fieldAssociation: fieldAssociation,
            ),
          ) ??
          PortablePresentationNodeRenderer(
            node: node,
            scope: scope,
            fieldAssociation: fieldAssociation,
          ),
  };
}

/// A header contribution stays scoped to the source that authored its expressions.
@freezed
abstract class _ScopedCollectionHeader with _$ScopedCollectionHeader {
  const factory _ScopedCollectionHeader({
    required PortablePresentationScope scope,
    skir.PresentationHeader? header,
    @Default([]) List<_SuppliedHeaderControl> controls,
  }) = __ScopedCollectionHeader;
}

enum CollectionEntryLayout { inline, sourceHeader, disclosure }

/// Reuses one prepared selection for classification and scoped rendering.
///
/// Intrinsic body contributions stop at authored headers and structural layouts.
/// Classification follows transparent delegation using the same prepared scope
/// as rendering, so inherited controls and permissions determine row shape.
/// Source headers consume collection controls once instead of nesting a second
/// generated disclosure around the same authored collection.
@freezed
abstract class _CollectionEditorContinuation
    with _$CollectionEditorContinuation {
  const factory _CollectionEditorContinuation({
    required AuthoredBindingAddress owner,
    required PortablePresentationScope scope,
    required CollectionEntryLayout layout,
    required Widget Function(
      BuildContext,
      Widget Function(_ScopedCollectionHeader, Widget)?,
    )
    render,
    Widget Function(
      BuildContext,
      Widget Function(_ScopedCollectionHeader, Widget),
    )?
    renderIntrinsicBody,
  }) = __CollectionEditorContinuation;
  const _CollectionEditorContinuation._();

  bool get effectiveInline => layout == CollectionEntryLayout.inline;
  bool get hasSourceHeader => layout == CollectionEntryLayout.sourceHeader;

  Widget renderStandalone(BuildContext context) => renderSafely(context, null);

  Widget renderInCollection(
    BuildContext context,
    Widget Function(_ScopedCollectionHeader, Widget) headerBuilder,
  ) => renderSafely(context, headerBuilder);

  Widget renderSafely(
    BuildContext context,
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
  ) {
    try {
      return render(context, headerBuilder);
    } on PresentationValueFailure catch (failure) {
      return _diagnostic(failure.message);
    } on FormatException catch (failure) {
      return _diagnostic(failure.message);
    }
  }
}

/// Immutable node gates and associations shared by both rendering entry points.
@freezed
abstract class PreparedNode with _$PreparedNode {
  const factory PreparedNode({
    required PortablePresentationScope scope,
    required bool available,
  }) = _PreparedNode;
}

extension CollectionEditorShape on ReadyEditorSelection {
  bool get isInline {
    if (node.header != null) return false;
    return switch (node.element) {
      skir.PresentationElement_linkInputWrapper(:final value) =>
        scope.read(value.control.binding)?.authoredItems == null,
      skir.PresentationElement_textInputWrapper() ||
      skir.PresentationElement_numericInputWrapper() ||
      skir.PresentationElement_toggleInputWrapper() ||
      skir.PresentationElement_selectInputWrapper() ||
      skir.PresentationElement_sliderInputWrapper() ||
      skir.PresentationElement_dateTimeInputWrapper() ||
      skir.PresentationElement_durationInputWrapper() ||
      skir.PresentationElement_colorInputWrapper() ||
      skir.PresentationElement_bytesInputWrapper() ||
      skir.PresentationElement_enumInputWrapper() => true,
      _ => false,
    };
  }
}

extension _CollectionEditorPreparation on PortablePresentationNodeRenderer {
  _CollectionEditorContinuation collectionContinuation(
    PortablePresentationScope preparedScope,
    bool available, {
    required AuthoredBindingAddress owner,
    required AuthoredBindingAddress? sourceOwner,
  }) {
    final bound = node.boundControl;
    final effectiveOwner = bound == null
        ? sourceOwner
        : preparedScope.authoredAliases.resolve(bound.binding);
    final rootHeader = node.header;
    final selection = selectTransparentBoundary(preparedScope);
    if (selection case FailedEditorSelection(:final message)) {
      return failedCollectionContinuation(owner, message);
    }
    final ownsSourceHeader =
        effectiveOwner == owner &&
        (rootHeader != null || ownsIntrinsicCollectionHeader(preparedScope));
    final child = selection is ReadyEditorSelection
        ? PortablePresentationNodeRenderer(
            node: selection.node,
            scope: selection.scope,
            fieldAssociation: selection.fieldAssociation,
          ).prepareCollectionContinuation(
            owner: owner,
            sourceOwner: effectiveOwner,
          )
        : null;
    final mutationScope = child?.scope ?? preparedScope;
    final intrinsic =
        effectiveOwner == owner &&
        rootHeader == null &&
        ownsIntrinsicCollectionHeader(preparedScope);

    if (intrinsic) {
      return _CollectionEditorContinuation(
        owner: owner,
        scope: preparedScope,
        layout: CollectionEntryLayout.sourceHeader,
        renderIntrinsicBody: (context, consume) =>
            intrinsicCollectionBody(context, preparedScope, available, consume),
        render: (context, headerBuilder) => _renderNode(
          context,
          node.element!,
          preparedScope,
          available,
          headerBuilder: headerBuilder,
        ),
      );
    }

    final intrinsicBody = child?.renderIntrinsicBody;
    if (rootHeader != null &&
        effectiveOwner == owner &&
        intrinsicBody != null) {
      return _CollectionEditorContinuation(
        owner: owner,
        scope: child!.scope,
        layout: CollectionEntryLayout.sourceHeader,
        render: (context, headerBuilder) => intrinsicBody(context, (
          intrinsicRoot,
          body,
        ) {
          final guided =
              (selection! as ReadyEditorSelection).guidance?.wrap(body) ?? body;
          return _renderNode(
            context,
            node.element!,
            preparedScope,
            available,
            renderedContent: guided,
            headerBuilder: (outerRoot, preparedBody) {
              final merged = outerRoot.copyWith(
                controls: [...intrinsicRoot.controls, ...outerRoot.controls],
              );
              if (headerBuilder != null) {
                return headerBuilder(merged, preparedBody);
              }
              return _AuthoredPresentationHeader(
                header: merged.header!,
                scope: merged.scope,
                body: preparedBody,
                contained:
                    node.element is skir.PresentationElement_sectionWrapper,
                collectionControls: merged.controls,
              );
            },
          );
        }),
      );
    }

    if (ownsSourceHeader) {
      return _CollectionEditorContinuation(
        owner: owner,
        scope: mutationScope,
        layout: CollectionEntryLayout.sourceHeader,
        render: (context, headerBuilder) {
          final selectedBody = child?.renderStandalone(context);
          return _renderNode(
            context,
            node.element!,
            preparedScope,
            available,
            renderedContent: selectedBody == null
                ? selection?.render()
                : (selection! as ReadyEditorSelection).guidance?.wrap(
                        selectedBody,
                      ) ??
                      selectedBody,
            headerBuilder: headerBuilder,
          );
        },
      );
    }
    if (rootHeader == null && child != null) {
      final intrinsicBody = child.renderIntrinsicBody;
      return child.copyWith(
        render: (context, headerBuilder) {
          final body = child.render(context, headerBuilder);
          return _renderNode(
            context,
            node.element!,
            preparedScope,
            available,
            renderedContent:
                (selection! as ReadyEditorSelection).guidance?.wrap(body) ??
                body,
          );
        },
        renderIntrinsicBody: intrinsicBody == null
            ? null
            : (context, consume) => intrinsicBody(context, (root, body) {
                final guided =
                    (selection! as ReadyEditorSelection).guidance?.wrap(body) ??
                    body;
                return consume(
                  root,
                  _renderNode(
                    context,
                    node.element!,
                    preparedScope,
                    available,
                    renderedContent: guided,
                  ),
                );
              }),
      );
    }

    return _CollectionEditorContinuation(
      owner: owner,
      scope: preparedScope,
      layout:
          rootHeader == null &&
              selection == null &&
              ReadyEditorSelection(node: node, scope: preparedScope).isInline
          ? CollectionEntryLayout.inline
          : CollectionEntryLayout.disclosure,
      render: (context, _) => _renderNode(
        context,
        node.element!,
        preparedScope,
        available,
        renderedContent: selection?.render(),
      ),
    );
  }

  PreparedNode prepareNode() {
    final indexed = scope.authoredIndex == null
        ? scope.withAuthoredLayout(node)
        : scope;
    final enabled = _boolean(
      indexed,
      node.properties.enabledIf,
      fallback: true,
    );
    if (enabled case _ResolvedFailure(:final message)) {
      throw PresentationValueFailure(message);
    }
    final available = (enabled as _ResolvedValue<bool>).value;
    var nested = indexed
        .withReadOnly(node.properties.readOnly)
        .withEnabled(available);
    final control = node.boundControl;
    nested = nested.copyWith(
      associatedControl: control,
      fieldAssociation:
          fieldAssociation ??
          (control == null
              ? null
              : ResolvedFieldAssociation.fromControl(control, nested)),
    );
    if (node.element == null) {
      throw const FormatException("The presentation node has no element");
    }
    return PreparedNode(scope: nested, available: available);
  }

  Widget renderPreparedNode(BuildContext context) {
    try {
      final prepared = prepareNode();
      final control = node.boundControl;
      final owner = control == null
          ? null
          : prepared.scope.authoredAliases.resolve(control.binding);
      if (owner != null) {
        return collectionContinuation(
          prepared.scope,
          prepared.available,
          owner: owner,
          sourceOwner: owner,
        ).renderStandalone(context);
      }
      return _renderNode(
        context,
        node.element!,
        prepared.scope,
        prepared.available,
      );
    } on PresentationValueFailure catch (failure) {
      return _diagnostic(failure.message);
    } on FormatException catch (failure) {
      return _diagnostic(failure.message);
    }
  }

  _CollectionEditorContinuation prepareCollectionContinuation({
    required AuthoredBindingAddress owner,
    required AuthoredBindingAddress? sourceOwner,
  }) {
    try {
      final prepared = prepareNode();
      return collectionContinuation(
        prepared.scope,
        prepared.available,
        owner: owner,
        sourceOwner: sourceOwner,
      );
    } on PresentationValueFailure catch (failure) {
      return failedCollectionContinuation(owner, failure.message);
    } on FormatException catch (failure) {
      return failedCollectionContinuation(owner, failure.message);
    }
  }

  _CollectionEditorContinuation failedCollectionContinuation(
    AuthoredBindingAddress owner,
    String message,
  ) {
    final failedScope = scope
        .withReadOnly(node.properties.readOnly)
        .withEnabled(false);
    return _CollectionEditorContinuation(
      owner: owner,
      scope: failedScope,
      layout: CollectionEntryLayout.inline,
      render: (context, _) => _diagnostic(message),
    );
  }

  skir.PresentationNode defaultChild(
    skir.ExpressionBindingId bindingId,
    String suffix,
  ) => skir.PresentationNode(
    nodeId: "${node.nodeId}.$suffix",
    properties: skir.PresentationProperties.defaultInstance,
    header: null,
    element: skir.PresentationElement.createDefaultPresentation(
      control: _generatedControl(
        skir.BindingRef(
          bindingId: bindingId,
          path: skir.ValuePath(segments: const []),
        ),
      ),
      presentationId: null,
    ),
  );

  _CollectionEditorContinuation prepareListChild(
    skir.PresentationNode? authored,
    skir.ExpressionBindingId itemBindingId,
    PortablePresentationScope itemScope,
  ) {
    final reference = skir.BindingRef(
      bindingId: itemBindingId,
      path: skir.ValuePath(segments: const []),
    );
    final owner = itemScope.authoredAliases.resolve(reference);
    if (owner == null) {
      throw const FormatException("The collection item address is unavailable");
    }
    return PortablePresentationNodeRenderer(
      node: authored ?? defaultChild(itemBindingId, "defaultItem"),
      scope: itemScope,
    ).prepareCollectionContinuation(owner: owner, sourceOwner: owner);
  }

  EditorSelection? selectTransparentBoundary(PortablePresentationScope scope) =>
      switch (node.element) {
        skir.PresentationElement_defaultPresentationWrapper(:final value) =>
          selectDefault(value, scope),
        skir.PresentationElement_invocationWrapper(:final value) =>
          selectInvocation(value, scope),
        skir.PresentationElement_scopedBindingWrapper(:final value) =>
          selectScopedBinding(value, scope),
        skir.PresentationElement_partWrapper() ||
        skir.PresentationElement_remainingFieldsWrapper() => null,
        _ => null,
      };

  EditorSelection selectScopedBinding(
    skir.ScopedBindingElement element,
    PortablePresentationScope scope,
  ) {
    final nested = scope.withBinding(element.binding, element.scopeBinding);
    return nested == null
        ? const EditorSelection.failed("The scoped binding is unavailable")
        : EditorSelection.ready(node: element.child, scope: nested);
  }

  bool ownsIntrinsicCollectionHeader(PortablePresentationScope scope) =>
      switch (node.element) {
        skir.PresentationElement_listInputWrapper() ||
        skir.PresentationElement_setInputWrapper() ||
        skir.PresentationElement_mapInputWrapper() => true,
        skir.PresentationElement_linkInputWrapper(:final value) =>
          scope.read(value.control.binding)?.authoredItems != null,
        _ => false,
      };

  Widget nodeEnvelope(Widget child, bool available) => Semantics(
    container: true,
    enabled: available,
    child: IgnorePointer(
      ignoring: !available,
      child: AnimatedOpacity(
        opacity: available ? 1 : 0.55,
        duration: const Duration(milliseconds: 120),
        child: KeyedSubtree(key: ValueKey(node.nodeId), child: child),
      ),
    ),
  );

  Widget intrinsicCollectionBody(
    BuildContext context,
    PortablePresentationScope preparedScope,
    bool available,
    Widget Function(_ScopedCollectionHeader, Widget) consume,
  ) => _renderElement(
    context,
    node.element!,
    preparedScope,
    ownedCollectionHeaderBuilder: (root, body) =>
        consume(root, nodeEnvelope(body, available)),
  );
}
