// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manuals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Platform {
  String get id;
  String get displayName;
  @ColorConverter()
  Color get color;
  List<PlatformRequirement> get requirements;

  /// Create a copy of Platform
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlatformCopyWith<Platform> get copyWith =>
      _$PlatformCopyWithImpl<Platform>(this as Platform, _$identity);

  /// Serializes this Platform to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Platform &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.color, color) || other.color == color) &&
            const DeepCollectionEquality()
                .equals(other.requirements, requirements));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, displayName, color,
      const DeepCollectionEquality().hash(requirements));

  @override
  String toString() {
    return 'Platform(id: $id, displayName: $displayName, color: $color, requirements: $requirements)';
  }
}

/// @nodoc
abstract mixin class $PlatformCopyWith<$Res> {
  factory $PlatformCopyWith(Platform value, $Res Function(Platform) _then) =
      _$PlatformCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String displayName,
      @ColorConverter() Color color,
      List<PlatformRequirement> requirements});
}

/// @nodoc
class _$PlatformCopyWithImpl<$Res> implements $PlatformCopyWith<$Res> {
  _$PlatformCopyWithImpl(this._self, this._then);

  final Platform _self;
  final $Res Function(Platform) _then;

  /// Create a copy of Platform
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? color = null,
    Object? requirements = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color,
      requirements: null == requirements
          ? _self.requirements
          : requirements // ignore: cast_nullable_to_non_nullable
              as List<PlatformRequirement>,
    ));
  }
}

/// Adds pattern-matching-related methods to [Platform].
extension PlatformPatterns on Platform {
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
    TResult Function(_Platform value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Platform() when $default != null:
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
    TResult Function(_Platform value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Platform():
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
    TResult? Function(_Platform value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Platform() when $default != null:
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
            String displayName,
            @ColorConverter() Color color,
            List<PlatformRequirement> requirements)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Platform() when $default != null:
        return $default(
            _that.id, _that.displayName, _that.color, _that.requirements);
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
            String displayName,
            @ColorConverter() Color color,
            List<PlatformRequirement> requirements)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Platform():
        return $default(
            _that.id, _that.displayName, _that.color, _that.requirements);
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
            String displayName,
            @ColorConverter() Color color,
            List<PlatformRequirement> requirements)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Platform() when $default != null:
        return $default(
            _that.id, _that.displayName, _that.color, _that.requirements);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Platform implements Platform {
  const _Platform(
      {required this.id,
      required this.displayName,
      @ColorConverter() this.color = Colors.blue,
      final List<PlatformRequirement> requirements = const []})
      : _requirements = requirements;
  factory _Platform.fromJson(Map<String, dynamic> json) =>
      _$PlatformFromJson(json);

  @override
  final String id;
  @override
  final String displayName;
  @override
  @JsonKey()
  @ColorConverter()
  final Color color;
  final List<PlatformRequirement> _requirements;
  @override
  @JsonKey()
  List<PlatformRequirement> get requirements {
    if (_requirements is EqualUnmodifiableListView) return _requirements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requirements);
  }

  /// Create a copy of Platform
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlatformCopyWith<_Platform> get copyWith =>
      __$PlatformCopyWithImpl<_Platform>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlatformToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Platform &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.color, color) || other.color == color) &&
            const DeepCollectionEquality()
                .equals(other._requirements, _requirements));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, displayName, color,
      const DeepCollectionEquality().hash(_requirements));

  @override
  String toString() {
    return 'Platform(id: $id, displayName: $displayName, color: $color, requirements: $requirements)';
  }
}

/// @nodoc
abstract mixin class _$PlatformCopyWith<$Res>
    implements $PlatformCopyWith<$Res> {
  factory _$PlatformCopyWith(_Platform value, $Res Function(_Platform) _then) =
      __$PlatformCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String displayName,
      @ColorConverter() Color color,
      List<PlatformRequirement> requirements});
}

/// @nodoc
class __$PlatformCopyWithImpl<$Res> implements _$PlatformCopyWith<$Res> {
  __$PlatformCopyWithImpl(this._self, this._then);

  final _Platform _self;
  final $Res Function(_Platform) _then;

  /// Create a copy of Platform
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? color = null,
    Object? requirements = null,
  }) {
    return _then(_Platform(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color,
      requirements: null == requirements
          ? _self._requirements
          : requirements // ignore: cast_nullable_to_non_nullable
              as List<PlatformRequirement>,
    ));
  }
}

