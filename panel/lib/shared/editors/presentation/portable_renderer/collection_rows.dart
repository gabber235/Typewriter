part of "../portable_presentation_renderer.dart";

// Commands identify equivalent controls without granting mutation capabilities.
@freezed
sealed class _CollectionCommand with _$CollectionCommand {
  const factory _CollectionCommand.removeList(
    PortableDiagnosticTarget target,
    skir.ItemId item,
  ) = _RemoveListCommand;
  const factory _CollectionCommand.removeMap(
    PortableDiagnosticTarget target,
    skir.ItemId row,
  ) = _RemoveMapCommand;
  const factory _CollectionCommand.reorder(PortableDiagnosticTarget item) =
      _ReorderCommand;
  const factory _CollectionCommand.disconnect(skir.LinkOccurrence occurrence) =
      _DisconnectCommand;
}

@freezed
abstract class _ScopedHeaderDeclaration with _$ScopedHeaderDeclaration {
  const factory _ScopedHeaderDeclaration({
    required skir.HeaderItem item,
    required PortablePresentationScope scope,
  }) = __ScopedHeaderDeclaration;
}

@freezed
abstract class _SuppliedHeaderControl with _$SuppliedHeaderControl {
  const factory _SuppliedHeaderControl({
    required WidgetBuilder build,
    _CollectionCommand? command,
  }) = __SuppliedHeaderControl;
}

extension _CollectionRemovalCommand on PortablePresentationScope {
  PortableDiagnosticTarget? collectionCommandTarget(skir.BindingRef reference) {
    final located = location(reference);
    if (located != null) return PortableDiagnosticTarget.value(located);
    final source = sourceReference(reference);
    final owner = authoredAliases.resolve(reference);
    if (source == null || owner == null) return null;
    return PortableDiagnosticTarget.binding(source);
  }

  _CollectionCommand? collectionRemovalCommand(skir.EditorAction action) =>
      switch (action) {
        skir.EditorAction_localWrapper(:final value) => switch (value) {
          skir.LocalEditorAction_removeListItemWrapper(:final value) =>
            switch (collectionCommandTarget(value.target)) {
              final target? => _CollectionCommand.removeList(
                target,
                value.item,
              ),
              null => null,
            },
          skir.LocalEditorAction_removeMapRowWrapper(:final value) =>
            switch (collectionCommandTarget(value.target)) {
              final target? => _CollectionCommand.removeMap(target, value.row),
              null => null,
            },
          _ => null,
        },
        _ => null,
      };
}
// SourceReference plus the resolved owner prove a bound alias target even
// when the host has no resource ValueLocation. Direct links still require
// a concrete occurrence location for relation mutation.

extension _HeaderCommandIdentity on _ScopedHeaderDeclaration {
  _CollectionCommand? get command => switch (item) {
    skir.HeaderItem_buttonWrapper(:final value) =>
      scope.collectionRemovalCommand(value.action),
    skir.HeaderItem_reorderHandleWrapper(:final value) => switch (scope
        .collectionCommandTarget(value.source)) {
      final target? => _CollectionCommand.reorder(target),
      null => null,
    },
    _ => null,
  };
}

List<_SuppliedHeaderControl> _remainingCollectionControls(
  List<_ScopedHeaderDeclaration> raw,
  List<_SuppliedHeaderControl> supplied,
) {
  final declared = raw
      .map((declaration) => declaration.command)
      .nonNulls
      .toSet();
  return [
    for (final control in supplied)
      if (control.command == null || !declared.contains(control.command))
        control,
  ];
}

// Host default Add and picker Add have no proven authored equivalent.
// Leave their command null. An authored append with any payload survives.
// Disconnect is not RemoveList, even at the same source location.
// Keep raw declarations, including hidden ones, for matching. Resolve each
// surviving authored item once using its own scope and existing _items logic.

