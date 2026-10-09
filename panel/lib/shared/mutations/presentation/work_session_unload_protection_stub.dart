import "work_session_unload_protection.dart";

final class PlatformWorkSessionUnloadProtection
    implements WorkSessionUnloadProtection {
  @override
  bool get protected => false;

  @override
  set protected(bool value) {}

  @override
  void dispose() {}
}