/// @nodoc
mixin _$PlatformRequirement {
  String get name;
  PlatformConstraintType get type;

  /// Create a copy of PlatformRequirement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlatformRequirementCopyWith<PlatformRequirement> get copyWith =>
      _$PlatformRequirementCopyWithImpl<PlatformRequirement>(
          this as PlatformRequirement, _$identity);

  /// Serializes this PlatformRequirement to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlatformRequirement &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, type);

  @override
  String toString() {
    return 'PlatformRequirement(name: $name, type: $type)';
  }
}

/// @nodoc
abstract mixin class $PlatformRequirementCopyWith<$Res> {
  factory $PlatformRequirementCopyWith(
          PlatformRequirement value, $Res Function(PlatformRequirement) _then) =
      _$PlatformRequirementCopyWithImpl;
  @useResult
  $Res call({String name, PlatformConstraintType type});
}

/// @nodoc
class _$PlatformRequirementCopyWithImpl<$Res>
    implements $PlatformRequirementCopyWith<$Res> {
  _$PlatformRequirementCopyWithImpl(this._self, this._then);

  final PlatformRequirement _self;
  final $Res Function(PlatformRequirement) _then;

  /// Create a copy of PlatformRequirement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? type = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as PlatformConstraintType,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlatformRequirement].
extension PlatformRequirementPatterns on PlatformRequirement {
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
    TResult Function(_PlatformRequirement value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlatformRequirement() when $default != null:
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
    TResult Function(_PlatformRequirement value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformRequirement():
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
    TResult? Function(_PlatformRequirement value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformRequirement() when $default != null:
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
    TResult Function(String name, PlatformConstraintType type)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlatformRequirement() when $default != null:
        return $default(_that.name, _that.type);
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
    TResult Function(String name, PlatformConstraintType type) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformRequirement():
        return $default(_that.name, _that.type);
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
    TResult? Function(String name, PlatformConstraintType type)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformRequirement() when $default != null:
        return $default(_that.name, _that.type);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlatformRequirement implements PlatformRequirement {
  const _PlatformRequirement({required this.name, required this.type});
  factory _PlatformRequirement.fromJson(Map<String, dynamic> json) =>
      _$PlatformRequirementFromJson(json);

  @override
  final String name;
  @override
  final PlatformConstraintType type;

  /// Create a copy of PlatformRequirement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlatformRequirementCopyWith<_PlatformRequirement> get copyWith =>
      __$PlatformRequirementCopyWithImpl<_PlatformRequirement>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlatformRequirementToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlatformRequirement &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, type);

  @override
  String toString() {
    return 'PlatformRequirement(name: $name, type: $type)';
  }
}

/// @nodoc
abstract mixin class _$PlatformRequirementCopyWith<$Res>
    implements $PlatformRequirementCopyWith<$Res> {
  factory _$PlatformRequirementCopyWith(_PlatformRequirement value,
          $Res Function(_PlatformRequirement) _then) =
      __$PlatformRequirementCopyWithImpl;
  @override
  @useResult
  $Res call({String name, PlatformConstraintType type});
}

/// @nodoc
class __$PlatformRequirementCopyWithImpl<$Res>
    implements _$PlatformRequirementCopyWith<$Res> {
  __$PlatformRequirementCopyWithImpl(this._self, this._then);

  final _PlatformRequirement _self;
  final $Res Function(_PlatformRequirement) _then;

  /// Create a copy of PlatformRequirement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? type = null,
  }) {
    return _then(_PlatformRequirement(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as PlatformConstraintType,
    ));
  }
}

PlatformConstraint _$PlatformConstraintFromJson(Map<String, dynamic> json) {
  return PlatformVersionConstraint.fromJson(json);
}

/// @nodoc
mixin _$PlatformConstraint {
  @SemverListJsonConverter()
  List<Version> get versions;

  /// Create a copy of PlatformConstraint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlatformConstraintCopyWith<PlatformConstraint> get copyWith =>
      _$PlatformConstraintCopyWithImpl<PlatformConstraint>(
          this as PlatformConstraint, _$identity);

  /// Serializes this PlatformConstraint to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlatformConstraint &&
            const DeepCollectionEquality().equals(other.versions, versions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(versions));

  @override
  String toString() {
    return 'PlatformConstraint(versions: $versions)';
  }
}

/// @nodoc
abstract mixin class $PlatformConstraintCopyWith<$Res> {
  factory $PlatformConstraintCopyWith(
          PlatformConstraint value, $Res Function(PlatformConstraint) _then) =
      _$PlatformConstraintCopyWithImpl;
  @useResult
  $Res call({@SemverListJsonConverter() List<Version> versions});
}

/// @nodoc
class _$PlatformConstraintCopyWithImpl<$Res>
    implements $PlatformConstraintCopyWith<$Res> {
  _$PlatformConstraintCopyWithImpl(this._self, this._then);

  final PlatformConstraint _self;
  final $Res Function(PlatformConstraint) _then;

  /// Create a copy of PlatformConstraint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? versions = null,
  }) {
    return _then(_self.copyWith(
      versions: null == versions
          ? _self.versions
          : versions // ignore: cast_nullable_to_non_nullable
              as List<Version>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlatformConstraint].
extension PlatformConstraintPatterns on PlatformConstraint {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PlatformVersionConstraint value)? version,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PlatformVersionConstraint() when version != null:
        return version(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(PlatformVersionConstraint value) version,
  }) {
    final _that = this;
    switch (_that) {
      case PlatformVersionConstraint():
        return version(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PlatformVersionConstraint value)? version,
  }) {
    final _that = this;
    switch (_that) {
      case PlatformVersionConstraint() when version != null:
        return version(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(@SemverListJsonConverter() List<Version> versions)?
        version,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case PlatformVersionConstraint() when version != null:
        return version(_that.versions);
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
  TResult when<TResult extends Object?>({
    required TResult Function(@SemverListJsonConverter() List<Version> versions)
        version,
  }) {
    final _that = this;
    switch (_that) {
      case PlatformVersionConstraint():
        return version(_that.versions);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(@SemverListJsonConverter() List<Version> versions)?
        version,
  }) {
    final _that = this;
    switch (_that) {
      case PlatformVersionConstraint() when version != null:
        return version(_that.versions);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class PlatformVersionConstraint extends PlatformConstraint {
  const PlatformVersionConstraint(
      {@SemverListJsonConverter() required final List<Version> versions})
      : _versions = versions,
        super._();
  factory PlatformVersionConstraint.fromJson(Map<String, dynamic> json) =>
      _$PlatformVersionConstraintFromJson(json);

  final List<Version> _versions;
  @override
  @SemverListJsonConverter()
  List<Version> get versions {
    if (_versions is EqualUnmodifiableListView) return _versions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_versions);
  }

  /// Create a copy of PlatformConstraint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlatformVersionConstraintCopyWith<PlatformVersionConstraint> get copyWith =>
      _$PlatformVersionConstraintCopyWithImpl<PlatformVersionConstraint>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlatformVersionConstraintToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlatformVersionConstraint &&
            const DeepCollectionEquality().equals(other._versions, _versions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_versions));

  @override
  String toString() {
    return 'PlatformConstraint.version(versions: $versions)';
  }
}

/// @nodoc
abstract mixin class $PlatformVersionConstraintCopyWith<$Res>
    implements $PlatformConstraintCopyWith<$Res> {
  factory $PlatformVersionConstraintCopyWith(PlatformVersionConstraint value,
          $Res Function(PlatformVersionConstraint) _then) =
      _$PlatformVersionConstraintCopyWithImpl;
  @override
  @useResult
  $Res call({@SemverListJsonConverter() List<Version> versions});
}

/// @nodoc
class _$PlatformVersionConstraintCopyWithImpl<$Res>
    implements $PlatformVersionConstraintCopyWith<$Res> {
  _$PlatformVersionConstraintCopyWithImpl(this._self, this._then);

  final PlatformVersionConstraint _self;
  final $Res Function(PlatformVersionConstraint) _then;

  /// Create a copy of PlatformConstraint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? versions = null,
  }) {
    return _then(PlatformVersionConstraint(
      versions: null == versions
          ? _self._versions
          : versions // ignore: cast_nullable_to_non_nullable
              as List<Version>,
    ));
  }
}

/// @nodoc
mixin _$PlatformTarget {
  Platform get platform;
  Map<String, PlatformConstraint> get constraints;

  /// Create a copy of PlatformTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlatformTargetCopyWith<PlatformTarget> get copyWith =>
      _$PlatformTargetCopyWithImpl<PlatformTarget>(
          this as PlatformTarget, _$identity);

  /// Serializes this PlatformTarget to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlatformTarget &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            const DeepCollectionEquality()
                .equals(other.constraints, constraints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, platform, const DeepCollectionEquality().hash(constraints));

  @override
  String toString() {
    return 'PlatformTarget(platform: $platform, constraints: $constraints)';
  }
}

/// @nodoc
abstract mixin class $PlatformTargetCopyWith<$Res> {
  factory $PlatformTargetCopyWith(
          PlatformTarget value, $Res Function(PlatformTarget) _then) =
      _$PlatformTargetCopyWithImpl;
  @useResult
  $Res call({Platform platform, Map<String, PlatformConstraint> constraints});

  $PlatformCopyWith<$Res> get platform;
}

/// @nodoc
class _$PlatformTargetCopyWithImpl<$Res>
    implements $PlatformTargetCopyWith<$Res> {
  _$PlatformTargetCopyWithImpl(this._self, this._then);

  final PlatformTarget _self;
  final $Res Function(PlatformTarget) _then;

  /// Create a copy of PlatformTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? platform = null,
    Object? constraints = null,
  }) {
    return _then(_self.copyWith(
      platform: null == platform
          ? _self.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as Platform,
      constraints: null == constraints
          ? _self.constraints
          : constraints // ignore: cast_nullable_to_non_nullable
              as Map<String, PlatformConstraint>,
    ));
  }

  /// Create a copy of PlatformTarget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlatformCopyWith<$Res> get platform {
    return $PlatformCopyWith<$Res>(_self.platform, (value) {
      return _then(_self.copyWith(platform: value));
    });
  }
}