// The caller supplies a fallback header factory.
// Authored headers still render at their original scoped position.
class _CollectionEntry extends StatelessWidget {
  const _CollectionEntry({
    required this.editor,
    required this.controls,
    required this.generatedHeader,
    required this.initiallyNeedsRepair,
    required this.scope,
    required this.owner,
    this.appearance,
  });
  final _CollectionEditorContinuation editor;
  final List<_SuppliedHeaderControl> controls;
  final skir.PresentationHeader Function() generatedHeader;
  final bool initiallyNeedsRepair;
  final PortablePresentationScope scope;
  final skir.PresentationNode owner;
  final skir.CollectionAppearance? appearance;

  @override
  Widget build(BuildContext context) {
    final child = switch (editor.layout) {
      CollectionEntryLayout.inline => _collectionHeaderLine(
        titleOrEditor: _CollectionInlineEditor(
          child: editor.renderStandalone(context),
        ),
        before: [
          for (final item in controls)
            if (item.command is _ReorderCommand) item.build(context),
        ],
        after: [
          for (final item in controls)
            if (item.command is! _ReorderCommand) item.build(context),
        ],
        secondary: const [],
      ),
      CollectionEntryLayout.sourceHeader => editor.renderInCollection(
        context,
        (header, body) => _headerWithCollectionOperations(
          header,
          body,
          controls,
          fallbackHeader: generatedHeader,
          initiallyNeedsRepair: initiallyNeedsRepair,
          recoveryFocus: _CollectionRowContext.maybeOf(context)?.recoveryFocus,
          disclosureFocus: _CollectionRowContext.maybeOf(context)
              ?.disclosureFocus,
        ),
      ),
      CollectionEntryLayout.disclosure => _GeneratedCollectionDisclosure(
        header: generatedHeader(),
        initiallyNeedsRepair: initiallyNeedsRepair,
        body: editor.renderStandalone(context),
        scope: editor.scope,
        collectionControls: controls,
      ),
    };
    final inset = appearance?.itemPadding;
    return Padding(
      padding: EdgeInsets.only(bottom: _collectionSpacing(context, appearance)),
      child: _collectionSurface(
        context,
        appearance,
        scope,
        owner,
        Padding(
          padding: inset != null
              ? _presentationInsets(inset)
              : editor.effectiveInline
              ? EdgeInsets.all(context.spacing.space2)
              : EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

// Scalar map keys provide a readable fallback title.
extension _CollectionKeyTitle on skir.DataValue {
  String? get collectionKeyTitle {
    final payload = authoredPayload;
    final readable = switch (payload) {
      skir.DataValue_stringValueWrapper() ||
      skir.DataValue_booleanWrapper() ||
      skir.DataValue_integerWrapper() ||
      skir.DataValue_floatWrapper() ||
      skir.DataValue_decimalWrapper() ||
      skir.DataValue_enumCaseWrapper() ||
      skir.DataValue_timestampWrapper() ||
      skir.DataValue_durationWrapper() => true,
      _ => false,
    };
    if (!readable) return null;
    final text = portableExpressionDisplayText(payload);
    return text.trim().isEmpty ? null : text;
  }
}

// Generated titles are literals rebuilt from the current rendered snapshot.
// Header expressions authored by a presentation keep their own scope.
skir.PresentationHeader _generatedEntryHeader(String title) =>
    skir.PresentationHeader(
      binding: null,
      title: skir.PresentationHeaderTitle.wrapText(
        skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue(title)),
      ),
      description: null,
      initiallyExpanded: null,
      items: const [],
      headerPadding: null,
      contentPadding: null,
    );
// Null binding retains the existing contained control diagnostic summary.
// _GeneratedCollectionDisclosure supplies the frozen initial expansion.

// Called by the existing header renderer after raw semantic matching.
Widget _collectionHeaderLine({
  required Widget titleOrEditor,
  required List<Widget> before,
  required List<Widget> after,
  required List<Widget> secondary,
  Widget? permittedHandle,
  Widget? primaryOperation,
}) => _PortableHeaderRow(
  before: [...before, ?permittedHandle],
  title: titleOrEditor,
  after: [...after, ?primaryOperation],
  end: secondary,
);

Widget _headerWithCollectionOperations(
  _ScopedCollectionHeader root,
  Widget body,
  List<_SuppliedHeaderControl> parentControls, {
  required skir.PresentationHeader Function() fallbackHeader,
  required bool initiallyNeedsRepair,
  FocusNode? recoveryFocus,
  FocusNode? disclosureFocus,
}) {
  final supplied = [...root.controls, ...parentControls];
  if (root.header == null) {
    return _GeneratedCollectionDisclosure(
      header: fallbackHeader(),
      initiallyNeedsRepair: initiallyNeedsRepair,
      body: body,
      scope: root.scope,
      collectionControls: supplied,
    );
  }
  return _AuthoredPresentationHeader(
    header: root.header!,
    scope: root.scope,
    body: body,
    contained: true,
    collectionControls: supplied,
    collectionRecoveryFocusNode: recoveryFocus,
    collectionDisclosureFocusNode: disclosureFocus,
  );
}

// add uses _addSequenceItem for lists and links, or scope.addMapRow for maps.
_SuppliedHeaderControl? _collectionAdd({
  required bool allowAdd,
  required PortablePresentationScope mutationScope,
  required skir.CollectionContent? content,
  required String fallbackLabel,
  required IconData fallbackIcon,
  required void Function(BuildContext) add,
  FocusNode? focusNode,
}) {
  if (!allowAdd) return null;
  return _SuppliedHeaderControl(
    // Host default creation has no guessed authored command equivalent.
    command: null,
    build: (context) => _operationAppearance(
      content,
      mutationScope,
      (states, style) => IconButton(
        focusNode: focusNode,
        statesController: states,
        style: style,
        tooltip: _operationText(
          mutationScope,
          content?.operationTooltip ?? content?.addLabel,
          fallbackLabel,
        ),
        onPressed: mutationScope.canExecuteAction ? () => add(context) : null,
        icon: _operationGlyph(
          content?.addIcon,
          mutationScope,
          Icon(fallbackIcon),
        ),
      ),
      tooltip: false,
    ),
  );
}

class _GeneratedCollectionDisclosure extends HookWidget {
  const _GeneratedCollectionDisclosure({
    required this.initiallyNeedsRepair,
    required this.header,
    required this.body,
    required this.scope,
    required this.collectionControls,
  });
  final bool initiallyNeedsRepair;
  final skir.PresentationHeader header;
  final Widget body;
  final PortablePresentationScope scope;
  final List<_SuppliedHeaderControl> collectionControls;

  @override
  Widget build(BuildContext context) {
    // Capture once per keyed row instance, not once per value refresh.
    final initialExpanded = useMemoized(() => initiallyNeedsRepair);
    final generated = (header.toMutable()..initiallyExpanded = initialExpanded)
        .toFrozen();
    return _AuthoredPresentationHeader(
      header: generated,
      body: body,
      scope: scope,
      contained: true,
      collectionControls: collectionControls,
      collectionRecoveryFocusNode: _CollectionRowContext.maybeOf(context)
          ?.recoveryFocus,
      collectionDisclosureFocusNode: _CollectionRowContext.maybeOf(context)
          ?.disclosureFocus,
    );
  }
}

extension CollectionMovement on PortablePresentationScope {
  void moveCollectionItem({
    required skir.BindingRef collection,
    required List<skir.ListItem> items,
    required skir.ItemId item,
    required int destination,
  }) {
    if (!canExecuteAction) return;
    final from = items.indexWhere((candidate) => candidate.id == item);
    if (from < 0 || destination < 0 || destination >= items.length) return;
    if (from == destination) return;
    final remaining = [...items]..removeAt(from);
    final after = destination == 0 ? null : remaining[destination - 1].id;
    moveListItem(collection, item, after);
  }
}

class CollectionSequence extends StatelessWidget {
  const CollectionSequence({
    required this.scope,
    required this.collection,
    required this.items,
    required this.allowReorder,
    required this.entryBuilder,
    super.key,
  });
  final PortablePresentationScope scope;
  final skir.BindingRef collection;
  final List<skir.ListItem> items;
  final bool allowReorder;
  final Widget Function(BuildContext, skir.ListItem, int) entryBuilder;

  // ReorderableListView promotes this stable source key to its own global
  // child key, preserving the editor through moves into its drag proxy.
  Widget _entry(int index) => KeyedSubtree(
    key: ValueKey(items[index].id.value),
    child: Builder(
      builder: (context) => entryBuilder(context, items[index], index),
    ),
  );

  void _move(BuildContext context, skir.ItemId item, int destination) {
    if (!allowReorder || !scope.canExecuteAction) return;
    _CollectionInteractionScope.invalidateAncestors(context);
    scope.moveCollectionItem(
      collection: collection,
      items: items,
      item: item,
      destination: destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!allowReorder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < items.length; i++) _entry(i)],
      );
    }
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, index) => _entry(index),
      proxyDecorator: (child, _, animation) => _collectionDragScopes(
        context,
        AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) => Material(
            elevation: 6 * Curves.easeInOut.transform(animation.value),
            child: child,
          ),
        ),
      ),
      onReorderStart: (_) =>
          _CollectionInteractionScope.invalidateAncestors(context),
      onReorderItem: (from, to) => _move(context, items[from].id, to),
    );
  }

  Widget handle(
    BuildContext context,
    int index,
    PortablePresentationScope itemScope, {
    Widget? icon,
    String? label,
  }) => _AuthoredReorderHandle(
    index: index,
    label: label ?? "Reorder item ${index + 1}",
    icon: icon,
    enabled:
        allowReorder && scope.canExecuteAction && itemScope.canExecuteAction,
    canMoveEarlier: index > 0,
    canMoveLater: index + 1 < items.length,
    onMoveEarlier: () {
      if (!itemScope.canExecuteAction) return;
      _move(context, items[index].id, index - 1);
    },
    onMoveLater: () {
      if (!itemScope.canExecuteAction) return;
      _move(context, items[index].id, index + 1);
    },
  );
}

