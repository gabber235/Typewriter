import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_theme_access.dart";

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

void showErrorSnackBar(BuildContext context, String message) {
  final colorScheme = Theme.of(context).colorScheme;
  showSnackBar(
    context,
    message: message,
    color: colorScheme.onError,
    backgroundColor: colorScheme.error,
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  showSnackBar(
    context,
    message: message,
    color: context.colors.onSuccess,
    backgroundColor: context.colors.success,
  );
}
