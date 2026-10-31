/// The panel as a scenario's user drives it: a few general verbs over the real
/// screens instead of one helper per journey, so every scenario reads as the
/// user's steps.
///
/// Scenarios run on the live binding against the real stack, where replies
/// take real time and animations such as the sign in character never settle.
/// So the driver never waits for the panel to settle: every step waits until
/// what it needs is on screen, and fails naming what the screen shows instead.
/// Controls are found the way the testkit drivers find them: by the text and
/// semantics labels a user reads, never by keys or widget types.
library;

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/drivers/shared/field_driver.dart";

import "stack.dart" as stack;

/// How long a step waits for the screen it needs; replies cross the real
/// broker, backend and Realm host.
const _patience = Duration(seconds: 30);

/// How often a waiting step looks at the screen again.
const _frame = Duration(milliseconds: 100);

/// How long a clicked field may take to accept text before the click
/// repeats.
const _refocus = Duration(seconds: 2);

/// Platform services initialize once per run, however many panels launch.
final Future<void> _platform = initializePanel();

/// The running panel and the session store it keeps between launches.
final class Panel {
  Panel._(this.tester, this._onCapture);

  /// Boots the real panel with an in memory session store, so no keychain or
  /// keyring is involved, and waits until it shows its first page.
  static Future<Panel> launch(
    WidgetTester tester, {
    required void Function(String name, Uint8List png) onCapture,
  }) async {
    await _platform;
    final panel = Panel._(tester, onCapture);
    addTearDown(() => panel._container?.dispose());
    await panel._start();
    return panel;
  }

  final WidgetTester tester;
  final void Function(String name, Uint8List png) _onCapture;

  /// Where the panel keeps the signed in session, as the platform store would
  /// across restarts.
  var _store = OidcMemoryStore();
  ProviderContainer? _container;

  /// The fixture user signed in now, or null.
  String? _user;

  /// How often the panel asked the identity provider to end its session.
  int _providerSessionEnds = 0;

  ProviderContainer get _app => _container!;

