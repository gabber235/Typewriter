import "package:typewriter_panel/typewriter_panel.dart";

part "realm_inbox_status.freezed.dart";

/// The complete visible inbox status, independent of live commands and details.
@freezed
sealed class RealmInboxStatus with _$RealmInboxStatus {
  const factory RealmInboxStatus.quiet() = QuietInboxStatus;
  const factory RealmInboxStatus.attention(int issueCount) =
      AttentionInboxStatus;
  const factory RealmInboxStatus.checking() = CheckingInboxStatus;
  const factory RealmInboxStatus.publishing() = PublishingInboxStatus;
  const factory RealmInboxStatus.ready() = ReadyInboxStatus;
}

extension RealmInboxStatusProjection on RealmInboxState {
  RealmInboxStatus get buttonStatus {
    if (issues.isNotEmpty) return RealmInboxStatus.attention(issues.length);
    return switch (publication) {
      BlockedRealmPublication() ||
      UnavailableRealmPublication() ||
      UncertainRealmPublication() => const RealmInboxStatus.attention(0),
      CheckingRealmPublication() => const RealmInboxStatus.checking(),
      PublishingRealmPublication() ||
      RequestActiveRealmPublication() => const RealmInboxStatus.publishing(),
      ReadyRealmPublication() => const RealmInboxStatus.ready(),
      CurrentRealmPublication() ||
      EmptyRealmPublication() => const RealmInboxStatus.quiet(),
    };
  }
}

/// Derives all decoration from the same displayed status and current theme.
extension RealmInboxStatusAppearance on RealmInboxStatus {
  String? get label => switch (this) {
    QuietInboxStatus() => null,
    AttentionInboxStatus(issueCount: 0) => "Needs attention",
    AttentionInboxStatus(:final issueCount) =>
      "$issueCount ${issueCount == 1 ? "issue" : "issues"}",
    CheckingInboxStatus() => "Checking",
    PublishingInboxStatus() => "Publishing",
    ReadyInboxStatus() => "Review changes",
  };

  String get semanticLabel => label == null
      ? "Realm inbox. Everything is published"
      : "Realm inbox. $label";

  IconData get icon => switch (this) {
    QuietInboxStatus() => Icons.inbox_outlined,
    AttentionInboxStatus() => Icons.error_outline,
    CheckingInboxStatus() || PublishingInboxStatus() => Icons.sync,
    ReadyInboxStatus() => Icons.publish,
  };

  Color iconColor(BuildContext context) => switch (this) {
    AttentionInboxStatus() => context.colors.warning,
    ReadyInboxStatus() => context.theme.colorScheme.primary,
    _ => context.colors.contentSecondary,
  };

  ButtonStyle buttonStyle(BuildContext context) => FilledButton.styleFrom(
    foregroundColor: switch (this) {
      QuietInboxStatus() => context.colors.contentSecondary,
      AttentionInboxStatus() => context.colors.onWarningContainer,
      _ => context.colors.onBrandContainer,
    },
    backgroundColor: switch (this) {
      QuietInboxStatus() => context.colors.surfaceRaised,
      AttentionInboxStatus() => context.colors.warningContainer,
      _ => context.colors.brandContainer,
    },
    side: BorderSide(color: iconColor(context).withValues(alpha: .22)),
    shape: context.shapes.mediumShape,
  );
}
