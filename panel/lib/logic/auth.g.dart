// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isAuthenticatedHash() => r'01cfa8d489aff8e3db8617554e57eec265333884';

/// See also [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = AutoDisposeFutureProvider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthenticatedRef = AutoDisposeFutureProviderRef<bool>;
String _$idTokenHash() => r'46c4980942716d29fc4dc28438a5c6562ddbe813';

/// See also [idToken].
@ProviderFor(idToken)
final idTokenProvider = AutoDisposeFutureProvider<String?>.internal(
  idToken,
  name: r'idTokenProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$idTokenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IdTokenRef = AutoDisposeFutureProviderRef<String?>;
String _$authUserInfoHash() => r'12b0d58d9ea77ff317b173a38fdf7263a845401e';

/// See also [authUserInfo].
@ProviderFor(authUserInfo)
final authUserInfoProvider =
    AutoDisposeFutureProvider<LogtoUserInfoResponse>.internal(
  authUserInfo,
  name: r'authUserInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authUserInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthUserInfoRef = AutoDisposeFutureProviderRef<LogtoUserInfoResponse>;
String _$authHash() => r'7f9a515216a882d8e27a12a0a45d45d00b9967d3';

/// See also [Auth].
@ProviderFor(Auth)
final authProvider = AutoDisposeNotifierProvider<Auth, LogtoClient>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = AutoDisposeNotifier<LogtoClient>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
