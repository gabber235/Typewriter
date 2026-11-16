import "package:typewriter_panel/typewriter_panel.dart";

/// A faint line that splits a list or menu into groups.
///
/// It spans its parent's width, one logical pixel high, with a small gap
/// above and below so the groups it splits keep their own rhythm.
class Separator extends StatelessWidget {
  const Separator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(
          color: context.colors.contentSecondary.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
