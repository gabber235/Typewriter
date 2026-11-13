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
  // A resolved alias proves a bound target even without a resource location.
  // Relation mutation still requires a concrete link occurrence location.
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

/// Removes supplied controls only when raw authored declarations prove the
/// same command, including hidden declarations. Add has no inferred equivalent,
/// and disconnect remains distinct from removing the containing list item.
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
    final caseName = enumCaseName;
    if (caseName != null) return caseName;
    final payload = authoredPayload;
    final readable = switch (payload) {
      skir.DataValue_stringValueWrapper() ||
      skir.DataValue_booleanWrapper() ||
      skir.DataValue_integerWrapper() ||
      skir.DataValue_floatWrapper() ||
      skir.DataValue_decimalWrapper() ||
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
}) {
  if (!allowAdd) return null;
  return _SuppliedHeaderControl(
    // Host default creation has no guessed authored command equivalent.
    command: null,
    build: (context) => _operationAppearance(
      content,
      mutationScope,
      (states, style) => Button(
        face: ButtonFace.icon,
        icon: _operationGlyph(
          content?.addIcon,
          mutationScope,
          Icon(fallbackIcon),
        ),
        label: _operationText(
          mutationScope,
          content?.operationTooltip ?? content?.addLabel,
          fallbackLabel,
        ),
        tooltip: _operationText(
          mutationScope,
          content?.operationTooltip ?? content?.addLabel,
          fallbackLabel,
        ),
        color: _accentOf(style, null),
        dense: _denseOf(style),
        statesController: states,
        onPressed: mutationScope.canExecuteAction ? () => add(context) : null,
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

/// The items of one editor collection on row entries: added items slide in
/// with rowIn, removed ones squash shut with listOut, and a reorder moves
/// items in place. [arrival] and [leave] are the service's item moves, read
/// by the collection input before this widget builds. A leaving item stays
/// as an extra, undraggable item, so visual and item indices differ while it
/// leaves; data that arrives during a drag waits for the drop.
/// Builds an entry's content while it stays and keeps its last content
/// while it leaves: a removed item is no longer in the scope, so building
/// it again would show a diagnostic instead of the item.
Widget Function(RowEntry<T> entry, Widget Function() build) _useLastBuilt<T>(
  List<RowEntry<T>> entries,
) {
  final built = useRef(<Object, Widget>{}).value;
  final ids = {for (final entry in entries) entry.id};
  built.removeWhere((id, _) => !ids.contains(id));
  return (entry, build) => entry.phase == RowPhase.leaving
      ? built[entry.id] ?? const SizedBox.shrink()
      : built[entry.id] = build();
}

class CollectionSequence extends HookWidget {
  const CollectionSequence({
    required this.scope,
    required this.collection,
    required this.items,
    required this.allowReorder,
    required this.entryBuilder,
    this.arrival,
    this.leave,
    super.key,
  });
  final PortablePresentationScope scope;
  final skir.BindingRef collection;
  final List<skir.ListItem> items;
  final bool allowReorder;
  final Widget Function(BuildContext, skir.ListItem, int) entryBuilder;
  final MotionOverride? arrival;
  final MotionOverride? leave;

  @override
  Widget build(BuildContext context) {
    // Data that arrives during a drag waits for the drop, so drag indices
    // stay valid.
    final dragging = useState(false);
    final shown = useRef(items);
    if (!dragging.value) shown.value = items;
    final rows = useAnimatedRows(
      items: shown.value,
      identity: (item) => item.id.value,
      arrival: arrival,
      leave: leave,
    );
    final entries = rows.entries;
    final lastBuilt = _useLastBuilt(entries);

    // A visual index counts only items that stay.
    int activeIndexAt(int visualIndex) => entries
        .take(visualIndex)
        .where((entry) => entry.phase != RowPhase.leaving)
        .length;

    void move(skir.ItemId item, int destination) {
      if (!allowReorder || !scope.canExecuteAction) return;
      final order = rows.items;
      if (destination < 0 || destination >= order.length) return;
      scope.moveCollectionItem(
        collection: collection,
        items: order,
        item: item,
        destination: destination,
      );
    }

    // ReorderableListView promotes the stable entry key to its own global
    // child key, preserving the editor through moves into its drag proxy.
    Widget visual(BuildContext context, int visualIndex) {
      final entry = entries[visualIndex];
      return _SequenceEntry(
        key: ValueKey(entry.id),
        visualIndex: visualIndex,
        leaving: entry.phase == RowPhase.leaving,
        move: (destination) => move(entry.item.id, destination),
        child: RowEntryScope(
          entry: entry,
          // The editor owns its scroll, so rows have no SliverRowAnchor.
          child: entry.motion(
            entry.row(
              // Editor rows hold fields, so a row is no stop: focus lands
              // on its RowLanding control.
              RowStop(
                role: RowRole.holder,
                child: Builder(
                  builder: (context) => lastBuilt(
                    entry,
                    () => entryBuilder(
                      context,
                      entry.item,
                      activeIndexAt(visualIndex),
                    ),
                  ),
                ),
              ),
            ),
            anchors: false,
          ),
        ),
      );
    }

    if (!allowReorder) {
      return RowFocusScope(
        focus: rows.focus,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < entries.length; index++)
              visual(context, index),
          ],
        ),
      );
    }
    return RowFocusScope(
      focus: rows.focus,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: visual,
        proxyDecorator: (child, _, animation) => _collectionDragScopes(
          context,
          AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final lift = motionTimeline(
                context,
                MotionToken.press,
              ).curve.transform(animation.value);
              // The row lifts off the list while it is dragged.
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: context.shapes.mediumBorderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.shadow.withValues(
                        alpha: .24 * lift,
                      ),
                      blurRadius: 16 * lift,
                      offset: Offset(0, 6 * lift),
                    ),
                  ],
                ),
                child: child,
              );
            },
          ),
        ),
        onReorderStart: (_) => dragging.value = true,
        onReorderEnd: (_) => dragging.value = false,
        onReorderItem: (from, to) {
          final entry = entries[from];
          if (entry.phase == RowPhase.leaving) return;
          move(entry.item.id, activeIndexAt(to));
        },
      ),
    );
  }

  /// The reorder handle for the entry being built. Its drag index is the
  /// entry's visual index, which differs from [index] while items leave.
  Widget handle(
    BuildContext context,
    int index,
    PortablePresentationScope itemScope, {
    Widget? icon,
    String? label,
  }) => Builder(
    builder: (context) {
      final entry = _SequenceEntry.of(context);
      return _AuthoredReorderHandle(
        index: entry.visualIndex,
        label: label ?? "Reorder item ${index + 1}",
        icon: icon,
        enabled:
            allowReorder &&
            scope.canExecuteAction &&
            itemScope.canExecuteAction &&
            !entry.leaving,
        canMoveEarlier: index > 0,
        canMoveLater: index + 1 < items.length,
        onMoveEarlier: () {
          if (!itemScope.canExecuteAction) return;
          entry.move(index - 1);
        },
        onMoveLater: () {
          if (!itemScope.canExecuteAction) return;
          entry.move(index + 1);
        },
      );
    },
  );
}

