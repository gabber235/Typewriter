import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Disable the context menu of the browser on the web.
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
