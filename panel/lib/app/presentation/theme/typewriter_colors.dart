import "package:flutter/material.dart";

@immutable
class TypewriterColors extends ThemeExtension<TypewriterColors> {
  const TypewriterColors({
    required this.brand,
    required this.onBrand,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.canvas,
    required this.panel,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceRaised,
    required this.surfaceEmphasized,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentDisabled,
    required this.contentInverse,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.focusRing,
    required this.selection,
    required this.onSelection,
    required this.selectionContainer,
    required this.onSelectionContainer,
    required this.shadow,
    required this.scrim,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.online,
    required this.onOnline,
    required this.onlineContainer,
    required this.onOnlineContainer,
    required this.offline,
    required this.onOffline,
    required this.offlineContainer,
    required this.onOfflineContainer,
  });

  final Color brand;
  final Color onBrand;
  final Color brandContainer;
  final Color onBrandContainer;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color canvas;
  final Color panel;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceRaised;
  final Color surfaceEmphasized;
  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentDisabled;
  final Color contentInverse;
  final Color border;
  final Color borderSubtle;
  final Color divider;
  final Color focusRing;
  final Color selection;
  final Color onSelection;
  final Color selectionContainer;
  final Color onSelectionContainer;
  final Color shadow;
  final Color scrim;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color online;
  final Color onOnline;
  final Color onlineContainer;
  final Color onOnlineContainer;
  final Color offline;
  final Color onOffline;
  final Color offlineContainer;
  final Color onOfflineContainer;

  @override
  TypewriterColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? brandContainer,
    Color? onBrandContainer,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? canvas,
    Color? panel,
    Color? surface,
    Color? surfaceContainer,
    Color? surfaceRaised,
    Color? surfaceEmphasized,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? contentDisabled,
    Color? contentInverse,
    Color? border,
    Color? borderSubtle,
    Color? divider,
    Color? focusRing,
    Color? selection,
    Color? onSelection,
    Color? selectionContainer,
    Color? onSelectionContainer,
    Color? shadow,
    Color? scrim,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? online,
    Color? onOnline,
    Color? onlineContainer,
    Color? onOnlineContainer,
    Color? offline,
    Color? onOffline,
    Color? offlineContainer,
    Color? onOfflineContainer,
  }) => TypewriterColors(
    brand: brand ?? this.brand,
    onBrand: onBrand ?? this.onBrand,
    brandContainer: brandContainer ?? this.brandContainer,
    onBrandContainer: onBrandContainer ?? this.onBrandContainer,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentContainer: accentContainer ?? this.accentContainer,
    onAccentContainer: onAccentContainer ?? this.onAccentContainer,
    canvas: canvas ?? this.canvas,
    panel: panel ?? this.panel,
    surface: surface ?? this.surface,
    surfaceContainer: surfaceContainer ?? this.surfaceContainer,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceEmphasized: surfaceEmphasized ?? this.surfaceEmphasized,
    contentPrimary: contentPrimary ?? this.contentPrimary,
    contentSecondary: contentSecondary ?? this.contentSecondary,
    contentDisabled: contentDisabled ?? this.contentDisabled,
    contentInverse: contentInverse ?? this.contentInverse,
    border: border ?? this.border,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    divider: divider ?? this.divider,
    focusRing: focusRing ?? this.focusRing,
    selection: selection ?? this.selection,
    onSelection: onSelection ?? this.onSelection,
    selectionContainer: selectionContainer ?? this.selectionContainer,
    onSelectionContainer: onSelectionContainer ?? this.onSelectionContainer,
    shadow: shadow ?? this.shadow,
    scrim: scrim ?? this.scrim,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
    infoContainer: infoContainer ?? this.infoContainer,
    onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerContainer: dangerContainer ?? this.dangerContainer,
    onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    online: online ?? this.online,
    onOnline: onOnline ?? this.onOnline,
    onlineContainer: onlineContainer ?? this.onlineContainer,
    onOnlineContainer: onOnlineContainer ?? this.onOnlineContainer,
    offline: offline ?? this.offline,
    onOffline: onOffline ?? this.onOffline,
    offlineContainer: offlineContainer ?? this.offlineContainer,
    onOfflineContainer: onOfflineContainer ?? this.onOfflineContainer,
  );

  @override
  TypewriterColors lerp(covariant TypewriterColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return copyWith(
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandContainer: l(brandContainer, other.brandContainer),
      onBrandContainer: l(onBrandContainer, other.onBrandContainer),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentContainer: l(accentContainer, other.accentContainer),
      onAccentContainer: l(onAccentContainer, other.onAccentContainer),
      canvas: l(canvas, other.canvas),
      panel: l(panel, other.panel),
      surface: l(surface, other.surface),
      surfaceContainer: l(surfaceContainer, other.surfaceContainer),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceEmphasized: l(surfaceEmphasized, other.surfaceEmphasized),
      contentPrimary: l(contentPrimary, other.contentPrimary),
      contentSecondary: l(contentSecondary, other.contentSecondary),
      contentDisabled: l(contentDisabled, other.contentDisabled),
      contentInverse: l(contentInverse, other.contentInverse),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      divider: l(divider, other.divider),
      focusRing: l(focusRing, other.focusRing),
      selection: l(selection, other.selection),
      onSelection: l(onSelection, other.onSelection),
      selectionContainer: l(selectionContainer, other.selectionContainer),
      onSelectionContainer: l(onSelectionContainer, other.onSelectionContainer),
      shadow: l(shadow, other.shadow),
      scrim: l(scrim, other.scrim),
      info: l(info, other.info),
      onInfo: l(onInfo, other.onInfo),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
      online: l(online, other.online),
      onOnline: l(onOnline, other.onOnline),
      onlineContainer: l(onlineContainer, other.onlineContainer),
      onOnlineContainer: l(onOnlineContainer, other.onOnlineContainer),
      offline: l(offline, other.offline),
      onOffline: l(onOffline, other.onOffline),
      offlineContainer: l(offlineContainer, other.offlineContainer),
      onOfflineContainer: l(onOfflineContainer, other.onOfflineContainer),
    );
  }
}
