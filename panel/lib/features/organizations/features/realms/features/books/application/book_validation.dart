part of "books.dart";

extension on skir.BookValidationError {
  ApiException toApiException() {
    return switch (kind) {
      skir.BookValidationError_kind.unknown =>
        ApiException.unknownResponseMessage(),
      skir.BookValidationError_kind.titleRequiredConst =>
        ApiException.badRequest("Book title is required"),
      skir.BookValidationError_kind.iconRequiredConst =>
        ApiException.badRequest("Book icon is required"),
    };
  }
}

extension on skir.PageValidationError {
  ApiException toApiException() {
    return switch (kind) {
      skir.PageValidationError_kind.unknown =>
        ApiException.unknownResponseMessage(),
      skir.PageValidationError_kind.nameRequiredConst =>
        ApiException.badRequest("Page name is required"),
      skir.PageValidationError_kind.pageKindUnknownConst =>
        ApiException.badRequest("Page kind is unknown"),
      skir.PageValidationError_kind.pageKindRevisionUnknownConst =>
        ApiException.badRequest("Page kind revision is unknown"),
    };
  }
}
