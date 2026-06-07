import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/l10n/app_localizations.dart";
import "package:typewriter/l10n/locale_provider.dart";

part "l10n_provider.g.dart";

@riverpod
AppLocalizations l10n(L10nRef ref) {
  final locale = ref.watch(localeControllerProvider);
  return lookupAppLocalizations(locale);
}