// Flutter transports themes for a drag proxy, but portable scopes are not
// themes. Forward their existing owners into the root overlay, retaining
// the original ancestor order. Popup overlays keep their normal viewport.
Widget _collectionDragScopes(BuildContext source, Widget child) {
  final wrappers = <Widget Function(Widget)>[];
  source.visitAncestorElements((element) {
    final inherited = element.widget;
    switch (inherited) {
      case _CollectionInteractionScope(:final owner):
        wrappers.add(
          (child) => _CollectionInteractionScope(owner: owner, child: child),
        );
      case _CollectionRowContext(:final binding):
        wrappers.add(
          (child) => _CollectionRowContext(binding: binding, child: child),
        );
      case PortableDiagnosticScope(:final tree, :final placement):
        wrappers.add(
          (child) => PortableDiagnosticScope(
            tree: tree,
            placement: placement,
            child: child,
          ),
        );
      case _PortableDiagnosticParent(:final id):
        wrappers.add(
          (child) => _PortableDiagnosticParent(id: id, child: child),
        );
      case PortableLocationRevealScope(:final controller, :final presentation):
        wrappers.add(
          (child) => PortableLocationRevealScope(
            controller: controller,
            presentation: presentation,
            child: child,
          ),
        );
      case _PortableHeaderTitle(:final title):
        wrappers.add(
          (child) => _PortableHeaderTitle(title: title, child: child),
        );
      case DepthContainer(:final depth):
        wrappers.add((child) => DepthContainer(depth: depth, child: child));
      case _PortableControlStateScope(:final controller):
        wrappers.add(
          (child) =>
              _PortableControlStateScope(controller: controller, child: child),
        );
      case PortableControlDiagnostics(
        :final identity,
        :final invalid,
        :final onValidationChanged,
      ):
        wrappers.add(
          (child) => PortableControlDiagnostics(
            identity: identity,
            invalid: invalid,
            onValidationChanged: onValidationChanged,
            child: child,
          ),
        );
      case PresentationInteractionScope(:final value):
        wrappers.add(
          (child) => PresentationInteractionScope(value: value, child: child),
        );
      case PresentationEnvironment(:final bindings):
        wrappers.add(
          (child) => PresentationEnvironment(bindings: bindings, child: child),
        );
      case PortablePageInteractionScope(
        :final nodeBuilder,
        :final graphBuilder,
      ):
        wrappers.add(
          (child) => PortablePageInteractionScope(
            nodeBuilder: nodeBuilder,
            graphBuilder: graphBuilder,
            child: child,
          ),
        );
      case _CollectionMenuInvocation(:final origin, :final row, :final close):
        wrappers.add(
          (child) => _CollectionMenuInvocation(
            origin: origin,
            row: row,
            close: close,
            child: child,
          ),
        );
      default:
        break;
    }
    return true;
  });
  var proxy = child;
  for (final wrap in wrappers) {
    proxy = wrap(proxy);
  }
  return proxy;
}

