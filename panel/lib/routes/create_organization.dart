part of "route.dart";

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

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggerEntrance(
            child: Text(
              "Create organization",
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 24),
          const StaggerEntrance(child: SectionTitle(title: "Name")),
          StaggerEntrance(
            child: TextFormField(
              controller: nameController,
              inputFormatters: [SnakeCaseInputFormatter()],
              decoration: const InputDecoration(
                hintText: "Enter organization name",
              ),
              validator: _validateName,
            ),
          ),
          const SizedBox(height: 24),
          StaggerEntrance(
            child: _OrganizationIconPicker(
              iconUrl: iconUrl,
              onRandomize: () => randomSeed.value = _generateSeed(),
            ),
          ),
          const SizedBox(height: 32),
          StaggerEntrance(
            child: SizedBox(
              width: double.infinity,
              child: LoadingButton.filled(
                onPressed: () => _createOrganization(
                  context: context,
                  ref: ref,
                  formKey: formKey,
                  nameController: nameController,
                  seed: randomSeed.value,
                ),
                child: const Text("Create"),
              ),
            ),
          ),
        ],
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

    final navigator = ref.read(appRouterProvider);
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
      showErrorSnackBar(context, "$error");
    }
  }
}

class _OrganizationIconPicker extends StatelessWidget {
  const _OrganizationIconPicker({
    required this.iconUrl,
    required this.onRandomize,
  });

  final String iconUrl;
  final VoidCallback onRandomize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onRandomize,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OrganizationLogo(logoUrl: iconUrl, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: "Icon"),
                    const SizedBox(height: 4),
                    Text(
                      "For now, generated and can be randomized again by clicking the icon.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
