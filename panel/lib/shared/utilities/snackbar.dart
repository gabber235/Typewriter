import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/theme/theme.dart";

/// Shows a dismissible message through the nearest [ScaffoldMessenger].
void showSnackBar(
  BuildContext context, {
  required String message,
  Color? color,
  Color? backgroundColor,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
      ),
      backgroundColor: backgroundColor,
      dismissDirection: DismissDirection.down,
      showCloseIcon: true,
    ),
  );
}

/// Shows [message] using the theme's error colors.
void showErrorSnackBar(BuildContext context, String message) {
  final colorScheme = Theme.of(context).colorScheme;
  showSnackBar(
    context,
    message: message,
    color: colorScheme.onError,
    backgroundColor: colorScheme.error,
  );
}

/// Shows [message] using the panel's success colors.
void showSuccessSnackBar(BuildContext context, String message) {
  showSnackBar(
    context,
    message: message,
    color: context.colors.onSuccess,
    backgroundColor: context.colors.success,
  );
}
