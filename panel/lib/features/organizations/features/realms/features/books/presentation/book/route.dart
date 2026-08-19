import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:collection/collection.dart";
import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart" hide Page;
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:iconify_flutter_plus/icons/mingcute.dart";
import "package:iconify_flutter_plus/icons/ph.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "book_route_shell.dart";
part "page_actions.dart";
part "page_dialogs.dart";
part "page_drag_data.dart";
part "page_sidebar.dart";
part "page_tile.dart";
part "page_tree.dart";
part "route.g.dart";

@RoutePage()
class BookPage extends HookConsumerWidget {
  const BookPage({
    @PathParam("realmId") required this.realmId,
    @PathParam("bookId") required this.bookId,
    super.key,
  });

  final String realmId;
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookScaffold(
      child: AutoRouter(placeholder: (context) => EmptyBookPage()),
    );
  }
}
