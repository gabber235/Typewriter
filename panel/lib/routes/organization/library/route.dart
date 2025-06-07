import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_framework/responsive_framework.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/generic/components/book.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/loading_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/page_heading.dart";
import "package:typewriter_panel/widgets/generic/components/retry_indicator.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/vertical_clipper.dart";
import "package:typewriter_panel/widgets/generic/screens/error_screen.dart";

@RoutePage()
class LibraryPage extends HookConsumerWidget {
  const LibraryPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState("");
    final filteredBooks = ref.watch(filteredBooksProvider(searchQuery.value));

    final padding =
        context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0);

    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
            child: const PageHeading(
              title: "Library",
              subtext:
                  "Browse and search all your books. Discover, organize, and manage your collection with ease.",
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search books...",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),
          Expanded(
            child: filteredBooks.when(
              data: (books) {
                if (books.isEmpty) {
                  return const Center(
                    child: Text(
                      "No books match your search",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ClipPath(
                  clipper: VerticalClipper(additionalWidth: 100),
                  child: ResponsiveGridView.builder(
                    gridDelegate: ResponsiveGridDelegate(
                      crossAxisExtent: 175,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 175 / 230,
                    ),
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return BookWidget(
                        title: book.title,
                        icon: Icones(book.icon),
                        color: book.color,
                        tags: book.tags,
                      );
                    },
                  ),
                );
              },
              loading: () => LoadingIndicator(
                message: "Loading books...",
              ),
              error: (error, stackTrace) => ErrorScreen(
                title: "Failed to load books",
                message: error.toString(),
                child: RetryIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
