// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'module_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModuleVersion {
  @_SemverFlexibleConverter()
  Version get version;
  ModuleVersionState get state;

  /// Create a copy of ModuleVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ModuleVersionCopyWith<ModuleVersion> get copyWith =>
      _$ModuleVersionCopyWithImpl<ModuleVersion>(
          this as ModuleVersion, _$identity);

  /// Serializes this ModuleVersion to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ModuleVersion &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, state);

  @override
  String toString() {
    return 'ModuleVersion(version: $version, state: $state)';
  }
}

/// @nodoc
abstract mixin class $ModuleVersionCopyWith<$Res> {
  factory $ModuleVersionCopyWith(
          ModuleVersion value, $Res Function(ModuleVersion) _then) =
      _$ModuleVersionCopyWithImpl;
  @useResult
  $Res call(
      {@_SemverFlexibleConverter() Version version, ModuleVersionState state});
}

/// @nodoc
class _$ModuleVersionCopyWithImpl<$Res>
    implements $ModuleVersionCopyWith<$Res> {
  _$ModuleVersionCopyWithImpl(this._self, this._then);

  final ModuleVersion _self;
  final $Res Function(ModuleVersion) _then;

  /// Create a copy of ModuleVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? state = null,
  }) {
    return _then(_self.copyWith(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ModuleVersionState,
    ));
  }
}

/// Adds pattern-matching-related methods to [ModuleVersion].
extension ModuleVersionPatterns on ModuleVersion {
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
    TResult Function(_ModuleVersion value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ModuleVersion() when $default != null:
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
    TResult Function(_ModuleVersion value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModuleVersion():
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
    TResult? Function(_ModuleVersion value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModuleVersion() when $default != null:
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
    TResult Function(@_SemverFlexibleConverter() Version version,
            ModuleVersionState state)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ModuleVersion() when $default != null:
        return $default(_that.version, _that.state);
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
    TResult Function(@_SemverFlexibleConverter() Version version,
            ModuleVersionState state)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModuleVersion():
        return $default(_that.version, _that.state);
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
    TResult? Function(@_SemverFlexibleConverter() Version version,
            ModuleVersionState state)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ModuleVersion() when $default != null:
        return $default(_that.version, _that.state);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ModuleVersion extends ModuleVersion {
  const _ModuleVersion(
      {@_SemverFlexibleConverter() required this.version,
      this.state = ModuleVersionState.developing})
      : super._();
  factory _ModuleVersion.fromJson(Map<String, dynamic> json) =>
      _$ModuleVersionFromJson(json);

  @override
  @_SemverFlexibleConverter()
  final Version version;
  @override
  @JsonKey()
  final ModuleVersionState state;

  /// Create a copy of ModuleVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ModuleVersionCopyWith<_ModuleVersion> get copyWith =>
      __$ModuleVersionCopyWithImpl<_ModuleVersion>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ModuleVersionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ModuleVersion &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, state);

  @override
  String toString() {
    return 'ModuleVersion(version: $version, state: $state)';
  }
}

/// @nodoc
abstract mixin class _$ModuleVersionCopyWith<$Res>
    implements $ModuleVersionCopyWith<$Res> {
  factory _$ModuleVersionCopyWith(
          _ModuleVersion value, $Res Function(_ModuleVersion) _then) =
      __$ModuleVersionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@_SemverFlexibleConverter() Version version, ModuleVersionState state});
}

/// @nodoc
class __$ModuleVersionCopyWithImpl<$Res>
    implements _$ModuleVersionCopyWith<$Res> {
  __$ModuleVersionCopyWithImpl(this._self, this._then);

  final _ModuleVersion _self;
  final $Res Function(_ModuleVersion) _then;

  /// Create a copy of ModuleVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? version = null,
    Object? state = null,
  }) {
    return _then(_ModuleVersion(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as ModuleVersionState,
    ));
  }
}

// dart format on
