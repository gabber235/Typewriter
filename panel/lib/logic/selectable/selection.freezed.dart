// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'selection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SelectedValue {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SelectedValue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SelectedValue()';
  }
}

/// @nodoc
class $SelectedValueCopyWith<$Res> {
  $SelectedValueCopyWith(SelectedValue _, $Res Function(SelectedValue) __);
}

/// Adds pattern-matching-related methods to [SelectedValue].
extension SelectedValuePatterns on SelectedValue {
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
    TResult Function(LoadingValue value)? loading,
    TResult Function(Value value)? value,
    TResult Function(ConflictValue value)? conflict,
    TResult Function(NoneValue value)? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadingValue() when loading != null:
        return loading(_that);
      case Value() when value != null:
        return value(_that);
      case ConflictValue() when conflict != null:
        return conflict(_that);
      case NoneValue() when none != null:
        return none(_that);
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
    required TResult Function(LoadingValue value) loading,
    required TResult Function(Value value) value,
    required TResult Function(ConflictValue value) conflict,
    required TResult Function(NoneValue value) none,
  }) {
    final _that = this;
    switch (_that) {
      case LoadingValue():
        return loading(_that);
      case Value():
        return value(_that);
      case ConflictValue():
        return conflict(_that);
      case NoneValue():
        return none(_that);
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
    TResult? Function(LoadingValue value)? loading,
    TResult? Function(Value value)? value,
    TResult? Function(ConflictValue value)? conflict,
    TResult? Function(NoneValue value)? none,
  }) {
    final _that = this;
    switch (_that) {
      case LoadingValue() when loading != null:
        return loading(_that);
      case Value() when value != null:
        return value(_that);
      case ConflictValue() when conflict != null:
        return conflict(_that);
      case NoneValue() when none != null:
        return none(_that);
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
    TResult Function()? loading,
    TResult Function(dynamic value)? value,
    TResult Function()? conflict,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadingValue() when loading != null:
        return loading();
      case Value() when value != null:
        return value(_that.value);
      case ConflictValue() when conflict != null:
        return conflict();
      case NoneValue() when none != null:
        return none();
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
    required TResult Function() loading,
    required TResult Function(dynamic value) value,
    required TResult Function() conflict,
    required TResult Function() none,
  }) {
    final _that = this;
    switch (_that) {
      case LoadingValue():
        return loading();
      case Value():
        return value(_that.value);
      case ConflictValue():
        return conflict();
      case NoneValue():
        return none();
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
    TResult? Function()? loading,
    TResult? Function(dynamic value)? value,
    TResult? Function()? conflict,
    TResult? Function()? none,
  }) {
    final _that = this;
    switch (_that) {
      case LoadingValue() when loading != null:
        return loading();
      case Value() when value != null:
        return value(_that.value);
      case ConflictValue() when conflict != null:
        return conflict();
      case NoneValue() when none != null:
        return none();
      case _:
        return null;
    }
  }
}

/// @nodoc

class LoadingValue implements SelectedValue {
  const LoadingValue();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LoadingValue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SelectedValue.loading()';
  }
}

/// @nodoc

class Value implements SelectedValue {
  const Value(this.value);

  final dynamic value;

  /// Create a copy of SelectedValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ValueCopyWith<Value> get copyWith =>
      _$ValueCopyWithImpl<Value>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Value &&
            const DeepCollectionEquality().equals(other.value, value));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(value));

  @override
  String toString() {
    return 'SelectedValue.value(value: $value)';
  }
}

/// @nodoc
abstract mixin class $ValueCopyWith<$Res>
    implements $SelectedValueCopyWith<$Res> {
  factory $ValueCopyWith(Value value, $Res Function(Value) _then) =
      _$ValueCopyWithImpl;
  @useResult
  $Res call({dynamic value});
}

/// @nodoc
class _$ValueCopyWithImpl<$Res> implements $ValueCopyWith<$Res> {
  _$ValueCopyWithImpl(this._self, this._then);

  final Value _self;
  final $Res Function(Value) _then;

  /// Create a copy of SelectedValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = freezed,
  }) {
    return _then(Value(
      freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc

class ConflictValue implements SelectedValue {
  const ConflictValue();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ConflictValue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SelectedValue.conflict()';
  }
}

/// @nodoc

class NoneValue implements SelectedValue {
  const NoneValue();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is NoneValue);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SelectedValue.none()';
  }
}

// dart format on
