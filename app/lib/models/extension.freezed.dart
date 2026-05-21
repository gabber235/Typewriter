// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'extension.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Extension _$ExtensionFromJson(Map<String, dynamic> json) {
  return _Extension.fromJson(json);
}

/// @nodoc
mixin _$Extension {
  ExtensionInfo get extension => throw _privateConstructorUsedError;
  List<EntryBlueprint> get entries => throw _privateConstructorUsedError;
  List<GlobalContextKey> get globalContextKeys =>
      throw _privateConstructorUsedError;
  Map<String, Map<String, String>> get translations =>
      throw _privateConstructorUsedError;

  /// Serializes this Extension to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Extension
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExtensionCopyWith<Extension> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExtensionCopyWith<$Res> {
  factory $ExtensionCopyWith(Extension value, $Res Function(Extension) then) =
      _$ExtensionCopyWithImpl<$Res, Extension>;
  @useResult
  $Res call(
      {ExtensionInfo extension,
      List<EntryBlueprint> entries,
      List<GlobalContextKey> globalContextKeys,
      Map<String, Map<String, String>> translations});

  $ExtensionInfoCopyWith<$Res> get extension;
}

/// @nodoc
class _$ExtensionCopyWithImpl<$Res, $Val extends Extension>
    implements $ExtensionCopyWith<$Res> {
  _$ExtensionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Extension
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? extension = null,
    Object? entries = null,
    Object? globalContextKeys = null,
    Object? translations = null,
  }) {
    return _then(_value.copyWith(
      extension: null == extension
          ? _value.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as ExtensionInfo,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<EntryBlueprint>,
      globalContextKeys: null == globalContextKeys
          ? _value.globalContextKeys
          : globalContextKeys // ignore: cast_nullable_to_non_nullable
              as List<GlobalContextKey>,
      translations: null == translations
          ? _value.translations
          : translations // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, String>>,
    ) as $Val);
  }

  /// Create a copy of Extension
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExtensionInfoCopyWith<$Res> get extension {
    return $ExtensionInfoCopyWith<$Res>(_value.extension, (value) {
      return _then(_value.copyWith(extension: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExtensionImplCopyWith<$Res>
    implements $ExtensionCopyWith<$Res> {
  factory _$$ExtensionImplCopyWith(
          _$ExtensionImpl value, $Res Function(_$ExtensionImpl) then) =
      __$$ExtensionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ExtensionInfo extension,
      List<EntryBlueprint> entries,
      List<GlobalContextKey> globalContextKeys,
      Map<String, Map<String, String>> translations});

  @override
  $ExtensionInfoCopyWith<$Res> get extension;
}

/// @nodoc
class __$$ExtensionImplCopyWithImpl<$Res>
    extends _$ExtensionCopyWithImpl<$Res, _$ExtensionImpl>
    implements _$$ExtensionImplCopyWith<$Res> {
  __$$ExtensionImplCopyWithImpl(
      _$ExtensionImpl _value, $Res Function(_$ExtensionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Extension
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? extension = null,
    Object? entries = null,
    Object? globalContextKeys = null,
    Object? translations = null,
  }) {
    return _then(_$ExtensionImpl(
      extension: null == extension
          ? _value.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as ExtensionInfo,
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<EntryBlueprint>,
      globalContextKeys: null == globalContextKeys
          ? _value._globalContextKeys
          : globalContextKeys // ignore: cast_nullable_to_non_nullable
              as List<GlobalContextKey>,
      translations: null == translations
          ? _value._translations
          : translations // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, String>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExtensionImpl with DiagnosticableTreeMixin implements _Extension {
  const _$ExtensionImpl(
      {required this.extension,
      final List<EntryBlueprint> entries = const [],
      final List<GlobalContextKey> globalContextKeys = const [],
      final Map<String, Map<String, String>> translations = const {}})
      : _entries = entries,
        _globalContextKeys = globalContextKeys,
        _translations = translations;

  factory _$ExtensionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExtensionImplFromJson(json);

  @override
  final ExtensionInfo extension;
  final List<EntryBlueprint> _entries;
  @override
  @JsonKey()
  List<EntryBlueprint> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  final List<GlobalContextKey> _globalContextKeys;
  @override
  @JsonKey()
  List<GlobalContextKey> get globalContextKeys {
    if (_globalContextKeys is EqualUnmodifiableListView)
      return _globalContextKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_globalContextKeys);
  }

  final Map<String, Map<String, String>> _translations;
  @override
  @JsonKey()
  Map<String, Map<String, String>> get translations {
    if (_translations is EqualUnmodifiableMapView) return _translations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_translations);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Extension(extension: $extension, entries: $entries, globalContextKeys: $globalContextKeys, translations: $translations)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Extension'))
      ..add(DiagnosticsProperty('extension', extension))
      ..add(DiagnosticsProperty('entries', entries))
      ..add(DiagnosticsProperty('globalContextKeys', globalContextKeys))
      ..add(DiagnosticsProperty('translations', translations));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExtensionImpl &&
            (identical(other.extension, extension) ||
                other.extension == extension) &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            const DeepCollectionEquality()
                .equals(other._globalContextKeys, _globalContextKeys) &&
            const DeepCollectionEquality()
                .equals(other._translations, _translations));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      extension,
      const DeepCollectionEquality().hash(_entries),
      const DeepCollectionEquality().hash(_globalContextKeys),
      const DeepCollectionEquality().hash(_translations));

  /// Create a copy of Extension
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExtensionImplCopyWith<_$ExtensionImpl> get copyWith =>
      __$$ExtensionImplCopyWithImpl<_$ExtensionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExtensionImplToJson(
      this,
    );
  }
}

abstract class _Extension implements Extension {
  const factory _Extension(
      {required final ExtensionInfo extension,
      final List<EntryBlueprint> entries,
      final List<GlobalContextKey> globalContextKeys,
      final Map<String, Map<String, String>> translations}) = _$ExtensionImpl;

  factory _Extension.fromJson(Map<String, dynamic> json) =
      _$ExtensionImpl.fromJson;

  @override
  ExtensionInfo get extension;
  @override
  List<EntryBlueprint> get entries;
  @override
  List<GlobalContextKey> get globalContextKeys;
  @override
  Map<String, Map<String, String>> get translations;

  /// Create a copy of Extension
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExtensionImplCopyWith<_$ExtensionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExtensionInfo _$ExtensionInfoFromJson(Map<String, dynamic> json) {
  return _ExtensionInfo.fromJson(json);
}

/// @nodoc
mixin _$ExtensionInfo {
  String get name => throw _privateConstructorUsedError;
  String get shortDescription => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;

  /// Serializes this ExtensionInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExtensionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExtensionInfoCopyWith<ExtensionInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExtensionInfoCopyWith<$Res> {
  factory $ExtensionInfoCopyWith(
          ExtensionInfo value, $Res Function(ExtensionInfo) then) =
      _$ExtensionInfoCopyWithImpl<$Res, ExtensionInfo>;
  @useResult
  $Res call(
      {String name,
      String shortDescription,
      String description,
      String version,
      String key});
}

/// @nodoc
class _$ExtensionInfoCopyWithImpl<$Res, $Val extends ExtensionInfo>
    implements $ExtensionInfoCopyWith<$Res> {
  _$ExtensionInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExtensionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? shortDescription = null,
    Object? description = null,
    Object? version = null,
    Object? key = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shortDescription: null == shortDescription
          ? _value.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExtensionInfoImplCopyWith<$Res>
    implements $ExtensionInfoCopyWith<$Res> {
  factory _$$ExtensionInfoImplCopyWith(
          _$ExtensionInfoImpl value, $Res Function(_$ExtensionInfoImpl) then) =
      __$$ExtensionInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String shortDescription,
      String description,
      String version,
      String key});
}

/// @nodoc
class __$$ExtensionInfoImplCopyWithImpl<$Res>
    extends _$ExtensionInfoCopyWithImpl<$Res, _$ExtensionInfoImpl>
    implements _$$ExtensionInfoImplCopyWith<$Res> {
  __$$ExtensionInfoImplCopyWithImpl(
      _$ExtensionInfoImpl _value, $Res Function(_$ExtensionInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExtensionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? shortDescription = null,
    Object? description = null,
    Object? version = null,
    Object? key = null,
  }) {
    return _then(_$ExtensionInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      shortDescription: null == shortDescription
          ? _value.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExtensionInfoImpl
    with DiagnosticableTreeMixin
    implements _ExtensionInfo {
  const _$ExtensionInfoImpl(
      {required this.name,
      required this.shortDescription,
      required this.description,
      required this.version,
      this.key = ""});

  factory _$ExtensionInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExtensionInfoImplFromJson(json);

  @override
  final String name;
  @override
  final String shortDescription;
  @override
  final String description;
  @override
  final String version;
  @override
  @JsonKey()
  final String key;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ExtensionInfo(name: $name, shortDescription: $shortDescription, description: $description, version: $version, key: $key)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ExtensionInfo'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('shortDescription', shortDescription))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('version', version))
      ..add(DiagnosticsProperty('key', key));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExtensionInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortDescription, shortDescription) ||
                other.shortDescription == shortDescription) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.key, key) || other.key == key));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, shortDescription, description, version, key);

  /// Create a copy of ExtensionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExtensionInfoImplCopyWith<_$ExtensionInfoImpl> get copyWith =>
      __$$ExtensionInfoImplCopyWithImpl<_$ExtensionInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExtensionInfoImplToJson(
      this,
    );
  }
}

