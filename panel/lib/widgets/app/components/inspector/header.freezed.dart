// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'header.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HeaderContext {
  DataBlueprint? get parentBlueprint;
  DataBlueprint? get genericBlueprint;

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HeaderContextCopyWith<HeaderContext> get copyWith =>
      _$HeaderContextCopyWithImpl<HeaderContext>(
          this as HeaderContext, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HeaderContext &&
            (identical(other.parentBlueprint, parentBlueprint) ||
                other.parentBlueprint == parentBlueprint) &&
            (identical(other.genericBlueprint, genericBlueprint) ||
                other.genericBlueprint == genericBlueprint));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, parentBlueprint, genericBlueprint);

  @override
  String toString() {
    return 'HeaderContext(parentBlueprint: $parentBlueprint, genericBlueprint: $genericBlueprint)';
  }
}

/// @nodoc
abstract mixin class $HeaderContextCopyWith<$Res> {
  factory $HeaderContextCopyWith(
          HeaderContext value, $Res Function(HeaderContext) _then) =
      _$HeaderContextCopyWithImpl;
  @useResult
  $Res call({DataBlueprint? parentBlueprint, DataBlueprint? genericBlueprint});

  $DataBlueprintCopyWith<$Res>? get parentBlueprint;
  $DataBlueprintCopyWith<$Res>? get genericBlueprint;
}

/// @nodoc
class _$HeaderContextCopyWithImpl<$Res>
    implements $HeaderContextCopyWith<$Res> {
  _$HeaderContextCopyWithImpl(this._self, this._then);

  final HeaderContext _self;
  final $Res Function(HeaderContext) _then;

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parentBlueprint = freezed,
    Object? genericBlueprint = freezed,
  }) {
    return _then(_self.copyWith(
      parentBlueprint: freezed == parentBlueprint
          ? _self.parentBlueprint
          : parentBlueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint?,
      genericBlueprint: freezed == genericBlueprint
          ? _self.genericBlueprint
          : genericBlueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint?,
    ));
  }

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res>? get parentBlueprint {
    if (_self.parentBlueprint == null) {
      return null;
    }

    return $DataBlueprintCopyWith<$Res>(_self.parentBlueprint!, (value) {
      return _then(_self.copyWith(parentBlueprint: value));
    });
  }

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res>? get genericBlueprint {
    if (_self.genericBlueprint == null) {
      return null;
    }

    return $DataBlueprintCopyWith<$Res>(_self.genericBlueprint!, (value) {
      return _then(_self.copyWith(genericBlueprint: value));
    });
  }
}

/// Adds pattern-matching-related methods to [HeaderContext].
extension HeaderContextPatterns on HeaderContext {
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
    TResult Function(_HeaderContext value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeaderContext() when $default != null:
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
    TResult Function(_HeaderContext value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeaderContext():
        return $default(_that);
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
    TResult? Function(_HeaderContext value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeaderContext() when $default != null:
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
            DataBlueprint? parentBlueprint, DataBlueprint? genericBlueprint)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeaderContext() when $default != null:
        return $default(_that.parentBlueprint, _that.genericBlueprint);
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
            DataBlueprint? parentBlueprint, DataBlueprint? genericBlueprint)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeaderContext():
        return $default(_that.parentBlueprint, _that.genericBlueprint);
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
            DataBlueprint? parentBlueprint, DataBlueprint? genericBlueprint)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeaderContext() when $default != null:
        return $default(_that.parentBlueprint, _that.genericBlueprint);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HeaderContext implements HeaderContext {
  const _HeaderContext({this.parentBlueprint, this.genericBlueprint});

  @override
  final DataBlueprint? parentBlueprint;
  @override
  final DataBlueprint? genericBlueprint;

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HeaderContextCopyWith<_HeaderContext> get copyWith =>
      __$HeaderContextCopyWithImpl<_HeaderContext>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HeaderContext &&
            (identical(other.parentBlueprint, parentBlueprint) ||
                other.parentBlueprint == parentBlueprint) &&
            (identical(other.genericBlueprint, genericBlueprint) ||
                other.genericBlueprint == genericBlueprint));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, parentBlueprint, genericBlueprint);

  @override
  String toString() {
    return 'HeaderContext(parentBlueprint: $parentBlueprint, genericBlueprint: $genericBlueprint)';
  }
}

/// @nodoc
abstract mixin class _$HeaderContextCopyWith<$Res>
    implements $HeaderContextCopyWith<$Res> {
  factory _$HeaderContextCopyWith(
          _HeaderContext value, $Res Function(_HeaderContext) _then) =
      __$HeaderContextCopyWithImpl;
  @override
  @useResult
  $Res call({DataBlueprint? parentBlueprint, DataBlueprint? genericBlueprint});

  @override
  $DataBlueprintCopyWith<$Res>? get parentBlueprint;
  @override
  $DataBlueprintCopyWith<$Res>? get genericBlueprint;
}

/// @nodoc
class __$HeaderContextCopyWithImpl<$Res>
    implements _$HeaderContextCopyWith<$Res> {
  __$HeaderContextCopyWithImpl(this._self, this._then);

  final _HeaderContext _self;
  final $Res Function(_HeaderContext) _then;

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? parentBlueprint = freezed,
    Object? genericBlueprint = freezed,
  }) {
    return _then(_HeaderContext(
      parentBlueprint: freezed == parentBlueprint
          ? _self.parentBlueprint
          : parentBlueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint?,
      genericBlueprint: freezed == genericBlueprint
          ? _self.genericBlueprint
          : genericBlueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint?,
    ));
  }

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res>? get parentBlueprint {
    if (_self.parentBlueprint == null) {
      return null;
    }

    return $DataBlueprintCopyWith<$Res>(_self.parentBlueprint!, (value) {
      return _then(_self.copyWith(parentBlueprint: value));
    });
  }

  /// Create a copy of HeaderContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res>? get genericBlueprint {
    if (_self.genericBlueprint == null) {
      return null;
    }

    return $DataBlueprintCopyWith<$Res>(_self.genericBlueprint!, (value) {
      return _then(_self.copyWith(genericBlueprint: value));
    });
  }
}

// dart format on