  Future<void> _start() async {
    final container = ProviderContainer(
      retry: panelRetry,
      overrides: [
        ...appOverrides(),
        oidcStoreProvider.overrideWithValue(_store),
        // The provider's end session flow opens a browser tab; the scenario
        // records the request instead of leaving a tab per sign out.
        providerSessionEndProvider.overrideWithValue((_) async {
          _providerSessionEnds++;
        }),
      ],
    );
    _container = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TypewriterPanel(),
      ),
    );
    await until("the panel shows its first page", () => _labels.isNotEmpty);
  }

  /// Closes the panel and opens it again, the way a user quits and restarts
  /// it; the stored session survives, everything in memory does not.
  Future<void> restart() async {
    await tester.pumpWidget(const SizedBox.shrink());
    _container?.dispose();
    _container = null;
    await _start();
  }

  /// Closes the panel and opens it the way another machine does: nothing
  /// stored, nobody signed in, so a second user can take over the run.
  Future<void> startElsewhere() async {
    _store = OidcMemoryStore();
    _user = null;
    await restart();
  }

  /// Signs in the fixture user [username] through the real session client
  /// with the password grant, which the stack's identity stand in accepts,
  /// and waits until the panel shows them signed in.
  ///
  /// The sign in page itself hands over to the browser, which a scenario
  /// cannot drive; the full suite covers it against the real provider.
  Future<void> signIn(String username) async {
    final user = stack.user(username);
    final manager = await _app.read(authProvider.future);
    if (manager == null) {
      throw StateError("the panel has no session client");
    }
    await manager.loginPassword(
      username: user.username,
      password: user.password,
    );
    _app.invalidate(authProvider);
    _user = username;
    await expectVisible(username);
  }

  /// Signs out through the user menu, waits for the sign in page, and checks
  /// the panel asked the identity provider to end its session once.
  Future<void> signOut() async {
    final user = _user ?? (throw StateError("nobody is signed in"));
    final ends = _providerSessionEnds;
    await _tap(await _control(user));
    await _tap(await _control("Logout"));
    _user = null;
    await expectVisible("Sign in");
    expect(
      _providerSessionEnds - ends,
      1,
      reason: "signing out asks the identity provider to end its session",
    );
  }

  /// Opens [place] the way the user sees it on screen, then [inside] within
  /// it when given: an organization in the list, a link in the sidebar, or a
  /// card on the services graph by its kind, such as `open("Acme", "Realm")`.
  Future<void> open(String place, [String? inside]) async {
    await _activate(place);
    if (inside != null) await _activate(inside);
  }

  /// Runs the command [name] through the search palette, the one path every
  /// action has: opens Search, types [name] and activates the result that
  /// reads it.
  Future<void> command(String name) => search(name, choose: name);

  /// Opens Search, types [query] and, when given, activates the result that
  /// reads [choose].
  Future<void> search(String query, {String? choose}) async {
    await _tap(await _control("Search"));
    await _typeInChooser(query);
    if (choose != null) await _tap(await _row(choose));
  }

  /// Picks [name] in the chooser on screen, such as the one a link field
  /// opens: types it into the chooser's search and activates the result
  /// reading it.
  Future<void> pick(String name) async {
    await _typeInChooser(name);
    await _tap(await _row(name));
  }

  /// A chooser opens with its search field focused; [text] goes there.
  Future<void> _typeInChooser(String text) async {
    SemanticsNode? focused;
    await until("a search field holds the focus", () {
      focused = visibleTextFields().firstWhereOrNull(
        (field) => field.isFocused,
      );
      return focused != null;
    });
    await until(
      "the search field takes text",
      () => focused!.getSemanticsData().hasAction(SemanticsAction.setText),
    );
    tester.semantics.setText(
      find.semantics.byPredicate((node) => identical(node, focused)),
      text,
    );
    await tester.pump(_frame);
  }

  /// Opens the context menu of the item the user reads as [item], the way a
  /// secondary click does, and chooses [entry] in it.
  Future<void> menu(String item, String entry) async {
    SemanticsNode? target;
    await until("\"$item\" is on screen", () {
      target = _tappable(
        (spoken) => spoken == item || spoken.split("\n").first == item,
      );
      return target != null;
    });
    await tester.tapAt(_centerOf(target!), buttons: kSecondaryMouseButton);
    await tester.pump(_frame);
    await press(entry);
  }

  /// Waits for text on screen matching [pattern] and returns the match, such
  /// as a join code the panel generated.
  Future<String> read(Pattern pattern) async {
    String? match;
    await until("the screen shows text matching $pattern", () {
      for (final label in _labels) {
        if (pattern.allMatches(label).firstOrNull case final found?) {
          match = found.group(0);
          return true;
        }
      }
      return false;
    });
    return match!;
  }

  /// The text field the user reads as [label]: its label, or its hint while
  /// it is empty.
  PanelField field(String label) => PanelField._(this, label);

  /// The row of the list on screen that shows [name], such as a member or a
  /// join request.
  PanelRow row(String name) => PanelRow._(this, name);

  /// Presses the button [label]; with a dialog open, its button wins over one
  /// behind it with the same label.
  Future<void> press(String label) async => _tap(await _control(label));

  /// Creates a resource of [kind] in the open surface the way its "New" action
  /// does and names it [name] in the field [field].
  Future<void> create(
    String kind,
    String name, {
    String field = "Title",
  }) async {
    await press("New $kind");
    final named = this.field(field);
    await named.submit(name);
    await until("the new $kind is named \"$name\"", () {
      final node = named._node;
      return node != null && node.getSemanticsData().value == name;
    });
  }

  /// Creates a book titled [title] holding a sequence page named [page], and
  /// leaves the page open: a page is what the realm compiles and publishes, so
  /// a book without one has nothing to publish.
  Future<void> createBookWithPage(String title, {required String page}) async {
    await create("Book", title);
    await press("New Page");
    await press("Sequence");
    await field("Name").submit(page);
  }

  /// The resource open on screen, the way another user's session addresses
  /// the same thing through a shared link.
  OpenResource get openResource {
    final scope = _app.read(selectedAuthoringScopeProvider);
    final resource = scope == null
        ? null
        : _app.read(routedResourceProvider(scope));
    if (scope == null || resource == null) {
      throw TestFailure("no resource is open; the panel is at $address");
    }
    return (scope: scope, resource: resource);
  }

  /// The address the panel shows, as a user copies it to share a link.
  String get address => _app.read(appRouterProvider).currentPath;

  /// Opens [address] the way following a link or typing it in the address
  /// bar does.
  Future<void> visit(String address) async {
    unawaited(
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
          MethodCall("pushRouteInformation", {
            "location": address,
            "state": null,
          }),
        ),
        (_) {},
      ),
    );
    await tester.pump(_frame);
  }

  /// Whether the screen shows [text], as text or as a semantics label.
  bool sees(String text) => _labels.any((label) => label.contains(text));

  /// Waits up to [within] until the screen shows [text]; a state the panel
  /// derives from a slow signal, such as a host's heartbeat, needs longer.
  Future<void> expectVisible(String text, {Duration within = _patience}) =>
      until("the screen shows \"$text\"", () => sees(text), timeout: within);

  /// Waits until the screen no longer shows [text], then checks it stays
  /// gone for [settled], so a slow reply cannot bring it back unnoticed.
  Future<void> expectHidden(
    String text, {
    Duration within = _patience,
    Duration settled = const Duration(seconds: 3),
  }) async {
    await until(
      "the screen hides \"$text\"",
      () => !sees(text),
      timeout: within,
    );
    final end = DateTime.now().add(settled);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(_frame);
      if (sees(text)) throw TestFailure("\"$text\" came back");
    }
  }

  /// Captures the whole panel as evidence named [name].
  Future<void> capture(String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(TypewriterPanel),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      if (bytes == null) {
        throw StateError("the panel could not be encoded as PNG");
      }
      _onCapture(name, bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  /// Pumps frames until [condition] holds; fails after [timeout] naming
  /// [description] and what the screen shows.
  Future<void> until(
    String description,
    bool Function() condition, {
    Duration timeout = _patience,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TestFailure(
          "Waited ${timeout.inSeconds}s until $description; "
          "the screen shows ${_labels.toSet().toList()}",
        );
      }
      await tester.pump(_frame);
    }
  }

  /// Every label and field text the screen reads out, in reading order.
  List<String> get _labels => [
    for (final node
        in find.semantics.byPredicate((node) => !node.isInvisible).evaluate())
      for (final text in [node.spoken, node.getSemanticsData().value])
        if (text.isNotEmpty) text,
  ];

  /// Waits for the control the user activates as [label] and returns it: a
  /// button, link or tile reading [label], or one whose first line does, or
  /// one that reads [label] and then its state, such as
  /// `Realm inbox. 2 issues`.
  Future<SemanticsNode> _control(String label) async {
    SemanticsNode? found;
    await until("a control reads \"$label\"", () {
      found = _tappable(
        (spoken) =>
            spoken == label ||
            spoken.split("\n").first == label ||
            spoken.startsWith("$label. "),
      );
      return found != null;
    });
    return found!;
  }

  /// Waits for the search result row reading [label] and returns it.
  Future<SemanticsNode> _row(String label) async {
    SemanticsNode? found;
    await until("a search result reads \"$label\"", () {
      found = _tappable(
        (spoken) => spoken.split("\n").any((line) => line.trim() == label),
      );
      return found != null;
    });
    return found!;
  }

  SemanticsNode? _tappable(bool Function(String spoken) reads) => find.semantics
      .byPredicate(
        (node) =>
            node.isTappable &&
            node.isEnabled &&
            !node.isInvisible &&
            reads(node.named),
      )
      .evaluate()
      .lastOrNull;

  /// Opens [place]: the entry reading it nearest the left edge, where the
  /// navigation lists places, so a sidebar link wins over a breadcrumb of
  /// the same name; a services graph card of that kind, which reads
  /// `Kind, Name, Status`, opens with a double click once its host is
  /// connected.
  ///
  /// An entry a long list has not built yet comes into view the way a screen
  /// reader user reaches it: by scrolling the content forward.
  Future<void> _activate(String place) async {
    SemanticsNode? entry;
    SemanticsNode? card;
    var scrolled = DateTime.now();
    await until("\"$place\" can be opened", () {
      if (DateTime.now().difference(scrolled) > _refocus) {
        scrolled = DateTime.now();
        _scrollContentForward();
      }
      entry = find.semantics
          .byPredicate(
            (node) =>
                !node.isInvisible &&
                !node.isMergedIntoParent &&
                node.isTappable &&
                (node.named == place || node.named.split("\n").first == place),
          )
          .evaluate()
          .sortedBy<num>((node) => node.screenRect.left)
          .firstOrNull;
      card = _tappable((spoken) {
        final parts = spoken.split(", ");
        return parts.length == 3 &&
            parts.first == place &&
            parts.last != "Host offline";
      });
      return entry != null || card != null;
    });
    if (entry case final entry?) return _tap(entry);
    final target = _centerOf(card!);
    await tester.tapAt(target);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(target);
    await tester.pump(_frame);
  }

  /// Scrolls the largest scrollable on screen one page forward through its
  /// scroll action, as a screen reader's scroll gesture does.
  void _scrollContentForward() {
    final content = find.semantics
        .byPredicate(
          (node) =>
              !node.isInvisible &&
              node.getSemanticsData().hasAction(SemanticsAction.scrollUp),
        )
        .evaluate()
        .sortedBy<num>((node) => -node.screenRect.size.longestSide)
        .firstOrNull;
    if (content == null) return;
    tester.semantics.performAction(
      find.semantics.byPredicate((node) => identical(node, content)),
      SemanticsAction.scrollUp,
    );
  }

  /// Activates [node] the way assistive technology does, through its tap
  /// action.
  Future<void> _tap(SemanticsNode node) async {
    tester.semantics.tap(
      find.semantics.byPredicate((candidate) => identical(candidate, node)),
    );
    // A control that also answers double taps acts once the timeout passed.
    await tester.pump(kDoubleTapTimeout);
    await tester.pump(_frame);
  }

  /// The center of [node] in the logical coordinates pointer events use.
  ///
  /// Every transform up to the root applies, the root's included, which
  /// gives physical pixels on the live binding; the view's pixel ratio turns
  /// them back into logical ones.
  Offset _centerOf(SemanticsNode node) {
    var rect = node.rect;
    for (SemanticsNode? current = node; current != null;) {
      if (current.transform case final transform?) {
        rect = MatrixUtils.transformRect(transform, rect);
      }
      current = current.parent;
    }
    return rect.center / tester.view.devicePixelRatio;
  }
}

