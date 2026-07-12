// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Auth)
final authProvider = AuthProvider._();

final class AuthProvider
    extends $AsyncNotifierProvider<Auth, OidcUserManager?> {
  AuthProvider._()
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

String _$authHash() => r'2b85fa665a6aacdf21a0f228dfc3089631d7bd3f';

abstract class _$Auth extends $AsyncNotifier<OidcUserManager?> {
  FutureOr<OidcUserManager?> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = IsAuthenticatedProvider._();

final class IsAuthenticatedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsAuthenticatedProvider._()
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
final userIdProvider = UserIdProvider._();

final class UserIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  UserIdProvider._()
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
final accessTokenProvider = AccessTokenProvider._();

final class AccessTokenProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccessToken?>,
          AccessToken?,
          FutureOr<AccessToken?>
        >
    with $FutureModifier<AccessToken?>, $FutureProvider<AccessToken?> {
  AccessTokenProvider._()
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
final authUserInfoProvider = AuthUserInfoProvider._();

final class AuthUserInfoProvider
    extends
        $FunctionalProvider<AsyncValue<UserInfo>, UserInfo, FutureOr<UserInfo>>
    with $FutureModifier<UserInfo>, $FutureProvider<UserInfo> {
  AuthUserInfoProvider._()
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