/// Adds pattern-matching-related methods to [PlatformTarget].
extension PlatformTargetPatterns on PlatformTarget {
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
    TResult Function(_PlatformTarget value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlatformTarget() when $default != null:
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
    TResult Function(_PlatformTarget value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformTarget():
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
    TResult? Function(_PlatformTarget value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformTarget() when $default != null:
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
            Platform platform, Map<String, PlatformConstraint> constraints)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlatformTarget() when $default != null:
        return $default(_that.platform, _that.constraints);
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
            Platform platform, Map<String, PlatformConstraint> constraints)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformTarget():
        return $default(_that.platform, _that.constraints);
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
            Platform platform, Map<String, PlatformConstraint> constraints)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlatformTarget() when $default != null:
        return $default(_that.platform, _that.constraints);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlatformTarget implements PlatformTarget {
  const _PlatformTarget(
      {required this.platform,
      final Map<String, PlatformConstraint> constraints = const {}})
      : _constraints = constraints;
  factory _PlatformTarget.fromJson(Map<String, dynamic> json) =>
      _$PlatformTargetFromJson(json);

  @override
  final Platform platform;
  final Map<String, PlatformConstraint> _constraints;
  @override
  @JsonKey()
  Map<String, PlatformConstraint> get constraints {
    if (_constraints is EqualUnmodifiableMapView) return _constraints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_constraints);
  }

