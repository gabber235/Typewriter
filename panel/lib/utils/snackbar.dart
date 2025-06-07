import "package:flutter/material.dart";

void showSnackBar(
  BuildContext context, {
  required String message,
  Color? backgroundColor,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      showCloseIcon: true,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  showSnackBar(
    context,
    message: message,
    backgroundColor: Theme.of(context).colorScheme.error,
  );
}
