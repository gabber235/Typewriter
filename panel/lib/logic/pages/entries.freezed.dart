// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entries.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EntryDefinition {
  String get id;
  String get name;
  EntryBlueprint get blueprint;
  DynamicData get data;
  DynamicData get metadata;

  /// Create a copy of EntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EntryDefinitionCopyWith<EntryDefinition> get copyWith =>
      _$EntryDefinitionCopyWithImpl<EntryDefinition>(
          this as EntryDefinition, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EntryDefinition &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.blueprint, blueprint) ||
                other.blueprint == blueprint) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, blueprint, data, metadata);

  @override
  String toString() {
    return 'EntryDefinition(id: $id, name: $name, blueprint: $blueprint, data: $data, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $EntryDefinitionCopyWith<$Res> {
  factory $EntryDefinitionCopyWith(
          EntryDefinition value, $Res Function(EntryDefinition) _then) =
      _$EntryDefinitionCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      EntryBlueprint blueprint,
      DynamicData data,
      DynamicData metadata});

  $EntryBlueprintCopyWith<$Res> get blueprint;
}

/// @nodoc
class _$EntryDefinitionCopyWithImpl<$Res>
    implements $EntryDefinitionCopyWith<$Res> {
  _$EntryDefinitionCopyWithImpl(this._self, this._then);

  final EntryDefinition _self;
  final $Res Function(EntryDefinition) _then;

  /// Create a copy of EntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? blueprint = null,
    Object? data = null,
    Object? metadata = null,
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
      blueprint: null == blueprint
          ? _self.blueprint
          : blueprint // ignore: cast_nullable_to_non_nullable
              as EntryBlueprint,
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as DynamicData,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as DynamicData,
    ));
  }

  /// Create a copy of EntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EntryBlueprintCopyWith<$Res> get blueprint {
    return $EntryBlueprintCopyWith<$Res>(_self.blueprint, (value) {
      return _then(_self.copyWith(blueprint: value));
    });
  }
}

