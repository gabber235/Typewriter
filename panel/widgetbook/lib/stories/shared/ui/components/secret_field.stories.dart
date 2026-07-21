import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Invite Link with Prefix", type: SecretField)
Widget secretFieldInviteLinkUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: "Title",
    initialValue: "Invite Link",
  );
  final description = context.knobs.string(
    label: "Description",
    initialValue:
        "Generate a unique invite link to share with team members. The link will expire after a set time for security.",
  );
  final ms = context.knobs.int.input(label: "Delay (ms)", initialValue: 1500);
  final expirySeconds = context.knobs.int.input(
    label: "Expiry (seconds)",
    initialValue: 30,
  );

  return FakeApp(
    child: SizedBox(
      width: 600,
      child: SecretField(
        title: title,
        description: description,
        prefix: "https://panel.typewritermc.com/join/",
        onGenerate: () async {
          await Future<void>.delayed(Duration(milliseconds: ms));
          return SecretFieldRevealed(
            value: "abc123xyz789",
            expiresAt: DateTime.now().add(Duration(seconds: expirySeconds)),
          );
        },
        generateButtonText: "Generate Link",
        regenerateButtonText: "New Link",
        copyButtonText: "Copy Link",
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Minecraft Server Command", type: SecretField)
Widget secretFieldMinecraftCommandUseCase(BuildContext context) {
  return FakeApp(
    child: SizedBox(
      width: 600,
      child: SecretField(
        title: "Server Connection Command",
        description:
            "Generate a one-time command to link your Minecraft server. Run this command in your server console.",
        prefix: "/typewriter link ",
        generateButtonText: "Generate Command",
        regenerateButtonText: "New Command",
        copyButtonText: "Copy Command",
        onGenerate: () async {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          return SecretFieldRevealed(
            value: "tk_abc123xyz789def456",
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          );
        },
      ),
    ),
  );
}

@widgetbook.UseCase(name: "API Key (No Prefix)", type: SecretField)
Widget secretFieldApiKeyUseCase(BuildContext context) {
  return FakeApp(
    child: SizedBox(
      width: 500,
      child: SecretField(
        title: "API Key",
        description:
            "Generate a temporary API key for testing. This key will expire and should not be used in production.",
        generateButtonText: "Generate Key",
        regenerateButtonText: "Regenerate",
        onGenerate: () async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          return SecretFieldRevealed(
            value: "tw_live_4eC39HqLyjWDarjtT1zdp7dc",
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          );
        },
      ),
    ),
  );
}

@widgetbook.UseCase(name: "State Transitions", type: SecretField)
Widget secretFieldStateTransitionsUseCase(BuildContext context) {
  return FakeApp(
    child: HookBuilder(
      builder: (context) {
        final copiedNotifier = useState(false);
        final expiredNotifier = useState(false);

        return SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SecretField(
                title: "Interactive Demo",
                description:
                    "Click Generate to see all state transitions. Watch the countdown timer and try both copy buttons.",
                prefix: "https://example.com/secret/",
                onGenerate: () async {
                  copiedNotifier.value = false;
                  expiredNotifier.value = false;
                  await Future<void>.delayed(
                    const Duration(milliseconds: 2000),
                  );
                  return SecretFieldRevealed(
                    value: "demo_12345",
                    expiresAt: DateTime.now().add(const Duration(seconds: 15)),
                  );
                },
                onCopied: () => copiedNotifier.value = true,
                onExpired: () => expiredNotifier.value = true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatusIndicator(
                    label: "Copied",
                    isActive: copiedNotifier.value,
                  ),
                  const SizedBox(width: 16),
                  _StatusIndicator(
                    label: "Expired",
                    isActive: expiredNotifier.value,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

@widgetbook.UseCase(name: "Quick Expiry (10s)", type: SecretField)
Widget secretFieldQuickExpiryUseCase(BuildContext context) {
  return FakeApp(
    child: SizedBox(
      width: 500,
      child: SecretField(
        title: "Quick Expiry Demo",
        description:
            "This secret expires in just 10 seconds to demonstrate the urgent expiry state.",
        onGenerate: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return SecretFieldRevealed(
            value: "quick_expire_token_xyz",
            expiresAt: DateTime.now().add(const Duration(seconds: 10)),
          );
        },
      ),
    ),
  );
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isActive ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
