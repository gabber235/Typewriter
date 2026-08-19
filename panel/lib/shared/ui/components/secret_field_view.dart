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
        SizedBox(height: context.spacing.space1),
        Text(
          field.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.spacing.space3),
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
          padding: EdgeInsets.all(context.spacing.space4),
          child: _buildSecretDisplay(context),
        ),
        SizedBox(height: context.spacing.space3),
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
      runSpacing: context.spacing.space2,
      spacing: context.spacing.space2,
      children: [
        Wrap(
          runSpacing: context.spacing.space2,
          spacing: context.spacing.space2,
          children: [
            if (state is SecretFieldRevealed) ...[
              CountdownBadge(endDate: (state as SecretFieldRevealed).expiresAt),
              SizedBox(width: context.spacing.space2),
            ],

            if (state is SecretFieldExpired) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: context.spacing.space1,
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
                    SizedBox(width: context.spacing.space1),
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
              SizedBox(width: context.spacing.space2),
            ],
          ],
        ),
        Wrap(
          spacing: context.spacing.space2,
          runSpacing: context.spacing.space2,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.space3,
                    vertical: context.spacing.space2,
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
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space4,
                  vertical: context.spacing.space2,
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