  /// Create a copy of PlatformTarget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlatformTargetCopyWith<_PlatformTarget> get copyWith =>
      __$PlatformTargetCopyWithImpl<_PlatformTarget>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlatformTargetToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlatformTarget &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            const DeepCollectionEquality()
                .equals(other._constraints, _constraints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, platform, const DeepCollectionEquality().hash(_constraints));

  @override
  String toString() {
    return 'PlatformTarget(platform: $platform, constraints: $constraints)';
  }
}

/// @nodoc
abstract mixin class _$PlatformTargetCopyWith<$Res>
    implements $PlatformTargetCopyWith<$Res> {
  factory _$PlatformTargetCopyWith(
          _PlatformTarget value, $Res Function(_PlatformTarget) _then) =
      __$PlatformTargetCopyWithImpl;
  @override
  @useResult
  $Res call({Platform platform, Map<String, PlatformConstraint> constraints});

  @override
  $PlatformCopyWith<$Res> get platform;
}

/// @nodoc
class __$PlatformTargetCopyWithImpl<$Res>
    implements _$PlatformTargetCopyWith<$Res> {
  __$PlatformTargetCopyWithImpl(this._self, this._then);

  final _PlatformTarget _self;
  final $Res Function(_PlatformTarget) _then;

  /// Create a copy of PlatformTarget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? platform = null,
    Object? constraints = null,
  }) {
    return _then(_PlatformTarget(
      platform: null == platform
          ? _self.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as Platform,
      constraints: null == constraints
          ? _self._constraints
          : constraints // ignore: cast_nullable_to_non_nullable
              as Map<String, PlatformConstraint>,
    ));
  }

  /// Create a copy of PlatformTarget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlatformCopyWith<$Res> get platform {
    return $PlatformCopyWith<$Res>(_self.platform, (value) {
      return _then(_self.copyWith(platform: value));
    });
  }
}