/// Adds pattern-matching-related methods to [EntryDefinition].
extension EntryDefinitionPatterns on EntryDefinition {
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
    TResult Function(_EntryDefinition value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryDefinition() when $default != null:
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
    TResult Function(_EntryDefinition value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryDefinition():
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
    TResult? Function(_EntryDefinition value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryDefinition() when $default != null:
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
    TResult Function(String id, String name, EntryBlueprint blueprint,
            DynamicData data, DynamicData metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryDefinition() when $default != null:
        return $default(
            _that.id, _that.name, _that.blueprint, _that.data, _that.metadata);
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
    TResult Function(String id, String name, EntryBlueprint blueprint,
            DynamicData data, DynamicData metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryDefinition():
        return $default(
            _that.id, _that.name, _that.blueprint, _that.data, _that.metadata);
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
    TResult? Function(String id, String name, EntryBlueprint blueprint,
            DynamicData data, DynamicData metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryDefinition() when $default != null:
        return $default(
            _that.id, _that.name, _that.blueprint, _that.data, _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EntryDefinition implements EntryDefinition {
  const _EntryDefinition(
      {required this.id,
      required this.name,
      required this.blueprint,
      required this.data,
      this.metadata = const DynamicData({})});

  @override
  final String id;
  @override
  final String name;
  @override
  final EntryBlueprint blueprint;
  @override
  final DynamicData data;
  @override
  @JsonKey()
  final DynamicData metadata;

  /// Create a copy of EntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EntryDefinitionCopyWith<_EntryDefinition> get copyWith =>
      __$EntryDefinitionCopyWithImpl<_EntryDefinition>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EntryDefinition &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.blueprint, blueprint) ||
                other.blueprint == blueprint) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, blueprint, data, metadata);

  @override
  String toString() {
    return 'EntryDefinition(id: $id, name: $name, blueprint: $blueprint, data: $data, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$EntryDefinitionCopyWith<$Res>
    implements $EntryDefinitionCopyWith<$Res> {
  factory _$EntryDefinitionCopyWith(
          _EntryDefinition value, $Res Function(_EntryDefinition) _then) =
      __$EntryDefinitionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      EntryBlueprint blueprint,
      DynamicData data,
      DynamicData metadata});

  @override
  $EntryBlueprintCopyWith<$Res> get blueprint;
}

/// @nodoc
class __$EntryDefinitionCopyWithImpl<$Res>
    implements _$EntryDefinitionCopyWith<$Res> {
  __$EntryDefinitionCopyWithImpl(this._self, this._then);

  final _EntryDefinition _self;
  final $Res Function(_EntryDefinition) _then;

  /// Create a copy of EntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? blueprint = null,
    Object? data = null,
    Object? metadata = null,
  }) {
    return _then(_EntryDefinition(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      blueprint: null == blueprint
          ? _self.blueprint
          : blueprint // ignore: cast_nullable_to_non_nullable
              as EntryBlueprint,
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as DynamicData,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as DynamicData,
    ));
  }

  /// Create a copy of EntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EntryBlueprintCopyWith<$Res> get blueprint {
    return $EntryBlueprintCopyWith<$Res>(_self.blueprint, (value) {
      return _then(_self.copyWith(blueprint: value));
    });
  }
}

/// @nodoc
mixin _$EntryBlueprint {
  String get id;
  String get name;
  String get description;
  String get extension;
  ObjectBlueprint get dataBlueprint;
  @ColorConverter()
  Color get color;
  String get icon;
  List<String> get tags;
  List<DataBlueprint>? get genericConstraints;
  DataBlueprint? get variableDataBlueprint;
  List<ContextKey> get contextKeys;
  List<EntryModifier> get modifiers;
  String? get wikiUrl;

  /// Create a copy of EntryBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EntryBlueprintCopyWith<EntryBlueprint> get copyWith =>
      _$EntryBlueprintCopyWithImpl<EntryBlueprint>(
          this as EntryBlueprint, _$identity);

  /// Serializes this EntryBlueprint to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EntryBlueprint &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.extension, extension) ||
                other.extension == extension) &&
            const DeepCollectionEquality()
                .equals(other.dataBlueprint, dataBlueprint) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality()
                .equals(other.genericConstraints, genericConstraints) &&
            (identical(other.variableDataBlueprint, variableDataBlueprint) ||
                other.variableDataBlueprint == variableDataBlueprint) &&
            const DeepCollectionEquality()
                .equals(other.contextKeys, contextKeys) &&
            const DeepCollectionEquality().equals(other.modifiers, modifiers) &&
            (identical(other.wikiUrl, wikiUrl) || other.wikiUrl == wikiUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      extension,
      const DeepCollectionEquality().hash(dataBlueprint),
      color,
      icon,
      const DeepCollectionEquality().hash(tags),
      const DeepCollectionEquality().hash(genericConstraints),
      variableDataBlueprint,
      const DeepCollectionEquality().hash(contextKeys),
      const DeepCollectionEquality().hash(modifiers),
      wikiUrl);

  @override
  String toString() {
    return 'EntryBlueprint(id: $id, name: $name, description: $description, extension: $extension, dataBlueprint: $dataBlueprint, color: $color, icon: $icon, tags: $tags, genericConstraints: $genericConstraints, variableDataBlueprint: $variableDataBlueprint, contextKeys: $contextKeys, modifiers: $modifiers, wikiUrl: $wikiUrl)';
  }
}

/// @nodoc
abstract mixin class $EntryBlueprintCopyWith<$Res> {
  factory $EntryBlueprintCopyWith(
          EntryBlueprint value, $Res Function(EntryBlueprint) _then) =
      _$EntryBlueprintCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String extension,
      ObjectBlueprint dataBlueprint,
      @ColorConverter() Color color,
      String icon,
      List<String> tags,
      List<DataBlueprint>? genericConstraints,
      DataBlueprint? variableDataBlueprint,
      List<ContextKey> contextKeys,
      List<EntryModifier> modifiers,
      String? wikiUrl});

  $DataBlueprintCopyWith<$Res>? get variableDataBlueprint;
}

