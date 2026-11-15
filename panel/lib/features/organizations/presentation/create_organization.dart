part of "route.dart";

/// Form for creating an organization and entering its workspace.
///
/// Validation protects the local identifier format before the provider performs
/// the authenticated mutation. The provider owns server errors and membership
/// reconciliation; this widget only reports them and navigates on success.
class _CreateOrganization extends HookConsumerWidget {
  const _CreateOrganization();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final randomSeed = useState(_generateSeed());
    final theme = Theme.of(context);

    useListenable(nameController);
    final iconUrl = _buildIconUrl(nameController.text, randomSeed.value);

    return SliverToBoxAdapter(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Enter(
              token: MotionToken.loadIn,
              child: Text(
                "Create organization",
                style: theme.textTheme.headlineMedium,
              ),
            ),
            SizedBox(height: context.spacing.space6),
            const Enter(
              token: MotionToken.loadIn,
              child: SectionTitle(title: "Name"),
            ),
            Enter(
              token: MotionToken.loadIn,
              child: EditorTextField(
                controller: nameController,
                inputFormatters: identifierInputFormatters,
                decoration: const InputDecoration(
                  hintText: "Enter organization name",
                ),
                validator: _validateName,
              ),
            ),
            SizedBox(height: context.spacing.space6),
            Enter(
              token: MotionToken.loadIn,
              child: OrganizationIconPicker(
                iconUrl: iconUrl,
                onRandomize: () => randomSeed.value = _generateSeed(),
              ),
            ),
            SizedBox(height: context.spacing.space8),
            Enter(
              token: MotionToken.loadIn,
              child: SizedBox(
                width: double.infinity,
                child: Button(
                  face: ButtonFace.filled,
                  label: "Create",
                  busyLabel: "Creating",
                  onPressed: () => _createOrganization(
                    context: context,
                    ref: ref,
                    formKey: formKey,
                    nameController: nameController,
                    seed: randomSeed.value,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _generateSeed() => Random().nextInt(1000000).toString();

  String _buildIconUrl(String name, String seed) {
    final iconSeed = name.isEmpty ? seed : name + seed;
    return generateOrganizationIconUrl(iconSeed);
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter an organization name.";
    }
    if (value.length < 3) {
      return "Name must be at least 3 characters long.";
    }
    if (!RegExp("^[a-z0-9]").hasMatch(value)) {
      return "Name must start with a lowercase letter or number.";
    }
    if (!RegExp(r"[a-z0-9]$").hasMatch(value)) {
      return "Name must end with a lowercase letter or number.";
    }
    if (!RegExp(r"^[a-z0-9_]+$").hasMatch(value)) {
      return "Name can only contain lowercase letters, numbers, and underscores.";
    }
    if (!RegExp(r"^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$").hasMatch(value)) {
      return "Name must be at least 3 characters, start and end with a letter or number, and only contain underscores in between.";
    }

    return null;
  }

  Future<void> _createOrganization({
    required BuildContext context,
    required WidgetRef ref,
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required String seed,
  }) async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    final navigator = ref.read(navigationRouterProvider);
    final logoUrl = _buildIconUrl(nameController.text, seed);

    try {
      final organizationId = await ref
          .read(organizationsProvider.notifier)
          .createOrganization(name: nameController.text, logoUrl: logoUrl);
      await navigator.push(
        OrganizationRoute(organizationId: organizationId.id),
      );
    } on Exception catch (error) {
      if (!context.mounted) {
        return;
      }
      context.reportFailure("Create organization failed", detail: "$error");
    }
  }
}
