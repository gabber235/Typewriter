part of "../../simple_input_renderer.dart";

extension ReferenceInputElementRendering on ReferenceInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    return BoundControlShell(
      nominal: true,
      control: control,
      scope: scope,
      shapeMismatch: (binding) =>
          _ReferenceBindingShape.parse(binding.type) == null
          ? "Reference input requires a reference, optional reference, or reference list binding"
          : null,
      builder: (context, field) {
        final shape = _ReferenceBindingShape.parse(field.binding.type)!;
        final sourceBuilder = scope.referenceSearchSourceBuilder;
        if (sourceBuilder == null) {
          return presentationDiagnostic(context, const [
            TypeDiagnostic(
              code: TypeDiagnosticCode.invalidPresentation,
              message: "Reference search is unavailable",
            ),
          ]);
        }
        final search = PresentationSearchInput(
          element: _referenceSearchElement(control, multiple: shape.multiple),
          binding: field.binding,
          scope: scope,
          maximumExtent: 320,
          sourceBuilder: (ref, selections) => sourceBuilder(
            target: shape.target,
            origins: scope.referenceOrigins,
            registry: scope.registry,
          ),
          mapSelection: shape.wrapSelection,
          selectionMatcher: shape.matches,
          candidateEvaluator: (result) {
            final payload = result.payload;
            if (payload is! PresentationSearchResultPayload ||
                payload.selectedValue is! ReferenceValue) {
              return const SearchActivationState.hidden();
            }
            return _candidateActivation(
              _evaluateReferenceCandidate(
                scope: scope,
                binding: field.binding,
                shape: shape,
                policyId: candidatePolicy,
                candidate: ReferenceCandidate(
                  id: (payload.selectedValue as ReferenceValue).id,
                ),
              ),
            );
          },
          hideRejectedCandidates:
              rejectionDisplay == ReferenceRejectionDisplay.hidden,
          summaryBuilder: (context, current) => _ReferenceSummary(
            target: shape.target,
            ids: shape.ids(current),
            resolver: scope.resolveReferences,
            registry: scope.registry,
            onRemoveAt: shape.multiple && field.editable
                ? (index) {
                    final current = field.value;
                    if (current is! ListValue) return;
                    final values = [...current.values]..removeAt(index);
                    field.update(ListValue(values));
                  }
                : null,
            onReorder: shape.multiple && allowReorder && field.editable
                ? (oldIndex, newIndex) {
                    final current = field.value;
                    if (current is! ListValue) return;
                    final values = [...current.values];
                    values.insert(newIndex, values.removeAt(oldIndex));
                    field.update(ListValue(values));
                  }
                : null,
            onClear: shape.optional && field.editable
                ? () => field.update(shape.emptyValue!)
                : null,
          ),
        );
        return DragTarget<Object>(
          onWillAcceptWithDetails: (details) =>
              field.editable &&
              details.data is ReferenceResourceDragData &&
              shape.accepts(
                details.data as ReferenceResourceDragData,
                scope.registry,
              ) &&
              _evaluateReferenceCandidate(
                scope: scope,
                binding: field.binding,
                shape: shape,
                policyId: candidatePolicy,
                candidate: ReferenceCandidate(
                  id: (details.data as ReferenceResourceDragData).referenceId,
                  types: (details.data as ReferenceResourceDragData)
                      .referenceTypes,
                ),
              ) is ReferenceCandidateAllowed,
          onAcceptWithDetails: (details) {
            final data = details.data as ReferenceResourceDragData;
            final decision = _evaluateReferenceCandidate(
              scope: scope,
              binding: field.binding,
              shape: shape,
              policyId: candidatePolicy,
              candidate: ReferenceCandidate(
                id: data.referenceId,
                types: data.referenceTypes,
              ),
            );
            if (decision is! ReferenceCandidateAllowed) return;
            final next = shape.drop(
              field.value,
              ReferenceValue(data.referenceId),
            );
            field.update(next);
          },
          builder: (context, accepted, rejected) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: context.shapes.mediumBorderRadius,
              border: accepted.isEmpty && rejected.isEmpty
                  ? null
                  : Border.all(
                      color: accepted.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                      width: 2,
                    ),
            ),
            child: search,
          ),
        );
      },
    );
  }
}

