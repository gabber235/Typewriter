import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class JoinCodeSettings extends HookConsumerWidget {
  const JoinCodeSettings({
    required this.onOptionsChanged,
    required this.availableRoles,
    super.key,
    this.initialOptions = const JoinCodeOptions(),
  });

  final ValueChanged<JoinCodeOptions> onOptionsChanged;
  final JoinCodeOptions initialOptions;
  final List<OrganizationRole> availableRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpanded = useState(false);
    final options = useState(initialOptions);

    void updateOptions(JoinCodeOptions newOptions) {
      options.value = newOptions;
      onOptionsChanged(newOptions);
    }

    void updateDuration(Duration duration) {
      updateOptions(
        options.value.copyWith(
          expiration: JoinCodeExpiration.duration(duration),
        ),
      );
    }

    final isCustomized = _hasNonDefaultOptions(options.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => isExpanded.value = !isExpanded.value,
          borderRadius: context.shapes.mediumBorderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.spacing.space2),
            child: Row(
              children: [
                Icon(
                  isExpanded.value ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: context.spacing.space2),
                Text(
                  "Advanced options",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: context.spacing.space2),
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: context.shapes.smallBorderRadius,
                      ),
                      child: Text(
                        "Customized",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                    .animate(target: isCustomized ? 1.0 : 0.0)
                    .scaleXY(
                      begin: 0.7,
                      end: 1.0,
                      duration: isCustomized ? 750.ms : 400.ms,
                      curve: isCustomized
                          ? ElasticOutCurve(0.4)
                          : Curves.fastOutSlowIn,
                    )
                    .fade(begin: 0.0, end: 1.0, duration: 400.ms),
              ],
            ),
          ),
        ),

        AnimatedSize(
          duration: 200.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: isExpanded.value
              ? Container(
                  margin: EdgeInsets.only(top: context.spacing.space2),
                  padding: EdgeInsets.all(context.spacing.space4),
                  decoration: BoxDecoration(
                    color: Surface.colorOf(context),
                    borderRadius: context.shapes.largeBorderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingRow(
                        title: "Single-use",
                        description: "Code becomes invalid after first use",
                        trailing: Switch(
                          value: options.value.singleUse,
                          onChanged: (value) => updateOptions(
                            options.value.copyWith(singleUse: value),
                          ),
                        ),
                      ),
                      const Divider(height: 24),

                      SettingRow(
                        title: "Expires after",
                        description: "How long the join code stays active",
                        trailing: Switch(
                          value: !_isNeverExpires(options.value.expiration),
                          onChanged: (enabled) {
                            if (enabled) {
                              updateDuration(7.days);
                            } else {
                              updateOptions(
                                options.value.copyWith(
                                  expiration: const JoinCodeExpiration.never(),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      if (!_isNeverExpires(options.value.expiration)) ...[
                        SizedBox(height: context.spacing.space3),
                        SizedBox(height: context.spacing.space3),
                        DurationInput(
                          duration:
                              (options.value.expiration
                                      as JoinCodeExpirationDuration)
                                  .duration,
                          onDurationChanged: updateDuration,
                        ),
                      ],
                      const Divider(height: 24),

                      SettingRow(
                        title: "Auto-accept",
                        description:
                            "Automatically accept users without approval",
                        trailing: Switch(
                          value: options.value.autoAcceptRoleIds.isNotEmpty,
                          onChanged: (enabled) {
                            if (enabled) {
                              // Default to default roles
                              final defaultRoleIds = availableRoles
                                  .where((r) => r.defaultRole)
                                  .map((r) => r.roleId)
                                  .toList();

                              assert(
                                defaultRoleIds.isNotEmpty,
                                "Database should have never allowed to not have any default roles",
                              );

                              updateOptions(
                                options.value.copyWith(
                                  autoAcceptRoleIds: defaultRoleIds,
                                ),
                              );
                            } else {
                              updateOptions(
                                options.value.copyWith(autoAcceptRoleIds: []),
                              );
                            }
                          },
                        ),
                      ),

                      if (options.value.autoAcceptRoleIds.isNotEmpty) ...[
                        SizedBox(height: context.spacing.space3),
                        Text(
                          "Roles to assign:",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: context.spacing.space2),
                        RoleMultiselectChips(
                          availableRoles: availableRoles,
                          selectedRoles: availableRoles
                              .where(
                                (role) => options.value.autoAcceptRoleIds
                                    .contains(role.roleId),
                              )
                              .toList(),
                          onRolesChanged: (newRoles) {
                            updateOptions(
                              options.value.copyWith(
                                autoAcceptRoleIds: newRoles
                                    .map((role) => role.roleId)
                                    .toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  bool _hasNonDefaultOptions(JoinCodeOptions options) {
    return !options.singleUse ||
        !_isDuration(options.expiration, 7.days) ||
        options.autoAcceptRoleIds.isNotEmpty;
  }

  bool _isNeverExpires(JoinCodeExpiration expiration) {
    return expiration is JoinCodeExpirationNever;
  }

  bool _isDuration(JoinCodeExpiration expiration, Duration target) {
    if (expiration is! JoinCodeExpirationDuration) return false;
    return expiration.duration == target;
  }
}
