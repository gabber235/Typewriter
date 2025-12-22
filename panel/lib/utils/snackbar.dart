import "package:flutter/material.dart";

void showSnackBar(
  BuildContext context, {
  required String message,
  Color? color,
  Color? backgroundColor,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: color)),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      showCloseIcon: true,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  final colorScheme = Theme.of(context).colorScheme;
  showSnackBar(
    context,
    message: message,
    color: colorScheme.onPrimary,
    backgroundColor: colorScheme.primary,
  );
}
