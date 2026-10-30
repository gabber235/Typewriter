import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The window a panel renders in unless a trait changes it.
const desktopWindow = Size(1400, 900);

/// What the traits of a test world set, before the world exists.
///
/// Traits write sources here in any order; [World.build] turns them into
/// doubles once every trait applied, so no trait depends on another's order.
final class WorldBuilder {
  WorldBuilder._();

  /// The signed in user, or null when nobody is signed in.
  PanelUser? user;

  /// The organizations [user] belongs to; the first is where the panel opens.
  final organizations = <skir.Organization>[];

  /// The Realm the panel can open, in the first organization.
  RealmSeed? realm;

  /// The operations the Realm offers on its resources.
  List<RealmOperation> operations = const [];

  /// How long the backend doubles take to answer.
  Duration latency = Duration.zero;

  /// When the backend goes away; null keeps it reachable.
  Duration? offlineAfter;

  /// The window the panel renders in.
  Size window = desktopWindow;

  /// The theme mode the user chose.
  ThemeMode themeMode = ThemeMode.light;

  /// Whether the organization projections the panel watches over NATS are
  /// replaced by [FakeOrganizations]; false leaves the real projections
  /// reading [World.nats], where the test registers replies.
  bool organizationDoubles = true;

  /// Whether Rive assets render through the real Rive runtime; false renders
  /// them as [FakeRive] empty boxes, as a test runner without the native
  /// Rive library needs.
  bool liveAnimations = false;

  /// Doubles traits install for sources the world does not model itself,
  /// such as the membership of an organization.
  final overrides = <Override>[];

  /// Effects that run once the world started, in order.
  final _startups = <void Function(World world)>[];

  /// Runs [effect] once the world started, such as a remote change after a
  /// delay.
  void onStart(void Function(World world) effect) => _startups.add(effect);
}

/// The content of a Realm a trait seeds.
final class RealmSeed {
  RealmSeed({
    required this.name,
    this.books = const [],
    this.tags = const [],
    this.pages = const [],
    this.scenes = const [],
    this.catalog,
    this.saved,
  });

  final String name;
  final List<Book> books;
  final List<Tag> tags;
  final List<Page> pages;

  /// The scenes the realm root holds besides its Library and tags section.
  final List<Scene> scenes;

  /// The catalog the seeded resources are typed by; null keeps the
  /// [libraryCatalog].
  final CheckedEditorCatalog? catalog;

  /// The whole saved document, for content the library catalog cannot
  /// describe; replaces [books], [tags], [pages] and [catalog].
  final AuthoringDocument? saved;

  /// The document the Realm starts with.
  AuthoringDocument get document =>
      saved ??
      realmDocument(
        books: books,
        tags: tags,
        pages: pages,
        scenes: scenes,
        catalog: catalog,
      );
}

/// Everything one test runs against: the doubles behind every seam, the
/// provider container and its cleanup.
///
/// A world is built from traits and owns every resource they need; [dispose]
/// releases them all, so tests register no cleanup of their own.
final class World {
  World._({
    required this.session,
    required this.nats,
    required this.organizations,
    required this.appearance,
    required this.realm,
    required this.window,
    required this._builder,
  }) {
    container = ProviderContainer(
      overrides: [
        ...appOverrides(),
        ...session.overrides,
        nats.override,
        if (_builder.organizationDoubles) ...organizations.overrides,
        appearance.override,
        if (!_builder.liveAnimations) const FakeRive().override,
        ...?realm?.overrides,
        ..._builder.overrides,
      ],
      // Tests and stories never retry, so a failure shows at once.
      retry: (retryCount, error) => null,
    );
  }