/// @nodoc
mixin _$ManualModuleReference {
  String get moduleId;
  String get name;
  @SemverJsonConverter()
  Version get version;
  ModuleType get type;
  List<String> get dependencies;
  List<String> get dependents;

  /// Create a copy of ManualModuleReference
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ManualModuleReferenceCopyWith<ManualModuleReference> get copyWith =>
      _$ManualModuleReferenceCopyWithImpl<ManualModuleReference>(
          this as ManualModuleReference, _$identity);

  /// Serializes this ManualModuleReference to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ManualModuleReference &&
            (identical(other.moduleId, moduleId) ||
                other.moduleId == moduleId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other.dependencies, dependencies) &&
            const DeepCollectionEquality()
                .equals(other.dependents, dependents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      moduleId,
      name,
      version,
      type,
      const DeepCollectionEquality().hash(dependencies),
      const DeepCollectionEquality().hash(dependents));

  @override
  String toString() {
    return 'ManualModuleReference(moduleId: $moduleId, name: $name, version: $version, type: $type, dependencies: $dependencies, dependents: $dependents)';
  }
}

/// @nodoc
abstract mixin class $ManualModuleReferenceCopyWith<$Res> {
  factory $ManualModuleReferenceCopyWith(ManualModuleReference value,
          $Res Function(ManualModuleReference) _then) =
      _$ManualModuleReferenceCopyWithImpl;
  @useResult
  $Res call(
      {String moduleId,
      String name,
      @SemverJsonConverter() Version version,
      ModuleType type,
      List<String> dependencies,
      List<String> dependents});
}

/// @nodoc
class _$ManualModuleReferenceCopyWithImpl<$Res>
    implements $ManualModuleReferenceCopyWith<$Res> {
  _$ManualModuleReferenceCopyWithImpl(this._self, this._then);

  final ManualModuleReference _self;
  final $Res Function(ManualModuleReference) _then;

  /// Create a copy of ManualModuleReference
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? moduleId = null,
    Object? name = null,
    Object? version = null,
    Object? type = null,
    Object? dependencies = null,
    Object? dependents = null,
  }) {
    return _then(_self.copyWith(
      moduleId: null == moduleId
          ? _self.moduleId
          : moduleId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ModuleType,
      dependencies: null == dependencies
          ? _self.dependencies
          : dependencies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dependents: null == dependents
          ? _self.dependents
          : dependents // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ManualModuleReference].
extension ManualModuleReferencePatterns on ManualModuleReference {
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
    TResult Function(_ManualModuleReference value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ManualModuleReference() when $default != null:
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
    TResult Function(_ManualModuleReference value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleReference():
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
    TResult? Function(_ManualModuleReference value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleReference() when $default != null:
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
            String moduleId,
            String name,
            @SemverJsonConverter() Version version,
            ModuleType type,
            List<String> dependencies,
            List<String> dependents)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ManualModuleReference() when $default != null:
        return $default(_that.moduleId, _that.name, _that.version, _that.type,
            _that.dependencies, _that.dependents);
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
            String moduleId,
            String name,
            @SemverJsonConverter() Version version,
            ModuleType type,
            List<String> dependencies,
            List<String> dependents)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleReference():
        return $default(_that.moduleId, _that.name, _that.version, _that.type,
            _that.dependencies, _that.dependents);
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
            String moduleId,
            String name,
            @SemverJsonConverter() Version version,
            ModuleType type,
            List<String> dependencies,
            List<String> dependents)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleReference() when $default != null:
        return $default(_that.moduleId, _that.name, _that.version, _that.type,
            _that.dependencies, _that.dependents);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ManualModuleReference implements ManualModuleReference {
  const _ManualModuleReference(
      {required this.moduleId,
      required this.name,
      @SemverJsonConverter() required this.version,
      required this.type,
      final List<String> dependencies = const <String>[],
      final List<String> dependents = const <String>[]})
      : _dependencies = dependencies,
        _dependents = dependents;
  factory _ManualModuleReference.fromJson(Map<String, dynamic> json) =>
      _$ManualModuleReferenceFromJson(json);

  @override
  final String moduleId;
  @override
  final String name;
  @override
  @SemverJsonConverter()
  final Version version;
  @override
  final ModuleType type;
  final List<String> _dependencies;
  @override
  @JsonKey()
  List<String> get dependencies {
    if (_dependencies is EqualUnmodifiableListView) return _dependencies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependencies);
  }

  final List<String> _dependents;
  @override
  @JsonKey()
  List<String> get dependents {
    if (_dependents is EqualUnmodifiableListView) return _dependents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependents);
  }

  /// Create a copy of ManualModuleReference
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ManualModuleReferenceCopyWith<_ManualModuleReference> get copyWith =>
      __$ManualModuleReferenceCopyWithImpl<_ManualModuleReference>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ManualModuleReferenceToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ManualModuleReference &&
            (identical(other.moduleId, moduleId) ||
                other.moduleId == moduleId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other._dependencies, _dependencies) &&
            const DeepCollectionEquality()
                .equals(other._dependents, _dependents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      moduleId,
      name,
      version,
      type,
      const DeepCollectionEquality().hash(_dependencies),
      const DeepCollectionEquality().hash(_dependents));

  @override
  String toString() {
    return 'ManualModuleReference(moduleId: $moduleId, name: $name, version: $version, type: $type, dependencies: $dependencies, dependents: $dependents)';
  }
}

/// @nodoc
abstract mixin class _$ManualModuleReferenceCopyWith<$Res>
    implements $ManualModuleReferenceCopyWith<$Res> {
  factory _$ManualModuleReferenceCopyWith(_ManualModuleReference value,
          $Res Function(_ManualModuleReference) _then) =
      __$ManualModuleReferenceCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String moduleId,
      String name,
      @SemverJsonConverter() Version version,
      ModuleType type,
      List<String> dependencies,
      List<String> dependents});
}

