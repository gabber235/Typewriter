import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: SearchFrame)
Widget searchFrameDefaultUseCase(BuildContext context) {
  return const FakeApp(child: SizedBox.expand(child: _SearchFrameDemo()));
}

class _SearchFrameDemo extends HookWidget {
  const _SearchFrameDemo();

  @override
  Widget build(BuildContext context) {
    final showPreview = useState(true);
    final shortcuts = useMemoized(
      () => [
        ActionShortcut(
          id: "open",
          label: "Open",
          description: "Open selected result",
          activators: const [SingleActivator(LogicalKeyboardKey.enter)],
          priority: 10,
        ),
        ActionShortcut(
          id: "preview",
          label: "Preview",
          description: "Toggle preview panel",
          activators: const [
            SingleActivator(LogicalKeyboardKey.keyP, meta: true),
          ],
          priority: 20,
          icon: const Icon(Icons.visibility_rounded),
          onInvoke: (_) => showPreview.value = !showPreview.value,
        ),
      ],
      [showPreview],
    );

    return ActionSet(
      shortcuts: shortcuts,
      child: Stack(
        children: [
          Center(
            child: SearchFrame(
              queryBar: const _DemoQueryBar(),
              searchResults: const _DemoResults(),
              preview: showPreview.value ? const _DemoPreview() : null,
              actionBar: const ActionRow(),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: _PreviewToggleButton(
              selected: showPreview.value,
              onPressed: () => showPreview.value = !showPreview.value,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewToggleButton extends StatelessWidget {
  const _PreviewToggleButton({required this.selected, required this.onPressed});

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          selected ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          key: ValueKey(selected),
          size: 18,
        ),
      ),
      label: Text(selected ? "Hide preview" : "Show preview"),
      style: FilledButton.styleFrom(
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _DemoQueryBar extends StatelessWidget {
  const _DemoQueryBar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Search entries, triggers, actions",
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "quest village intro",
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const ShortcutDisplay(
            shortcut: SingleActivator(LogicalKeyboardKey.keyK, meta: true),
          ),
        ],
      ),
    );
  }
}

class _DemoResults extends StatelessWidget {
  const _DemoResults();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
      child: SingleChildScrollView(
        child: Column(
          spacing: 8,
          children: const [
            _ResultTile(
              title: "Village intro dialogue",
              subtitle: "Dialogue • 6 branches • updated now",
              icon: Icons.chat_bubble_outline_rounded,
              selected: true,
            ),
            _ResultTile(
              title: "Give welcome bundle",
              subtitle: "Action chain • 3 steps",
              icon: Icons.inventory_2_outlined,
            ),
            _ResultTile(
              title: "Detect first join",
              subtitle: "Trigger • player lifecycle",
              icon: Icons.bolt_outlined,
            ),
            _ResultTile(
              title: "Mayor camera path",
              subtitle: "Cinematic • 18 seconds",
              icon: Icons.videocam_outlined,
            ),
            _ResultTile(
              title: "Village intro dialogue",
              subtitle: "Dialogue • 6 branches • updated now",
              icon: Icons.chat_bubble_outline_rounded,
              selected: true,
            ),
            _ResultTile(
              title: "Give welcome bundle",
              subtitle: "Action chain • 3 steps",
              icon: Icons.inventory_2_outlined,
            ),
            _ResultTile(
              title: "Detect first join",
              subtitle: "Trigger • player lifecycle",
              icon: Icons.bolt_outlined,
            ),
            _ResultTile(
              title: "Mayor camera path",
              subtitle: "Cinematic • 18 seconds",
              icon: Icons.videocam_outlined,
            ),
            _ResultTile(
              title: "Village intro dialogue",
              subtitle: "Dialogue • 6 branches • updated now",
              icon: Icons.chat_bubble_outline_rounded,
              selected: true,
            ),
            _ResultTile(
              title: "Give welcome bundle",
              subtitle: "Action chain • 3 steps",
              icon: Icons.inventory_2_outlined,
            ),
            _ResultTile(
              title: "Detect first join",
              subtitle: "Trigger • player lifecycle",
              icon: Icons.bolt_outlined,
            ),
            _ResultTile(
              title: "Mayor camera path",
              subtitle: "Cinematic • 18 seconds",
              icon: Icons.videocam_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tint = selected ? colors.primary : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.38)
            : colors.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? colors.primary.withValues(alpha: 0.46)
              : colors.outlineVariant.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPreview extends StatelessWidget {
  const _DemoPreview();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.account_tree_outlined,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Village intro dialogue",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Entry preview",
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _PreviewStat(label: "Branches", value: "6"),
        const SizedBox(height: 8),
        const _PreviewStat(label: "Variables", value: "12"),
        const SizedBox(height: 8),
        const _PreviewStat(label: "Last edited", value: "now"),
        const SizedBox(height: 16),
        Text(
          "Mayor says hello, player chooses path, reward chain starts when dialogue closes.",
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.78),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
