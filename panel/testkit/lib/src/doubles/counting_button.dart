import "package:typewriter_panel/typewriter_panel.dart";

/// A button reading `Count n` that counts its presses in its own state.
///
/// Content that was rebuilt from scratch starts over at `Count 0`, so a test
/// placing it behind a wrapper sees whether the wrapper kept the content
/// alive.
final class CountingButton extends StatefulWidget {
  const CountingButton({super.key});

  @override
  State<CountingButton> createState() => _CountingButtonState();
}

final class _CountingButtonState extends State<CountingButton> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => setState(() => _count++),
      child: Text("Count $_count"),
    );
  }
}
