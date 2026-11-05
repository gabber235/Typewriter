import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The roles of a story organization, from the founder to the default
/// guest, the way a provisioned organization starts.
final storyRoles = [
  for (final (index, (name, color)) in const [
    ("Founder", Colors.indigo),
    ("Admin", Colors.red),
    ("Editor", Colors.blue),
    ("Writer", Colors.green),
    ("Moderator", Colors.orange),
    ("Guest", Colors.grey),
  ].indexed)
    skir.OrganizationRole(
      roleId: skir.recordId("organization_role:${name.snakeCase()}"),
      name: name,
      color: color.toSkirColor(),
      defaultRole: name == "Guest",
      assignable: index > 0,
      deletable: index > 0 && name != "Guest",
    ),
];

const _givenNames = [
  "Ada",
  "Grace",
  "Linus",
  "Margaret",
  "Alan",
  "Barbara",
  "Dennis",
  "Frances",
  "Ken",
  "Radia",
];

const _familyNames = [
  "Lovelace",
  "Hopper",
  "Torvalds",
  "Hamilton",
  "Turing",
  "Liskov",
  "Ritchie",
  "Allen",
  "Thompson",
  "Perlman",
];

/// A person [generator] names, with an address and avatar to match.
({String id, String name, String email}) _person(Generator generator) {
  final given = generator.pick(_givenNames);
  final family = generator.pick(_familyNames);
  final suffix = generator.integer(1000);
  return (
    id: "${given.toLowerCase()}_${family.toLowerCase()}_$suffix",
    name: "$given $family",
    email: "${given.toLowerCase()}.${family.toLowerCase()}@typewriter.test",
  );
}

String _avatar(String id) => "$userIconUrl&seed=$id";

/// [count] members of a story organization: the founder first, a member
/// with a very long name second, then people [generator] makes up.
List<skir.OrganizationMember> storyMembers(Generator generator, int count) {
  final now = clock.now();
  return [
    for (var index = 0; index < count; index++)
      switch (index) {
        0 => skir.OrganizationMember(
          userId: skir.recordId("user:founder"),
          name: "Ada Lovelace",
          email: "ada@typewriter.test",
          avatarUrl: _avatar("founder"),
          roles: [storyRoles.first],
          joinedAt: now.subtract(const Duration(days: 900)),
        ),
        1 => skir.OrganizationMember(
          userId: skir.recordId("user:long_name"),
          name: "Maximiliana Theodora Wilhelmina von Habsburg Lothringen",
          email: "maximiliana.theodora.von.habsburg@typewriter.test",
          avatarUrl: _avatar("long_name"),
          roles: storyRoles.skip(1).take(4).toList(),
          joinedAt: now.subtract(const Duration(days: 30)),
        ),
        _ => () {
          final person = _person(generator);
          return skir.OrganizationMember(
            userId: skir.recordId("user:${person.id}"),
            name: person.name,
            email: person.email,
            avatarUrl: _avatar(person.id),
            roles: [
              for (final role in storyRoles.skip(1))
                if (generator.chance(0.3)) role,
            ],
            joinedAt: now.subtract(Duration(days: generator.integer(700))),
          );
        }(),
      },
  ];
}

/// [count] join codes: one expiring single use code, one that never expires
/// and accepts as Editor, then codes [generator] makes up.
List<skir.JoinCode> storyJoinCodes(Generator generator, int count) {
  final now = clock.now();
  return [
    for (var index = 0; index < count; index++)
      skir.JoinCode(
        code: skir.recordId(
          "organization_join_code:${index}_${generator.word(length: 12)}",
        ),
        createdAt: now.subtract(Duration(hours: generator.integer(72, min: 1))),
        expiresAt: switch (index) {
          0 => now.add(const Duration(minutes: 45)),
          1 => null,
          _ =>
            generator.chance(0.3)
                ? null
                : now.add(Duration(hours: generator.integer(168, min: 1))),
        },
        singleUse: switch (index) {
          0 => true,
          1 => false,
          _ => generator.chance(0.6),
        },
        autoAccept: skir.JoinCode_AutoAccept(
          roleIds: switch (index) {
            0 => const [],
            1 => [storyRoles[2].roleId],
            _ => [
              for (final role in storyRoles.skip(1))
                if (generator.chance(0.15)) role.roleId,
            ],
          },
        ),
      ),
  ];
}

/// [count] requests to join: a fresh one, one from someone with a very long
/// name that is about to expire, then requests [generator] makes up.
List<skir.OrganizationJoinRequest> storyJoinRequests(
  Generator generator,
  int count,
) {
  final now = clock.now();
  return [
    for (var index = 0; index < count; index++)
      switch (index) {
        1 => skir.OrganizationJoinRequest(
          requestId: skir.recordId("request_to_join:long_name"),
          userId: skir.recordId("user:requester_long_name"),
          userName: "Bartholomew Montgomery Fitzgerald Worthington the Third",
          userEmail: "bartholomew.montgomery.fitzgerald@typewriter.test",
          userAvatarUrl: _avatar("requester_long_name"),
          requestedAt: now.subtract(const Duration(minutes: 55)),
          expiresAt: now.add(const Duration(minutes: 5)),
        ),
        _ => () {
          final person = _person(generator);
          return skir.OrganizationJoinRequest(
            requestId: skir.recordId("request_to_join:${person.id}_$index"),
            userId: skir.recordId("user:${person.id}"),
            userName: person.name,
            userEmail: person.email,
            userAvatarUrl: _avatar(person.id),
            requestedAt: now.subtract(
              Duration(minutes: index == 0 ? 1 : generator.integer(50)),
            ),
            expiresAt: now.add(
              Duration(minutes: generator.integer(60, min: 10)),
            ),
          );
        }(),
      },
  ];
}

/// [count] organizations the signed in user belongs to; the second has a
/// very long name.
List<skir.Organization> storyOrganizations(Generator generator, int count) => [
  for (var index = 0; index < count; index++)
    () {
      final name = switch (index) {
        0 => "Acme",
        1 => "The Very Long Named Interactive Storytelling Guild of Westeros",
        _ => generator.title(words: generator.integer(4, min: 1)),
      };
      return skir.Organization(
        organizationId: skir.recordId("organization:${name.snakeCase()}"),
        name: name,
        logoUrl: index == 0 ? "" : generateOrganizationIconUrl(name),
      );
    }(),
];

/// [count] organizations the signed in user asked to join and waits on.
List<skir.UserJoinRequest> storyUserJoinRequests(
  Generator generator,
  int count,
) {
  final now = clock.now();
  return [
    for (var index = 0; index < count; index++)
      () {
        final name = generator.title(words: generator.integer(3, min: 1));
        return skir.UserJoinRequest(
          requestId: skir.recordId("request_to_join:${name.snakeCase()}"),
          organizationId: skir.recordId("organization:${name.snakeCase()}"),
          organizationName: name,
          organizationLogoUrl: generateOrganizationIconUrl(name),
          requestedAt: now.subtract(Duration(minutes: generator.integer(30))),
          expiresAt: now.add(Duration(minutes: generator.integer(60, min: 5))),
        );
      }(),
  ];
}
