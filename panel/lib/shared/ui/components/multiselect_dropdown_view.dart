part of "multiselect_dropdown.dart";

class _MultiselectDropdownView<T extends Object> extends StatelessWidget {
  const _MultiselectDropdownView({
    required this.dropdown,
    required this.controller,
  });

  final MultiselectDropdown<T> dropdown;
  final _MultiselectDropdownController<T> controller;

  @override
  Widget build(BuildContext context) {
    return InputFieldContainer(
      controller: controller.inputFieldController,
      actions: dropdown.actions,
      inputActions: dropdown.menuActions,
      surroundingActions: dropdown.surroundingActions,
      onInputFocus: controller.openAfterFocus,
      onDismiss: controller.popupController.close,
      child: AnchoredPopup(
        controller: controller.popupController,
        // Focus stays in the field while it filters; it opens the choices.
        opensOnHover: false,
        minWidth: controller.fieldWidth,
        maxWidth: controller.fieldWidth,
        popupBuilder: (context, close) => TapRegion(
          groupId: controller.tapGroup,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, entry) in controller.filteredEntries.indexed)
                  PanelMenuItem(
                    label: entry.label,
                    leading: entry.leading,
                    trailing: entry.trailing,
                    enabled: entry.enabled,
                    highlighted: controller.fakeFocusIndex.value == index,
                    onPressed: () => controller.toggle(entry.value),
                    child: entry.content,
                  ),
              ],
            ),
          ),
        ),
        builder: (context, show) => Actions(
          actions: {
            _NextIntent: CallbackAction<_NextIntent>(
              onInvoke: (_) => controller.next(),
            ),
            _PreviousIntent: CallbackAction<_PreviousIntent>(
              onInvoke: (_) => controller.previous(),
            ),
            _EnterIntent: CallbackAction<_EnterIntent>(
              onInvoke: (_) {
                controller.enter();
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: {
              for (final shortcut in shortcutsFor(PreviousFocusIntent))
                shortcut: _PreviousIntent(),
              for (final shortcut in shortcutsFor(NextFocusIntent))
                shortcut: _NextIntent(),
              for (final shortcut in shortcutsForIntent<DirectionalFocusIntent>(
                (intent) => intent.direction == TraversalDirection.up,
              ))
                shortcut: _PreviousIntent(),
              for (final shortcut in shortcutsForIntent<DirectionalFocusIntent>(
                (intent) => intent.direction == TraversalDirection.down,
              ))
                shortcut: _NextIntent(),
              SingleActivator(LogicalKeyboardKey.enter): _EnterIntent(),
              SingleActivator(
                LogicalKeyboardKey.arrowLeft,
              ): ExtendSelectionByCharacterIntent(
                forward: false,
                collapseSelection: true,
              ),
              SingleActivator(
                LogicalKeyboardKey.arrowRight,
              ): ExtendSelectionByCharacterIntent(
                forward: true,
                collapseSelection: true,
              ),
            },
            child: TextField(
              key: controller.anchorKey,
              groupId: controller.tapGroup,
              focusNode: controller.focusNode,
              controller: controller.textController,
              enabled: dropdown.enabled,
              // Prevent selecting all text when focus is reparented on rebuild.
              selectAllOnFocus: false,
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
              ],
              decoration: InputDecoration(
                hintText: dropdown.placeholder,
                suffixIcon: Padding(
                  padding: controller.isCollapsed
                      ? EdgeInsets.zero
                      : EdgeInsets.all(context.spacing.space1),
                  child: Icon(
                    controller.popupController.isOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                ),
                isCollapsed: false,
                isDense: false,
                visualDensity: VisualDensity.comfortable,
                contentPadding: EdgeInsets.all(context.spacing.space3),
              ),
              keyboardType: TextInputType.text,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(height: 1.7),
              maxLines: null,
              onEditingComplete: controller.enter,
              onChanged: (_) => controller.open(),
              onTap: dropdown.enabled ? controller.open : null,
            ),
          ),
        ),
      ),
    );
  }
}
