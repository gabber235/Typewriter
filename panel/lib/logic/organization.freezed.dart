// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrganizationData {
  String get name;
  String get id;
  String? get iconUrl;

  /// Create a copy of OrganizationData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OrganizationDataCopyWith<OrganizationData> get copyWith =>
      _$OrganizationDataCopyWithImpl<OrganizationData>(
          this as OrganizationData, _$identity);

  /// Serializes this OrganizationData to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OrganizationData &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, id, iconUrl);

  @override
  String toString() {
    return 'OrganizationData(name: $name, id: $id, iconUrl: $iconUrl)';
  }
}

/// @nodoc
abstract mixin class $OrganizationDataCopyWith<$Res> {
  factory $OrganizationDataCopyWith(
          OrganizationData value, $Res Function(OrganizationData) _then) =
      _$OrganizationDataCopyWithImpl;
  @useResult
  $Res call({String name, String id, String? iconUrl});
}

/// @nodoc
class _$OrganizationDataCopyWithImpl<$Res>
    implements $OrganizationDataCopyWith<$Res> {
  _$OrganizationDataCopyWithImpl(this._self, this._then);

  final OrganizationData _self;
  final $Res Function(OrganizationData) _then;

  /// Create a copy of OrganizationData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? id = null,
    Object? iconUrl = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: freezed == iconUrl
          ? _self.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [OrganizationData].
extension OrganizationDataPatterns on OrganizationData {
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
    TResult Function(_OrganizationData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OrganizationData() when $default != null:
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
    TResult Function(_OrganizationData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrganizationData():
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
    TResult? Function(_OrganizationData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrganizationData() when $default != null:
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
    TResult Function(String name, String id, String? iconUrl)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OrganizationData() when $default != null:
        return $default(_that.name, _that.id, _that.iconUrl);
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
    TResult Function(String name, String id, String? iconUrl) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrganizationData():
        return $default(_that.name, _that.id, _that.iconUrl);
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
    TResult? Function(String name, String id, String? iconUrl)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OrganizationData() when $default != null:
        return $default(_that.name, _that.id, _that.iconUrl);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _OrganizationData implements OrganizationData {
  const _OrganizationData({required this.name, required this.id, this.iconUrl});
  factory _OrganizationData.fromJson(Map<String, dynamic> json) =>
      _$OrganizationDataFromJson(json);

  @override
  final String name;
  @override
  final String id;
  @override
  final String? iconUrl;

  /// Create a copy of OrganizationData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OrganizationDataCopyWith<_OrganizationData> get copyWith =>
      __$OrganizationDataCopyWithImpl<_OrganizationData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$OrganizationDataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OrganizationData &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, id, iconUrl);

  @override
  String toString() {
    return 'OrganizationData(name: $name, id: $id, iconUrl: $iconUrl)';
  }
}

/// @nodoc
abstract mixin class _$OrganizationDataCopyWith<$Res>
    implements $OrganizationDataCopyWith<$Res> {
  factory _$OrganizationDataCopyWith(
          _OrganizationData value, $Res Function(_OrganizationData) _then) =
      __$OrganizationDataCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String id, String? iconUrl});
}

/// @nodoc
class __$OrganizationDataCopyWithImpl<$Res>
    implements _$OrganizationDataCopyWith<$Res> {
  __$OrganizationDataCopyWithImpl(this._self, this._then);

  final _OrganizationData _self;
  final $Res Function(_OrganizationData) _then;

  /// Create a copy of OrganizationData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? id = null,
    Object? iconUrl = freezed,
  }) {
    return _then(_OrganizationData(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: freezed == iconUrl
          ? _self.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
