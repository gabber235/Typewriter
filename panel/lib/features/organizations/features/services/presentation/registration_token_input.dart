import "package:typewriter_panel/typewriter_panel.dart";

/// Binds a service registration token to the selected organization.
///
/// Validation happens before the request so malformed tokens never reach the
/// service API. A successful request clears the input after the application
/// provider accepts the bind. Provider failures are passed to [LoadingButton],
/// which owns the in progress and error presentation for the request.
class RegistrationTokenInput extends HookConsumerWidget {
  const RegistrationTokenInput({super.key});

  /// Matches the registration token format accepted by the panel boundary.
  ///
  /// Trimming is performed by the submitter, not here, so this predicate also
  /// remains useful while deciding whether an input error can be cleared.
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
      final organization = ref.read(organizationIdProvider);
      if (organization == null) throw ApiException.noOrganization();
      final repository = ref
          .read(resourceRepositoriesProvider)
          .services(organization);
      final response = await ref
          .read(localWorkControllerProvider)
          .execute(repository.bind(token));
      response.requireAcceptedBinding();
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