abstract class _ExtensionInfo implements ExtensionInfo {
  const factory _ExtensionInfo(
      {required final String name,
      required final String shortDescription,
      required final String description,
      required final String version,
      final String key}) = _$ExtensionInfoImpl;

  factory _ExtensionInfo.fromJson(Map<String, dynamic> json) =
      _$ExtensionInfoImpl.fromJson;

  @override
  String get name;
  @override
  String get shortDescription;
  @override
  String get description;
  @override
  String get version;
  @override
  String get key;

  /// Create a copy of ExtensionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExtensionInfoImplCopyWith<_$ExtensionInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GlobalContextKey _$GlobalContextKeyFromJson(Map<String, dynamic> json) {
  return _GlobalContextKey.fromJson(json);
}

/// @nodoc
mixin _$GlobalContextKey {
  String get name => throw _privateConstructorUsedError;
  String get klassName => throw _privateConstructorUsedError;
  DataBlueprint get blueprint => throw _privateConstructorUsedError;

  /// Serializes this GlobalContextKey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GlobalContextKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GlobalContextKeyCopyWith<GlobalContextKey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GlobalContextKeyCopyWith<$Res> {
  factory $GlobalContextKeyCopyWith(
          GlobalContextKey value, $Res Function(GlobalContextKey) then) =
      _$GlobalContextKeyCopyWithImpl<$Res, GlobalContextKey>;
  @useResult
  $Res call({String name, String klassName, DataBlueprint blueprint});

  $DataBlueprintCopyWith<$Res> get blueprint;
}

