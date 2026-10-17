import "package:typewriter_panel/typewriter_panel.dart";

/// Entry page for users without an authenticated panel session.
///
/// The page owns only presentation. [Auth] owns the authorization flow, allowing
/// the route to remain a simple caller of the application boundary.
@RoutePage()
class AuthPage extends HookConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Expanded(
          flex: 2,
          child: const RiveAsset(
            asset: "assets/game_character.riv",
            stateMachineName: "State Machine",
          ),
        ),
        Text(
          "Your journey starts here",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge!
              .copyWith(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: context.spacing.space6),
        LoadingButton.filled(
          child: Text("Sign in"),
          onPressed: () => ref.read(authProvider.notifier).signIn(),
        ),
        Spacer(),
      ],
    );
  }
}
