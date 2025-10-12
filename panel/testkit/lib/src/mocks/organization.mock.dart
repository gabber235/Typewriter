import "dart:async";

import "package:faker/faker.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/organization.pb.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

OrganizationData generateRandomOrganization() {
  return OrganizationData()
    ..id = faker.guid.guid()
    ..name = faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase()
    ..iconUrl = generateOrganizationIconUrl(faker.guid.guid());
}

class OrganizationsMock extends Organizations {
  OrganizationsMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<OrganizationData>> build() async {
    return displayState.generate(generateRandomOrganization);
  }

  @override
  Future<String?> createOrganization({
    required String name,
    required String iconUrl,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    return null;
  }
}

class OrganizationProviderMock extends Organization {
  OrganizationProviderMock({required this.organization});

  final OrganizationData organization;

  @override
  Future<OrganizationData?> build() async {
    return organization;
  }
}

List<Override> organizationsProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [
      organizationsProvider.overrideWith(
        () => OrganizationsMock(displayState: state),
      ),
    ];

List<Override> organizationProviderOverrides({
  OrganizationData? organization,
}) =>
    [
      organizationProvider.overrideWith(
        () => OrganizationProviderMock(
          organization: organization ?? generateRandomOrganization(),
        ),
      ),
      organizationIdProvider.overrideWith(
        (ref) => ref
            .watch(organizationProvider)
            .whenData((value) => value?.id)
            .value,
      ),
    ];