  /// Builds the world [traits] describe.
  ///
  /// Throws an [ArgumentError] naming both traits when two of them set the
  /// same source.
  factory World.build(List<Trait> traits) {
    final seen = <Slot, Trait>{};
    for (final trait in traits) {
      final previous = seen[trait.slot];
      if (previous != null) {
        throw ArgumentError(
          "Two traits set the ${trait.slot}: $previous and $trait. "
          "A world takes one trait per source; drop one of them.",
        );
      }
      seen[trait.slot] = trait;
    }
    final builder = WorldBuilder._();
    for (final trait in traits) {
      trait.applyTo(builder);
    }

    final organizations = FakeOrganizations();
    final user = builder.user;
    if (user != null) {
      for (final organization in builder.organizations) {
        organizations.join(user.id, organization);
      }
    }
    FakeRealm? realm;
    final seed = builder.realm;
    if (seed != null) {
      final organization = builder.organizations.firstOrNull;
      if (organization == null) {
        throw ArgumentError(
          "The realm ${seed.name} needs an organization to live in; "
          "sign in with signedIn(user, organization: ...)",
        );
      }
      final instance = organizations.addRealm(
        organization.organizationId,
        id: skir.recordId("realm_instance:${seed.name.snakeCase()}"),
        name: seed.name,
      );
      realm = FakeRealm(
        scope: AuthoringScope(
          organizationId: organization.organizationId,
          realmId: instance.realmId,
        ),
        name: seed.name,
        document: seed.document,
        operations: builder.operations,
      )..latency = builder.latency;
    }
    return World._(
      session: FakeSession(user: user),
      nats: FakeNats(),
      organizations: organizations,
      appearance: FakeAppearance(builder.themeMode),
      realm: realm,
      window: builder.window,
      builder: builder,
    );
  }

  /// The identity provider session.
  final FakeSession session;

  /// The NATS server every panel connection reaches.
  final FakeNats nats;

  /// The organizations, realms and services the backend knows.
  final FakeOrganizations organizations;

  /// The stored theme preference.
  final FakeAppearance appearance;

  /// The Realm a trait seeded, or null.
  final FakeRealm? realm;

  /// The window the panel renders in.
  final Size window;

  final WorldBuilder _builder;

  /// The provider container every panel widget of this world reads.
  late final ProviderContainer container;

  final _cleanups = <FutureOr<void> Function()>[];
  final _timers = <Timer>[];
  var _started = false;
  var _disposed = false;

  /// The Realm a trait seeded; throws when no trait seeded one.
  FakeRealm get requireRealm =>
      realm ?? (throw StateError("No trait seeded a realm; add realm([...])"));

  /// Where the panel opens when a test names no location: the seeded Realm,
  /// else the user's first organization, else the panel's start page.
  PageRouteInfo get home {
    final seeded = realm;
    if (seeded != null) return const RealmRouteTree().realm(seeded.scope);
    final organization = _builder.organizations.firstOrNull;
    if (organization != null) {
      return OrganizationRoute(organizationId: organization.organizationId.id);
    }
    return const IndexRoute();
  }

  /// Starts the effects traits scheduled, such as going offline later.
  ///
  /// Runs once, when the panel first mounts.
  void start() {
    if (_started) return;
    _started = true;
    final offlineAfter = _builder.offlineAfter;
    if (offlineAfter != null) {
      _timers.add(Timer(offlineAfter, nats.disconnect));
    }
    for (final effect in _builder._startups) {
      effect(this);
    }
  }

  /// Replaces the resource session the way a new work scope or user does;
  /// everything built on it rebuilds when next read.
  void replaceResourceSession() => container.invalidate(resourceSessionProvider);

  /// Runs [effect] after [delay], unless the world was disposed first.
  void schedule(Duration delay, void Function() effect) =>
      _timers.add(Timer(delay, effect));

  /// Releases [cleanup] when the world is disposed, after the container.
  void addCleanup(FutureOr<void> Function() cleanup) => _cleanups.add(cleanup);

  /// Disposes the container, every double and every registered cleanup.
  ///
  /// Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    container.dispose();
    await nats.close();
    await organizations.close();
    await realm?.close();
    for (final cleanup in _cleanups.reversed) {
      await cleanup();
    }
  }
}
