import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:mocktail/mocktail.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/routes/route.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

enum IndexPageState {
  loading("Loading"),
  noOrganizations("No Organizations"),
  fewOrganizations("Few Organizations"),
  manyOrganizations("Many Organizations"),
  error("Error");

  const IndexPageState(this.name);

  final String name;
}

@widgetbook.UseCase(name: "IndexPage", type: IndexPage)
Widget indexPageUseCase(BuildContext context) {
  final state = context.knobs.list(
    label: "State",
    initialOption: IndexPageState.loading,
    options: IndexPageState.values,
    labelBuilder: (option) => option.name,
  );

  final organizations = OrganizationsMock();
  when(organizations.build).thenAnswer(
    (_) => switch (state) {
      IndexPageState.loading => Future.delayed(
        Duration(days: 100000),
        () => [],
      ),
      IndexPageState.noOrganizations => Future.value([]),
      IndexPageState.fewOrganizations => Future.value([
        OrganizationData(
          id: "1",
          name: "Organization 1",
          iconUrl: OrganizationData.generateIconUrl("org1"),
        ),
        OrganizationData(
          id: "2",
          name: "Organization 2",
          iconUrl: OrganizationData.generateIconUrl("org2"),
        ),
      ]),
      IndexPageState.manyOrganizations => Future.value([
        for (var i = 0; i < 100; i++)
          OrganizationData(
            id: "$i",
            name: "Organization $i",
            iconUrl: OrganizationData.generateIconUrl("org$i"),
          ),
      ]),
      IndexPageState.error => Future.error(Exception("Error")),
    },
  );

  when(
    () => organizations.createOrganization(
      name: any(named: "name"),
      iconUrl: any(named: "iconUrl"),
    ),
  ).thenAnswer((_) => Future.delayed(1.seconds, () => null));

  return ProviderScope(
    overrides: [organizationsProvider.overrideWith(() => organizations)],
    child: IndexPage(),
  );
}
