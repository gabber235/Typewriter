import "package:flutter/material.dart";
import "package:typewriter_panel/logic/proto/api_exception.dart";
import "package:typewriter_panel/utils/snackbar.dart";

extension FutureExt<T> on Future<T> {
  Future<T> catchApiExceptionsAndDisplay(BuildContext context) {
    return catchError((error, stackTrace) {
      showErrorSnackBar(context, error.message);
    }, test: (error) => error is ApiException);
  }
}
