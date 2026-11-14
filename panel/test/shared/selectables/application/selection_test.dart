import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final a = TestSelectableIdentifier(id: "A");
  final b = TestSelectableIdentifier(id: "B");
  final c = TestSelectableIdentifier(id: "C");
  final d = TestSelectableIdentifier(id: "D");
  final e = TestSelectableIdentifier(id: "E");
  final order = [a, b, c, d, e];

  group("a plain choice", () {
    test("selects only that item, without checks", () {
      final container = ProviderContainer.test();
      final selection = container.read(selectionProvider.notifier)
        ..toggle(a)
        ..toggle(b)
        ..selectOnly(c);

      expect(container.read(selectionProvider), [c]);
      expect(container.read(selectModeProvider), isFalse);

      selection.selectOnly(c);
      expect(container.read(selectionProvider), [
        c,
      ], reason: "choosing the selected item again keeps it selected");
    });
  });

  group("a toggle", () {
    test("adds or removes one item and shows checks", () {
      final container = ProviderContainer.test();
      final selection = container.read(selectionProvider.notifier)
        ..selectOnly(a)
        ..toggle(b);

      expect(container.read(selectionProvider), [a, b]);
      expect(container.read(selectModeProvider), isTrue);

      selection.toggle(a);
      expect(container.read(selectionProvider), [b]);
      expect(container.read(selectModeProvider), isTrue);
    });

    test("removing the last item ends select mode", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..toggle(a)
        ..toggle(a);

      expect(container.read(selectionProvider), isEmpty);
      expect(container.read(selectModeProvider), isFalse);
    });
  });

  group("a range", () {
    test("selects from the anchor to the item in visible order", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..selectOnly(b)
        ..selectRange(d, order: order);

      expect(container.read(selectionProvider), [b, c, d]);
      expect(container.read(selectModeProvider), isTrue);
    });

    test("moves its far end while the anchor stays", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..selectOnly(c)
        ..selectRange(e, order: order)
        ..selectRange(a, order: order);

      expect(container.read(selectionProvider), [a, b, c]);
    });

    test("keeps items toggled before its anchor", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..selectOnly(a)
        ..toggle(c)
        ..selectRange(e, order: order);

      expect(container.read(selectionProvider), [a, c, d, e]);
    });

    test("starts at the item itself with no anchor on the surface", () {
      final container = ProviderContainer.test();
      final elsewhere = TestSelectableIdentifier(id: "elsewhere");
      container.read(selectionProvider.notifier)
        ..selectOnly(elsewhere)
        ..selectRange(d, order: order, from: b);

      expect(container.read(selectionProvider), [b, c, d]);
    });
  });

  group("select every item", () {
    test("selects the whole surface, then clears it when pressed again", () {
      final container = ProviderContainer.test();
      final selection = container.read(selectionProvider.notifier)
        ..selectOnly(b)
        ..selectEvery(order);

      expect(container.read(selectionProvider), order);
      expect(container.read(selectModeProvider), isTrue);

      selection.selectEvery(order);
      expect(container.read(selectionProvider), isEmpty);
      expect(container.read(selectModeProvider), isFalse);
    });
  });

  group("other changes", () {
    test("clearing ends select mode", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..toggle(a)
        ..clear();

      expect(container.read(selectionProvider), isEmpty);
      expect(container.read(selectModeProvider), isFalse);
    });

    test("selectAll replaces the selection by default, without checks", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..toggle(a)
        ..selectAll([b, c]);

      expect(container.read(selectionProvider), [b, c]);
      expect(container.read(selectModeProvider), isFalse);
    });

    test("selectAll appends when replaceCurrentSelection is false", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..selectAll([a])
        ..selectAll([b, c], replaceCurrentSelection: false);

      expect(container.read(selectionProvider), [a, b, c]);
    });

    test("unselecting removes only the named items", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..selectAll([a, b, c, d])
        ..unselect(b)
        ..unselect(e)
        ..unselectAll([a, d]);

      expect(container.read(selectionProvider), [c]);
    });

    test("unselecting the last item ends select mode", () {
      final container = ProviderContainer.test();
      container.read(selectionProvider.notifier)
        ..toggle(a)
        ..unselect(a);

      expect(container.read(selectModeProvider), isFalse);
    });
  });
}
