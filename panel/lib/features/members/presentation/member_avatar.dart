import "package:typewriter_panel/typewriter_panel.dart";

/// A person's identity mark: their avatar image.
///
/// It stays the same while the person is selected; the row's fill shows the
/// selection, and in select mode its [SelectorCheck] is the one check.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({required this.avatarUrl, super.key, this.radius = 24});

  final String avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(avatarUrl),
      backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
    );
  }
}
