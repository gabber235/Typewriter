import "package:typewriter_panel/typewriter_panel.dart";

export "package:typewriter_panel/shared/ui/components/secret_field_state.dart";

part "secret_field_controller.dart";
part "secret_field_displays.dart";
part "secret_field_view.dart";

/// Generates, reveals, copies, and expires a secret value in one field.
///
/// The field owns its local lifecycle state. [onGenerate] supplies the value
/// and optional expiry; the value is copied automatically when [copyOnGenerate]
/// is true. Expired values remain present but concealed, and generation
/// failures become an error state and an error snackbar.
class SecretField extends HookWidget {
  const SecretField({
    required this.title,
    required this.description,
    required this.onGenerate,
    this.prefix,
    this.generateButtonText = "Generate",
    this.regenerateButtonText = "Regenerate",
    this.copyButtonText = "Copy",
    this.expiredText = "Expired",
    this.copiedSnackbarText = "Copied to clipboard",
    this.errorSnackbarText = "Failed to generate",
    this.copyOnGenerate = true,
    this.onCopied,
    this.onExpired,
    super.key,
  });

  /// Heading that identifies the generated value.
  final String title;

  /// Caller supplied explanation shown below [title].
  final String description;

  /// Produces the next value and its optional expiration time.
  final FutureOr<SecretFieldRevealed> Function() onGenerate;

  /// Text prepended when the value is displayed and copied.
  final String? prefix;

  /// Label used before the first successful generation.
  final String generateButtonText;

  /// Label used while replacing an existing value.
  final String regenerateButtonText;

  /// Label for copying a currently revealed value.
  final String copyButtonText;

  /// Label shown after the revealed value expires.
  final String expiredText;

  /// Success message shown after clipboard write completes.
  final String copiedSnackbarText;

  /// Prefix for the exception message shown when generation fails.
  final String errorSnackbarText;

  /// Whether a successful generation also writes the complete value to the clipboard.
  final bool copyOnGenerate;

  /// Called after the complete prefixed value is written to the clipboard.
  final VoidCallback? onCopied;

  /// Called once when a revealed value reaches its expiration time.
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final controller = _useSecretFieldController(context, this);
    return _SecretFieldView(field: this, controller: controller);
  }
}
