import "package:faker/faker.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:mocktail/mocktail.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

OrganizationData generateRandomOrganization() {
  return OrganizationData(
    id: faker.guid.guid(),
    name: faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase(),
    iconUrl: OrganizationData.generateIconUrl(faker.guid.guid()),
  );
}

OrganizationsMock createOrganizationsMockForState(
  DisplayState state,
) {
  final organizations = OrganizationsMock();
  when(organizations.build).thenAnswer(
    (_) => state.generate(generateRandomOrganization),
  );
  when(
    () => organizations.createOrganization(
      name: any(named: "name"),
      iconUrl: any(named: "iconUrl"),
    ),
  ).thenAnswer((_) => Future.delayed(Duration(milliseconds: 100), () => null));
  return organizations;
}

List<Override> organizationsProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [
      organizationsProvider.overrideWith(
        () => createOrganizationsMockForState(state),
      ),
    ];

OrganizationMock createOrganizationMock(OrganizationData organization) {
  final mock = OrganizationMock();
  when(mock.build).thenAnswer((_) => Future.value(organization));
  return mock;
}

List<Override> organizationProviderOverrides({
  OrganizationData? organization,
}) =>
    [
      organizationProvider.overrideWith(
        () => createOrganizationMock(
            organization ?? generateRandomOrganization(),),
      ),
      organizationIdProvider.overrideWith(
        (ref) => ref
            .watch(organizationProvider)
            .whenData((value) => value?.id)
            .value,
      ),
    ];
