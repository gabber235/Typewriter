import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_badges.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_url.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class JoinCodeCard extends HookConsumerWidget {
  const JoinCodeCard({
    required this.code,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.hasSelection,
    required this.onRevokeSelection,
    super.key,
  });

  final OrganizationJoinCode code;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool hasSelection;
  final Future<void> Function() onRevokeSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expansibleController = useExpansibleController();
    final fullUrl = joinCodeUrl(code.code);

    useListenable(expansibleController);

    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : expansibleController.isExpanded
        ? theme.cardColor
        : Surface.colorOf(context);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Surface(
        color: backgroundColor,
        child: Expansible(
          controller: expansibleController,
          animationStyle: AnimationStyle(
            duration: 500.ms,
            curve: ElasticOutCurve(0.9),
            reverseDuration: 20.ms,
            reverseCurve: Curves.easeInCubic,
          ),
          headerBuilder: (context, animation) => ManagedActionSet(
            shortcuts: [
              ActionShortcut.intent(
                id: "select_join_code_${code.code}",
                label: "Select join code",
                description: "Toggle selection for this join code",
                intent: ActivateIntent,
                priority: 1,
                onInvoke: (_) => onSelectionChanged(!isSelected),
              ),
              ActionShortcut.intent(
                id: "select_all_join_codes_${code.code}",
                label: "Select all join codes",
                description: "Select all visible join codes",
                intent: ActivateAllIntent,
                priority: 1,
                onInvoke: (_) => onSelectAll(),
              ),
              ActionShortcut.intent(
                id: "clear_join_code_selection_${code.code}",
                label: "Clear selection",
                description: "Clear selected join codes",
                intent: DismissIntent,
                priority: 1,
                onInvoke: (_) => onClearSelection(),
              ),
              if (!hasSelection)
                ActionShortcut(
                  id: "copy_join_code_${code.code}",
                  label: "Copy join code",
                  description: "Copy this join code",
                  activators: const [SingleActivator(LogicalKeyboardKey.keyC)],
                  priority: 1,
                  onInvoke: (_) => _copyToClipboard(context, fullUrl),
                ),
              ActionShortcut.intent(
                id: "revoke_join_code_key_${code.code}",
                label: "Revoke join code",
                description: "Revoke this join code",
                intent: DeleteIntent,
                priority: 1,
                onInvoke: (_) => hasSelection && isSelected
                    ? onRevokeSelection()
                    : _confirmRevokeCode(context, ref),
              ),
            ],
            child: InkWell(
              onTap: expansibleController.toggle,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => onSelectionChanged(!isSelected),
                      child: CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.green
                            : theme.colorScheme.primaryContainer,
                        child: Icon(
                          isSelected ? Icons.check : Icons.link,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlurReveal(
                            blurSigma: 3,
                            child: Text(
                              fullUrl,
                              style: const TextStyle(
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
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              CountdownBadge(
                                endDate: code.expiresAt,
                                onExpired: () {
                                  onSelectionChanged(false);
                                  ref
                                      .read(
                                        organizationJoinCodesProvider.notifier,
                                      )
                                      .cleanupExpiredCodes();
                                },
                              ),
                              JoinCodeTypeBadges(code: code),
                            ],
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: Tween<double>(
                        begin: 0,
                        end: 0.5,
                      ).animate(animation),
                      child: Icon(
                        Icons.expand_less_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bodyBuilder: (context, animation) => ElasticMessageTransition(
            animation: animation,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    alignment: .center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(context, fullUrl),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text("Copy Join Code"),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _confirmRevokeCode(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text("Revoke"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackBar(context, "Join code copied to clipboard");
  }

  Future<void> _confirmRevokeCode(BuildContext context, WidgetRef ref) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this join code?",
      content:
          "Are you sure you want to revoke this join code? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        onSelectionChanged(false);
        await ref
            .read(organizationJoinCodesProvider.notifier)
            .revokeCode(code.code);
      },
    );
  }
}
