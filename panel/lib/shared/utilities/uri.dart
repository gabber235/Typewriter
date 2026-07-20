import "package:url_launcher/url_launcher.dart";

extension UriExtensions on Uri {
  Future<bool> launchExternally() async {
    if (await canLaunchUrl(this)) {
      await launchUrl(this, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
