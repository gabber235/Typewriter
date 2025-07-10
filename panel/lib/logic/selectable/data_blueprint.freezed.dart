// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_blueprint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
DataBlueprint _$DataBlueprintFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'default':
      return _DataBlueprintType.fromJson(json);
    case 'primitive':
      return PrimitiveBlueprint.fromJson(json);
    case 'enum':
      return EnumBlueprint.fromJson(json);
    case 'list':
      return ListBlueprint.fromJson(json);
    case 'map':
      return MapBlueprint.fromJson(json);
    case 'object':
      return ObjectBlueprint.fromJson(json);
    case 'algebraic':
      return AlgebraicBlueprint.fromJson(json);
    case 'custom':
      return CustomBlueprint.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'DataBlueprint',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$DataBlueprint implements DiagnosticableTreeMixin {
  @JsonKey(name: "default")
  dynamic get internalDefaultValue;
  List<Modifier> get modifiers;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<DataBlueprint> get copyWith =>
      _$DataBlueprintCopyWithImpl<DataBlueprint>(
          this as DataBlueprint, _$identity);

  /// Serializes this DataBlueprint to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint'))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DataBlueprint &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality().equals(other.modifiers, modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint(internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $DataBlueprintCopyWith<$Res> {
  factory $DataBlueprintCopyWith(
          DataBlueprint value, $Res Function(DataBlueprint) _then) =
      _$DataBlueprintCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});
}

