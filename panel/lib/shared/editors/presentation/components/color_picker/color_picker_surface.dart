import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ColorPickerSurface extends HookConsumerWidget {
  const ColorPickerSurface({
    required this.color,
    required this.includeAlpha,
    required this.onChanged,
    this.enabled = true,
    this.warnsAboutAlpha = false,
    super.key,
  });

  final Color color;
  final bool includeAlpha;
  final ValueChanged<Color> onChanged;
  final bool enabled;
  final bool warnsAboutAlpha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(colorLibraryProvider);
    final libraryController = ref.read(colorLibraryProvider.notifier);
    final incomingHsv = HSVColor.fromColor(color);
    final rememberedHue = useState(incomingHsv.hue);
    final hsv = hsvWithPreservedHue(color, rememberedHue.value);

    void update(Color next) {
      final value = includeAlpha
          ? next
          : Color(0xFF000000 | next.toARGB32() & 0xFFFFFF);
      final nextHsv = HSVColor.fromColor(value);
      if (nextHsv.saturation > 0.0001) rememberedHue.value = nextHsv.hue;
      onChanged(value);
    }

    KeyEventResult handleKey(FocusNode node, KeyEvent event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      final primary =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (!primary) return KeyEventResult.ignored;
      final format = switch (event.logicalKey) {
        LogicalKeyboardKey.digit1 => ColorFieldFormat.hex,
        LogicalKeyboardKey.digit2 => ColorFieldFormat.rgb,
        LogicalKeyboardKey.digit3 => ColorFieldFormat.hsl,
        _ => null,
      };
      if (format == null) return KeyEventResult.ignored;
      libraryController.setFormat(format);
      return KeyEventResult.handled;
    }

    return FocusScope(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: handleKey,
          child: Surface(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              elevation: 8,
              borderRadius: context.shapes.largeBorderRadius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 340,
                  maxHeight: 620,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      SizedBox(
                        height: 180,
                        child: ClipRRect(
                          borderRadius: context.shapes.largeBorderRadius,
                          child: ColorArea(
                            color: hsv,
                            enabled: enabled,
                            autofocus: true,
                            onChanged: (value) => update(value.toColor()),
                          ),
                        ),
                      ),
                      ColorChannelSlider(
                        label: "Hue",
                        value: hsv.hue / 360,
                        divisions: 360,
                        enabled: enabled,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                        onChanged: (value) {
                          rememberedHue.value = value * 360;
                          update(hsv.withHue(value * 360).toColor());
                        },
                      ),
                      if (includeAlpha)
                        ColorChannelSlider(
                          label: "Opacity",
                          value: color.alphaByte / 255,
                          divisions: 100,
                          checkerboard: true,
                          enabled: enabled,
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0),
                              color.withValues(alpha: 1),
                            ],
                          ),
                          onChanged: (value) =>
                              update(color.withValues(alpha: value)),
                        ),
                      Row(
                        children: [
                          Checkerboard(
                            borderRadius: context.shapes.mediumBorderRadius,
                            child: Container(
                              key: const ValueKey("color_picker_preview"),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: context.shapes.mediumBorderRadius,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: "Copy color",
                            onPressed: () => Clipboard.setData(
                              ClipboardData(
                                text: color.formatHex(
                                  includeAlpha: includeAlpha,
                                ),
                              ),
                            ),
                            icon: const Icones(
                              MaterialSymbols.content_copy_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: library.favorites.contains(color.argbValue)
                                ? "Remove from favorites"
                                : "Add to favorites",
                            onPressed: enabled
                                ? () => libraryController.toggleFavorite(
                                    color.argbValue,
                                  )
                                : null,
                            icon: Icones(
                              library.favorites.contains(color.argbValue)
                                  ? MaterialSymbols.star_rounded
                                  : MaterialSymbols.star_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      if (warnsAboutAlpha)
                        const Admonition.warning(
                          child: Text(
                            "This opaque editor will set alpha to FF when the color changes.",
                          ),
                        ),
                      ColorFields(
                        color: color,
                        format: library.format,
                        includeAlpha: includeAlpha,
                        enabled: enabled,
                        onFormatChanged: libraryController.setFormat,
                        onChanged: update,
                      ),
                      if (library.recent.isNotEmpty) ...[
                        Text(
                          "Recent",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        ColorSwatchGrid(
                          label: "Recent colors",
                          colors: library.recent,
                          enabled: enabled,
                          onSelected: (value) => update(Color(value)),
                        ),
                      ],
                      if (library.favorites.isNotEmpty) ...[
                        Text(
                          "Favorites",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        ColorSwatchGrid(
                          label: "Favorite colors",
                          colors: library.favorites,
                          enabled: enabled,
                          onSelected: (value) => update(Color(value)),
                          onRemoved: libraryController.removeFavorite,
                          onReordered: libraryController.replaceFavorites,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