/// @nodoc
class _$EntryBlueprintCopyWithImpl<$Res>
    implements $EntryBlueprintCopyWith<$Res> {
  _$EntryBlueprintCopyWithImpl(this._self, this._then);

  final EntryBlueprint _self;
  final $Res Function(EntryBlueprint) _then;

  /// Create a copy of EntryBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? extension = null,
    Object? dataBlueprint = freezed,
    Object? color = null,
    Object? icon = null,
    Object? tags = null,
    Object? genericConstraints = freezed,
    Object? variableDataBlueprint = freezed,
    Object? contextKeys = null,
    Object? modifiers = null,
    Object? wikiUrl = freezed,
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
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      extension: null == extension
          ? _self.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as String,
      dataBlueprint: freezed == dataBlueprint
          ? _self.dataBlueprint
          : dataBlueprint // ignore: cast_nullable_to_non_nullable
              as ObjectBlueprint,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color,
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      genericConstraints: freezed == genericConstraints
          ? _self.genericConstraints
          : genericConstraints // ignore: cast_nullable_to_non_nullable
              as List<DataBlueprint>?,
      variableDataBlueprint: freezed == variableDataBlueprint
          ? _self.variableDataBlueprint
          : variableDataBlueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint?,
      contextKeys: null == contextKeys
          ? _self.contextKeys
          : contextKeys // ignore: cast_nullable_to_non_nullable
              as List<ContextKey>,
      modifiers: null == modifiers
          ? _self.modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<EntryModifier>,
      wikiUrl: freezed == wikiUrl
          ? _self.wikiUrl
          : wikiUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of EntryBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res>? get variableDataBlueprint {
    if (_self.variableDataBlueprint == null) {
      return null;
    }

    return $DataBlueprintCopyWith<$Res>(_self.variableDataBlueprint!, (value) {
      return _then(_self.copyWith(variableDataBlueprint: value));
    });
  }
}

