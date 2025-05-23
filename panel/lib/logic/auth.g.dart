// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(Auth)
const authProvider = AuthProvider._();

final class AuthProvider extends $NotifierProvider<Auth, LogtoClient> {
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

  @$internal
  @override
  $NotifierProviderElement<Auth, LogtoClient> $createElement(
          $ProviderPointer pointer) =>
      $NotifierProviderElement(pointer);

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogtoClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $ValueProvider<LogtoClient>(value),
    );
  }
}

String _$authHash() => r'7f02474a574ae333e6ce19dbf1c0d2abb102829d';

abstract class _$Auth extends $Notifier<LogtoClient> {
  LogtoClient build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LogtoClient>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<LogtoClient>, LogtoClient, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(isAuthenticated)
const isAuthenticatedProvider = IsAuthenticatedProvider._();

final class IsAuthenticatedProvider
    extends $FunctionalProvider<AsyncValue<bool>, FutureOr<bool>>
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

String _$isAuthenticatedHash() => r'a122de67d3dbd6bae712235e8a57c8ff7399edf8';

@ProviderFor(userId)
const userIdProvider = UserIdProvider._();

final class UserIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, FutureOr<String?>>
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

final class AccessTokenProvider extends $FunctionalProvider<
        AsyncValue<AccessToken?>, FutureOr<AccessToken?>>
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
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AccessToken?> create(Ref ref) {
    return accessToken(ref);
  }
}

String _$accessTokenHash() => r'9c7cde866e768bda04a70eafbbe8ab76408843ac';

@ProviderFor(authUserInfo)
const authUserInfoProvider = AuthUserInfoProvider._();

final class AuthUserInfoProvider extends $FunctionalProvider<
        AsyncValue<LogtoUserInfoResponse>, FutureOr<LogtoUserInfoResponse>>
    with
        $FutureModifier<LogtoUserInfoResponse>,
        $FutureProvider<LogtoUserInfoResponse> {
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
  $FutureProviderElement<LogtoUserInfoResponse> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LogtoUserInfoResponse> create(Ref ref) {
    return authUserInfo(ref);
  }
}

String _$authUserInfoHash() => r'6ecf0b44884d7ef0a2a26b013e8c964714e9f24d';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
