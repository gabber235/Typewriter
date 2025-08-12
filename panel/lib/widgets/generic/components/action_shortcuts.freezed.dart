// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action_shortcuts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActionShortcut implements DiagnosticableTreeMixin {
  String get id;
  String get label;
  String get description;
  List<ShortcutActivator> get activators;
  int get priority;
  Widget? get icon;
  ActionInvoke? get onInvoke;
  GlobalKey? get owner;

  /// Create a copy of ActionShortcut
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ActionShortcutCopyWith<ActionShortcut> get copyWith =>
      _$ActionShortcutCopyWithImpl<ActionShortcut>(
          this as ActionShortcut, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ActionShortcut'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('label', label))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('activators', activators))
      ..add(DiagnosticsProperty('priority', priority))
      ..add(DiagnosticsProperty('icon', icon))
      ..add(DiagnosticsProperty('onInvoke', onInvoke))
      ..add(DiagnosticsProperty('owner', owner));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ActionShortcut &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other.activators, activators) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.onInvoke, onInvoke) ||
                other.onInvoke == onInvoke) &&
            (identical(other.owner, owner) || other.owner == owner));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      label,
      description,
      const DeepCollectionEquality().hash(activators),
      priority,
      icon,
      onInvoke,
      owner);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ActionShortcut(id: $id, label: $label, description: $description, activators: $activators, priority: $priority, icon: $icon, onInvoke: $onInvoke, owner: $owner)';
  }
}

/// @nodoc
abstract mixin class $ActionShortcutCopyWith<$Res> {
  factory $ActionShortcutCopyWith(
          ActionShortcut value, $Res Function(ActionShortcut) _then) =
      _$ActionShortcutCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String label,
      String description,
      List<ShortcutActivator> activators,
      int priority,
      Widget? icon,
      ActionInvoke? onInvoke,
      GlobalKey? owner});
}

/// @nodoc
class _$ActionShortcutCopyWithImpl<$Res>
    implements $ActionShortcutCopyWith<$Res> {
  _$ActionShortcutCopyWithImpl(this._self, this._then);

  final ActionShortcut _self;
  final $Res Function(ActionShortcut) _then;

  /// Create a copy of ActionShortcut
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? description = null,
    Object? activators = null,
    Object? priority = null,
    Object? icon = freezed,
    Object? onInvoke = freezed,
    Object? owner = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      activators: null == activators
          ? _self.activators
          : activators // ignore: cast_nullable_to_non_nullable
              as List<ShortcutActivator>,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      icon: freezed == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Widget?,
      onInvoke: freezed == onInvoke
          ? _self.onInvoke
          : onInvoke // ignore: cast_nullable_to_non_nullable
              as ActionInvoke?,
      owner: freezed == owner
          ? _self.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as GlobalKey?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ActionShortcut].
extension ActionShortcutPatterns on ActionShortcut {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ActionShortcut value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ActionShortcut() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ActionShortcut value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActionShortcut():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ActionShortcut value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActionShortcut() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String label,
            String description,
            List<ShortcutActivator> activators,
            int priority,
            Widget? icon,
            ActionInvoke? onInvoke,
            GlobalKey? owner)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ActionShortcut() when $default != null:
        return $default(
            _that.id,
            _that.label,
            _that.description,
            _that.activators,
            _that.priority,
            _that.icon,
            _that.onInvoke,
            _that.owner);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String label,
            String description,
            List<ShortcutActivator> activators,
            int priority,
            Widget? icon,
            ActionInvoke? onInvoke,
            GlobalKey? owner)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActionShortcut():
        return $default(
            _that.id,
            _that.label,
            _that.description,
            _that.activators,
            _that.priority,
            _that.icon,
            _that.onInvoke,
            _that.owner);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String label,
            String description,
            List<ShortcutActivator> activators,
            int priority,
            Widget? icon,
            ActionInvoke? onInvoke,
            GlobalKey? owner)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ActionShortcut() when $default != null:
        return $default(
            _that.id,
            _that.label,
            _that.description,
            _that.activators,
            _that.priority,
            _that.icon,
            _that.onInvoke,
            _that.owner);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ActionShortcut with DiagnosticableTreeMixin implements ActionShortcut {
  const _ActionShortcut(
      {required this.id,
      required this.label,
      required this.description,
      required final List<ShortcutActivator> activators,
      required this.priority,
      this.icon,
      this.onInvoke,
      this.owner})
      : _activators = activators;

  @override
  final String id;
  @override
  final String label;
  @override
  final String description;
  final List<ShortcutActivator> _activators;
  @override
  List<ShortcutActivator> get activators {
    if (_activators is EqualUnmodifiableListView) return _activators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activators);
  }

  @override
  final int priority;
  @override
  final Widget? icon;
  @override
  final ActionInvoke? onInvoke;
  @override
  final GlobalKey? owner;

  /// Create a copy of ActionShortcut
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ActionShortcutCopyWith<_ActionShortcut> get copyWith =>
      __$ActionShortcutCopyWithImpl<_ActionShortcut>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ActionShortcut'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('label', label))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('activators', activators))
      ..add(DiagnosticsProperty('priority', priority))
      ..add(DiagnosticsProperty('icon', icon))
      ..add(DiagnosticsProperty('onInvoke', onInvoke))
      ..add(DiagnosticsProperty('owner', owner));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ActionShortcut &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._activators, _activators) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.onInvoke, onInvoke) ||
                other.onInvoke == onInvoke) &&
            (identical(other.owner, owner) || other.owner == owner));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      label,
      description,
      const DeepCollectionEquality().hash(_activators),
      priority,
      icon,
      onInvoke,
      owner);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ActionShortcut(id: $id, label: $label, description: $description, activators: $activators, priority: $priority, icon: $icon, onInvoke: $onInvoke, owner: $owner)';
  }
}

/// @nodoc
abstract mixin class _$ActionShortcutCopyWith<$Res>
    implements $ActionShortcutCopyWith<$Res> {
  factory _$ActionShortcutCopyWith(
          _ActionShortcut value, $Res Function(_ActionShortcut) _then) =
      __$ActionShortcutCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      String description,
      List<ShortcutActivator> activators,
      int priority,
      Widget? icon,
      ActionInvoke? onInvoke,
      GlobalKey? owner});
}

/// @nodoc
class __$ActionShortcutCopyWithImpl<$Res>
    implements _$ActionShortcutCopyWith<$Res> {
  __$ActionShortcutCopyWithImpl(this._self, this._then);

  final _ActionShortcut _self;
  final $Res Function(_ActionShortcut) _then;

  /// Create a copy of ActionShortcut
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? description = null,
    Object? activators = null,
    Object? priority = null,
    Object? icon = freezed,
    Object? onInvoke = freezed,
    Object? owner = freezed,
  }) {
    return _then(_ActionShortcut(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      activators: null == activators
          ? _self._activators
          : activators // ignore: cast_nullable_to_non_nullable
              as List<ShortcutActivator>,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      icon: freezed == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as Widget?,
      onInvoke: freezed == onInvoke
          ? _self.onInvoke
          : onInvoke // ignore: cast_nullable_to_non_nullable
              as ActionInvoke?,
      owner: freezed == owner
          ? _self.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as GlobalKey?,
    ));
  }
}

// dart format on