Widget _inlineMapPair({
  required BuildContext context,
  required Widget keyEditor,
  required Widget valueEditor,
}) {
  final gap = context.spacing.space2;
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Reserve enough width for the value while keeping readable keys.
      const minimumKey = 120.0;
      const minimumValue = 180.0;
      const maximumKey = 220.0;
      final sideBySide = width >= minimumKey + gap + minimumValue;
      final keyWidth = sideBySide
          ? (width * 0.35).clamp(minimumKey, maximumKey)
          : width;
      final valueWidth = sideBySide ? width - keyWidth - gap : width;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(
            key: const ValueKey("keyEditor"),
            width: keyWidth,
            child: keyEditor,
          ),
          SizedBox(
            key: const ValueKey("valueEditor"),
            width: valueWidth,
            child: valueEditor,
          ),
        ],
      );
    },
  );
}

Widget _structuredMapBody({
  required BuildContext context,
  required Widget keyEditor,
  required Widget valueEditor,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    keyEditor,
    SizedBox(height: context.spacing.space3),
    valueEditor,
  ],
);
// Resizing only changes SizedBox widths. It does not replace a Row
// subtree with a Column subtree or recreate the two input controllers.

extension _CollectionFocusCallers on PortablePresentationNodeRenderer {
  void runGeneratedRemove({
    required _CollectionRowBinding row,
    required PortablePresentationScope scope,
    required skir.EditorAction action,
  }) {
    final origin = row.focus?.captureOrigin(row.row);
    final recovery = row.focus;
    if (recovery == null) {
      unawaited(scope.executeAction(action));
      return;
    }
    unawaited(
      recovery.removeLocal(
        row: row.row,
        scope: scope,
        action: action,
        origin: origin,
      ),
    );
  }