/// Adds pattern-matching-related methods to [EntryBlueprint].
extension EntryBlueprintPatterns on EntryBlueprint {
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
    TResult Function(_EntryBlueprint value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryBlueprint() when $default != null:
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
    TResult Function(_EntryBlueprint value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryBlueprint():
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
    TResult? Function(_EntryBlueprint value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryBlueprint() when $default != null:
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
            String name,
            String description,
            String extension,
            ObjectBlueprint dataBlueprint,
            @ColorConverter() Color color,
            String icon,
            List<String> tags,
            List<DataBlueprint>? genericConstraints,
            DataBlueprint? variableDataBlueprint,
            List<ContextKey> contextKeys,
            List<EntryModifier> modifiers,
            String? wikiUrl)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EntryBlueprint() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.description,
            _that.extension,
            _that.dataBlueprint,
            _that.color,
            _that.icon,
            _that.tags,
            _that.genericConstraints,
            _that.variableDataBlueprint,
            _that.contextKeys,
            _that.modifiers,
            _that.wikiUrl);
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
            String name,
            String description,
            String extension,
            ObjectBlueprint dataBlueprint,
            @ColorConverter() Color color,
            String icon,
            List<String> tags,
            List<DataBlueprint>? genericConstraints,
            DataBlueprint? variableDataBlueprint,
            List<ContextKey> contextKeys,
            List<EntryModifier> modifiers,
            String? wikiUrl)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryBlueprint():
        return $default(
            _that.id,
            _that.name,
            _that.description,
            _that.extension,
            _that.dataBlueprint,
            _that.color,
            _that.icon,
            _that.tags,
            _that.genericConstraints,
            _that.variableDataBlueprint,
            _that.contextKeys,
            _that.modifiers,
            _that.wikiUrl);
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
            String name,
            String description,
            String extension,
            ObjectBlueprint dataBlueprint,
            @ColorConverter() Color color,
            String icon,
            List<String> tags,
            List<DataBlueprint>? genericConstraints,
            DataBlueprint? variableDataBlueprint,
            List<ContextKey> contextKeys,
            List<EntryModifier> modifiers,
            String? wikiUrl)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EntryBlueprint() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.description,
            _that.extension,
            _that.dataBlueprint,
            _that.color,
            _that.icon,
            _that.tags,
            _that.genericConstraints,
            _that.variableDataBlueprint,
            _that.contextKeys,
            _that.modifiers,
            _that.wikiUrl);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _EntryBlueprint implements EntryBlueprint {
  const _EntryBlueprint(
      {required this.id,
      required this.name,
      required this.description,
      required this.extension,
      required this.dataBlueprint,
      @ColorConverter() this.color = Colors.grey,
      this.icon = "fa-solid:question-circle",
      final List<String> tags = const <String>[],
      final List<DataBlueprint>? genericConstraints = null,
      this.variableDataBlueprint = null,
      final List<ContextKey> contextKeys = const [],
      final List<EntryModifier> modifiers = const [],
      this.wikiUrl = null})
      : _tags = tags,
        _genericConstraints = genericConstraints,
        _contextKeys = contextKeys,
        _modifiers = modifiers;
  factory _EntryBlueprint.fromJson(Map<String, dynamic> json) =>
      _$EntryBlueprintFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String extension;
  @override
  final ObjectBlueprint dataBlueprint;
  @override
  @JsonKey()
  @ColorConverter()
  final Color color;
  @override
  @JsonKey()
  final String icon;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<DataBlueprint>? _genericConstraints;
  @override
  @JsonKey()
  List<DataBlueprint>? get genericConstraints {
    final value = _genericConstraints;
    if (value == null) return null;
    if (_genericConstraints is EqualUnmodifiableListView)
      return _genericConstraints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final DataBlueprint? variableDataBlueprint;
  final List<ContextKey> _contextKeys;
  @override
  @JsonKey()
  List<ContextKey> get contextKeys {
    if (_contextKeys is EqualUnmodifiableListView) return _contextKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contextKeys);
  }

  final List<EntryModifier> _modifiers;
  @override
  @JsonKey()
  List<EntryModifier> get modifiers {
    if (_modifiers is EqualUnmodifiableListView) return _modifiers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modifiers);
  }

  @override
  @JsonKey()
  final String? wikiUrl;

  /// Create a copy of EntryBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EntryBlueprintCopyWith<_EntryBlueprint> get copyWith =>
      __$EntryBlueprintCopyWithImpl<_EntryBlueprint>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EntryBlueprintToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EntryBlueprint &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.extension, extension) ||
                other.extension == extension) &&
            const DeepCollectionEquality()
                .equals(other.dataBlueprint, dataBlueprint) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._genericConstraints, _genericConstraints) &&
            (identical(other.variableDataBlueprint, variableDataBlueprint) ||
                other.variableDataBlueprint == variableDataBlueprint) &&
            const DeepCollectionEquality()
                .equals(other._contextKeys, _contextKeys) &&
            const DeepCollectionEquality()
                .equals(other._modifiers, _modifiers) &&
            (identical(other.wikiUrl, wikiUrl) || other.wikiUrl == wikiUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      extension,
      const DeepCollectionEquality().hash(dataBlueprint),
      color,
      icon,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_genericConstraints),
      variableDataBlueprint,
      const DeepCollectionEquality().hash(_contextKeys),
      const DeepCollectionEquality().hash(_modifiers),
      wikiUrl);

  @override
  String toString() {
    return 'EntryBlueprint(id: $id, name: $name, description: $description, extension: $extension, dataBlueprint: $dataBlueprint, color: $color, icon: $icon, tags: $tags, genericConstraints: $genericConstraints, variableDataBlueprint: $variableDataBlueprint, contextKeys: $contextKeys, modifiers: $modifiers, wikiUrl: $wikiUrl)';
  }
}

