import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class PublishPagesIntent extends Intent {
  const PublishPagesIntent();
}

final stagingStateProvider = StateProvider((ref) => StagingState.production);

enum StagingState {
  publishing(Colors.lightBlue),
  staging(Colors.orange),
  production(Colors.green);

  const StagingState(this.color);

  final Color color;
}
