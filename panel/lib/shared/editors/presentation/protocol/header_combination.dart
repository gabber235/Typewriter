import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "header_combination.freezed.dart";

/// The effective header and the nested headers it replaces during rendering.
///
/// [header] is the merged outer header. [suppressed] contains the node and
/// canonical binding pairs that [PresentationNodeRenderer] must not render a
/// second time. A missing header means the chain had no usable header at its
/// starting node.
@freezed
abstract class ResolvedHeaderChain with _$ResolvedHeaderChain {
  const factory ResolvedHeaderChain({
    required PresentationHeader? header,
    required Set<(String, BindingReference?)> suppressed,
    @Default(false) bool showDirectDiagnostics,
  }) = _ResolvedHeaderChain;
}

/// Resolves header chrome across presentation wrappers that are transparent
/// to the rendered value.
///
/// The outer header supplies the anchor binding. Traversal continues through
/// typed fields, aliases, conditionals, delegated defaults, invocations, and
/// sections only while the next header resolves to that same canonical
/// binding. Matching inner headers merge into the outer header and are returned
/// as suppressed locations. A different binding or an unresolvable branch
/// ends composition, so the node renderer can keep the boundary visible.
extension PresentationNodeHeaderCombination on PresentationNode {
  ResolvedHeaderChain resolveHeaderChain(PresentationRenderScope scope) {
    final own = _ownHeader(scope);
    if (own == null) {
      final child = element._transparentChild(scope);
      if (child == null) {
        return const ResolvedHeaderChain(header: null, suppressed: {});
      }
      final inner = child.$1.resolveHeaderChain(child.$2);
      final header = inner.header;
      if (header == null) return inner;
      final binding = header.binding == null
          ? null
          : child.$2.canonical(header.binding!);
      return ResolvedHeaderChain(
        header: header,
        suppressed: {...inner.suppressed, (child.$1.id, binding)},
        showDirectDiagnostics: inner.showDirectDiagnostics,
      );
    }
    final anchor = own.binding == null ? null : scope.canonical(own.binding!);
    if (anchor == null) {
      return ResolvedHeaderChain(
        header: own,
        suppressed: const {},
        showDirectDiagnostics: element.ownsDirectHeaderDiagnostics,
      );
    }
    return _collect(
      scope,
      own,
      anchor,
      const {},
      showDirectDiagnostics: element.ownsDirectHeaderDiagnostics,
    );
  }

  ResolvedHeaderChain _collect(
    PresentationRenderScope scope,
    PresentationHeader outer,
    BindingReference anchor,
    Set<(String, BindingReference?)> suppressed, {
    required bool showDirectDiagnostics,
  }) {
    final child = element._transparentChild(scope);
    if (child == null) {
      return ResolvedHeaderChain(
        header: outer,
        suppressed: suppressed,
        showDirectDiagnostics: showDirectDiagnostics,
      );
    }
    final inner = child.$1._ownHeader(child.$2);
    if (inner == null) {
      return child.$1._collect(
        child.$2,
        outer,
        anchor,
        suppressed,
        showDirectDiagnostics: showDirectDiagnostics,
      );
    }
    final binding = inner.binding == null
        ? null
        : child.$2.canonical(inner.binding!);
    if (binding != anchor) {
      return ResolvedHeaderChain(
        header: outer,
        suppressed: suppressed,
        showDirectDiagnostics: showDirectDiagnostics,
      );
    }

    final nextSuppressed = {...suppressed, (child.$1.id, binding)};
    return child.$1._collect(
      child.$2,
      outer.mergeInner(inner),
      anchor,
      nextSuppressed,
      showDirectDiagnostics: showDirectDiagnostics,
    );
  }

  PresentationHeader? _ownHeader(PresentationRenderScope scope) {
    final contribution = element.contributeHeader(scope);
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
  bool get ownsDirectHeaderDiagnostics =>
      this is ListInputElement ||
      this is MapInputElement ||
      this is RecordInputElement;
}

extension on PresentationElement {
  (PresentationNode, PresentationRenderScope)? _transparentChild(
    PresentationRenderScope scope,
  ) => switch (this) {
    TypedFieldElement(:final presentation?) => (presentation, scope),
    final ScopedBindingElement element => element._scopedChild(scope),
    final ConditionalElement element => element._selectedChild(scope),
    final DefaultPresentationElement element => element._delegatedChild(scope),
    final PresentationInvocationElement element => element._invokedChild(scope),
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
        binding,
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

    if (selected == null) return (child, scope);

    final input = selected.primaryInput;

    if (input == null) return null;
    return scope.bindPresentation(selected, {input: binding}).valueOrNull;
  }
}

extension on PresentationInvocationElement {
  (PresentationNode, PresentationRenderScope)? _invokedChild(
    PresentationRenderScope scope,
  ) {
    final definition = scope.resolvePresentation(null, presentationId);
    if (definition == null ||
        scope.activePresentations.contains(presentationId)) {
      return null;
    }
    return scope.bindPresentation(definition, arguments).valueOrNull;
  }
}
