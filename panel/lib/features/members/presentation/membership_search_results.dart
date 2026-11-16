import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A member in the primary search: their name over the roles they hold.
class MemberSearchResultItem extends StatelessWidget {
  const MemberSearchResultItem({
    required this.member,
    required this.row,
    super.key,
  });

  final skir.OrganizationMember member;
  final SearchResultRowContext row;

  @override
  Widget build(BuildContext context) {
    return _MembershipSearchResult(
      row: row,
      title: member.searchTitle,
      detail: member.rolesLine,
      icon: MaterialSymbols.person_rounded,
      kind: "member",
    );
  }
}

/// A join code in the primary search: the roles it grants and how often it
/// works. The link itself stays on the join codes page, where it is blurred.
class JoinCodeSearchResultItem extends StatelessWidget {
  const JoinCodeSearchResultItem({
    required this.code,
    required this.row,
    super.key,
  });

  final JoinCodeSearchItem code;
  final SearchResultRowContext row;

  @override
  Widget build(BuildContext context) {
    return _MembershipSearchResult(
      row: row,
      title: "Join code",
      detail: code.detail,
      icon: MaterialSymbols.key,
      kind: "join code",
    );
  }
}

/// A pending join request in the primary search: who asks, over their email
/// when their name is known.
class JoinRequestSearchResultItem extends StatelessWidget {
  const JoinRequestSearchResultItem({
    required this.request,
    required this.row,
    super.key,
  });

  final skir.OrganizationJoinRequest request;
  final SearchResultRowContext row;

  @override
  Widget build(BuildContext context) {
    return _MembershipSearchResult(
      row: row,
      title: request.searchTitle,
      detail: request.userName == null
          ? "Waiting for approval"
          : request.userEmail ?? "Waiting for approval",
      icon: MaterialSymbols.person_add,
      kind: "join request",
    );
  }
}

class _MembershipSearchResult extends StatelessWidget {
  const _MembershipSearchResult({
    required this.row,
    required this.title,
    required this.detail,
    required this.icon,
    required this.kind,
  });

  final SearchResultRowContext row;
  final String title;
  final String detail;
  final String icon;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SearchResultRow(
      row: row,
      density: SearchResultDensity.card,
      title: title,
      leading: Icones(icon),
      kindLabel: kind,
      body: Text(
        detail,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