/// @nodoc
abstract mixin class _$EntryBlueprintCopyWith<$Res>
    implements $EntryBlueprintCopyWith<$Res> {
  factory _$EntryBlueprintCopyWith(
          _EntryBlueprint value, $Res Function(_EntryBlueprint) _then) =
      __$EntryBlueprintCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String extension,
      ObjectBlueprint dataBlueprint,
      @ColorConverter() Color color,
      String icon,
      List<String> tags,
      List<DataBlueprint>? genericConstraints,
      DataBlueprint? variableDataBlueprint,
      List<ContextKey> contextKeys,
      List<EntryModifier> modifiers,
      String? wikiUrl});

  @override
  $DataBlueprintCopyWith<$Res>? get variableDataBlueprint;
}

/// @nodoc
class __$EntryBlueprintCopyWithImpl<$Res>
    implements _$EntryBlueprintCopyWith<$Res> {
  __$EntryBlueprintCopyWithImpl(this._self, this._then);

  final _EntryBlueprint _self;
  final $Res Function(_EntryBlueprint) _then;

  /// Create a copy of EntryBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? extension = null,
    Object? dataBlueprint = freezed,
    Object? color = null,
    Object? icon = null,
    Object? tags = null,
    Object? genericConstraints = freezed,
    Object? variableDataBlueprint = freezed,
    Object? contextKeys = null,
    Object? modifiers = null,
    Object? wikiUrl = freezed,
  }) {
    return _then(_EntryBlueprint(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      extension: null == extension
          ? _self.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as String,
      dataBlueprint: freezed == dataBlueprint
          ? _self.dataBlueprint
          : dataBlueprint // ignore: cast_nullable_to_non_nullable
              as ObjectBlueprint,
      color: null == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color,
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      genericConstraints: freezed == genericConstraints
          ? _self._genericConstraints
          : genericConstraints // ignore: cast_nullable_to_non_nullable
              as List<DataBlueprint>?,
      variableDataBlueprint: freezed == variableDataBlueprint
          ? _self.variableDataBlueprint
          : variableDataBlueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint?,
      contextKeys: null == contextKeys
          ? _self._contextKeys
          : contextKeys // ignore: cast_nullable_to_non_nullable
              as List<ContextKey>,
      modifiers: null == modifiers
          ? _self._modifiers
          : modifiers // ignore: cast_nullable_to_non_nullable
              as List<EntryModifier>,
      wikiUrl: freezed == wikiUrl
          ? _self.wikiUrl
          : wikiUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of EntryBlueprint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res>? get variableDataBlueprint {
    if (_self.variableDataBlueprint == null) {
      return null;
    }

    return $DataBlueprintCopyWith<$Res>(_self.variableDataBlueprint!, (value) {
      return _then(_self.copyWith(variableDataBlueprint: value));
    });
  }
}

/// @nodoc
mixin _$ContextKey {
  String get name;
  String get klassName;
  DataBlueprint get blueprint;

  /// Create a copy of ContextKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ContextKeyCopyWith<ContextKey> get copyWith =>
      _$ContextKeyCopyWithImpl<ContextKey>(this as ContextKey, _$identity);

  /// Serializes this ContextKey to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ContextKey &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.klassName, klassName) ||
                other.klassName == klassName) &&
            (identical(other.blueprint, blueprint) ||
                other.blueprint == blueprint));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, klassName, blueprint);

  @override
  String toString() {
    return 'ContextKey(name: $name, klassName: $klassName, blueprint: $blueprint)';
  }
}

/// @nodoc
abstract mixin class $ContextKeyCopyWith<$Res> {
  factory $ContextKeyCopyWith(
          ContextKey value, $Res Function(ContextKey) _then) =
      _$ContextKeyCopyWithImpl;
  @useResult
  $Res call({String name, String klassName, DataBlueprint blueprint});

  $DataBlueprintCopyWith<$Res> get blueprint;
}

/// @nodoc
class _$ContextKeyCopyWithImpl<$Res> implements $ContextKeyCopyWith<$Res> {
  _$ContextKeyCopyWithImpl(this._self, this._then);

