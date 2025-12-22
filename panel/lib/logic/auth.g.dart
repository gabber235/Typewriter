// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Auth)
const authProvider = AuthProvider._();

final class AuthProvider
    extends $AsyncNotifierProvider<Auth, OidcUserManager?> {
  const AuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authHash();

  @$internal
  @override
  Auth create() => Auth();
}

String _$authHash() => r'96a2e1be8d0b85245fa34ea23307fc2a4ad1e015';

abstract class _$Auth extends $AsyncNotifier<OidcUserManager?> {
  FutureOr<OidcUserManager?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<OidcUserManager?>, OidcUserManager?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OidcUserManager?>, OidcUserManager?>,
              AsyncValue<OidcUserManager?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(isAuthenticated)
const isAuthenticatedProvider = IsAuthenticatedProvider._();

final class IsAuthenticatedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  const IsAuthenticatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAuthenticatedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isAuthenticated(ref);
  }
}

String _$isAuthenticatedHash() => r'01f00b31ef3086bf1de4f7f7c4bdc8967f4fa199';

@ProviderFor(userId)
const userIdProvider = UserIdProvider._();

final class UserIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  const UserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return userId(ref);
  }
}

String _$userIdHash() => r'6655b62760fa3487a0f1aa8c80604428f5d78ce6';

@ProviderFor(accessToken)
const accessTokenProvider = AccessTokenProvider._();

final class AccessTokenProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccessToken?>,
          AccessToken?,
          FutureOr<AccessToken?>
        >
    with $FutureModifier<AccessToken?>, $FutureProvider<AccessToken?> {
  const AccessTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessTokenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessTokenHash();

  @$internal
  @override
  $FutureProviderElement<AccessToken?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AccessToken?> create(Ref ref) {
    return accessToken(ref);
  }
}

String _$accessTokenHash() => r'2e8a4fc614c401c2dbb3bee3fc6fb6444afcd016';

@ProviderFor(authUserInfo)
const authUserInfoProvider = AuthUserInfoProvider._();

final class AuthUserInfoProvider
    extends
        $FunctionalProvider<AsyncValue<UserInfo>, UserInfo, FutureOr<UserInfo>>
    with $FutureModifier<UserInfo>, $FutureProvider<UserInfo> {
  const AuthUserInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authUserInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authUserInfoHash();

  @$internal
  @override
  $FutureProviderElement<UserInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserInfo> create(Ref ref) {
    return authUserInfo(ref);
  }
}

String _$authUserInfoHash() => r'b733e3db042800cfddb47fe6458593faf4e5966a';
