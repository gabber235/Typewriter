import "package:faker/faker.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:mocktail/mocktail.dart";

enum MockOrganizationsState {
  loading,
  noOrganizations,
  fewOrganizations,
  manyOrganizations,
  error,
}

OrganizationData generateRandomOrganization() {
  return OrganizationData(
    id: faker.guid.guid(),
    name:
        faker.lorem
            .words(faker.randomGenerator.integer(4, min: 2))
            .join(" ")
            .snakeCase(),
    iconUrl: OrganizationData.generateIconUrl(faker.guid.guid()),
  );
}

OrganizationsMock createOrganizationsMockForState(
  MockOrganizationsState state,
) {
  final organizations = OrganizationsMock();
  when(organizations.build).thenAnswer(
    (_) => switch (state) {
      MockOrganizationsState.loading => Future.delayed(
        Duration(days: 100000),
        () => [],
      ),
      MockOrganizationsState.noOrganizations => Future.value([]),
      MockOrganizationsState.fewOrganizations => Future.value([
        for (var i = 0; i < 3; i++) generateRandomOrganization(),
      ]),
      MockOrganizationsState.manyOrganizations => Future.value([
        for (var i = 0; i < 100; i++) generateRandomOrganization(),
      ]),
      MockOrganizationsState.error => Future.error(Exception("Error")),
    },
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
  MockOrganizationsState state = MockOrganizationsState.loading,
}) => [
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
}) => [
  organizationProvider.overrideWith(
    () => createOrganizationMock(organization ?? generateRandomOrganization()),
  ),
  organizationIdProvider.overrideWith(
    (ref) =>
        ref.watch(organizationProvider).whenData((value) => value?.id).value,
  ),
];
