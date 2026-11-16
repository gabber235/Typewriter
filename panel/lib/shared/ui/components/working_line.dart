import "package:typewriter_panel/typewriter_panel.dart";

/// A thin line that sweeps while work with no measurable progress runs,
/// heard as [label].
///
/// It is for the edge of a control that waits, such as a query field
/// loading its first results. The sweep is the skeleton token, so it loops
/// like a skeleton and stands still under reduced motion; work with
/// measurable progress shows stepped progress instead.
class WorkingLine extends StatelessWidget {
  const WorkingLine({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    return Semantics(
      container: true,
      label: label,
      child: SizedBox(
        height: 2,
        width: double.infinity,
        child: Shimmer(
          linearGradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.24),
              accent,
              accent.withValues(alpha: 0.24),
            ],
            stops: const [0.1, 0.3, 0.5],
          ),
          child: ShimmerLoading(child: ColoredBox(color: accent)),
        ),
      ),
    );
  }
}