/// One text field, found by what the user reads on it.
final class PanelField {
  PanelField._(this._panel, this.label);

  final Panel _panel;
  final String label;

  WidgetTester get _tester => _panel.tester;

  /// The field labeled or hinted [label].
  SemanticsNode? get _node => visibleTextFields().firstWhereOrNull((node) {
    final data = node.getSemanticsData();
    return data.label.startsWith(label) || data.hint.startsWith(label);
  });

  Future<SemanticsNode> _found() async {
    await _panel.until("a text field reads \"$label\"", () => _node != null);
    return _node!;
  }

  /// The text the field shows.
  Future<String> value() async => (await _found()).getSemanticsData().value;

  /// Types [text] and commits it with Enter, the way a user finishes a
  /// value.
  Future<void> submit(String text) async {
    await set(text);
    await _tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _tester.pump(_frame);
  }

  /// Focuses the field and replaces its text with [text], as typing does.
  ///
  /// An editor field wraps its text input in a focus boundary that reads as
  /// the same field; the innermost text field is the input a click reaches.
  Future<void> set(String text) async {
    // A field rebuilt while its surface loads drops the focus a click gave
    // it, so the click repeats until the field takes text, as a user clicks
    // again.
    var clicked = DateTime(0);
    await _panel.until("the text field \"$label\" accepts text", () {
      final field = _node;
      if (field == null) return false;
      if (field.getSemanticsData().hasAction(SemanticsAction.setText)) {
        return true;
      }
      if (DateTime.now().difference(clicked) > _refocus) {
        clicked = DateTime.now();
        final input = [field, ...field.descendants]
            .where(
              (node) => node.getSemanticsData().flagsCollection.isTextField,
            )
            .last;
        _tester.semantics.tap(
          find.semantics.byPredicate((node) => identical(node, input)),
        );
      }
      return false;
    });
    _tester.semantics.setText(
      find.semantics.byPredicate((node) => identical(node, _node)),
      text,
    );
    await _tester.pump(_frame);
  }
}