/// @nodoc
class _$DataBlueprintCopyWithImpl<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  _$DataBlueprintCopyWithImpl(this._self, this._then);

  final DataBlueprint _self;
  final $Res Function(DataBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(_self.copyWith(
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self.modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// Adds pattern-matching-related methods to [DataBlueprint].
extension DataBlueprintPatterns on DataBlueprint {
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
    TResult Function(_DataBlueprintType value)? $default, {
    TResult Function(PrimitiveBlueprint value)? primitive,
    TResult Function(EnumBlueprint value)? enumBlueprint,
    TResult Function(ListBlueprint value)? list,
    TResult Function(MapBlueprint value)? map,
    TResult Function(ObjectBlueprint value)? object,
    TResult Function(AlgebraicBlueprint value)? algebraic,
    TResult Function(CustomBlueprint value)? custom,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DataBlueprintType() when $default != null:
        return $default(_that);
      case PrimitiveBlueprint() when primitive != null:
        return primitive(_that);
      case EnumBlueprint() when enumBlueprint != null:
        return enumBlueprint(_that);
      case ListBlueprint() when list != null:
        return list(_that);
      case MapBlueprint() when map != null:
        return map(_that);
      case ObjectBlueprint() when object != null:
        return object(_that);
      case AlgebraicBlueprint() when algebraic != null:
        return algebraic(_that);
      case CustomBlueprint() when custom != null:
        return custom(_that);
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
    TResult Function(_DataBlueprintType value) $default, {
    required TResult Function(PrimitiveBlueprint value) primitive,
    required TResult Function(EnumBlueprint value) enumBlueprint,
    required TResult Function(ListBlueprint value) list,
    required TResult Function(MapBlueprint value) map,
    required TResult Function(ObjectBlueprint value) object,
    required TResult Function(AlgebraicBlueprint value) algebraic,
    required TResult Function(CustomBlueprint value) custom,
  }) {
    final _that = this;
    switch (_that) {
      case _DataBlueprintType():
        return $default(_that);
      case PrimitiveBlueprint():
        return primitive(_that);
      case EnumBlueprint():
        return enumBlueprint(_that);
      case ListBlueprint():
        return list(_that);
      case MapBlueprint():
        return map(_that);
      case ObjectBlueprint():
        return object(_that);
      case AlgebraicBlueprint():
        return algebraic(_that);
      case CustomBlueprint():
        return custom(_that);
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
    TResult? Function(_DataBlueprintType value)? $default, {
    TResult? Function(PrimitiveBlueprint value)? primitive,
    TResult? Function(EnumBlueprint value)? enumBlueprint,
    TResult? Function(ListBlueprint value)? list,
    TResult? Function(MapBlueprint value)? map,
    TResult? Function(ObjectBlueprint value)? object,
    TResult? Function(AlgebraicBlueprint value)? algebraic,
    TResult? Function(CustomBlueprint value)? custom,
  }) {
    final _that = this;
    switch (_that) {
      case _DataBlueprintType() when $default != null:
        return $default(_that);
      case PrimitiveBlueprint() when primitive != null:
        return primitive(_that);
      case EnumBlueprint() when enumBlueprint != null:
        return enumBlueprint(_that);
      case ListBlueprint() when list != null:
        return list(_that);
      case MapBlueprint() when map != null:
        return map(_that);
      case ObjectBlueprint() when object != null:
        return object(_that);
      case AlgebraicBlueprint() when algebraic != null:
        return algebraic(_that);
      case CustomBlueprint() when custom != null:
        return custom(_that);
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
    TResult Function(@JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        $default, {
    TResult Function(
            PrimitiveType type,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        primitive,
    TResult Function(
            List<String> values,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        enumBlueprint,
    TResult Function(
            DataBlueprint type,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        list,
    TResult Function(
            DataBlueprint key,
            DataBlueprint value,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        map,
    TResult Function(
            Map<String, DataBlueprint> fields,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        object,
    TResult Function(
            Map<String, DataBlueprint> cases,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        algebraic,
    TResult Function(
            String editor,
            DataBlueprint shape,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        custom,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DataBlueprintType() when $default != null:
        return $default(_that.internalDefaultValue, _that.modifiers);
      case PrimitiveBlueprint() when primitive != null:
        return primitive(
            _that.type, _that.internalDefaultValue, _that.modifiers);
      case EnumBlueprint() when enumBlueprint != null:
        return enumBlueprint(
            _that.values, _that.internalDefaultValue, _that.modifiers);
      case ListBlueprint() when list != null:
        return list(_that.type, _that.internalDefaultValue, _that.modifiers);
      case MapBlueprint() when map != null:
        return map(_that.key, _that.value, _that.internalDefaultValue,
            _that.modifiers);
      case ObjectBlueprint() when object != null:
        return object(
            _that.fields, _that.internalDefaultValue, _that.modifiers);
      case AlgebraicBlueprint() when algebraic != null:
        return algebraic(
            _that.cases, _that.internalDefaultValue, _that.modifiers);
      case CustomBlueprint() when custom != null:
        return custom(_that.editor, _that.shape, _that.internalDefaultValue,
            _that.modifiers);
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
    TResult Function(@JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        $default, {
    required TResult Function(
            PrimitiveType type,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        primitive,
    required TResult Function(
            List<String> values,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        enumBlueprint,
    required TResult Function(
            DataBlueprint type,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        list,
    required TResult Function(
            DataBlueprint key,
            DataBlueprint value,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        map,
    required TResult Function(
            Map<String, DataBlueprint> fields,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        object,
    required TResult Function(
            Map<String, DataBlueprint> cases,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        algebraic,
    required TResult Function(
            String editor,
            DataBlueprint shape,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)
        custom,
  }) {
    final _that = this;
    switch (_that) {
      case _DataBlueprintType():
        return $default(_that.internalDefaultValue, _that.modifiers);
      case PrimitiveBlueprint():
        return primitive(
            _that.type, _that.internalDefaultValue, _that.modifiers);
      case EnumBlueprint():
        return enumBlueprint(
            _that.values, _that.internalDefaultValue, _that.modifiers);
      case ListBlueprint():
        return list(_that.type, _that.internalDefaultValue, _that.modifiers);
      case MapBlueprint():
        return map(_that.key, _that.value, _that.internalDefaultValue,
            _that.modifiers);
      case ObjectBlueprint():
        return object(
            _that.fields, _that.internalDefaultValue, _that.modifiers);
      case AlgebraicBlueprint():
        return algebraic(
            _that.cases, _that.internalDefaultValue, _that.modifiers);
      case CustomBlueprint():
        return custom(_that.editor, _that.shape, _that.internalDefaultValue,
            _that.modifiers);
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
    TResult? Function(@JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        $default, {
    TResult? Function(
            PrimitiveType type,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        primitive,
    TResult? Function(
            List<String> values,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        enumBlueprint,
    TResult? Function(
            DataBlueprint type,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        list,
    TResult? Function(
            DataBlueprint key,
            DataBlueprint value,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        map,
    TResult? Function(
            Map<String, DataBlueprint> fields,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        object,
    TResult? Function(
            Map<String, DataBlueprint> cases,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        algebraic,
    TResult? Function(
            String editor,
            DataBlueprint shape,
            @JsonKey(name: "default") dynamic internalDefaultValue,
            List<Modifier> modifiers)?
        custom,
  }) {
    final _that = this;
    switch (_that) {
      case _DataBlueprintType() when $default != null:
        return $default(_that.internalDefaultValue, _that.modifiers);
      case PrimitiveBlueprint() when primitive != null:
        return primitive(
            _that.type, _that.internalDefaultValue, _that.modifiers);
      case EnumBlueprint() when enumBlueprint != null:
        return enumBlueprint(
            _that.values, _that.internalDefaultValue, _that.modifiers);
      case ListBlueprint() when list != null:
        return list(_that.type, _that.internalDefaultValue, _that.modifiers);
      case MapBlueprint() when map != null:
        return map(_that.key, _that.value, _that.internalDefaultValue,
            _that.modifiers);
      case ObjectBlueprint() when object != null:
        return object(
            _that.fields, _that.internalDefaultValue, _that.modifiers);
      case AlgebraicBlueprint() when algebraic != null:
        return algebraic(
            _that.cases, _that.internalDefaultValue, _that.modifiers);
      case CustomBlueprint() when custom != null:
        return custom(_that.editor, _that.shape, _that.internalDefaultValue,
            _that.modifiers);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _DataBlueprintType with DiagnosticableTreeMixin implements DataBlueprint {
  const _DataBlueprintType(
      {@JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _modifiers = modifiers,
        $type = $type ?? 'default';
  factory _DataBlueprintType.fromJson(Map<String, dynamic> json) =>
      _$DataBlueprintTypeFromJson(json);

  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DataBlueprintTypeCopyWith<_DataBlueprintType> get copyWith =>
      __$DataBlueprintTypeCopyWithImpl<_DataBlueprintType>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DataBlueprintTypeToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint'))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DataBlueprintType &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint(internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class _$DataBlueprintTypeCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory _$DataBlueprintTypeCopyWith(
          _DataBlueprintType value, $Res Function(_DataBlueprintType) _then) =
      __$DataBlueprintTypeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});
}

/// @nodoc
class __$DataBlueprintTypeCopyWithImpl<$Res>
    implements _$DataBlueprintTypeCopyWith<$Res> {
  __$DataBlueprintTypeCopyWithImpl(this._self, this._then);

  final _DataBlueprintType _self;
  final $Res Function(_DataBlueprintType) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(_DataBlueprintType(
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class PrimitiveBlueprint with DiagnosticableTreeMixin implements DataBlueprint {
  const PrimitiveBlueprint(
      {required this.type,
      @JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _modifiers = modifiers,
        $type = $type ?? 'primitive';
  factory PrimitiveBlueprint.fromJson(Map<String, dynamic> json) =>
      _$PrimitiveBlueprintFromJson(json);

  final PrimitiveType type;
  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PrimitiveBlueprintCopyWith<PrimitiveBlueprint> get copyWith =>
      _$PrimitiveBlueprintCopyWithImpl<PrimitiveBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PrimitiveBlueprintToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint.primitive'))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PrimitiveBlueprint &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint.primitive(type: $type, internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $PrimitiveBlueprintCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory $PrimitiveBlueprintCopyWith(
          PrimitiveBlueprint value, $Res Function(PrimitiveBlueprint) _then) =
      _$PrimitiveBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {PrimitiveType type,
      @JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});
}

/// @nodoc
class _$PrimitiveBlueprintCopyWithImpl<$Res>
    implements $PrimitiveBlueprintCopyWith<$Res> {
  _$PrimitiveBlueprintCopyWithImpl(this._self, this._then);

  final PrimitiveBlueprint _self;
  final $Res Function(PrimitiveBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(PrimitiveBlueprint(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as PrimitiveType,
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class EnumBlueprint with DiagnosticableTreeMixin implements DataBlueprint {
  const EnumBlueprint(
      {required final List<String> values,
      @JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _values = values,
        _modifiers = modifiers,
        $type = $type ?? 'enum';
  factory EnumBlueprint.fromJson(Map<String, dynamic> json) =>
      _$EnumBlueprintFromJson(json);

  final List<String> _values;
  List<String> get values {
    if (_values is EqualUnmodifiableListView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_values);
  }

  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EnumBlueprintCopyWith<EnumBlueprint> get copyWith =>
      _$EnumBlueprintCopyWithImpl<EnumBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EnumBlueprintToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint.enumBlueprint'))
      ..add(DiagnosticsProperty('values', values))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EnumBlueprint &&
            const DeepCollectionEquality().equals(other._values, _values) &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_values),
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint.enumBlueprint(values: $values, internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $EnumBlueprintCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory $EnumBlueprintCopyWith(
          EnumBlueprint value, $Res Function(EnumBlueprint) _then) =
      _$EnumBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<String> values,
      @JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});
}

/// @nodoc
class _$EnumBlueprintCopyWithImpl<$Res>
    implements $EnumBlueprintCopyWith<$Res> {
  _$EnumBlueprintCopyWithImpl(this._self, this._then);

  final EnumBlueprint _self;
  final $Res Function(EnumBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? values = null,
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(EnumBlueprint(
      values: null == values
          ? _self._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<String>,
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class ListBlueprint with DiagnosticableTreeMixin implements DataBlueprint {
  const ListBlueprint(
      {required this.type,
      @JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _modifiers = modifiers,
        $type = $type ?? 'list';
  factory ListBlueprint.fromJson(Map<String, dynamic> json) =>
      _$ListBlueprintFromJson(json);

  final DataBlueprint type;
  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ListBlueprintCopyWith<ListBlueprint> get copyWith =>
      _$ListBlueprintCopyWithImpl<ListBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ListBlueprintToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint.list'))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ListBlueprint &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint.list(type: $type, internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $ListBlueprintCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory $ListBlueprintCopyWith(
          ListBlueprint value, $Res Function(ListBlueprint) _then) =
      _$ListBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DataBlueprint type,
      @JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});

  $DataBlueprintCopyWith<$Res> get type;
}

/// @nodoc
class _$ListBlueprintCopyWithImpl<$Res>
    implements $ListBlueprintCopyWith<$Res> {
  _$ListBlueprintCopyWithImpl(this._self, this._then);

  final ListBlueprint _self;
  final $Res Function(ListBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(ListBlueprint(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res> get type {
    return $DataBlueprintCopyWith<$Res>(_self.type, (value) {
      return _then(_self.copyWith(type: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class MapBlueprint with DiagnosticableTreeMixin implements DataBlueprint {
  const MapBlueprint(
      {required this.key,
      required this.value,
      @JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _modifiers = modifiers,
        $type = $type ?? 'map';
  factory MapBlueprint.fromJson(Map<String, dynamic> json) =>
      _$MapBlueprintFromJson(json);

  final DataBlueprint key;
  final DataBlueprint value;
  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MapBlueprintCopyWith<MapBlueprint> get copyWith =>
      _$MapBlueprintCopyWithImpl<MapBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MapBlueprintToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint.map'))
      ..add(DiagnosticsProperty('key', key))
      ..add(DiagnosticsProperty('value', value))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MapBlueprint &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      key,
      value,
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint.map(key: $key, value: $value, internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $MapBlueprintCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory $MapBlueprintCopyWith(
          MapBlueprint value, $Res Function(MapBlueprint) _then) =
      _$MapBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DataBlueprint key,
      DataBlueprint value,
      @JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});

  $DataBlueprintCopyWith<$Res> get key;
  $DataBlueprintCopyWith<$Res> get value;
}

/// @nodoc
class _$MapBlueprintCopyWithImpl<$Res> implements $MapBlueprintCopyWith<$Res> {
  _$MapBlueprintCopyWithImpl(this._self, this._then);

  final MapBlueprint _self;
  final $Res Function(MapBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? key = null,
    Object? value = null,
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(MapBlueprint(
      key: null == key
          ? _self.key
          : key // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res> get key {
    return $DataBlueprintCopyWith<$Res>(_self.key, (value) {
      return _then(_self.copyWith(key: value));
    });
  }

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res> get value {
    return $DataBlueprintCopyWith<$Res>(_self.value, (value) {
      return _then(_self.copyWith(value: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class ObjectBlueprint with DiagnosticableTreeMixin implements DataBlueprint {
  const ObjectBlueprint(
      {required final Map<String, DataBlueprint> fields,
      @JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _fields = fields,
        _modifiers = modifiers,
        $type = $type ?? 'object';
  factory ObjectBlueprint.fromJson(Map<String, dynamic> json) =>
      _$ObjectBlueprintFromJson(json);

  final Map<String, DataBlueprint> _fields;
  Map<String, DataBlueprint> get fields {
    if (_fields is EqualUnmodifiableMapView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_fields);
  }

  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ObjectBlueprintCopyWith<ObjectBlueprint> get copyWith =>
      _$ObjectBlueprintCopyWithImpl<ObjectBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ObjectBlueprintToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint.object'))
      ..add(DiagnosticsProperty('fields', fields))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ObjectBlueprint &&
            const DeepCollectionEquality().equals(other._fields, _fields) &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_fields),
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint.object(fields: $fields, internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $ObjectBlueprintCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory $ObjectBlueprintCopyWith(
          ObjectBlueprint value, $Res Function(ObjectBlueprint) _then) =
      _$ObjectBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Map<String, DataBlueprint> fields,
      @JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});
}

/// @nodoc
class _$ObjectBlueprintCopyWithImpl<$Res>
    implements $ObjectBlueprintCopyWith<$Res> {
  _$ObjectBlueprintCopyWithImpl(this._self, this._then);

  final ObjectBlueprint _self;
  final $Res Function(ObjectBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fields = null,
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(ObjectBlueprint(
      fields: null == fields
          ? _self._fields
          : fields // ignore: cast_nullable_to_non_nullable
              as Map<String, DataBlueprint>,
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class AlgebraicBlueprint with DiagnosticableTreeMixin implements DataBlueprint {
  const AlgebraicBlueprint(
      {required final Map<String, DataBlueprint> cases,
      @JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _cases = cases,
        _modifiers = modifiers,
        $type = $type ?? 'algebraic';
  factory AlgebraicBlueprint.fromJson(Map<String, dynamic> json) =>
      _$AlgebraicBlueprintFromJson(json);

  final Map<String, DataBlueprint> _cases;
  Map<String, DataBlueprint> get cases {
    if (_cases is EqualUnmodifiableMapView) return _cases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_cases);
  }

  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AlgebraicBlueprintCopyWith<AlgebraicBlueprint> get copyWith =>
      _$AlgebraicBlueprintCopyWithImpl<AlgebraicBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AlgebraicBlueprintToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint.algebraic'))
      ..add(DiagnosticsProperty('cases', cases))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AlgebraicBlueprint &&
            const DeepCollectionEquality().equals(other._cases, _cases) &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_cases),
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint.algebraic(cases: $cases, internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $AlgebraicBlueprintCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory $AlgebraicBlueprintCopyWith(
          AlgebraicBlueprint value, $Res Function(AlgebraicBlueprint) _then) =
      _$AlgebraicBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Map<String, DataBlueprint> cases,
      @JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});
}

/// @nodoc
class _$AlgebraicBlueprintCopyWithImpl<$Res>
    implements $AlgebraicBlueprintCopyWith<$Res> {
  _$AlgebraicBlueprintCopyWithImpl(this._self, this._then);

  final AlgebraicBlueprint _self;
  final $Res Function(AlgebraicBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cases = null,
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(AlgebraicBlueprint(
      cases: null == cases
          ? _self._cases
          : cases // ignore: cast_nullable_to_non_nullable
              as Map<String, DataBlueprint>,
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class CustomBlueprint with DiagnosticableTreeMixin implements DataBlueprint {
  const CustomBlueprint(
      {required this.editor,
      required this.shape,
      @JsonKey(name: "default") this.internalDefaultValue,
      final List<Modifier> modifiers = const [],
      final String? $type})
      : _modifiers = modifiers,
        $type = $type ?? 'custom';
  factory CustomBlueprint.fromJson(Map<String, dynamic> json) =>
      _$CustomBlueprintFromJson(json);

  final String editor;
  final DataBlueprint shape;
  @override
  @JsonKey(name: "default")
  final dynamic internalDefaultValue;
  final List<Modifier> _modifiers;
  @override
  @JsonKey()
  List<Modifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CustomBlueprintCopyWith<CustomBlueprint> get copyWith =>
      _$CustomBlueprintCopyWithImpl<CustomBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CustomBlueprintToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DataBlueprint.custom'))
      ..add(DiagnosticsProperty('editor', editor))
      ..add(DiagnosticsProperty('shape', shape))
      ..add(DiagnosticsProperty('internalDefaultValue', internalDefaultValue))
      ..add(DiagnosticsProperty('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CustomBlueprint &&
            (identical(other.editor, editor) || other.editor == editor) &&
            (identical(other.shape, shape) || other.shape == shape) &&
            const DeepCollectionEquality()
                .equals(other.internalDefaultValue, internalDefaultValue) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      editor,
      shape,
      const DeepCollectionEquality().hash(internalDefaultValue),
      const DeepCollectionEquality().hash(_modifiers));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DataBlueprint.custom(editor: $editor, shape: $shape, internalDefaultValue: $internalDefaultValue, modifiers: $modifiers)';
  }
}

/// @nodoc
abstract mixin class $CustomBlueprintCopyWith<$Res>
    implements $DataBlueprintCopyWith<$Res> {
  factory $CustomBlueprintCopyWith(
          CustomBlueprint value, $Res Function(CustomBlueprint) _then) =
      _$CustomBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String editor,
      DataBlueprint shape,
      @JsonKey(name: "default") dynamic internalDefaultValue,
      List<Modifier> modifiers});

  $DataBlueprintCopyWith<$Res> get shape;
}

/// @nodoc
class _$CustomBlueprintCopyWithImpl<$Res>
    implements $CustomBlueprintCopyWith<$Res> {
  _$CustomBlueprintCopyWithImpl(this._self, this._then);

  final CustomBlueprint _self;
  final $Res Function(CustomBlueprint) _then;

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? editor = null,
    Object? shape = null,
    Object? internalDefaultValue = freezed,
    Object? modifiers = null,
  }) {
    return _then(CustomBlueprint(
      editor: null == editor
          ? _self.editor
          : editor // ignore: cast_nullable_to_non_nullable
              as String,
      shape: null == shape
          ? _self.shape
          : shape // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
      internalDefaultValue: freezed == internalDefaultValue
          ? _self.internalDefaultValue
          : internalDefaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<Modifier>,
    ));
  }

  /// Create a copy of DataBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res> get shape {
    return $DataBlueprintCopyWith<$Res>(_self.shape, (value) {
      return _then(_self.copyWith(shape: value));
    });
  }
}

Modifier _$ModifierFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'multiline':
      return MultilineModifier.fromJson(json);
    case 'snakeCase':
      return SnakeCaseModifier.fromJson(json);
    case 'generated':
      return GeneratedModifier.fromJson(json);
    case 'min':
      return MinModifier.fromJson(json);
    case 'max':
      return MaxModifier.fromJson(json);
    case 'negative':
      return NegativeModifier.fromJson(json);
    case 'custom':
      return CustomModifier.fromJson(json);

    default:
      throw CheckedFromJsonException(
          json, 'kind', 'Modifier', 'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$Modifier implements DiagnosticableTreeMixin {
  /// Serializes this Modifier to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties..add(DiagnosticsProperty('type', 'Modifier'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is Modifier);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier()';
  }
}

/// @nodoc
class $ModifierCopyWith<$Res> {
  $ModifierCopyWith(Modifier _, $Res Function(Modifier) __);
}

/// Adds pattern-matching-related methods to [Modifier].
extension ModifierPatterns on Modifier {
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
    TResult Function(MultilineModifier value)? multiline,
    TResult Function(SnakeCaseModifier value)? snakeCase,
    TResult Function(GeneratedModifier value)? generated,
    TResult Function(MinModifier value)? min,
    TResult Function(MaxModifier value)? max,
    TResult Function(NegativeModifier value)? negative,
    TResult Function(CustomModifier value)? custom,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case MultilineModifier() when multiline != null:
        return multiline(_that);
      case SnakeCaseModifier() when snakeCase != null:
        return snakeCase(_that);
      case GeneratedModifier() when generated != null:
        return generated(_that);
      case MinModifier() when min != null:
        return min(_that);
      case MaxModifier() when max != null:
        return max(_that);
      case NegativeModifier() when negative != null:
        return negative(_that);
      case CustomModifier() when custom != null:
        return custom(_that);
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
    required TResult Function(MultilineModifier value) multiline,
    required TResult Function(SnakeCaseModifier value) snakeCase,
    required TResult Function(GeneratedModifier value) generated,
    required TResult Function(MinModifier value) min,
    required TResult Function(MaxModifier value) max,
    required TResult Function(NegativeModifier value) negative,
    required TResult Function(CustomModifier value) custom,
  }) {
    final _that = this;
    switch (_that) {
      case MultilineModifier():
        return multiline(_that);
      case SnakeCaseModifier():
        return snakeCase(_that);
      case GeneratedModifier():
        return generated(_that);
      case MinModifier():
        return min(_that);
      case MaxModifier():
        return max(_that);
      case NegativeModifier():
        return negative(_that);
      case CustomModifier():
        return custom(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MultilineModifier value)? multiline,
    TResult? Function(SnakeCaseModifier value)? snakeCase,
    TResult? Function(GeneratedModifier value)? generated,
    TResult? Function(MinModifier value)? min,
    TResult? Function(MaxModifier value)? max,
    TResult? Function(NegativeModifier value)? negative,
    TResult? Function(CustomModifier value)? custom,
  }) {
    final _that = this;
    switch (_that) {
      case MultilineModifier() when multiline != null:
        return multiline(_that);
      case SnakeCaseModifier() when snakeCase != null:
        return snakeCase(_that);
      case GeneratedModifier() when generated != null:
        return generated(_that);
      case MinModifier() when min != null:
        return min(_that);
      case MaxModifier() when max != null:
        return max(_that);
      case NegativeModifier() when negative != null:
        return negative(_that);
      case CustomModifier() when custom != null:
        return custom(_that);
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
    TResult Function()? multiline,
    TResult Function()? snakeCase,
    TResult Function()? generated,
    TResult Function(num value)? min,
    TResult Function(num value)? max,
    TResult Function()? negative,
    TResult Function(String name, dynamic data)? custom,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case MultilineModifier() when multiline != null:
        return multiline();
      case SnakeCaseModifier() when snakeCase != null:
        return snakeCase();
      case GeneratedModifier() when generated != null:
        return generated();
      case MinModifier() when min != null:
        return min(_that.value);
      case MaxModifier() when max != null:
        return max(_that.value);
      case NegativeModifier() when negative != null:
        return negative();
      case CustomModifier() when custom != null:
        return custom(_that.name, _that.data);
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
    required TResult Function() multiline,
    required TResult Function() snakeCase,
    required TResult Function() generated,
    required TResult Function(num value) min,
    required TResult Function(num value) max,
    required TResult Function() negative,
    required TResult Function(String name, dynamic data) custom,
  }) {
    final _that = this;
    switch (_that) {
      case MultilineModifier():
        return multiline();
      case SnakeCaseModifier():
        return snakeCase();
      case GeneratedModifier():
        return generated();
      case MinModifier():
        return min(_that.value);
      case MaxModifier():
        return max(_that.value);
      case NegativeModifier():
        return negative();
      case CustomModifier():
        return custom(_that.name, _that.data);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? multiline,
    TResult? Function()? snakeCase,
    TResult? Function()? generated,
    TResult? Function(num value)? min,
    TResult? Function(num value)? max,
    TResult? Function()? negative,
    TResult? Function(String name, dynamic data)? custom,
  }) {
    final _that = this;
    switch (_that) {
      case MultilineModifier() when multiline != null:
        return multiline();
      case SnakeCaseModifier() when snakeCase != null:
        return snakeCase();
      case GeneratedModifier() when generated != null:
        return generated();
      case MinModifier() when min != null:
        return min(_that.value);
      case MaxModifier() when max != null:
        return max(_that.value);
      case NegativeModifier() when negative != null:
        return negative();
      case CustomModifier() when custom != null:
        return custom(_that.name, _that.data);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class MultilineModifier with DiagnosticableTreeMixin implements Modifier {
  const MultilineModifier({final String? $type}) : $type = $type ?? 'multiline';
  factory MultilineModifier.fromJson(Map<String, dynamic> json) =>
      _$MultilineModifierFromJson(json);

  @JsonKey(name: 'kind')
  final String $type;

  @override
  Map<String, dynamic> toJson() {
    return _$MultilineModifierToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties..add(DiagnosticsProperty('type', 'Modifier.multiline'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MultilineModifier);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier.multiline()';
  }
}

/// @nodoc
@JsonSerializable()
class SnakeCaseModifier with DiagnosticableTreeMixin implements Modifier {
  const SnakeCaseModifier({final String? $type}) : $type = $type ?? 'snakeCase';
  factory SnakeCaseModifier.fromJson(Map<String, dynamic> json) =>
      _$SnakeCaseModifierFromJson(json);

  @JsonKey(name: 'kind')
  final String $type;

  @override
  Map<String, dynamic> toJson() {
    return _$SnakeCaseModifierToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties..add(DiagnosticsProperty('type', 'Modifier.snakeCase'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SnakeCaseModifier);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier.snakeCase()';
  }
}

/// @nodoc
@JsonSerializable()
class GeneratedModifier with DiagnosticableTreeMixin implements Modifier {
  const GeneratedModifier({final String? $type}) : $type = $type ?? 'generated';
  factory GeneratedModifier.fromJson(Map<String, dynamic> json) =>
      _$GeneratedModifierFromJson(json);

  @JsonKey(name: 'kind')
  final String $type;

  @override
  Map<String, dynamic> toJson() {
    return _$GeneratedModifierToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties..add(DiagnosticsProperty('type', 'Modifier.generated'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is GeneratedModifier);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier.generated()';
  }
}

/// @nodoc
@JsonSerializable()
class MinModifier with DiagnosticableTreeMixin implements Modifier {
  const MinModifier(this.value, {final String? $type}) : $type = $type ?? 'min';
  factory MinModifier.fromJson(Map<String, dynamic> json) =>
      _$MinModifierFromJson(json);

  final num value;

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MinModifierCopyWith<MinModifier> get copyWith =>
      _$MinModifierCopyWithImpl<MinModifier>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MinModifierToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'Modifier.min'))
      ..add(DiagnosticsProperty('value', value));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MinModifier &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier.min(value: $value)';
  }
}

/// @nodoc
abstract mixin class $MinModifierCopyWith<$Res>
    implements $ModifierCopyWith<$Res> {
  factory $MinModifierCopyWith(
          MinModifier value, $Res Function(MinModifier) _then) =
      _$MinModifierCopyWithImpl;
  @useResult
  $Res call({num value});
}

/// @nodoc
class _$MinModifierCopyWithImpl<$Res> implements $MinModifierCopyWith<$Res> {
  _$MinModifierCopyWithImpl(this._self, this._then);

  final MinModifier _self;
  final $Res Function(MinModifier) _then;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
  }) {
    return _then(MinModifier(
      null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class MaxModifier with DiagnosticableTreeMixin implements Modifier {
  const MaxModifier(this.value, {final String? $type}) : $type = $type ?? 'max';
  factory MaxModifier.fromJson(Map<String, dynamic> json) =>
      _$MaxModifierFromJson(json);

  final num value;

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MaxModifierCopyWith<MaxModifier> get copyWith =>
      _$MaxModifierCopyWithImpl<MaxModifier>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MaxModifierToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'Modifier.max'))
      ..add(DiagnosticsProperty('value', value));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MaxModifier &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier.max(value: $value)';
  }
}

/// @nodoc
abstract mixin class $MaxModifierCopyWith<$Res>
    implements $ModifierCopyWith<$Res> {
  factory $MaxModifierCopyWith(
          MaxModifier value, $Res Function(MaxModifier) _then) =
      _$MaxModifierCopyWithImpl;
  @useResult
  $Res call({num value});
}

/// @nodoc
class _$MaxModifierCopyWithImpl<$Res> implements $MaxModifierCopyWith<$Res> {
  _$MaxModifierCopyWithImpl(this._self, this._then);

  final MaxModifier _self;
  final $Res Function(MaxModifier) _then;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? value = null,
  }) {
    return _then(MaxModifier(
      null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class NegativeModifier with DiagnosticableTreeMixin implements Modifier {
  const NegativeModifier({final String? $type}) : $type = $type ?? 'negative';
  factory NegativeModifier.fromJson(Map<String, dynamic> json) =>
      _$NegativeModifierFromJson(json);

  @JsonKey(name: 'kind')
  final String $type;

  @override
  Map<String, dynamic> toJson() {
    return _$NegativeModifierToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties..add(DiagnosticsProperty('type', 'Modifier.negative'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is NegativeModifier);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier.negative()';
  }
}

/// @nodoc
@JsonSerializable()
class CustomModifier with DiagnosticableTreeMixin implements Modifier {
  const CustomModifier(
      {required this.name, required this.data, final String? $type})
      : $type = $type ?? 'custom';
  factory CustomModifier.fromJson(Map<String, dynamic> json) =>
      _$CustomModifierFromJson(json);

  final String name;
  final dynamic data;

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CustomModifierCopyWith<CustomModifier> get copyWith =>
      _$CustomModifierCopyWithImpl<CustomModifier>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CustomModifierToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'Modifier.custom'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CustomModifier &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, const DeepCollectionEquality().hash(data));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Modifier.custom(name: $name, data: $data)';
  }
}

/// @nodoc
abstract mixin class $CustomModifierCopyWith<$Res>
    implements $ModifierCopyWith<$Res> {
  factory $CustomModifierCopyWith(
          CustomModifier value, $Res Function(CustomModifier) _then) =
      _$CustomModifierCopyWithImpl;
  @useResult
  $Res call({String name, dynamic data});
}

/// @nodoc
class _$CustomModifierCopyWithImpl<$Res>
    implements $CustomModifierCopyWith<$Res> {
  _$CustomModifierCopyWithImpl(this._self, this._then);

  final CustomModifier _self;
  final $Res Function(CustomModifier) _then;

  /// Create a copy of Modifier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? data = freezed,
  }) {
    return _then(CustomModifier(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

// dart format on