  final ContextKey _self;
  final $Res Function(ContextKey) _then;

  /// Create a copy of ContextKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? klassName = null,
    Object? blueprint = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      klassName: null == klassName
          ? _self.klassName
          : klassName // ignore: cast_nullable_to_non_nullable
              as String,
      blueprint: null == blueprint
          ? _self.blueprint
          : blueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
    ));
  }

  /// Create a copy of ContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res> get blueprint {
    return $DataBlueprintCopyWith<$Res>(_self.blueprint, (value) {
      return _then(_self.copyWith(blueprint: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ContextKey].
extension ContextKeyPatterns on ContextKey {
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
    TResult Function(_ContextKey value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ContextKey() when $default != null:
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
    TResult Function(_ContextKey value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ContextKey():
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
    TResult? Function(_ContextKey value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ContextKey() when $default != null:
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
    TResult Function(String name, String klassName, DataBlueprint blueprint)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ContextKey() when $default != null:
        return $default(_that.name, _that.klassName, _that.blueprint);
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
    TResult Function(String name, String klassName, DataBlueprint blueprint)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ContextKey():
        return $default(_that.name, _that.klassName, _that.blueprint);
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
    TResult? Function(String name, String klassName, DataBlueprint blueprint)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ContextKey() when $default != null:
        return $default(_that.name, _that.klassName, _that.blueprint);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ContextKey implements ContextKey {
  const _ContextKey(
      {required this.name, required this.klassName, required this.blueprint});
  factory _ContextKey.fromJson(Map<String, dynamic> json) =>
      _$ContextKeyFromJson(json);

  @override
  final String name;
  @override
  final String klassName;
  @override
  final DataBlueprint blueprint;

  /// Create a copy of ContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ContextKeyCopyWith<_ContextKey> get copyWith =>
      __$ContextKeyCopyWithImpl<_ContextKey>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ContextKeyToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ContextKey &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.klassName, klassName) ||
                other.klassName == klassName) &&
            (identical(other.blueprint, blueprint) ||
                other.blueprint == blueprint));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, klassName, blueprint);

  @override
  String toString() {
    return 'ContextKey(name: $name, klassName: $klassName, blueprint: $blueprint)';
  }
}

/// @nodoc
abstract mixin class _$ContextKeyCopyWith<$Res>
    implements $ContextKeyCopyWith<$Res> {
  factory _$ContextKeyCopyWith(
          _ContextKey value, $Res Function(_ContextKey) _then) =
      __$ContextKeyCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String klassName, DataBlueprint blueprint});

  @override
  $DataBlueprintCopyWith<$Res> get blueprint;
}

/// @nodoc
class __$ContextKeyCopyWithImpl<$Res> implements _$ContextKeyCopyWith<$Res> {
  __$ContextKeyCopyWithImpl(this._self, this._then);

  final _ContextKey _self;
  final $Res Function(_ContextKey) _then;

  /// Create a copy of ContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? klassName = null,
    Object? blueprint = null,
  }) {
    return _then(_ContextKey(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      klassName: null == klassName
          ? _self.klassName
          : klassName // ignore: cast_nullable_to_non_nullable
              as String,
      blueprint: null == blueprint
          ? _self.blueprint
          : blueprint // ignore: cast_nullable_to_non_nullable
              as DataBlueprint,
    ));
  }

  /// Create a copy of ContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataBlueprintCopyWith<$Res> get blueprint {
    return $DataBlueprintCopyWith<$Res>(_self.blueprint, (value) {
      return _then(_self.copyWith(blueprint: value));
    });
  }
}

EntryModifier _$EntryModifierFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'default':
      return _EmptyModifier.fromJson(json);
    case 'deprecated':
      return DeprecatedModifier.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'EntryModifier',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$EntryModifier {
  /// Serializes this EntryModifier to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is EntryModifier);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'EntryModifier()';
  }
}

