import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's dialog surface: a [title], the [content] below it, and the
/// [actions] along the bottom, end aligned. Open it with
/// [showAdvancedDialog].
///
/// It is heard by its title and reads its words in the panel's body
/// style. It grows to fit its content, no wider than [maxWidth].
class PanelDialog extends StatelessWidget {
  const PanelDialog({
    required this.title,
    required this.content,
    this.actions = const [],
    this.maxWidth = 560,
    super.key,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.space6),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: context.shapes.largeBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.24),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Surface(
                color: colors.surfaceRaised,
                child: DefaultTextStyle(
                  style: text.bodyMedium!.copyWith(
                    color: colors.contentPrimary,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.space6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: spacing.space4,
                      children: [
                        Text(
                          title,
                          style: text.titleLarge?.copyWith(
                            color: colors.contentPrimary,
                          ),
                        ),
                        Flexible(child: content),
                        if (actions.isNotEmpty)
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: spacing.space2,
                            runSpacing: spacing.space2,
                            children: actions,
                          ),
                      ],
                    ),
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
