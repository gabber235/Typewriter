part of "secret_field.dart";

class _SecretFieldView extends StatelessWidget {
  const _SecretFieldView({required this.field, required this.controller});

  final SecretField field;
  final _SecretFieldController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          field.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _SecretFieldContent(
          state: controller.state,
          prefix: field.prefix,
          generateButtonText: field.generateButtonText,
          regenerateButtonText: field.regenerateButtonText,
          copyButtonText: field.copyButtonText,
          expiredText: field.expiredText,
          onGenerate: controller.generate,
          onCopy: controller.copy,
        ),
      ],
    );
  }
}

class _SecretFieldContent extends StatelessWidget {
  const _SecretFieldContent({
    required this.state,
    required this.prefix,
    required this.generateButtonText,
    required this.regenerateButtonText,
    required this.copyButtonText,
    required this.expiredText,
    required this.onGenerate,
    required this.onCopy,
  });

  final SecretFieldState state;
  final String? prefix;
  final String generateButtonText;
  final String regenerateButtonText;
  final String copyButtonText;
  final String expiredText;
  final Future<void> Function() onGenerate;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: .circular(12),
          ),
          padding: const .all(16),
          child: _buildSecretDisplay(context),
        ),
        const SizedBox(height: 12),
        _buildActions(context),
      ],
    );
  }

  Widget _buildSecretDisplay(BuildContext context) {
    final hasPrefix = prefix != null;

    return switch (state) {
      SecretFieldIdle() => _ConcealedDisplay(
        prefix: prefix,
        hasPrefix: hasPrefix,
      ),
      SecretFieldLoading() => _TypewriterLoadingDisplay(
        prefix: prefix,
        hasPrefix: hasPrefix,
      ),
      SecretFieldRevealed(:final value) => _RevealedDisplay(
        prefix: prefix,
        value: value,
      ),
      SecretFieldExpired(:final value) => _ExpiredDisplay(
        prefix: prefix,
        value: value,
      ),
      SecretFieldError() => _ConcealedDisplay(
        prefix: prefix,
        hasPrefix: hasPrefix,
      ),
    };
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIdle = state is SecretFieldIdle;
    final isError = state is SecretFieldError;
    final canCopy = state is SecretFieldRevealed;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 8,
      spacing: 8,
      children: [
        Wrap(
          runSpacing: 8,
          spacing: 8,
          children: [
            if (state is SecretFieldRevealed) ...[
              CountdownBadge(endDate: (state as SecretFieldRevealed).expiresAt),
              const SizedBox(width: 8),
            ],

            if (state is SecretFieldExpired) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: context.shapes.largeBorderRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icones(
                      MaterialSymbols.timer_off_rounded,
                      size: 14,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      expiredText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            if (canCopy)
              LoadingButton.textIcon(
                onPressed: onCopy,
                icon: const Icones(
                  MaterialSymbols.content_copy_rounded,
                  size: 16,
                ),
                label: Text(copyButtonText),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            LoadingButton.filledIcon(
              onPressed: onGenerate,
              icon: const Icones(MaterialSymbols.autorenew_rounded, size: 16),
              label: Text(
                isIdle || isError ? generateButtonText : regenerateButtonText,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isError ? colorScheme.error : null,
                foregroundColor: isError ? colorScheme.onError : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