/// @nodoc
class $EntryModifierCopyWith<$Res> {
  $EntryModifierCopyWith(EntryModifier _, $Res Function(EntryModifier) __);
}

/// Adds pattern-matching-related methods to [EntryModifier].
extension EntryModifierPatterns on EntryModifier {
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
    TResult Function(_EmptyModifier value)? $default, {
    TResult Function(DeprecatedModifier value)? deprecated,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EmptyModifier() when $default != null:
        return $default(_that);
      case DeprecatedModifier() when deprecated != null:
        return deprecated(_that);
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
    TResult Function(_EmptyModifier value) $default, {
    required TResult Function(DeprecatedModifier value) deprecated,
  }) {
    final _that = this;
    switch (_that) {
      case _EmptyModifier():
        return $default(_that);
      case DeprecatedModifier():
        return deprecated(_that);
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
    TResult? Function(_EmptyModifier value)? $default, {
    TResult? Function(DeprecatedModifier value)? deprecated,
  }) {
    final _that = this;
    switch (_that) {
      case _EmptyModifier() when $default != null:
        return $default(_that);
      case DeprecatedModifier() when deprecated != null:
        return deprecated(_that);
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
    TResult Function()? $default, {
    TResult Function(String reason)? deprecated,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EmptyModifier() when $default != null:
        return $default();
      case DeprecatedModifier() when deprecated != null:
        return deprecated(_that.reason);
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
    TResult Function() $default, {
    required TResult Function(String reason) deprecated,
  }) {
    final _that = this;
    switch (_that) {
      case _EmptyModifier():
        return $default();
      case DeprecatedModifier():
        return deprecated(_that.reason);
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
    TResult? Function()? $default, {
    TResult? Function(String reason)? deprecated,
  }) {
    final _that = this;
    switch (_that) {
      case _EmptyModifier() when $default != null:
        return $default();
      case DeprecatedModifier() when deprecated != null:
        return deprecated(_that.reason);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _EmptyModifier implements EntryModifier {
  const _EmptyModifier({final String? $type}) : $type = $type ?? 'default';
  factory _EmptyModifier.fromJson(Map<String, dynamic> json) =>
      _$EmptyModifierFromJson(json);

  @JsonKey(name: 'kind')
  final String $type;

  @override
  Map<String, dynamic> toJson() {
    return _$EmptyModifierToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _EmptyModifier);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'EntryModifier()';
  }
}

/// @nodoc
@JsonSerializable()
class DeprecatedModifier implements EntryModifier {
  const DeprecatedModifier({this.reason = "", final String? $type})
      : $type = $type ?? 'deprecated';
  factory DeprecatedModifier.fromJson(Map<String, dynamic> json) =>
      _$DeprecatedModifierFromJson(json);

  @JsonKey()
  final String reason;

  @JsonKey(name: 'kind')
  final String $type;

  /// Create a copy of EntryModifier
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DeprecatedModifierCopyWith<DeprecatedModifier> get copyWith =>
      _$DeprecatedModifierCopyWithImpl<DeprecatedModifier>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DeprecatedModifierToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DeprecatedModifier &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @override
  String toString() {
    return 'EntryModifier.deprecated(reason: $reason)';
  }
}

/// @nodoc
abstract mixin class $DeprecatedModifierCopyWith<$Res>
    implements $EntryModifierCopyWith<$Res> {
  factory $DeprecatedModifierCopyWith(
          DeprecatedModifier value, $Res Function(DeprecatedModifier) _then) =
      _$DeprecatedModifierCopyWithImpl;
  @useResult
  $Res call({String reason});
}

/// @nodoc
class _$DeprecatedModifierCopyWithImpl<$Res>
    implements $DeprecatedModifierCopyWith<$Res> {
  _$DeprecatedModifierCopyWithImpl(this._self, this._then);

  final DeprecatedModifier _self;
  final $Res Function(DeprecatedModifier) _then;

  /// Create a copy of EntryModifier
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reason = null,
  }) {
    return _then(DeprecatedModifier(
      reason: null == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