  _SuppliedHeaderControl generatedRemove({
    required _CollectionRowBinding row,
    required PortablePresentationScope scope,
    required skir.EditorAction action,
    required skir.CollectionContent? content,
  }) => _SuppliedHeaderControl(
    command: scope.collectionRemovalCommand(action),
    build: (context) => _operationAppearance(
      content,
      scope,
      (states, style) => IconButton(
        statesController: states,
        style: style,
        focusNode: row.recoveryFocus,
        tooltip: _operationText(
          scope,
          content?.operationTooltip ?? content?.removeLabel,
          action is skir.EditorAction_localWrapper &&
                  action.value is skir.LocalEditorAction_removeMapRowWrapper
              ? "Remove row"
              : "Remove item",
        ),
        onPressed: scope.canExecuteAction
            ? () => runGeneratedRemove(row: row, scope: scope, action: action)
            : null,
        icon: _operationGlyph(
          content?.removeIcon,
          scope,
          const Icon(Icons.delete_outline),
        ),
      ),
      tooltip: false,
    ),
  );

  Widget collectionRowWithFocus({
    required skir.ItemId id,
    required _CollectionEditorContinuation editor,
    required PortablePresentationScope scope,
    required skir.PresentationNode owner,
    required skir.PresentationHeader Function() generatedHeader,
    required bool initiallyNeedsRepair,
    required List<_SuppliedHeaderControl> controls,
    required skir.EditorAction? permittedRemove,
    required skir.CollectionAppearance? appearance,
    required skir.CollectionContent? content,
  }) => _MountedCollectionRow(
    key: ValueKey(id.value),
    row: id,
    builder: (context, row) => _CollectionEntry(
      editor: editor,
      controls: [
        ...controls,
        if (permittedRemove != null)
          generatedRemove(
            row: row,
            // The action targets the containing collection. Child presentation
            // bindings may shadow its binding ID, so retain the source scope
            // while applying the effective editor permissions.
            scope: scope
                .withEnabled(editor.scope.enabled)
                .withReadOnly(editor.scope.readOnly),
            action: permittedRemove,
            content: content,
          ),
      ],
      generatedHeader: generatedHeader,
      initiallyNeedsRepair: initiallyNeedsRepair,
      scope: scope,
      owner: owner,
      appearance: appearance,
    ),
  );

