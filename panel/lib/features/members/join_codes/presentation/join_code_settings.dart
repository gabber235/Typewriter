import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Local editor for generation options.
///
/// Changes are emitted to the route but are not sent to the service until the
/// user generates a code. Default role selection comes from organization roles;
/// the service validates the selected role identifiers again.
/// [initialOptions] seeds local state only on mount. Enabling automatic
/// acceptance starts with the supplied catalog's default roles.
class JoinCodeSettings extends HookConsumerWidget {
  const JoinCodeSettings({
    required this.onOptionsChanged,
    required this.availableRoles,
    super.key,
    this.initialOptions = const JoinCodeOptions(),
  });

  final ValueChanged<JoinCodeOptions> onOptionsChanged;
  final JoinCodeOptions initialOptions;
  final List<skir.OrganizationRole> availableRoles;

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
    final chipStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Button(
          face: ButtonFace.bare,
          label: "",
          onPressed: () => isExpanded.value = !isExpanded.value,
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
                // The chip keeps its width; its word types in when the
                // options leave their defaults, and it is empty otherwise.
                AnimatedContainer(
                  duration: motionTimeline(context, MotionToken.ink).duration,
                  curve: motionTimeline(context, MotionToken.ink).curve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCustomized
                        ? theme.colorScheme.primaryContainer
                        : context.colors.clear,
                    borderRadius: context.shapes.smallBorderRadius,
                  ),
                  child: Stack(
                    children: [
                      ExcludeSemantics(
                        child: Opacity(
                          opacity: 0,
                          child: Text("Customized", style: chipStyle),
                        ),
                      ),
                      if (isCustomized)
                        MotionLabel(
                          "Customized",
                          typesIn: true,
                          style: chipStyle,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        AnimatedSize(
          // Grows with surfaceIn and shrinks with panelOut.
          duration: motionTimeline(context, MotionToken.surfaceIn).duration,
          reverseDuration: motionTimeline(
            context,
            MotionToken.panelOut,
          ).duration,
          curve: motionTimeline(
            context,
            isExpanded.value ? MotionToken.surfaceIn : MotionToken.panelOut,
          ).curve,
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
                              updateDuration(const Duration(days: 7));
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
        !_isDuration(options.expiration, const Duration(days: 7)) ||
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
