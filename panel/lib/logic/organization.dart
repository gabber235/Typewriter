import "dart:convert";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:mocktail/mocktail.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";

part "organization.freezed.dart";
part "organization.g.dart";

@riverpod
class Organizations extends _$Organizations {
  @override
  Future<List<OrganizationData>> build() async {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      return [];
    }
    final response = await ref.watch(natsProvider).requestString(
      "user.$userIdProvider.organization.list",
      "",
      jsonDecoder: (data) {
        final json = jsonDecode(data);
        if (json! is List) {
          throw Exception(
            "Expected user.$userIdProvider.organization.list to return a list",
          );
        }
        return (json as List).map((e) => OrganizationData.fromJson(e));
      },
    );

    return response.data.toList(growable: false);
  }

  /// Creates a new organization and returns its ID
  ///
  /// [name] The name of the organization
  /// [iconUrl] The URL of the organization's icon
  ///
  /// Returns the ID of the created organization
  Future<String?> createOrganization({
    required String name,
    required String iconUrl,
  }) async {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      throw Exception("User not found");
    }
    final response = await ref.watch(natsProvider).requestString(
      "user.$userId.organization.create",
      jsonEncode({"name": name, "iconUrl": iconUrl}),
      jsonDecoder: (data) {
        return data;
      },
    );
    final organisationId = response.data;
    if (organisationId.isEmpty) {
      return null;
    }
    return organisationId;
  }
}

class OrganizationsMock extends _$Organizations
    with
        // ignore: prefer_mixin
        Mock
    implements
        Organizations {}

@riverpod
String? organizationId(Ref ref) {
  final routeData = ref.watch(currentRouteDataProvider(OrganizationRoute.name));
  return routeData?.params.getString("organizationId");
}

@riverpod
class Organization extends _$Organization {
  @override
  Future<OrganizationData?> build() async {
    final organizationId = ref.watch(organizationIdProvider);

    return null;
  }
}

class OrganizationMock extends _$Organization
    with
        // ignore: prefer_mixin
        Mock
    implements
        Organization {}

@freezed
abstract class OrganizationData with _$OrganizationData {
  const factory OrganizationData({
    required String name,
    required String id,
    String? iconUrl,
  }) = _OrganizationData;

  factory OrganizationData.fromJson(Map<String, dynamic> json) =>
      _$OrganizationDataFromJson(json);

  static String generateIconUrl(String seed) {
    return "https://api.dicebear.com/9.x/shapes/avif?seed=$seed";
  }
}
