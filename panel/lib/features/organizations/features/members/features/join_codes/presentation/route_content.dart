import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_actions.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_list.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_settings.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_table.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/presentation/join_code_url.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/loading_indicator.dart";
import "package:typewriter_panel/shared/ui/components/secret_field.dart";
import "package:typewriter_panel/shared/ui/screens/error_screen.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

class JoinCodesTab extends HookConsumerWidget {
  const JoinCodesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codesAsync = ref.watch(organizationJoinCodesProvider);
    final rolesAsync = ref.watch(organizationRolesProvider);
    final selectedCodes = useState<Set<skir.RecordId>>({});
    final joinCodeOptions = useState(const JoinCodeOptions());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SecretField(
                  title: "Join Code",
                  description:
                      "Generate a unique join code to invite new members to your organization.",
                  prefix: joinCodeUrlPrefix,
                  onGenerate: () => ref
                      .read(organizationJoinCodesProvider.notifier)
                      .generateCode(options: joinCodeOptions.value),
                  generateButtonText: "Generate Join Code",
                  regenerateButtonText: "New Join Code",
                  copyButtonText: "Copy Join Code",
                  copiedSnackbarText: "Join code copied to clipboard",
                ),
                const SizedBox(height: 8),
                rolesAsync.when(
                  data: (roles) => JoinCodeSettings(
                    initialOptions: joinCodeOptions.value,
                    availableRoles: roles,
                    onOptionsChanged: (options) =>
                        joinCodeOptions.value = options,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Text("Active Join Codes", style: theme.textTheme.titleMedium),
              if (selectedCodes.value.isNotEmpty)
                BulkJoinCodeActions(
                  selectedCount: selectedCodes.value.length,
                  selectedCodes: selectedCodes.value,
                  onClearSelection: () => selectedCodes.value = {},
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        codesAsync(
          name: "Join Codes",
          builder: (codes) => context.isDesktop
              ? JoinCodesTable(codes: codes, selectedCodes: selectedCodes)
              : JoinCodesCardList(codes: codes, selectedCodes: selectedCodes),
          loading: (name) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LoadingIndicator(message: "Loading $name..."),
            ),
          ),
          error: (title, message) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ErrorScreen.small(title: title, message: message),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
