import "dart:async";
import "dart:math";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

export "package:typewriter_panel/shared/ui/components/secret_field_state.dart";

part "secret_field_controller.dart";
part "secret_field_displays.dart";
part "secret_field_view.dart";

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

  final String title;
  final String description;
  final FutureOr<SecretFieldRevealed> Function() onGenerate;
  final String? prefix;
  final String generateButtonText;
  final String regenerateButtonText;
  final String copyButtonText;
  final String expiredText;
  final String copiedSnackbarText;
  final String errorSnackbarText;
  final bool copyOnGenerate;
  final VoidCallback? onCopied;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final controller = _useSecretFieldController(context, this);
    return _SecretFieldView(field: this, controller: controller);
  }
}
