part of "presentation_element.dart";

enum StatusTone {
  neutral,
  unknown,
  information,
  success,
  warning,
  danger,
  active,
  inactive,
  online,
  offline,
  pending,
  inProgress,
  paused,
}

@freezed
abstract class StatusAppearance with _$StatusAppearance {
  const factory StatusAppearance({
    required StatusTone tone,
    TypedExpression? label,
  }) = _StatusAppearance;
}

@freezed
abstract class StatusCase with _$StatusCase {
  const factory StatusCase({
    required DataValue match,
    required StatusAppearance appearance,
  }) = _StatusCase;
}