/// The entry's place in the visual list, read by its reorder handle.
class _SequenceEntry extends InheritedWidget {
  const _SequenceEntry({
    required this.visualIndex,
    required this.leaving,
    required this.move,
    required super.child,
    super.key,
  });
  final int visualIndex;
  final bool leaving;
  final void Function(int destination) move;

  static _SequenceEntry of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SequenceEntry>()!;

  @override
  bool updateShouldNotify(_SequenceEntry oldWidget) =>
      oldWidget.visualIndex != visualIndex || oldWidget.leaving != leaving;
}

// Flutter transports themes for a drag proxy, but portable scopes are not
// themes. Forward their existing owners into the root overlay, retaining
// the original ancestor order. Popup overlays keep their normal viewport.
Widget _collectionDragScopes(BuildContext source, Widget child) {
  final wrappers = <Widget Function(Widget)>[];
  source.visitAncestorElements((element) {
    final inherited = element.widget;
    switch (inherited) {
      case RowFocusScope(:final focus):
        wrappers.add((child) => RowFocusScope(focus: focus, child: child));
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
      case PresentationEnvironment(:final host):
        wrappers.add(
          (child) => PresentationEnvironment(host: host, child: child),
        );
      case PortableResourcesInteractionScope(
        :final itemBuilder,
        :final layoutBuilder,
      ):
        wrappers.add(
          (child) => PortableResourcesInteractionScope(
            itemBuilder: itemBuilder,
            layoutBuilder: layoutBuilder,
            child: child,
          ),
        );
      case _CollectionMenuInvocation(:final close):
        wrappers.add(
          (child) => _CollectionMenuInvocation(close: close, child: child),
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

// Keep the same Wrap subtree across widths to preserve both input controllers.
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

extension _CollectionRowParts on PortablePresentationNodeRenderer {
  _SuppliedHeaderControl generatedRemove({
    required PortablePresentationScope scope,
    required skir.EditorAction action,
    required skir.CollectionContent? content,
  }) => _SuppliedHeaderControl(
    command: scope.collectionRemovalCommand(action),
    build: (context) => _operationAppearance(
      content,
      scope,
      // After a remove, focus lands on this control in the next row.
      (states, style) => RowLanding(
        child: Button(
          face: ButtonFace.icon,
          icon: _operationGlyph(
            content?.removeIcon,
            scope,
            const Icon(Icons.delete_outline),
          ),
          label: _operationText(
            scope,
            content?.operationTooltip ?? content?.removeLabel,
            action is skir.EditorAction_localWrapper &&
                    action.value is skir.LocalEditorAction_removeMapRowWrapper
                ? "Remove row"
                : "Remove item",
          ),
          tooltip: _operationText(
            scope,
            content?.operationTooltip ?? content?.removeLabel,
            action is skir.EditorAction_localWrapper &&
                    action.value is skir.LocalEditorAction_removeMapRowWrapper
                ? "Remove row"
                : "Remove item",
          ),
          color: _accentOf(style, null),
          dense: _denseOf(style),
          statesController: states,
          onPressed: scope.canExecuteAction
              ? () => unawaited(scope.executeAction(action))
              : null,
        ),
      ),
      tooltip: false,
    ),
  );

  /// The row's key is the entry id, given by CollectionSequence or _MapRows.
  Widget collectionRow({
    required _CollectionEditorContinuation editor,
    required PortablePresentationScope scope,
    required skir.PresentationNode owner,
    required skir.PresentationHeader Function() generatedHeader,
    required bool initiallyNeedsRepair,
    required List<_SuppliedHeaderControl> controls,
    required skir.EditorAction? permittedRemove,
    required skir.CollectionAppearance? appearance,
    required skir.CollectionContent? content,
  }) => _CollectionEntry(
    editor: editor,
    controls: [
      ...controls,
      if (permittedRemove != null)
        generatedRemove(
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
  );
}

extension _CollectionHeaderParts on PortablePresentationNodeRenderer {
  Widget collectionWithHeader({
    required PortablePresentationScope sourceScope,
    required PortablePresentationScope mutationScope,
    required skir.BindingRef reference,
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
  }) => KeyedSubtree(
    key: ValueKey(sourceScope.authoredAliases.resolve(reference)),
    child: Builder(
      builder: (context) {
        final addControl = _collectionAdd(
          allowAdd: allowAdd,
          mutationScope: mutationScope,
          content: content,
          fallbackLabel: addLabel,
          fallbackIcon: addIcon,
          add: add,
        );
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
        } on PresentationValueFailure catch (failure) {
          return _diagnostic(failure.message);
        } on FormatException catch (failure) {
          return _diagnostic(failure.message);
        }
      },
    ),
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
