//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <oidc_linux/oidc_plugin.h>
#include <rive_native/rive_native_plugin.h>
#include <simple_secure_storage_linux/simple_secure_storage_linux_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>
#include <webcrypto/webcrypto_plugin.h>
#include <window_to_front/window_to_front_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) oidc_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "OidcPlugin");
  oidc_plugin_register_with_registrar(oidc_linux_registrar);
  g_autoptr(FlPluginRegistrar) rive_native_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "RiveNativePlugin");
  rive_native_plugin_register_with_registrar(rive_native_registrar);
  g_autoptr(FlPluginRegistrar) simple_secure_storage_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SimpleSecureStorageLinuxPlugin");
  simple_secure_storage_linux_plugin_register_with_registrar(simple_secure_storage_linux_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
  g_autoptr(FlPluginRegistrar) webcrypto_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WebcryptoPlugin");
  webcrypto_plugin_register_with_registrar(webcrypto_registrar);
  g_autoptr(FlPluginRegistrar) window_to_front_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowToFrontPlugin");
  window_to_front_plugin_register_with_registrar(window_to_front_registrar);
}
