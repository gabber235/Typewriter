import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "header_combination.freezed.dart";

@freezed
abstract class ResolvedHeaderChain with _$ResolvedHeaderChain {
  const factory ResolvedHeaderChain({
    required PresentationHeader? header,
    required Set<(String, BindingReference?)> suppressed,
  }) = _ResolvedHeaderChain;
}

extension PresentationNodeHeaderCombination on PresentationNode {
  ResolvedHeaderChain resolveHeaderChain(PresentationRenderScope scope) {
    final own = _ownHeader(scope);
    if (own == null) {
      return const ResolvedHeaderChain(header: null, suppressed: {});
    }
    final anchor = own.binding == null ? null : scope.canonical(own.binding!);
    if (anchor == null) {
      return ResolvedHeaderChain(header: own, suppressed: const {});
    }
    return _collect(scope, own, anchor, const {});
  }

  ResolvedHeaderChain _collect(
    PresentationRenderScope scope,
    PresentationHeader outer,
    BindingReference anchor,
    Set<(String, BindingReference?)> suppressed,
  ) {
    final child = element._transparentChild(scope);
    if (child == null) {
      return ResolvedHeaderChain(header: outer, suppressed: suppressed);
    }
    final inner = child.$1._ownHeader(child.$2);
    if (inner == null) {
      return child.$1._collect(child.$2, outer, anchor, suppressed);
    }
    final binding = inner.binding == null
        ? null
        : child.$2.canonical(inner.binding!);
    if (binding != anchor) {
      return ResolvedHeaderChain(header: outer, suppressed: suppressed);
    }
    final nextSuppressed = {...suppressed, (child.$1.id, binding)};
    return child.$1._collect(
      child.$2,
      outer.mergeInner(inner),
      anchor,
      nextSuppressed,
    );
  }

  PresentationHeader? _ownHeader(PresentationRenderScope scope) {
    final contribution = element.contributeHeader(
      scope.expressions,
      registry: scope.registry,
    );
    return switch ((header, contribution)) {
      (final PresentationHeader outer, final PresentationHeader inner) =>
        outer.mergeInner(inner),
      (final PresentationHeader header, null) ||
      (null, final PresentationHeader header) => header,
      _ => null,
    };
  }
}

extension on PresentationElement {
  (PresentationNode, PresentationRenderScope)? _transparentChild(
    PresentationRenderScope scope,
  ) => switch (this) {
    TypedFieldElement(:final presentation?) => (presentation, scope),
    final ScopedBindingElement element => element._scopedChild(scope),
    final ConditionalElement element => element._selectedChild(scope),
    final DefaultPresentationElement element => element._delegatedChild(scope),
    SectionElement(:final child) => (child, scope),
    _ => null,
  };
}

extension on ScopedBindingElement {
  (PresentationNode, PresentationRenderScope)? _scopedChild(
    PresentationRenderScope scope,
  ) {
    final resolved = scope.resolve(binding).valueOrNull;
    if (resolved == null) return null;
    return (
      child,
      scope.withAlias(
        scopeBindingId,
        scope.canonical(binding),
        BindingSnapshot(
          type: resolved.type,
          value: resolved.value,
          revision: resolved.revision,
          writable: resolved.writable,
        ),
      ),
    );
  }
}

extension on ConditionalElement {
  (PresentationNode, PresentationRenderScope)? _selectedChild(
    PresentationRenderScope scope,
  ) {
    final value = scope.evaluate(condition).valueOrNull;
    if (value is! BooleanValue) return null;
    final selected = value.value ? whenTrue : whenFalse;
    return selected == null ? null : (selected, scope);
  }
}

extension on DefaultPresentationElement {
  (PresentationNode, PresentationRenderScope)? _delegatedChild(
    PresentationRenderScope scope,
  ) {
    final resolved = scope.resolve(binding).valueOrNull;
    if (resolved == null) return null;
    final selected = scope.resolvePresentation(resolved.type, presentationId);
    final child =
        selected?.root ??
        resolved.type.generateDefaultPresentation(
          binding: binding,
          nodeId: "default.${binding.bindingId.value}",
        );
    if (selected != null && scope.activePresentations.contains(selected.id)) {
      return null;
    }
    final childScope = scope.withAlias(
      const BindingId(0),
      scope.canonical(binding),
      BindingSnapshot(
        type: resolved.type,
        value: resolved.value,
        revision: resolved.revision,
        writable: resolved.writable,
      ),
    );
    return (
      child,
      selected == null
          ? childScope
          : childScope.copyWith(
              activePresentations: {...scope.activePresentations, selected.id},
            ),
    );
  }
}