/// @nodoc
class _$GlobalContextKeyCopyWithImpl<$Res, $Val extends GlobalContextKey>
    implements $GlobalContextKeyCopyWith<$Res> {
  _$GlobalContextKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GlobalContextKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? klassName = null,
    Object? blueprint = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      klassName: null == klassName
          ? _value.klassName
          : klassName // ignore: cast_nullable_to_non_nullable
              as String,
      blueprint: null == blueprint
          ? _value.blueprint
          : blueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
    ) as $Val);
  }

  /// Create a copy of GlobalContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res> get blueprint {
    return $DataBlueprintCopyWith<$Res>(_value.blueprint, (value) {
      return _then(_value.copyWith(blueprint: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GlobalContextKeyImplCopyWith<$Res>
    implements $GlobalContextKeyCopyWith<$Res> {
  factory _$$GlobalContextKeyImplCopyWith(_$GlobalContextKeyImpl value,
          $Res Function(_$GlobalContextKeyImpl) then) =
      __$$GlobalContextKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String klassName, DataBlueprint blueprint});

  @override
  $DataBlueprintCopyWith<$Res> get blueprint;
}

/// @nodoc
class __$$GlobalContextKeyImplCopyWithImpl<$Res>
    extends _$GlobalContextKeyCopyWithImpl<$Res, _$GlobalContextKeyImpl>
    implements _$$GlobalContextKeyImplCopyWith<$Res> {
  __$$GlobalContextKeyImplCopyWithImpl(_$GlobalContextKeyImpl _value,
      $Res Function(_$GlobalContextKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of GlobalContextKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? klassName = null,
    Object? blueprint = null,
  }) {
    return _then(_$GlobalContextKeyImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      klassName: null == klassName
          ? _value.klassName
          : klassName // ignore: cast_nullable_to_non_nullable
              as String,
      blueprint: null == blueprint
          ? _value.blueprint
          : blueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GlobalContextKeyImpl
    with DiagnosticableTreeMixin
    implements _GlobalContextKey {
  const _$GlobalContextKeyImpl(
      {required this.name, required this.klassName, required this.blueprint});

  factory _$GlobalContextKeyImpl.fromJson(Map<String, dynamic> json) =>
      _$$GlobalContextKeyImplFromJson(json);

  @override
  final String name;
  @override
  final String klassName;
  @override
  final DataBlueprint blueprint;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'GlobalContextKey(name: $name, klassName: $klassName, blueprint: $blueprint)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'GlobalContextKey'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('klassName', klassName))
      ..add(DiagnosticsProperty('blueprint', blueprint));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalContextKeyImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.klassName, klassName) ||
                other.klassName == klassName) &&
            (identical(other.blueprint, blueprint) ||
                other.blueprint == blueprint));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, klassName, blueprint);

  /// Create a copy of GlobalContextKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GlobalContextKeyImplCopyWith<_$GlobalContextKeyImpl> get copyWith =>
      __$$GlobalContextKeyImplCopyWithImpl<_$GlobalContextKeyImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GlobalContextKeyImplToJson(
      this,
    );
  }
}

abstract class _GlobalContextKey implements GlobalContextKey {
  const factory _GlobalContextKey(
      {required final String name,
      required final String klassName,
      required final DataBlueprint blueprint}) = _$GlobalContextKeyImpl;

  factory _GlobalContextKey.fromJson(Map<String, dynamic> json) =
      _$GlobalContextKeyImpl.fromJson;

  @override
  String get name;
  @override
  String get klassName;
  @override
  DataBlueprint get blueprint;

  /// Create a copy of GlobalContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GlobalContextKeyImplCopyWith<_$GlobalContextKeyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
