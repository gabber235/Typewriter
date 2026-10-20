import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the navigator presentation of [resource], such as the sections of
/// the realm root or the chapter tree of a Book, with [routedResource] marked
/// as routed. Activating a member opens its surface. The navigator binds the
/// resource for editing, so creation actions in it stage like any edit.
class AuthoredResourceNavigator extends ConsumerStatefulWidget {
  const AuthoredResourceNavigator({
    required this.scope,
    required this.resource,
    this.routedResource,
    this.showHeader = false,
    this.onOpen,
    super.key,
  });

  final AuthoringScope scope;
  final skir.ResourceId resource;
  final skir.ResourceId? routedResource;

  /// Shows the resource's name and icon above the navigator, opening the
  /// resource when activated.
  final bool showHeader;

  /// Runs before activating a member opens its surface, for example to close
  /// the sheet holding the navigator.
  final VoidCallback? onOpen;

  @override
  ConsumerState<AuthoredResourceNavigator> createState() =>
      _AuthoredResourceNavigatorState();
}

class _AuthoredResourceNavigatorState
    extends ConsumerState<AuthoredResourceNavigator> {
  RealmEditing? _workspace;
  RealmEditingBinding? _binding;

  void _updated() {
    if (mounted) setState(() {});
  }

  void _attach(RealmEditing workspace) {
    if (identical(workspace, _workspace) && _binding != null) return;
    _detach();
    _workspace = workspace;
    _binding = workspace.attach(widget.resource)..addListener(_updated);
  }

  void _detach() {
    _binding
      ?..removeListener(_updated)
      ..detach();
    _binding = null;
  }

  @override
  void didUpdateWidget(covariant AuthoredResourceNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource != widget.resource ||
        oldWidget.scope != widget.scope) {
      _detach();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(realmEditingProvider(widget.scope));
    final commands = ref.watch(authoredResourceCommandsProvider(widget.scope));
    _attach(workspace);
    final binding = _binding!;
    void open(skir.ResourceId target) {
      widget.onOpen?.call();
      ref.read(realmSurfaceNavigationProvider).open(widget.scope, target);
    }

    final navigator = AuthoredResourceEditor(
      resource: widget.resource,
      document: binding.document,
      edit: binding,
      role: skir.PresentationRole.navigator,
      budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
      watchSearch: commands.watchSearch,
      reload: commands.reload,
      prepareValue: commands.prepareValue,
      onStatus: binding.reportStatus,
      openResource: open,
      routedResource: widget.routedResource,
      enabled:
          workspace.state.available &&
          binding.document.entry(widget.resource) != null,
      readOnly: !binding.control.canEdit,
    );
    if (!widget.showHeader) return navigator;
    final appearance = ref.watch(
      resourceAppearanceProvider(widget.scope, widget.resource),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (appearance != null)
          ListTile(
            dense: true,
            selected: widget.routedResource == widget.resource,
            leading: ResourceIcon(
              icon: appearance.icon,
              color: appearance.accent,
              size: 20,
            ),
            title: Text(
              appearance.label,
              overflow: TextOverflow.ellipsis,
              style: context.theme.textTheme.titleSmall,
            ),
            onTap: () => open(widget.resource),
          ),
        navigator,
        if (binding.status case final message?) Text(message),
      ],
    );
  }
}

/// The shell sidebar's realm area: the navigator of the realm root, listing
/// every section.
class RealmSectionsNavigator extends ConsumerWidget {
  const RealmSectionsNavigator({required this.scope, super.key});

  final AuthoringScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = ref.watch(
      workingAuthoringDocumentProvider(scope)
          .select((document) => document.value?.realmRoot),
    );
    if (root == null) return const SizedBox.shrink();
    return AuthoredResourceNavigator(
      key: ValueKey(root),
      scope: scope,
      resource: root,
      routedResource: ref.watch(routedSectionProvider(scope)),
    );
  }
}
