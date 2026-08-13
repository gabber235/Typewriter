import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ColorPickerField extends HookConsumerWidget {
  const ColorPickerField({
    required this.color,
    required this.includeAlpha,
    required this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    super.key,
  });

  final Color color;
  final bool includeAlpha;
  final ValueChanged<Color> onChanged;
  final bool enabled;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = useState(false);
    final pickerFocus = useFocusNode(debugLabel: "Open color picker");
    final openingColor = useRef(color.argbValue);
    final tapGroup = useMemoized(Object.new);
    final library = ref.watch(colorLibraryProvider);

    void close() {
      if (!open.value) return;
      open.value = false;
      if (openingColor.value != color.argbValue) {
        ref.read(colorLibraryProvider.notifier).recordRecent(color.argbValue);
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
      openingColor.value = color.argbValue;
      open.value = true;
    }

    final editable = enabled && !readOnly;

    Future<void> copyColor() => Clipboard.setData(
      ClipboardData(text: color.formatHex(includeAlpha: includeAlpha)),
    );

    void toggleFavorite() =>
        ref.read(colorLibraryProvider.notifier).toggleFavorite(color.argbValue);

    final isFavorite = library.favorites.contains(color.argbValue);
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
          child: CallbackShortcuts(
            bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
            child: SizedBox(
              width: 340,
              child: ColorPickerSurface(
                color: color,
                includeAlpha: includeAlpha,
                enabled: editable,
                warnsAboutAlpha: !includeAlpha && color.alphaByte != 0xFF,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        child: ValidatedTextField<Color>(
          value: color,
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
          onDone: (value) {
            if (value.argbValue != color.argbValue) {
              ref
                  .read(colorLibraryProvider.notifier)
                  .recordRecent(value.argbValue);
            }
          },
          surroundingActions: [
            if (enabled)
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
            if (editable)
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
            prefixIcon: GestureDetector(
              onTap: enabled ? toggle : null,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Checkerboard(
                  borderRadius: context.shapes.smallBorderRadius,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
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