ReferenceCandidateDecision _evaluateReferenceCandidate({
  required PresentationRenderScope scope,
  required InspectedBinding binding,
  required _ReferenceBindingShape shape,
  required ReferencePolicyId? policyId,
  required ReferenceCandidate candidate,
}) {
  final current = shape.ids(binding.value.valueOrNull).toSet();
  final selected = current.contains(candidate.id);
  final transition = selected && (shape.multiple || shape.optional)
      ? ReferenceSelectionTransition.remove
      : current.isEmpty
      ? ReferenceSelectionTransition.add
      : ReferenceSelectionTransition.replace;
  final reference = scope.canonical(binding.reference);
  return scope.referencePolicies.evaluate(
    policyId,
    ReferenceCandidatePolicyContext(
      owner: scope.editOwnerFor?.call(reference),
      path: reference.path,
      transition: transition,
      currentSelection: current,
      candidate: candidate,
    ),
  );
}

SearchActivationState _candidateActivation(
  ReferenceCandidateDecision decision,
) => switch (decision) {
  ReferenceCandidateAllowed() => const SearchActivationState.enabled(),
  ReferenceCandidateRejected(:final issue) ||
  ReferenceCandidateUnavailable(
    :final issue,
  ) => SearchActivationState.disabled(issue.message),
};

SearchInputElement _referenceSearchElement(
  BoundControl control, {
  required bool multiple,
}) => SearchInputElement(
  control: control,
  selectionMode: multiple
      ? SearchSelectionMode.multiple
      : SearchSelectionMode.single,
  queryBindingId: const BindingId(2147483600),
  summaryBindingId: const BindingId(2147483601),
  maximumExtent: 320.asFloatLiteral,
  placeholder: "Search references".asStringLiteral,
  provider: SearchProvider.staticValues(
    values: const ListValue([]).asLiteral(const ListType(element: AnyType())),
    result: SearchResultMapping(
      bindingId: const BindingId(2147483602),
      key: "".asStringLiteral,
      selectedValue: "".asStringLiteral,
      presentation: PresentationNode(
        id: "reference.unused",
        element: TextElement("".asStringLiteral),
      ),
    ),
  ),
);

final class _ReferenceBindingShape {
  const _ReferenceBindingShape({
    required this.target,
    required this.multiple,
    required this.optional,
    required this.wrapSelection,
    required this.matches,
    required this.ids,
    this.emptyValue,
  });

  final ResolvedTypeRef target;
  final bool multiple;
  final bool optional;
  final DataValue Function(DataValue) wrapSelection;
  final bool Function(EditorValue, DataValue) matches;
  final List<RecordId> Function(DataValue?) ids;
  final DataValue? emptyValue;

  bool accepts(ReferenceResourceDragData data, TypeRegistry registry) {
    return data.isAcceptedBy(target, registry);
  }

  DataValue drop(DataValue? current, ReferenceValue selected) {
    if (multiple) {
      final values = current is ListValue ? [...current.values] : <DataValue>[];
      final index = values.indexOf(selected);
      if (index < 0) {
        values.add(selected);
      } else {
        values.removeAt(index);
      }
      return ListValue(values);
    }
    return wrapSelection(selected);
  }

