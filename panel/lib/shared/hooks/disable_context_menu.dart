import "package:typewriter_panel/typewriter_panel.dart";

/// Disables the browser context menu while the owning widget is mounted.
///
/// This affects the web page, not only the widget subtree, so it belongs on a
/// stable shell owner such as [AppRequiredWidgets]. On non web platforms the
/// hook has no effect. If the menu was enabled when the hook mounted, it is
/// restored on disposal provided another owner has not changed it meanwhile.
void useDisableContextMenu() {
  if (!kIsWeb) {
    return;
  }
  use(_DisableContextMenuHook());
}

class _DisableContextMenuHook extends Hook<void> {
  @override
  _DisableContextMenuHookState createState() => _DisableContextMenuHookState();
}

class _DisableContextMenuHookState
    extends HookState<void, _DisableContextMenuHook> {
  bool wasEnabled = true;

  @override
  void initHook() {
    wasEnabled = BrowserContextMenu.enabled;
    if (wasEnabled) {
      BrowserContextMenu.disableContextMenu();
    }
    super.initHook();
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    if (wasEnabled && !BrowserContextMenu.enabled) {
      BrowserContextMenu.enableContextMenu();
    }
    super.dispose();
  }
}
