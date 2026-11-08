import "support/remote_session.dart";
import "support/scenarios.dart";
import "support/stack.dart" as stack;

// Every name carries the run's start time: the stack keeps what earlier runs
// and reruns authored, and a name must find this run's resource only.

void main() {
  scenario(
    "BOOK-1",
    "an author creates a book and finds it after reopening the realm",
    Demonstrates.happyPath,
    (panel) async {
      final title = "The Lost Map ${DateTime.now().millisecondsSinceEpoch}";
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.create("Book", title);
      await panel.restart();
      await panel.open("Acme", "Realm");
      await panel.search(title, choose: title);
      expect(await panel.fieldValue("Title"), title);
      await panel.capture("book-persisted");
    },
  );

  scenario(
    "BOOK-3",
    "a deleted book disappears and the inbox lists its page as removed",
    Demonstrates.happyPath,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      final title = "Old Notes $run";
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.createBookWithPage(title, page: "Old Chapter $run");
      await panel.publishRealm(ownPage: "Old Chapter $run");
      await panel.press("Close");
      await panel.open("Library");
      await panel.open(title);
      await panel.hold("Delete this resource and what it owns?");
      await panel.expectHidden(title);
      // The realm publishes the book's page, so the inbox names the page
      // the deletion takes out of the published content.
      await panel.press("Realm inbox");
      await panel.expectVisible("Old Chapter $run");
      await panel.expectVisible("Removed");
      await panel.capture("book-removed");
    },
  );

  scenario(
    "PAGE-1",
    "an author adds a page and an entry and places the entry on the graph",
    Demonstrates.happyPath,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.createBookWithPage("Chronicle $run", page: "Opening $run");
      await panel.press("New Element");
      await panel.press("Simple Message Action Entry");
      await panel.submit("name", "Greeting $run");
      await panel.submit("message", "Welcome");
      await panel.submit("X coordinate", "2");
      await panel.restart();
      await panel.open("Acme", "Realm");
      await panel.search("Greeting $run", choose: "Greeting $run");
      expect(await panel.fieldValue("X coordinate"), "2");
      await panel.expectVisible("Greeting $run", outside: "Inspector");
      await panel.capture("entry-placed");
    },
  );

  scenario(
    "LINK-1",
    "a tag linked to a book shows on the book",
    Demonstrates.happyPath,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      final tag = "Legend $run";
      final book = "Myths $run";
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.open("Tags");
      await panel.press("New Tag");
      await panel.submit("Name", tag);
      await panel.open("Library");
      await panel.create("Book", book);
      await panel.press("Add item");
      await panel.press("Choose linked resource");
      await panel.pick(tag);
      await panel.restart();
      await panel.open("Acme", "Realm");
      await panel.search(book, choose: book);
      await panel.expectVisible(tag);
      await panel.capture("tag-linked");
    },
  );

  scenario(
    "SEARCH-1",
    "search finds a resource by name and opens it",
    Demonstrates.happyPath,
    (panel) async {
      final title = "Hidden Atlas ${DateTime.now().millisecondsSinceEpoch}";
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.create("Book", title);
      await panel.open("Library");
      await panel.search(title, choose: title);
      expect(await panel.fieldValue("Title"), title);
      await panel.capture("search-opened");
    },
  );

  faultScenario(
    "GUARD-1",
    "leaving with unsaved work asks first; staying keeps the work",
    Demonstrates.edgeCase,
    (panel) async {
      final title = "Draft ${DateTime.now().millisecondsSinceEpoch}";
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.create("Book", title);
      // Edits save within a moment; a slow link keeps this one unsaved
      // while the user tries to leave.
      await stack.natsLatency(const Duration(seconds: 10));
      await panel.submit("Title", "$title, unsaved");
      await panel.press("ada");
      await panel.press("Logout");
      await panel.expectVisible("Leave this work session?");
      await panel.capture("leave-asked");
      await panel.press("Stay");
      expect(await panel.fieldValue("Title"), "$title, unsaved");
    },
  );

  faultScenario(
    "CONFLICT-1",
    "an edit to a value someone else changed is refused with a comparison, "
        "and nothing is lost",
    Demonstrates.edgeCase,
    (panel) async {
      final run = DateTime.now().millisecondsSinceEpoch;
      await panel.signIn("ada");
      await panel.open("Acme", "Realm");
      await panel.create("Book", "Shared $run");
      final book = panel.openResource;
      final other = await remoteSession("ada");
      await other.follow(book);
      // A slow link keeps the other edit from reaching this panel before the
      // user's own edit leaves it, the way two people typing at once race.
      await stack.natsLatency(const Duration(seconds: 3));
      final theirs = other.write(book, ["title"], "Theirs $run");
      await panel.type("Title", "Mine $run");
      await theirs;
      await panel.expectVisible("Saved values changed");
      await panel.press("Review changes");
      await panel.expectVisible("Mine $run");
      await panel.expectVisible("Theirs $run");
      await panel.capture("comparison");
      await panel.press("Close");
      await panel.press("Discard");
      expect(await panel.fieldValue("Title"), "Theirs $run");
      await stack.resetFaults();
      await other.expectSaved(book, ["title"], "Theirs $run");
      await panel.restart();
      await panel.open("Acme", "Realm");
      await panel.search("Theirs $run", choose: "Theirs $run");
      expect(await panel.fieldValue("Title"), "Theirs $run");
      await panel.capture("their-value-kept");
    },
  );
}