  void runCollectionAdd({
    required BuildContext context,
    required void Function(BuildContext) add,
  }) {
    _CollectionInteractionScope.invalidateAncestors(context);
    add(context);
  }

  void runCollectionClear({
    required _CollectionRowBinding row,
    required PortablePresentationScope scope,
    required skir.BindingRef reference,
    required skir.LinkOccurrence occurrence,
  }) {
    final origin = row.focus?.captureOrigin(row.row);
    final recovery = row.focus;
    if (recovery == null) {
      unawaited(
        scope.clearLinkedOccurrence(
          reference: reference,
          occurrence: occurrence,
        ),
      );
      return;
    }
    unawaited(
      recovery.clearLink(
        row: row.row,
        scope: scope,
        reference: reference,
        occurrence: occurrence,
        origin: origin,
      ),
    );
  }
}

extension _CollectionHeaderFocus on PortablePresentationNodeRenderer {
  Widget collectionWithFocus({
    required PortablePresentationScope sourceScope,
    required PortablePresentationScope mutationScope,
    required skir.BindingRef reference,
    required _CollectionRemovalKind removalKind,
    required List<skir.ItemId> renderedOrder,
    required _ScopedCollectionHeader? sourceHeader,
    required skir.PresentationHeader Function() fallbackHeader,
    required WidgetBuilder buildBody,
    required bool contained,
    required bool allowAdd,
    required skir.CollectionContent? content,
    required String addLabel,
    required IconData addIcon,
    required void Function(BuildContext) add,
    List<_SuppliedHeaderControl> parentRowControls = const [],
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
  }) => _MountedCollectionInteraction(
    key: ValueKey(sourceScope.authoredAliases.resolve(reference)),
    scope: sourceScope,
    reference: reference,
    removalKind: removalKind,
    renderedOrder: renderedOrder,
    builder: (context) {
      final interaction = _CollectionInteractionScope.of(context);
      final addControl = _collectionAdd(
        allowAdd: allowAdd,
        mutationScope: mutationScope,
        content: content,
        fallbackLabel: addLabel,
        fallbackIcon: addIcon,
        focusNode: interaction.addFocus,
        add: (context) => runCollectionAdd(context: context, add: add),
      );
      // Own the header and Add inside the same mounted collection as its rows.
      try {
        final body = buildBody(context);
        final scopedHeader = _ScopedCollectionHeader(
          header: sourceHeader?.header,
          scope: sourceHeader?.scope ?? sourceScope,
          controls: [?addControl, ...parentRowControls],
        );
        if (headerBuilder != null) return headerBuilder(scopedHeader, body);
        return _AuthoredPresentationHeader(
          header: scopedHeader.header ?? fallbackHeader(),
          scope: scopedHeader.scope,
          body: body,
          contained: contained,
          collectionControls: scopedHeader.controls,
        );
      } on PresentationColorFailure catch (failure) {
        return _diagnostic(failure.message);
      } on FormatException catch (failure) {
        return _diagnostic(failure.message);
      }
    },
  );
}

// Standalone collections reveal their contents; item disclosures own their
// initial repair policy separately.
skir.PresentationHeader _generatedCollectionHeader(String title) =>
    (_generatedEntryHeader(
      title,
    ).toMutable()..initiallyExpanded = true).toFrozen();

/// The collection row already owns the surface around its effective editor.
class _CollectionInlineEditor extends InheritedWidget {
  const _CollectionInlineEditor({required super.child});

  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CollectionInlineEditor>() !=
      null;

  @override
  bool updateShouldNotify(_CollectionInlineEditor oldWidget) => false;
}
