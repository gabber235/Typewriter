import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_badges.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_url.dart";
import "package:typewriter_panel/shared/ui/components/blur_reveal.dart";
import "package:typewriter_panel/shared/ui/components/countdown_badge.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";

class JoinCodeCard extends HookConsumerWidget {
  const JoinCodeCard({
    required this.code,
    required this.index,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final OrganizationJoinCode code;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpanded = useState(false);
    final isRevoking = useState(false);
    final fullUrl = joinCodeUrl(code.code);

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      child: isRevoking.value
          ? const SizedBox.shrink()
          : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          )
                        : Surface.colorOf(context),
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => isExpanded.value = !isExpanded.value,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => onSelectionChanged(!isSelected),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green
                                          : theme.colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSelected ? Icons.check : Icons.link,
                                      color: isSelected
                                          ? Colors.white
                                          : theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BlurReveal(
                                        blurSigma: 3,
                                        child: Text(
                                          fullUrl,
                                          style: TextStyle(
                                            fontFamily: "monospace",
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          CountdownBadge(
                                            endDate: code.expiresAt,
                                            onExpired: () => ref.invalidate(
                                              organizationJoinCodesProvider,
                                            ),
                                          ),
                                          JoinCodeTypeBadges(code: code),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded.value
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: isExpanded.value
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      height: 1,
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _copyToClipboard(
                                                context,
                                                fullUrl,
                                              ),
                                              icon: const Icon(
                                                Icons.copy,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                "Copy Join Code",
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _confirmRevokeCode(
                                                    context,
                                                    ref,
                                                    isRevoking,
                                                  ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    theme.colorScheme.error,
                                                side: BorderSide(
                                                  color: theme.colorScheme.error
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.link_off,
                                                size: 18,
                                              ),
                                              label: const Text("Revoke"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(duration: 200.ms)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                .slideY(
                  begin: 0.02,
                  end: 0,
                  duration: 300.ms,
                  delay: (50 * index).ms,
                ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Join code copied to clipboard"),
        duration: 2.seconds,
      ),
    );
  }

  Future<void> _confirmRevokeCode(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRevoking,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this join code?",
      content:
          "Are you sure you want to revoke this join code? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        isRevoking.value = true;
        onSelectionChanged(false);
        await ref
            .read(organizationJoinCodesProvider.notifier)
            .revokeCode(code.code);
      },
    );
  }
}

/// Expandable settings panel for join code generation.
/// This widget is designed to be used alongside SecretField without
/// the SecretField knowing about join code specifics.
