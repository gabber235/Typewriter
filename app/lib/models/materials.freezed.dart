// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'materials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MinecraftMaterial _$MinecraftMaterialFromJson(Map<String, dynamic> json) {
  return _MinecraftMaterial.fromJson(json);
}

/// @nodoc
mixin _$MinecraftMaterial {
  String get name => throw _privateConstructorUsedError;
  List<MaterialProperty> get properties => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  McVersion? get since => throw _privateConstructorUsedError;

  /// Serializes this MinecraftMaterial to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MinecraftMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MinecraftMaterialCopyWith<MinecraftMaterial> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MinecraftMaterialCopyWith<$Res> {
  factory $MinecraftMaterialCopyWith(
          MinecraftMaterial value, $Res Function(MinecraftMaterial) then) =
      _$MinecraftMaterialCopyWithImpl<$Res, MinecraftMaterial>;
  @useResult
  $Res call(
      {String name,
      List<MaterialProperty> properties,
      String icon,
      McVersion? since});
}

/// @nodoc
class _$MinecraftMaterialCopyWithImpl<$Res, $Val extends MinecraftMaterial>
    implements $MinecraftMaterialCopyWith<$Res> {
  _$MinecraftMaterialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MinecraftMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? properties = null,
    Object? icon = null,
    Object? since = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<MaterialProperty>,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      since: freezed == since
          ? _value.since
          : since // ignore: cast_nullable_to_non_nullable
              as McVersion?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MinecraftMaterialImplCopyWith<$Res>
    implements $MinecraftMaterialCopyWith<$Res> {
  factory _$$MinecraftMaterialImplCopyWith(_$MinecraftMaterialImpl value,
          $Res Function(_$MinecraftMaterialImpl) then) =
      __$$MinecraftMaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      List<MaterialProperty> properties,
      String icon,
      McVersion? since});
}

/// @nodoc
class __$$MinecraftMaterialImplCopyWithImpl<$Res>
    extends _$MinecraftMaterialCopyWithImpl<$Res, _$MinecraftMaterialImpl>
    implements _$$MinecraftMaterialImplCopyWith<$Res> {
  __$$MinecraftMaterialImplCopyWithImpl(_$MinecraftMaterialImpl _value,
      $Res Function(_$MinecraftMaterialImpl) _then)
      : super(_value, _then);

  /// Create a copy of MinecraftMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? properties = null,
    Object? icon = null,
    Object? since = freezed,
  }) {
    return _then(_$MinecraftMaterialImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as List<MaterialProperty>,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      since: freezed == since
          ? _value.since
          : since // ignore: cast_nullable_to_non_nullable
              as McVersion?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MinecraftMaterialImpl implements _MinecraftMaterial {
  const _$MinecraftMaterialImpl(
      {required this.name,
      required final List<MaterialProperty> properties,
      required this.icon,
      this.since})
      : _properties = properties;

  factory _$MinecraftMaterialImpl.fromJson(Map<String, dynamic> json) =>
      _$$MinecraftMaterialImplFromJson(json);

  @override
  final String name;
  final List<MaterialProperty> _properties;
  @override
  List<MaterialProperty> get properties {
    if (_properties is EqualUnmodifiableListView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_properties);
  }

  @override
  final String icon;
  @override
  final McVersion? since;

  @override
  String toString() {
    return 'MinecraftMaterial(name: $name, properties: $properties, icon: $icon, since: $since)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MinecraftMaterialImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.since, since) || other.since == since));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name,
      const DeepCollectionEquality().hash(_properties), icon, since);

  /// Create a copy of MinecraftMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MinecraftMaterialImplCopyWith<_$MinecraftMaterialImpl> get copyWith =>
      __$$MinecraftMaterialImplCopyWithImpl<_$MinecraftMaterialImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MinecraftMaterialImplToJson(
      this,
    );
  }
}

abstract class _MinecraftMaterial implements MinecraftMaterial {
  const factory _MinecraftMaterial(
      {required final String name,
      required final List<MaterialProperty> properties,
      required final String icon,
      final McVersion? since}) = _$MinecraftMaterialImpl;

  factory _MinecraftMaterial.fromJson(Map<String, dynamic> json) =
      _$MinecraftMaterialImpl.fromJson;

  @override
  String get name;
  @override
  List<MaterialProperty> get properties;
  @override
  String get icon;
  @override
  McVersion? get since;

  /// Create a copy of MinecraftMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MinecraftMaterialImplCopyWith<_$MinecraftMaterialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