/// @nodoc
class __$ManualModuleReferenceCopyWithImpl<$Res>
    implements _$ManualModuleReferenceCopyWith<$Res> {
  __$ManualModuleReferenceCopyWithImpl(this._self, this._then);

  final _ManualModuleReference _self;
  final $Res Function(_ManualModuleReference) _then;

  /// Create a copy of ManualModuleReference
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? moduleId = null,
    Object? name = null,
    Object? version = null,
    Object? type = null,
    Object? dependencies = null,
    Object? dependents = null,
  }) {
    return _then(_ManualModuleReference(
      moduleId: null == moduleId
          ? _self.moduleId
          : moduleId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ModuleType,
      dependencies: null == dependencies
          ? _self._dependencies
          : dependencies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dependents: null == dependents
          ? _self._dependents
          : dependents // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
mixin _$Manual {
  String get id;
  String get name;
  List<PlatformTarget> get platforms;
  List<ManualModuleReference> get modules;
  bool get autoUpdate;

  /// Create a copy of Manual
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ManualCopyWith<Manual> get copyWith =>
      _$ManualCopyWithImpl<Manual>(this as Manual, _$identity);

  /// Serializes this Manual to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Manual &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.platforms, platforms) &&
            const DeepCollectionEquality().equals(other.modules, modules) &&
            (identical(other.autoUpdate, autoUpdate) ||
                other.autoUpdate == autoUpdate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      const DeepCollectionEquality().hash(platforms),
      const DeepCollectionEquality().hash(modules),
      autoUpdate);

  @override
  String toString() {
    return 'Manual(id: $id, name: $name, platforms: $platforms, modules: $modules, autoUpdate: $autoUpdate)';
  }
}

/// @nodoc
abstract mixin class $ManualCopyWith<$Res> {
  factory $ManualCopyWith(Manual value, $Res Function(Manual) _then) =
      _$ManualCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      List<PlatformTarget> platforms,
      List<ManualModuleReference> modules,
      bool autoUpdate});
}

/// @nodoc
class _$ManualCopyWithImpl<$Res> implements $ManualCopyWith<$Res> {
  _$ManualCopyWithImpl(this._self, this._then);

  final Manual _self;
  final $Res Function(Manual) _then;

  /// Create a copy of Manual
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? platforms = null,
    Object? modules = null,
    Object? autoUpdate = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      platforms: null == platforms
          ? _self.platforms
          : platforms // ignore: cast_nullable_to_non_nullable
              as List<PlatformTarget>,
      modules: null == modules
          ? _self.modules
          : modules // ignore: cast_nullable_to_non_nullable
              as List<ManualModuleReference>,
      autoUpdate: null == autoUpdate
          ? _self.autoUpdate
          : autoUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [Manual].
extension ManualPatterns on Manual {
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
    TResult Function(_Manual value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Manual() when $default != null:
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
    TResult Function(_Manual value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Manual():
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
    TResult? Function(_Manual value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Manual() when $default != null:
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
    TResult Function(String id, String name, List<PlatformTarget> platforms,
            List<ManualModuleReference> modules, bool autoUpdate)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Manual() when $default != null:
        return $default(_that.id, _that.name, _that.platforms, _that.modules,
            _that.autoUpdate);
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
    TResult Function(String id, String name, List<PlatformTarget> platforms,
            List<ManualModuleReference> modules, bool autoUpdate)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Manual():
        return $default(_that.id, _that.name, _that.platforms, _that.modules,
            _that.autoUpdate);
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
    TResult? Function(String id, String name, List<PlatformTarget> platforms,
            List<ManualModuleReference> modules, bool autoUpdate)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Manual() when $default != null:
        return $default(_that.id, _that.name, _that.platforms, _that.modules,
            _that.autoUpdate);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Manual implements Manual {
  const _Manual(
      {required this.id,
      required this.name,
      final List<PlatformTarget> platforms = const <PlatformTarget>[],
      final List<ManualModuleReference> modules =
          const <ManualModuleReference>[],
      this.autoUpdate = true})
      : _platforms = platforms,
        _modules = modules;
  factory _Manual.fromJson(Map<String, dynamic> json) => _$ManualFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<PlatformTarget> _platforms;
  @override
  @JsonKey()
  List<PlatformTarget> get platforms {
    if (_platforms is EqualUnmodifiableListView) return _platforms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_platforms);
  }

  final List<ManualModuleReference> _modules;
  @override
  @JsonKey()
  List<ManualModuleReference> get modules {
    if (_modules is EqualUnmodifiableListView) return _modules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modules);
  }

  @override
  @JsonKey()
  final bool autoUpdate;

  /// Create a copy of Manual
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ManualCopyWith<_Manual> get copyWith =>
      __$ManualCopyWithImpl<_Manual>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ManualToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Manual &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._platforms, _platforms) &&
            const DeepCollectionEquality().equals(other._modules, _modules) &&
            (identical(other.autoUpdate, autoUpdate) ||
                other.autoUpdate == autoUpdate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      const DeepCollectionEquality().hash(_platforms),
      const DeepCollectionEquality().hash(_modules),
      autoUpdate);

  @override
  String toString() {
    return 'Manual(id: $id, name: $name, platforms: $platforms, modules: $modules, autoUpdate: $autoUpdate)';
  }
}

/// @nodoc
abstract mixin class _$ManualCopyWith<$Res> implements $ManualCopyWith<$Res> {
  factory _$ManualCopyWith(_Manual value, $Res Function(_Manual) _then) =
      __$ManualCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      List<PlatformTarget> platforms,
      List<ManualModuleReference> modules,
      bool autoUpdate});
}

/// @nodoc
class __$ManualCopyWithImpl<$Res> implements _$ManualCopyWith<$Res> {
  __$ManualCopyWithImpl(this._self, this._then);

  final _Manual _self;
  final $Res Function(_Manual) _then;

  /// Create a copy of Manual
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? platforms = null,
    Object? modules = null,
    Object? autoUpdate = null,
  }) {
    return _then(_Manual(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      platforms: null == platforms
          ? _self._platforms
          : platforms // ignore: cast_nullable_to_non_nullable
              as List<PlatformTarget>,
      modules: null == modules
          ? _self._modules
          : modules // ignore: cast_nullable_to_non_nullable
              as List<ManualModuleReference>,
      autoUpdate: null == autoUpdate
          ? _self.autoUpdate
          : autoUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

ManualOperationResult _$ManualOperationResultFromJson(
    Map<String, dynamic> json) {
  switch (json['status']) {
    case 'success':
      return ManualOperationSuccess.fromJson(json);
    case 'failure':
      return ManualOperationFailure.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'status', 'ManualOperationResult',
          'Invalid union type "${json['status']}"!');
  }
}

/// @nodoc
mixin _$ManualOperationResult {
  /// Serializes this ManualOperationResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ManualOperationResult);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ManualOperationResult()';
  }
}

/// @nodoc
class $ManualOperationResultCopyWith<$Res> {
  $ManualOperationResultCopyWith(
      ManualOperationResult _, $Res Function(ManualOperationResult) __);
}

/// Adds pattern-matching-related methods to [ManualOperationResult].
extension ManualOperationResultPatterns on ManualOperationResult {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ManualOperationSuccess value)? success,
    TResult Function(ManualOperationFailure value)? failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ManualOperationSuccess() when success != null:
        return success(_that);
      case ManualOperationFailure() when failure != null:
        return failure(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(ManualOperationSuccess value) success,
    required TResult Function(ManualOperationFailure value) failure,
  }) {
    final _that = this;
    switch (_that) {
      case ManualOperationSuccess():
        return success(_that);
      case ManualOperationFailure():
        return failure(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ManualOperationSuccess value)? success,
    TResult? Function(ManualOperationFailure value)? failure,
  }) {
    final _that = this;
    switch (_that) {
      case ManualOperationSuccess() when success != null:
        return success(_that);
      case ManualOperationFailure() when failure != null:
        return failure(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Manual manual)? success,
    TResult Function(String reason, List<String> details)? failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ManualOperationSuccess() when success != null:
        return success(_that.manual);
      case ManualOperationFailure() when failure != null:
        return failure(_that.reason, _that.details);
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
  TResult when<TResult extends Object?>({
    required TResult Function(Manual manual) success,
    required TResult Function(String reason, List<String> details) failure,
  }) {
    final _that = this;
    switch (_that) {
      case ManualOperationSuccess():
        return success(_that.manual);
      case ManualOperationFailure():
        return failure(_that.reason, _that.details);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Manual manual)? success,
    TResult? Function(String reason, List<String> details)? failure,
  }) {
    final _that = this;
    switch (_that) {
      case ManualOperationSuccess() when success != null:
        return success(_that.manual);
      case ManualOperationFailure() when failure != null:
        return failure(_that.reason, _that.details);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class ManualOperationSuccess implements ManualOperationResult {
  const ManualOperationSuccess({required this.manual, final String? $type})
      : $type = $type ?? 'success';
  factory ManualOperationSuccess.fromJson(Map<String, dynamic> json) =>
      _$ManualOperationSuccessFromJson(json);

  final Manual manual;

  @JsonKey(name: 'status')
  final String $type;

  /// Create a copy of ManualOperationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ManualOperationSuccessCopyWith<ManualOperationSuccess> get copyWith =>
      _$ManualOperationSuccessCopyWithImpl<ManualOperationSuccess>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ManualOperationSuccessToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ManualOperationSuccess &&
            (identical(other.manual, manual) || other.manual == manual));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, manual);

  @override
  String toString() {
    return 'ManualOperationResult.success(manual: $manual)';
  }
}

/// @nodoc
abstract mixin class $ManualOperationSuccessCopyWith<$Res>
    implements $ManualOperationResultCopyWith<$Res> {
  factory $ManualOperationSuccessCopyWith(ManualOperationSuccess value,
          $Res Function(ManualOperationSuccess) _then) =
      _$ManualOperationSuccessCopyWithImpl;
  @useResult
  $Res call({Manual manual});

  $ManualCopyWith<$Res> get manual;
}

/// @nodoc
class _$ManualOperationSuccessCopyWithImpl<$Res>
    implements $ManualOperationSuccessCopyWith<$Res> {
  _$ManualOperationSuccessCopyWithImpl(this._self, this._then);

  final ManualOperationSuccess _self;
  final $Res Function(ManualOperationSuccess) _then;

  /// Create a copy of ManualOperationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? manual = null,
  }) {
    return _then(ManualOperationSuccess(
      manual: null == manual
          ? _self.manual
          : manual // ignore: cast_nullable_to_non_nullable
              as Manual,
    ));
  }

  /// Create a copy of ManualOperationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ManualCopyWith<$Res> get manual {
    return $ManualCopyWith<$Res>(_self.manual, (value) {
      return _then(_self.copyWith(manual: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class ManualOperationFailure implements ManualOperationResult {
  const ManualOperationFailure(
      {required this.reason,
      final List<String> details = const <String>[],
      final String? $type})
      : _details = details,
        $type = $type ?? 'failure';
  factory ManualOperationFailure.fromJson(Map<String, dynamic> json) =>
      _$ManualOperationFailureFromJson(json);

  final String reason;
  final List<String> _details;
  @JsonKey()
  List<String> get details {
    if (_details is EqualUnmodifiableListView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_details);
  }

  @JsonKey(name: 'status')
  final String $type;

  /// Create a copy of ManualOperationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ManualOperationFailureCopyWith<ManualOperationFailure> get copyWith =>
      _$ManualOperationFailureCopyWithImpl<ManualOperationFailure>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ManualOperationFailureToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ManualOperationFailure &&
            (identical(other.reason, reason) || other.reason == reason) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, reason, const DeepCollectionEquality().hash(_details));

  @override
  String toString() {
    return 'ManualOperationResult.failure(reason: $reason, details: $details)';
  }
}

/// @nodoc
abstract mixin class $ManualOperationFailureCopyWith<$Res>
    implements $ManualOperationResultCopyWith<$Res> {
  factory $ManualOperationFailureCopyWith(ManualOperationFailure value,
          $Res Function(ManualOperationFailure) _then) =
      _$ManualOperationFailureCopyWithImpl;
  @useResult
  $Res call({String reason, List<String> details});
}

/// @nodoc
class _$ManualOperationFailureCopyWithImpl<$Res>
    implements $ManualOperationFailureCopyWith<$Res> {
  _$ManualOperationFailureCopyWithImpl(this._self, this._then);

  final ManualOperationFailure _self;
  final $Res Function(ManualOperationFailure) _then;

  /// Create a copy of ManualOperationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reason = null,
    Object? details = null,
  }) {
    return _then(ManualOperationFailure(
      reason: null == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _self._details
          : details // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
