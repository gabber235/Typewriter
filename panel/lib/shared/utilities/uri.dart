import "package:typewriter_panel/typewriter_panel.dart";

/// URI actions used when navigation must leave the panel application.
extension UriExtensions on Uri {
  /// Opens this URI in the platform's external application.
  ///
  /// Returns `false` when no handler is available. Otherwise awaits the launch
  /// and returns `true` without inspecting its result. Exceptions still escape.
  Future<bool> launchExternally() async {
    if (await canLaunchUrl(this)) {
      await launchUrl(this, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
