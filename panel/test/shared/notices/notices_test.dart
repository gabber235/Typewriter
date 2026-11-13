import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "a failure toasts first, then waits unread in Activity once it lands",
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notices = container.read(noticesProvider.notifier);

      final id = notices.report(title: "Publish failed", detail: "No engine");
      expect(container.read(noticesProvider).single.toasting, isTrue);
      expect(container.read(noticesProvider).single.unread, isFalse);

      notices.land(id);
      expect(container.read(noticesProvider).single.unread, isTrue);

      notices.readAll();
      expect(container.read(noticesProvider).single.unread, isFalse);
      expect(container.read(noticesProvider), hasLength(1));
    },
  );

  test("at most three toasts float; a fourth lands the oldest in Activity", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notices = container.read(noticesProvider.notifier);

    final first = notices.report(title: "One failed");
    for (final title in ["Two failed", "Three failed", "Four failed"]) {
      notices.report(title: title);
    }

    final state = container.read(noticesProvider);
    expect(state.where((notice) => notice.toasting), hasLength(3));
    expect(state.firstWhere((notice) => notice.id == first).unread, isTrue);
  });

  test("a toast dismissed by hand stays in Activity as read; removing it "
      "clears it", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notices = container.read(noticesProvider.notifier);

    final id = notices.report(title: "Save failed");
    notices.dismiss(id);
    final kept = container.read(noticesProvider).single;
    expect((kept.toasting, kept.read), (false, true));

    notices.remove(id);
    expect(container.read(noticesProvider), isEmpty);
  });

  test("a success only toasts and never lands in Activity", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notices = container.read(noticesProvider.notifier);

    final id = notices.report(
      tone: NoticeTone.success,
      title: "Join request sent",
    );
    notices.land(id);

    expect(container.read(noticesProvider), isEmpty);
  });

  test("a retry that works resolves the failure; one that fails keeps it "
      "with the new reason and counts the attempt", () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notices = container.read(noticesProvider.notifier);
    var works = false;

    final id = notices.report(
      title: "Save failed",
      detail: "Offline",
      retry: () async {
        if (!works) throw ApiException.badRequest("Still offline");
      },
    );

    final failing = notices.retry(id);
    expect(
      container.read(noticesProvider).single.progress,
      NoticeProgress.retrying,
    );
    await failing;
    final kept = container.read(noticesProvider).single;
    expect(
      (kept.progress, kept.detail, kept.attempts),
      (NoticeProgress.open, "Still offline", 1),
    );

    works = true;
    await notices.retry(id);
    expect(
      container.read(noticesProvider).single.progress,
      NoticeProgress.resolved,
    );
  });
}
