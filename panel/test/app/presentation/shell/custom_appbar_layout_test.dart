import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/app/presentation/shell/custom_appbar_layout.dart";

void main() {
  const leadingKey = ValueKey("leading");
  const searchKey = ValueKey("search");
  const trailingKey = ValueKey("trailing");
  const compactSearchKey = ValueKey("compact_search");
  const compactTrailingKey = ValueKey("compact_trailing");

  Widget layout({
    required double width,
    required double leadingWidth,
    required double trailingWidth,
  }) {
    return MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: 48,
          child: CustomAppBarLayout(
            spacing: 8,
            leading: SizedBox(key: leadingKey, width: leadingWidth, height: 20),
            search: const SizedBox(key: searchKey, width: 200, height: 40),
            trailing: SizedBox(
              key: trailingKey,
              width: trailingWidth,
              height: 40,
            ),
            compactSearch: const SizedBox(
              key: compactSearchKey,
              width: 48,
              height: 40,
            ),
            compactTrailing: const SizedBox(
              key: compactTrailingKey,
              width: 96,
              height: 40,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("centers full search when measured content leaves room", (
    tester,
  ) async {
    await tester.pumpWidget(
      layout(width: 600, leadingWidth: 100, trailingWidth: 100),
    );

    expect(
      tester.getCenter(find.byKey(searchKey)).dx,
      tester.getCenter(find.byType(CustomAppBarLayout)).dx,
    );
  });

  testWidgets("moves full search after wide leading content", (tester) async {
    await tester.pumpWidget(
      layout(width: 600, leadingWidth: 250, trailingWidth: 50),
    );

    final leadingRight = tester.getTopRight(find.byKey(leadingKey)).dx;
    final searchLeft = tester.getTopLeft(find.byKey(searchKey)).dx;

    expect(searchLeft, leadingRight + 8);
  });

  testWidgets("moves full search before wide trailing content", (tester) async {
    await tester.pumpWidget(
      layout(width: 600, leadingWidth: 50, trailingWidth: 250),
    );

    final searchRight = tester.getTopRight(find.byKey(searchKey)).dx;
    final trailingLeft = tester.getTopLeft(find.byKey(trailingKey)).dx;

    expect(searchRight + 8, trailingLeft);
  });

  testWidgets("uses compact slots when measured full content does not fit", (
    tester,
  ) async {
    await tester.pumpWidget(
      layout(width: 500, leadingWidth: 260, trailingWidth: 160),
    );

    final renderObject = tester.renderObject<RenderCustomAppBarLayout>(
      find.byType(CustomAppBarLayout),
    );
    final search = tester.renderObject<RenderBox>(find.byKey(searchKey));
    final trailing = tester.renderObject<RenderBox>(find.byKey(trailingKey));
    final compactSearch = tester.renderObject<RenderBox>(
      find.byKey(compactSearchKey),
    );
    final compactTrailing = tester.renderObject<RenderBox>(
      find.byKey(compactTrailingKey),
    );

    expect(renderObject.paintsChild(search), isFalse);
    expect(renderObject.paintsChild(trailing), isFalse);
    expect(renderObject.paintsChild(compactSearch), isTrue);
    expect(renderObject.paintsChild(compactTrailing), isTrue);
    expect(
      tester.getTopRight(find.byKey(leadingKey)).dx + 8,
      lessThanOrEqualTo(tester.getTopLeft(find.byKey(compactSearchKey)).dx),
    );
    expect(
      tester.getTopRight(find.byKey(compactSearchKey)).dx + 8,
      tester.getTopLeft(find.byKey(compactTrailingKey)).dx,
    );
  });
}
