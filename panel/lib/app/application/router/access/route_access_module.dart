import "package:flutter/foundation.dart";

abstract interface class RouteAccessModule {
  Listenable get reevaluation;
  Future<void> waitUntilReady();
  void dispose();
}
