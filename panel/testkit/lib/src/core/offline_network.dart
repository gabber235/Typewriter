/// Keeps a test world off the network: native platforms replace sockets and
/// HTTP, and the browser, where no test world runs, has no such seam.
library;

export "offline_network_io.dart"
    if (dart.library.js_interop) "offline_network_web.dart";