  static _ReferenceBindingShape? parse(TypeExpression type) {
    if (type case ReferenceType(:final target)) {
      return _ReferenceBindingShape(
        target: target,
        multiple: false,
        optional: false,
        wrapSelection: (value) => value,
        matches: (current, selected) => current.valueOrNull == selected,
        ids: (value) => value is ReferenceValue ? [value.id] : const [],
      );
    }
    if (type case ListType(element: ReferenceType(:final target))) {
      return _ReferenceBindingShape(
        target: target,
        multiple: true,
        optional: false,
        wrapSelection: (value) => value,
        matches: (current, selected) => switch (current.valueOrNull) {
          ListValue(:final values) => values.contains(selected),
          _ => false,
        },
        ids: (value) => switch (value) {
          ListValue(:final values) =>
            values
                .whereType<ReferenceValue>()
                .map((item) => item.id)
                .toList(growable: false),
          _ => const [],
        },
      );
    }
    if (type case NamedType(:final reference)) {
      final argument = reference.arguments.singleOrNull;
      if (reference.id != const TypeId.option() || argument is! ReferenceType) {
        return null;
      }
      final target = argument.target;
      final inner = ReferenceType(target: target);
      final empty = PolymorphicValue(
        concreteType: standardTypeRefs.noneOf(inner),
        value: const UnitValue(),
      );
      ReferenceValue? selected(DataValue? value) => switch (value) {
        PolymorphicValue(
          concreteType: final concrete,
          value: RecordValue(fields: final fields),
        )
            when concrete.id == const TypeId.some() =>
          fields["value"] as ReferenceValue?,
        _ => null,
      };
      return _ReferenceBindingShape(
        target: target,
        multiple: false,
        optional: true,
        emptyValue: empty,
        wrapSelection: (value) => PolymorphicValue(
          concreteType: standardTypeRefs.someOf(inner),
          value: RecordValue({"value": value}),
        ),
        matches: (current, value) => selected(current.valueOrNull) == value,
        ids: (value) {
          final reference = selected(value);
          return reference == null ? const [] : [reference.id];
        },
      );
    }
    return null;
  }
}

class _ReferenceSummary extends HookWidget {
  const _ReferenceSummary({
    required this.target,
    required this.ids,
    required this.resolver,
    required this.registry,
    required this.onRemoveAt,
    required this.onReorder,
    required this.onClear,
  });

  final ResolvedTypeRef target;
  final List<RecordId> ids;
  final ReferenceResourceResolver? resolver;
  final TypeRegistry registry;
  final ValueChanged<int>? onRemoveAt;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final request = useMemoized(
      () => resolver?.call(target: target, ids: ids, registry: registry),
      [resolver, target, Object.hashAll(ids), registry],
    );
    final snapshot = useFuture(request);
    final resources = snapshot.data;
    final content = ids.isEmpty
        ? Text(
            "No reference",
            style: TextStyle(color: context.colors.contentSecondary),
          )
        : resources == null
        ? Text(
            ids.length == 1 ? ids.single.toSurrealQl() : "${ids.length} items",
          )
        : onReorder != null
        ? ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resources.length,
            onReorderItem: onReorder,
            itemBuilder: (context, index) {
              final resource = resources[index];
              return ListTile(
                key: ValueKey(resource.id),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: resource.exists
                    ? null
                    : Icon(
                        Icons.link_off_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                title: Text(
                  resource.exists
                      ? resource.title ?? resource.id.toSurrealQl()
                      : "Missing: ${resource.id.toSurrealQl()}",
                ),
                trailing: IconButton(
                  tooltip: "Remove reference",
                  onPressed: () => onRemoveAt?.call(index),
                  icon: const Icon(Icons.close_rounded),
                ),
              );
            },
          )
        : Wrap(
            spacing: context.spacing.space2,
            runSpacing: context.spacing.space2,
            children: [
              for (final resource in resources)
                Chip(
                  avatar: resource.exists
                      ? null
                      : Icon(
                          Icons.link_off_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  label: Text(
                    resource.exists
                        ? resource.title ?? resource.id.toSurrealQl()
                        : "Missing: ${resource.id.toSurrealQl()}",
                  ),
                  onDeleted: onRemoveAt == null
                      ? null
                      : () => onRemoveAt!(resources.indexOf(resource)),
                ),
            ],
          );
    return Row(
      children: [
        Expanded(child: content),
        if (onClear != null && ids.isNotEmpty)
          IconButton(
            tooltip: "Clear reference",
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}
