import "package:typewriter_panel/typewriter_panel.dart";

/// Animates decorative status changes without replacing their interactive owner.
///
/// Key [icon] by its visual identity. Optional label spacing enters and leaves
/// with the text. Compact layout removes the entire label region immediately.
class AnimatedStatusContent extends StatelessWidget {
  const AnimatedStatusContent({
    required this.icon,
    required this.compact,
    this.label,
    super.key,
  });

  final Widget icon;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ElasticMessageSwitcher(
        duration: const Duration(milliseconds: 180),
        reverseDuration: const Duration(milliseconds: 120),
        sizeDuration: const Duration(milliseconds: 200),
        child: icon,
      ),
      if (!compact)
        Flexible(
          child: ElasticMessageSwitcher(
            duration: const Duration(milliseconds: 180),
            reverseDuration: const Duration(milliseconds: 120),
            sizeDuration: const Duration(milliseconds: 200),
            // An empty switcher stack would expand to its available width.
            child: label == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(label),
                    padding: EdgeInsetsDirectional.only(
                      start: context.spacing.space2,
                    ),
                    child: Text(label!, overflow: TextOverflow.ellipsis),
                  ),
          ),
        ),
    ],
  );
}
