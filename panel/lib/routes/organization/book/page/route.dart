import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

@RoutePage()
class PagePage extends HookConsumerWidget {
  const PagePage({
    @PathParam("pageId") required this.pageId,
    super.key,
  });

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
