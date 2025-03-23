// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/material.dart' as _i4;
import 'package:typewriter_panel/routes/auth/route.dart' as _i1;
import 'package:typewriter_panel/routes/route.dart' as _i2;

/// generated route for
/// [_i1.AuthPage]
class AuthRoute extends _i3.PageRouteInfo<AuthRouteArgs> {
  AuthRoute({
    required void Function(bool) onResult,
    _i4.Key? key,
    List<_i3.PageRouteInfo>? children,
  }) : super(
         AuthRoute.name,
         args: AuthRouteArgs(onResult: onResult, key: key),
         initialChildren: children,
       );

  static const String name = 'AuthRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AuthRouteArgs>();
      return _i1.AuthPage(onResult: args.onResult, key: args.key);
    },
  );
}

class AuthRouteArgs {
  const AuthRouteArgs({required this.onResult, this.key});

  final void Function(bool) onResult;

  final _i4.Key? key;

  @override
  String toString() {
    return 'AuthRouteArgs{onResult: $onResult, key: $key}';
  }
}

/// generated route for
/// [_i2.HomePage]
class HomeRoute extends _i3.PageRouteInfo<void> {
  const HomeRoute({List<_i3.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i3.PageInfo page = _i3.PageInfo(
    name,
    builder: (data) {
      return const _i2.HomePage();
    },
  );
}
