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
      onDismiss: controller.menuController.close,
      child: MenuAnchor(
        controller: controller.menuController,
        style: controller.effectiveMenuStyle,
        menuChildren: controller.filteredEntries.indexed
            .map(
              (entry) => _buildMenuItem(
                context,
                entry.$2,
                controller.effectiveMenuStyle,
                isFakeFocused: controller.fakeFocusIndex.value == entry.$1,
              ),
            )
            .toList(growable: false),
        childFocusNode: controller.focusNode,
        onClose: controller.surroundingFocusNode.requestFocus,
        crossAxisUnconstrained: false,
        child: Actions(
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
                    controller.menuController.isOpen
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(height: 1.7),
              maxLines: null,
              onEditingComplete: controller.enter,
              onChanged: (_) => controller.menuController.open(),
              onTap: dropdown.enabled ? controller.menuController.open : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    DropdownMenuEntry<T> entry,
    MenuStyle effectiveMenuStyle, {
    bool isFakeFocused = false,
  }) {
    final menuPadding = effectiveMenuStyle.padding!.resolve({})!.horizontal;
    final width =
        effectiveMenuStyle.minimumSize!.resolve({})!.width - menuPadding;
    final themeStyle = MenuButtonTheme.of(context).style;
    final foreground =
        entry.style?.foregroundColor ?? themeStyle?.foregroundColor;
    final icon = entry.style?.iconColor ?? themeStyle?.iconColor;
    final overlay = entry.style?.overlayColor ?? themeStyle?.overlayColor;
    final background =
        entry.style?.backgroundColor ?? themeStyle?.backgroundColor;
    var style = entry.style ?? MenuItemButton.styleFrom();

    // Simulate focus because traversal keeps focus on the text field.
    if (entry.enabled && isFakeFocused) {
      final defaultStyle = const MenuItemButton().defaultStyleOf(context);
      Color? focused(WidgetStateProperty<Color?>? property) =>
          property?.resolve(<WidgetState>{WidgetState.focused});
      final focusedForeground = focused(
        foreground ?? defaultStyle.foregroundColor!,
      )!;
      final focusedIcon = focused(icon ?? defaultStyle.iconColor!)!;
      final focusedOverlay = focused(overlay ?? defaultStyle.overlayColor!)!;
      // The default background is transparent, so use the focused surface.
      final focusedBackground =
          focused(background) ??
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
      style = style.copyWith(
        backgroundColor: WidgetStatePropertyAll<Color>(focusedBackground),
        foregroundColor: WidgetStatePropertyAll<Color>(focusedForeground),
        iconColor: WidgetStatePropertyAll<Color>(focusedIcon),
        overlayColor: WidgetStatePropertyAll<Color>(focusedOverlay),
      );
    } else {
      style = style.copyWith(
        backgroundColor: background,
        foregroundColor: foreground,
        iconColor: icon,
        overlayColor: overlay,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width),
      child: MenuItemButton(
        style: style,
        leadingIcon: entry.leadingIcon,
        trailingIcon: entry.trailingIcon,
        closeOnActivate: false,
        onPressed: entry.enabled ? () => controller.toggle(entry.value) : null,
        requestFocusOnHover: false,
        child: entry.labelWidget ?? Text(entry.label),
      ),
    );
  }
}
