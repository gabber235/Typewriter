import "package:typewriter_panel/typewriter_panel.dart";

/// Resolves a presentation binding through the aliases introduced by scoped
/// and virtual presentations.
///
/// Aliases are lexical routing metadata, not additional owners. The returned
/// reference keeps the child path and points at the binding that owns the
/// value, so callers can use it for updates, actions, and interaction gates.
extension BindingReferenceCanonicalization on BindingReference {
  BindingReference canonicalizedWith(Map<BindingId, BindingReference> aliases) {
    final alias = aliases[bindingId];
    return alias == null ? this : alias.at(path);
  }
}

/// Rewrites every binding address carried by a local action to its owner.
///
/// Presentation actions are authored against the current scope. Canonicalizing
/// all variants before execution prevents scoped inputs from mutating a
/// temporary binding or routing structural mutations to the wrong root. The
/// action and its expressions remain otherwise unchanged.
extension LocalEditorActionCanonicalization on LocalEditorAction {
  LocalEditorAction canonicalizedWith(
    Map<BindingId, BindingReference> aliases,
  ) {
    final local = action;
    return LocalEditorAction(switch (local) {
      SetValueAction() => SetValueAction(
        target: local.target.canonicalizedWith(aliases),
        value: local.value,
      ),
      InsertListItemAction() => InsertListItemAction(
        target: local.target.canonicalizedWith(aliases),
        index: local.index,
        value: local.value,
      ),
      RemoveListItemAction() => RemoveListItemAction(
        target: local.target.canonicalizedWith(aliases),
        index: local.index,
      ),
      AppendListItemAction() => AppendListItemAction(
        target: local.target.canonicalizedWith(aliases),
        value: local.value,
      ),
      DuplicateListItemAction() => DuplicateListItemAction(
        source: local.source.canonicalizedWith(aliases),
      ),
      ReorderListItemAction() => ReorderListItemAction(
        source: local.source.canonicalizedWith(aliases),
        newIndex: local.newIndex,
      ),
      PutMapEntryAction() => PutMapEntryAction(
        target: local.target.canonicalizedWith(aliases),
        key: local.key,
        value: local.value,
      ),
      RemoveMapEntryAction() => RemoveMapEntryAction(
        target: local.target.canonicalizedWith(aliases),
        key: local.key,
      ),
      ReplaceConcreteTypeAction() => ReplaceConcreteTypeAction(
        target: local.target.canonicalizedWith(aliases),
        concreteType: local.concreteType,
      ),
    });
  }
}
