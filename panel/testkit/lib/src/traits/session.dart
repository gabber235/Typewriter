import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/session.dart";

/// A user most tests sign in as.
const ada = PanelUser(id: "ada", name: "Ada", email: "ada@typewriter.test");

/// A second user, for cases about someone else.
const grace = PanelUser(
  id: "grace",
  name: "Grace",
  email: "grace@typewriter.test",
);

/// The organization most tests work in.
final acme = organization("Acme");

/// An organization named [name], identified by its snake cased name.
skir.Organization organization(String name) => skir.Organization(
  organizationId: skir.recordId("organization:${name.snakeCase()}"),
  name: name,
  logoUrl: "",
);

/// [user] is signed in and belongs to [organization] and [others]; the panel
/// opens in [organization].
Trait signedIn(
  PanelUser user, {
  skir.Organization? organization,
  List<skir.Organization> others = const [],
}) => _SignedIn(user, [?organization, ...others]);

final class _SignedIn extends Trait {
  const _SignedIn(this.user, this.organizations);

  final PanelUser user;
  final List<skir.Organization> organizations;

  @override
  Slot get slot => Slot.session;

  @override
  String get description =>
      "signedIn($user${organizations.isEmpty ? "" : ", in ${organizations.map((it) => it.name).join(", ")}"})";

  @override
  void applyTo(WorldBuilder world) {
    world.user = user;
    world.organizations.addAll(organizations);
  }
}