/// A resource of a realm, as a link to it names it.
typedef OpenResource = ({AuthoringScope scope, skir.ResourceId resource});

/// One row of a list on screen, found by the name it shows.
final class PanelRow {
  PanelRow._(this._panel, this.name);

  final Panel _panel;
  final String name;

  /// Chooses the action [label] in the row, such as `Approve`: the control
  /// reading [label] nearest to the name, in the smallest part of the screen
  /// holding both.
  Future<void> choose(String label) async {
    SemanticsNode? action;
    await _panel.until("the row \"$name\" offers \"$label\"", () {
      action = _action(label);
      return action != null;
    });
    await _panel._tap(action!);
  }

  /// The control reading [label] closest to a node showing [name]: the one
  /// reached through the fewest ancestors, so a row's own action wins over
  /// the same action of a row beside it.
  SemanticsNode? _action(String label) {
    bool isAction(SemanticsNode node) =>
        node.isTappable && node.isEnabled && node.named == label;
    bool shows(SemanticsNode node) => [
      ...node.spoken.split("\n"),
      node.getSemanticsData().value,
    ].any((line) => line.trim() == name);
    SemanticsNode? nearest;
    var nearestDistance = 1 << 30;
    for (final shown in find.semantics.byPredicate(shows).evaluate()) {
      var distance = 0;
      for (SemanticsNode? row = shown; row != null; row = row.parent) {
        if (distance >= nearestDistance) break;
        final action = isAction(row)
            ? row
            : row.descendants.firstWhereOrNull(isAction);
        if (action != null) {
          nearest = action;
          nearestDistance = distance;
          break;
        }
        distance++;
      }
    }
    return nearest;
  }
}

extension on SemanticsNode {
  /// What the user knows the control by: its label, or the tooltip of an
  /// icon button that has none.
  String get named => switch (spoken) {
    "" => getSemanticsData().tooltip,
    final label => label,
  };
}
