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

/// Route entry point for a book and its nested page editor.
///
/// The route parameters identify the organization, realm, and book. The
/// surrounding scaffold establishes the realm connection barrier and shared
/// navigation chrome. The nested router decides whether to show the empty
/// state or a page editor.
@RoutePage()
class BookPage extends HookConsumerWidget {
  const BookPage({
    @PathParam("organizationId") required this.organizationId,
    @PathParam("realmId") required this.realmId,
    @PathParam("bookId") required this.bookId,
    super.key,
  });

  final String organizationId;
  final String realmId;
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookScaffold(
      child: AutoRouter(placeholder: (context) => EmptyBookPage()),
    );
  }
}
