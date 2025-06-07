import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:logto_dart_sdk/logto_client.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/widgets/generic/components/sidebar.dart";

final mockUserInfo = LogtoUserInfoResponse(
  sub: "1",
  name: "John Doe",
  email: "john.doe@example.com",
  roles: ["admin"],
  picture: "$userIconUrl&seed=1",
  emailVerified: true,
);

List<Override> authProviderOverrides({LogtoUserInfoResponse? userInfo}) => [
  authUserInfoProvider.overrideWithValue(
    AsyncValue.data(userInfo ?? mockUserInfo),
  ),
];
