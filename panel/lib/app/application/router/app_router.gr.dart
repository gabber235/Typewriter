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
class AuthRoute extends PageRouteInfo<void> {
  const AuthRoute({List<PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AuthPage();
    },
  );
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
/// [JoinCodesPage]
class JoinCodesRoute extends PageRouteInfo<void> {
  const JoinCodesRoute({List<PageRouteInfo>? children})
    : super(JoinCodesRoute.name, initialChildren: children);

  static const String name = 'JoinCodesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const JoinCodesPage();
    },
  );
}

/// generated route for
/// [JoinRequestsPage]
class JoinRequestsRoute extends PageRouteInfo<void> {
  const JoinRequestsRoute({List<PageRouteInfo>? children})
    : super(JoinRequestsRoute.name, initialChildren: children);

  static const String name = 'JoinRequestsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const JoinRequestsPage();
    },
  );
}

/// generated route for
/// [MemberListPage]
class MemberListRoute extends PageRouteInfo<void> {
  const MemberListRoute({List<PageRouteInfo>? children})
    : super(MemberListRoute.name, initialChildren: children);

  static const String name = 'MemberListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MemberListPage();
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
/// [RealmHomePage]
class RealmHomeRoute extends PageRouteInfo<void> {
  const RealmHomeRoute({List<PageRouteInfo>? children})
    : super(RealmHomeRoute.name, initialChildren: children);

  static const String name = 'RealmHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RealmHomePage();
    },
  );
}

/// generated route for
/// [RealmPage]
class RealmRoute extends PageRouteInfo<RealmRouteArgs> {
  RealmRoute({required String realmId, Key? key, List<PageRouteInfo>? children})
    : super(
        RealmRoute.name,
        args: RealmRouteArgs(realmId: realmId, key: key),
        rawPathParams: {'realmId': realmId},
        initialChildren: children,
      );

  static const String name = 'RealmRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RealmRouteArgs>(
        orElse: () => RealmRouteArgs(realmId: pathParams.getString('realmId')),
      );
      return RealmPage(realmId: args.realmId, key: args.key);
    },
  );
}

class RealmRouteArgs {
  const RealmRouteArgs({required this.realmId, this.key});

  final String realmId;

  final Key? key;

  @override
  String toString() {
    return 'RealmRouteArgs{realmId: $realmId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RealmRouteArgs) return false;
    return realmId == other.realmId && key == other.key;
  }

  @override
  int get hashCode => realmId.hashCode ^ key.hashCode;
}

/// generated route for
/// [ResourcePage]
class ResourceRoute extends PageRouteInfo<ResourceRouteArgs> {
  ResourceRoute({
    required String resourceId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ResourceRoute.name,
         args: ResourceRouteArgs(resourceId: resourceId, key: key),
         rawPathParams: {'resourceId': resourceId},
         initialChildren: children,
       );

  static const String name = 'ResourceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ResourceRouteArgs>(
        orElse: () =>
            ResourceRouteArgs(resourceId: pathParams.getString('resourceId')),
      );
      return ResourcePage(resourceId: args.resourceId, key: args.key);
    },
  );
}

class ResourceRouteArgs {
  const ResourceRouteArgs({required this.resourceId, this.key});

  final String resourceId;

  final Key? key;

  @override
  String toString() {
    return 'ResourceRouteArgs{resourceId: $resourceId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResourceRouteArgs) return false;
    return resourceId == other.resourceId && key == other.key;
  }

  @override
  int get hashCode => resourceId.hashCode ^ key.hashCode;
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
