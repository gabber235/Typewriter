import "package:typewriter_panel/typewriter_panel.dart";

extension BindingReferenceCanonicalization on BindingReference {
  BindingReference canonicalizedWith(Map<BindingId, BindingReference> aliases) {
    final alias = aliases[bindingId];
    return alias == null ? this : alias.at(path);
  }
}

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
        initialValue: local.initialValue,
      ),
    });
  }
}
