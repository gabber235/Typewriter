// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [BookPage]
class BookRoute extends PageRouteInfo<void> {
  const BookRoute({List<PageRouteInfo>? children})
    : super(BookRoute.name, initialChildren: children);

  static const String name = 'BookRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BookPage();
    },
  );
}

/// generated route for
/// [ConnectPage]
class ConnectRoute extends PageRouteInfo<ConnectRouteArgs> {
  ConnectRoute({
    String hostname = "",
    int? port,
    String token = "",
    bool secure = false,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ConnectRoute.name,
         args: ConnectRouteArgs(
           hostname: hostname,
           port: port,
           token: token,
           secure: secure,
           key: key,
         ),
         rawQueryParams: {
           'host': hostname,
           'port': port,
           'token': token,
           'secure': secure,
         },
         initialChildren: children,
       );

  static const String name = 'ConnectRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<ConnectRouteArgs>(
        orElse:
            () => ConnectRouteArgs(
              hostname: queryParams.getString('host', ""),
              port: queryParams.optInt('port'),
              token: queryParams.getString('token', ""),
              secure: queryParams.getBool('secure', false),
            ),
      );
      return ConnectPage(
        hostname: args.hostname,
        port: args.port,
        token: args.token,
        secure: args.secure,
        key: args.key,
      );
    },
  );
}

class ConnectRouteArgs {
  const ConnectRouteArgs({
    this.hostname = "",
    this.port,
    this.token = "",
    this.secure = false,
    this.key,
  });

  final String hostname;

  final int? port;

  final String token;

  final bool secure;

  final Key? key;

  @override
  String toString() {
    return 'ConnectRouteArgs{hostname: $hostname, port: $port, token: $token, secure: $secure, key: $key}';
  }
}

/// generated route for
/// [EmptyPageEditor]
class EmptyPageEditorRoute extends PageRouteInfo<void> {
  const EmptyPageEditorRoute({List<PageRouteInfo>? children})
    : super(EmptyPageEditorRoute.name, initialChildren: children);

  static const String name = 'EmptyPageEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmptyPageEditor();
    },
  );
}

/// generated route for
/// [ErrorConnectPage]
class ErrorConnectRoute extends PageRouteInfo<void> {
  const ErrorConnectRoute({List<PageRouteInfo>? children})
    : super(ErrorConnectRoute.name, initialChildren: children);

  static const String name = 'ErrorConnectRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ErrorConnectPage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [PageEditor]
class PageEditorRoute extends PageRouteInfo<PageEditorRouteArgs> {
  PageEditorRoute({required String id, Key? key, List<PageRouteInfo>? children})
    : super(
        PageEditorRoute.name,
        args: PageEditorRouteArgs(id: id, key: key),
        rawPathParams: {'id': id},
        initialChildren: children,
      );

  static const String name = 'PageEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PageEditorRouteArgs>(
        orElse: () => PageEditorRouteArgs(id: pathParams.getString('id')),
      );
      return PageEditor(id: args.id, key: args.key);
    },
  );
}

class PageEditorRouteArgs {
  const PageEditorRouteArgs({required this.id, this.key});

  final String id;

  final Key? key;

  @override
  String toString() {
    return 'PageEditorRouteArgs{id: $id, key: $key}';
  }
}

/// generated route for
/// [PagesList]
class PagesListRoute extends PageRouteInfo<void> {
  const PagesListRoute({List<PageRouteInfo>? children})
    : super(PagesListRoute.name, initialChildren: children);

  static const String name = 'PagesListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PagesList();
    },
  );
}
