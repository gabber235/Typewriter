import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/misc.dart" show Override;
import "package:typewriter_panel/app/presentation/shell/sidebar.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";

final mockUserInfo = const UserInfo(
  sub: "1",
  name: "John Doe",
  email: "john.doe@example.com",
  avatarUrl: "$userIconUrl&seed=1",
  emailVerified: true,
);

List<Override> authProviderOverrides({UserInfo? userInfo}) => [
  authUserInfoProvider.overrideWithValue(
    AsyncValue.data(userInfo ?? mockUserInfo),
  ),
];
