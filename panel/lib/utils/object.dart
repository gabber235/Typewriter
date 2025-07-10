extension ObjectExtension on Object? {
  T? cast<T>() => this is T ? this as T : null;
}
