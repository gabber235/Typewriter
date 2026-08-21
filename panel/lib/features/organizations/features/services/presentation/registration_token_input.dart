import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Binds a service registration token to the selected organization.
///
/// Validation happens before the request so malformed tokens never reach the
/// service API. A successful request clears the token while request failures
/// remain owned by the shared loading button error behavior.
class RegistrationTokenInput extends HookConsumerWidget {
  const RegistrationTokenInput({super.key});

  bool _isValidToken(String token) => RegExp(r"^[A-Z0-9]{10}$").hasMatch(token);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final loading = useLoadingButtonController();
    final error = useState<String?>(null);

    Future<void> bind() async {
      final token = controller.text.trim();
      if (!_isValidToken(token)) {
        error.value = "Token must be 10 uppercase alphanumeric characters";
        return;
      }
      error.value = null;
      await ref.read(servicesProvider.notifier).bindService(token);
      controller.clear();
    }

    final input = EditorTextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: "Enter registration token",
        prefixIcon: const Icon(Icons.key),
        errorText: error.value,
      ),
      onChanged: (value) {
        if (error.value != null && _isValidToken(value.trim())) {
          error.value = null;
        }
      },
      onSubmitted: loading.canTrigger ? (_) => loading.trigger() : null,
    );
    final button = LoadingButton(
      controller: loading,
      onPressed: bind,
      child: const Text("Connect"),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              input,
              SizedBox(height: context.spacing.space2),
              button,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: input),
            SizedBox(width: context.spacing.space3),
            button,
          ],
        );
      },
    );
  }
}
