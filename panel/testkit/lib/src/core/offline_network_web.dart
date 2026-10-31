/// Test worlds run on the native test runner only. A browser has no
/// `IOOverrides` seam to keep a test off the network, so a browser suite that
/// builds a test world fails here instead of silently reaching the network.
void keepOffline() => throw UnsupportedError(
  "A test world keeps the network away through dart:io, which a browser "
  "lacks; run widget and application tests on the native test runner",
);
