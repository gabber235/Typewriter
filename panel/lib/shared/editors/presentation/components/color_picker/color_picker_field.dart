import "package:typewriter_panel/typewriter_panel.dart";

/// Edits one color value in the shared editor surface.
///
/// The bound editor owns the color and receives every valid change through
/// [onChanged]. This field owns only picker visibility and interaction
/// boundaries. Opening begins an interaction, ordinary dismissal commits it,
/// and every dismissal preserves the current value. The mixed constructor
/// keeps differing bound values distinct until the caller
/// chooses a replacement color. Supply [onCleared] to allow empty text to
/// remove the value.
class ColorPickerField extends HookConsumerWidget {
  const ColorPickerField({
    required this.color,
    required this.includeAlpha,
    required this.onChanged,
    this.onCleared,
    this.onInteractionStart,
    this.onInteractionCommit,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  }) : mixed = false;

  const ColorPickerField.mixed({
    required this.includeAlpha,
    required this.onChanged,
    this.onCleared,
    this.onInteractionStart,
    this.onInteractionCommit,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  }) : color = null,
       mixed = true;

  final Color? color;

  /// Whether selected owners disagree, independently of an empty color.
  final bool mixed;
  final bool includeAlpha;
  final ValueChanged<Color> onChanged;
  final VoidCallback? onCleared;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionCommit;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = useState(false);
    final pickerFocus = useFocusNode(debugLabel: "Open color picker");
    final openingColor = useRef(color?.argbValue);
    final tapGroup = useMemoized(Object.new);
    final library = ref.watch(colorLibraryProvider);
    final currentColor = color;
    final pickerColor = currentColor ?? Theme.of(context).colorScheme.primary;

    void close() {
      if (!open.value) return;
      open.value = false;
      onInteractionCommit?.call();
      if (currentColor != null &&
          openingColor.value != currentColor.argbValue) {
        ref
            .read(colorLibraryProvider.notifier)
            .recordRecent(currentColor.argbValue);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pickerFocus.canRequestFocus) pickerFocus.requestFocus();
      });
    }

    void toggle() {
      if (open.value) {
        close();
        return;
      }
      openingColor.value = currentColor?.argbValue;
      onInteractionStart?.call();
      open.value = true;
    }

    final editable = enabled && !readOnly;

    Future<void> copyColor() {
      if (currentColor == null) return Future.value();
      return Clipboard.setData(
        ClipboardData(text: currentColor.formatHex(includeAlpha: includeAlpha)),
      );
    }

    void toggleFavorite() {
      if (currentColor == null) return;
      ref
          .read(colorLibraryProvider.notifier)
          .toggleFavorite(currentColor.argbValue);
    }

    final isFavorite =
        currentColor != null &&
        library.favorites.contains(currentColor.argbValue);
    return TapRegion(
      groupId: tapGroup,
      onTapOutside: (_) => close(),
      child: AnchoredOverlayPortal(
        visible: open.value,
        config: const AnchoredOverlayConfig(
          preferredSide: AnchoredOverlaySide.bottom,
          spacing: 6,
          sharedAxisConstraintMode: SharedAxisConstraintMode.none,
          maxWidth: 340,
          maxHeight: 620,
        ),
        overlayBuilder: (context, anchorSize) => TapRegion(
          groupId: tapGroup,
          child: Actions(
            actions: {
              DismissIntent: CallbackAction(onInvoke: (_) => close()),
              CancelIntent: CallbackAction(onInvoke: (_) => close()),
            },
            child: SizedBox(
              width: 340,
              child: ColorPickerSurface(
                color: pickerColor,
                includeAlpha: includeAlpha,
                enabled: editable,
                warnsAboutAlpha: !includeAlpha && pickerColor.alphaByte != 0xFF,
                replacing: mixed,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        child: ValidatedTextField<Color>(
          value: currentColor,
          mixed: mixed,
          name: includeAlpha ? "ARGB color" : "RGB color",
          readOnly: !editable,
          deserialize: (value) => value.formatHex(includeAlpha: includeAlpha),
          serialize: (value) =>
              parseColorHex(value, includeAlpha: includeAlpha),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[0-9A-Fa-fxX#]")),
            LengthLimitingTextInputFormatter(includeAlpha ? 10 : 8),
          ],
          onChanged: onChanged,
          onCleared: onCleared,
          onInputFocus: onInteractionStart,
          onInputBlur: onInteractionCommit,
          onDone: (value) {
            if (value.argbValue != currentColor?.argbValue) {
              ref
                  .read(colorLibraryProvider.notifier)
                  .recordRecent(value.argbValue);
            }
          },
          surroundingActions: [
            if (enabled && currentColor != null)
              ActionShortcut(
                id: "color_copy",
                label: "Copy Color",
                description: "Copy the current color",
                activators: [
                  AdaptiveSingleActivator(
                    LogicalKeyboardKey.keyC,
                    control: true,
                  ),
                ],
                priority: 1000,
                onInvoke: (_) => copyColor(),
              ),
            if (editable && currentColor != null)
              ActionShortcut(
                id: "color_toggle_favorite",
                label: isFavorite ? "Remove Favorite" : "Add Favorite",
                description: isFavorite
                    ? "Remove the current color from favorites"
                    : "Add the current color to favorites",
                activators: [AdaptiveSingleActivator(LogicalKeyboardKey.keyF)],
                priority: 1001,
                onInvoke: (_) => toggleFavorite(),
              ),
            if (enabled)
              ActionShortcut(
                id: "color_toggle_picker",
                label: open.value ? "Close Picker" : "Open Picker",
                description: open.value
                    ? "Close the color picker"
                    : "Open the color picker",
                activators: [AdaptiveSingleActivator(LogicalKeyboardKey.keyP)],
                priority: 1002,
                onInvoke: (_) => toggle(),
              ),
          ],
          decoration: InputDecoration(
            hintText: mixed ? "Multiple colors" : null,
            helperText: !mixed && currentColor == null
                ? "This value is Unfilled"
                : null,
            prefixIcon: GestureDetector(
              onTap: enabled ? toggle : null,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: mixed
                    ? const MixedColorSwatch()
                    : currentColor == null
                    ? const Icon(Icons.palette_outlined, size: 24)
                    : Checkerboard(
                        borderRadius: context.shapes.smallBorderRadius,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: currentColor,
                            borderRadius: context.shapes.smallBorderRadius,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Copy color",
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: enabled ? copyColor : null,
                  icon: const Icones(
                    MaterialSymbols.content_copy_rounded,
                    size: 18,
                  ),
                ),
                IconButton(
                  tooltip: isFavorite
                      ? "Remove from favorites"
                      : "Add to favorites",
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: editable ? toggleFavorite : null,
                  icon: Icones(
                    isFavorite
                        ? MaterialSymbols.star_rounded
                        : MaterialSymbols.star_outline_rounded,
                    size: 18,
                  ),
                ),
                IconButton(
                  focusNode: pickerFocus,
                  tooltip: open.value
                      ? "Close color picker"
                      : "Open color picker",
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: enabled ? toggle : null,
                  icon: const Icones(MaterialSymbols.palette, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
