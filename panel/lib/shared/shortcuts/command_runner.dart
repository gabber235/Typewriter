import "package:typewriter_panel/typewriter_panel.dart";

part "command_runner.freezed.dart";

/// What can end a hold early.
@freezed
sealed class HoldInput with _$HoldInput {
  /// A key hold: releasing one of [keys], or focus leaving [focus], ends it.
  const factory HoldInput.key({
    required Set<LogicalKeyboardKey> keys,
    required FocusNode? focus,
  }) = KeyHoldInput;

  /// A pointer hold: lifting or cancelling [pointer] ends it.
  const factory HoldInput.pointer(int pointer) = PointerHoldInput;

  /// A screen reader long press, which confirms at once.
  const factory HoldInput.assistive() = AssistiveHoldInput;
}

/// What a key press needs from the panel's one owner of command runs, so a
/// key and a Button bound to the same command share one run.
abstract interface class CommandRunner {
  /// Keeps the run of [command] while a set or Button that offers it is
  /// mounted; the returned callback lets go.
  VoidCallback retain(String command);

  /// Runs [command]'s press once; false when it is refused.
  bool press(ActionShortcut command, WidgetRef ref);

  /// Starts or continues the hold of [command] from [input].
  void start(
    ActionShortcut command,
    WidgetRef ref,
    HoldInput input, {
    required ResolvedMotion<NoLanding> motion,
  });
}

/// Hands the panel's [CommandRunner] to the action sets below it.
class CommandRunnerScope extends InheritedWidget {
  const CommandRunnerScope({
    required this.runner,
    required super.child,
    super.key,
  });

  final CommandRunner runner;

  static CommandRunner of(BuildContext context) => maybeOf(context)!;

  /// Null outside the panel shell, as in a bare widget test of one row.
  static CommandRunner? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommandRunnerScope>()?.runner;

  @override
  bool updateShouldNotify(CommandRunnerScope old) => old.runner != runner;
}
