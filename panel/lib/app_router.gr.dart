// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AuthPage]
class AuthRoute extends PageRouteInfo<AuthRouteArgs> {
  AuthRoute({
    required void Function(bool) onResult,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         AuthRoute.name,
         args: AuthRouteArgs(onResult: onResult, key: key),
         initialChildren: children,
       );

  static const String name = 'AuthRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AuthRouteArgs>();
      return AuthPage(onResult: args.onResult, key: args.key);
    },
  );
}

class AuthRouteArgs {
  const AuthRouteArgs({required this.onResult, this.key});

  final void Function(bool) onResult;

  final Key? key;

  @override
  String toString() {
    return 'AuthRouteArgs{onResult: $onResult, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [BookPage]
class BookRoute extends PageRouteInfo<BookRouteArgs> {
  BookRoute({
    required String realmId,
    required String bookId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         BookRoute.name,
         args: BookRouteArgs(realmId: realmId, bookId: bookId, key: key),
         rawPathParams: {'realmId': realmId, 'bookId': bookId},
         initialChildren: children,
       );

  static const String name = 'BookRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<BookRouteArgs>(
        orElse: () => BookRouteArgs(
          realmId: pathParams.getString('realmId'),
          bookId: pathParams.getString('bookId'),
        ),
      );
      return BookPage(
        realmId: args.realmId,
        bookId: args.bookId,
        key: args.key,
      );
    },
  );
}

class BookRouteArgs {
  const BookRouteArgs({required this.realmId, required this.bookId, this.key});

  final String realmId;

  final String bookId;

  final Key? key;

  @override
  String toString() {
    return 'BookRouteArgs{realmId: $realmId, bookId: $bookId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BookRouteArgs) return false;
    return realmId == other.realmId &&
        bookId == other.bookId &&
        key == other.key;
  }

  @override
  int get hashCode => realmId.hashCode ^ bookId.hashCode ^ key.hashCode;
}

/// generated route for
/// [IndexPage]
class IndexRoute extends PageRouteInfo<void> {
  const IndexRoute({List<PageRouteInfo>? children})
    : super(IndexRoute.name, initialChildren: children);

  static const String name = 'IndexRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const IndexPage();
    },
  );
}

/// generated route for
/// [LibraryPage]
class LibraryRoute extends PageRouteInfo<void> {
  const LibraryRoute({List<PageRouteInfo>? children})
    : super(LibraryRoute.name, initialChildren: children);

  static const String name = 'LibraryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LibraryPage();
    },
  );
}

/// generated route for
/// [MembersPage]
class MembersRoute extends PageRouteInfo<void> {
  const MembersRoute({List<PageRouteInfo>? children})
    : super(MembersRoute.name, initialChildren: children);

  static const String name = 'MembersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MembersPage();
    },
  );
}

/// generated route for
/// [OrganizationPage]
class OrganizationRoute extends PageRouteInfo<OrganizationRouteArgs> {
  OrganizationRoute({
    required String organizationId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         OrganizationRoute.name,
         args: OrganizationRouteArgs(organizationId: organizationId, key: key),
         rawPathParams: {'organizationId': organizationId},
         initialChildren: children,
       );

  static const String name = 'OrganizationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<OrganizationRouteArgs>(
        orElse: () => OrganizationRouteArgs(
          organizationId: pathParams.getString('organizationId'),
        ),
      );
      return OrganizationPage(
        organizationId: args.organizationId,
        key: args.key,
      );
    },
  );
}

class OrganizationRouteArgs {
  const OrganizationRouteArgs({required this.organizationId, this.key});

  final String organizationId;

  final Key? key;

  @override
  String toString() {
    return 'OrganizationRouteArgs{organizationId: $organizationId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OrganizationRouteArgs) return false;
    return organizationId == other.organizationId && key == other.key;
  }

  @override
  int get hashCode => organizationId.hashCode ^ key.hashCode;
}

/// generated route for
/// [PagePage]
class RouteRoute extends PageRouteInfo<RouteRouteArgs> {
  RouteRoute({required String pageId, Key? key, List<PageRouteInfo>? children})
    : super(
        RouteRoute.name,
        args: RouteRouteArgs(pageId: pageId, key: key),
        rawPathParams: {'pageId': pageId},
        initialChildren: children,
      );

  static const String name = 'RouteRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RouteRouteArgs>(
        orElse: () => RouteRouteArgs(pageId: pathParams.getString('pageId')),
      );
      return PagePage(pageId: args.pageId, key: args.key);
    },
  );
}

class RouteRouteArgs {
  const RouteRouteArgs({required this.pageId, this.key});

  final String pageId;

  final Key? key;

  @override
  String toString() {
    return 'RouteRouteArgs{pageId: $pageId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RouteRouteArgs) return false;
    return pageId == other.pageId && key == other.key;
  }

  @override
  int get hashCode => pageId.hashCode ^ key.hashCode;
}

/// generated route for
/// [RealmPage]
class RealmRoute extends PageRouteInfo<RealmRouteArgs> {
  RealmRoute({
    required String organizationId,
    required String realmId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         RealmRoute.name,
         args: RealmRouteArgs(
           organizationId: organizationId,
           realmId: realmId,
           key: key,
         ),
         rawPathParams: {'organizationId': organizationId, 'realmId': realmId},
         initialChildren: children,
       );

  static const String name = 'RealmRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RealmRouteArgs>(
        orElse: () => RealmRouteArgs(
          organizationId: pathParams.getString('organizationId'),
          realmId: pathParams.getString('realmId'),
        ),
      );
      return RealmPage(
        organizationId: args.organizationId,
        realmId: args.realmId,
        key: args.key,
      );
    },
  );
}

class RealmRouteArgs {
  const RealmRouteArgs({
    required this.organizationId,
    required this.realmId,
    this.key,
  });

  final String organizationId;

  final String realmId;

  final Key? key;

  @override
  String toString() {
    return 'RealmRouteArgs{organizationId: $organizationId, realmId: $realmId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RealmRouteArgs) return false;
    return organizationId == other.organizationId &&
        realmId == other.realmId &&
        key == other.key;
  }

  @override
  int get hashCode => organizationId.hashCode ^ realmId.hashCode ^ key.hashCode;
}

/// generated route for
/// [ServicesPage]
class ServicesRoute extends PageRouteInfo<void> {
  const ServicesRoute({List<PageRouteInfo>? children})
    : super(ServicesRoute.name, initialChildren: children);

  static const String name = 'ServicesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ServicesPage();
    },
  );
}
