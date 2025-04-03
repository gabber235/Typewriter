import "package:freezed_annotation/freezed_annotation.dart";
import "package:localstorage/localstorage.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "organization.freezed.dart";
part "organization.g.dart";

@riverpod
class Organization extends _$Organization {
  @override
  Future<OrganizationData?> build() async {
    final orginizationId = localStorage.getItem("organizationId");
    if (orginizationId == null) {
      return null;
    }

    return null;
  }
}

@freezed
abstract class OrganizationData with _$OrganizationData {
  const factory OrganizationData({
    required String name,
    required String id,
  }) = _OrganizationData;

  factory OrganizationData.fromJson(Map<String, dynamic> json) =>
      _$OrganizationDataFromJson(json);
}
