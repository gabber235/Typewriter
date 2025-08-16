// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modules_popup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ManualModuleInformation implements DiagnosticableTreeMixin {
  String get moduleId;
  String get name;
  String get description;
  String get author;
  ModuleType get type;
  @SemverJsonConverter()
  Version get version;
  @SemverListJsonConverter()
  List<Version> get compatibleVersions;
  bool get canBeRemoved;

  /// Create a copy of ManualModuleInformation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ManualModuleInformationCopyWith<ManualModuleInformation> get copyWith =>
      _$ManualModuleInformationCopyWithImpl<ManualModuleInformation>(
          this as ManualModuleInformation, _$identity);

  /// Serializes this ManualModuleInformation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ManualModuleInformation'))
      ..add(DiagnosticsProperty('moduleId', moduleId))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('author', author))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('version', version))
      ..add(DiagnosticsProperty('compatibleVersions', compatibleVersions))
      ..add(DiagnosticsProperty('canBeRemoved', canBeRemoved));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ManualModuleInformation &&
            (identical(other.moduleId, moduleId) ||
                other.moduleId == moduleId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality()
                .equals(other.compatibleVersions, compatibleVersions) &&
            (identical(other.canBeRemoved, canBeRemoved) ||
                other.canBeRemoved == canBeRemoved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      moduleId,
      name,
      description,
      author,
      type,
      version,
      const DeepCollectionEquality().hash(compatibleVersions),
      canBeRemoved);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ManualModuleInformation(moduleId: $moduleId, name: $name, description: $description, author: $author, type: $type, version: $version, compatibleVersions: $compatibleVersions, canBeRemoved: $canBeRemoved)';
  }
}

/// @nodoc
abstract mixin class $ManualModuleInformationCopyWith<$Res> {
  factory $ManualModuleInformationCopyWith(ManualModuleInformation value,
          $Res Function(ManualModuleInformation) _then) =
      _$ManualModuleInformationCopyWithImpl;
  @useResult
  $Res call(
      {String moduleId,
      String name,
      String description,
      String author,
      ModuleType type,
      @SemverJsonConverter() Version version,
      @SemverListJsonConverter() List<Version> compatibleVersions,
      bool canBeRemoved});
}

/// @nodoc
class _$ManualModuleInformationCopyWithImpl<$Res>
    implements $ManualModuleInformationCopyWith<$Res> {
  _$ManualModuleInformationCopyWithImpl(this._self, this._then);

  final ManualModuleInformation _self;
  final $Res Function(ManualModuleInformation) _then;

  /// Create a copy of ManualModuleInformation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? moduleId = null,
    Object? name = null,
    Object? description = null,
    Object? author = null,
    Object? type = null,
    Object? version = null,
    Object? compatibleVersions = null,
    Object? canBeRemoved = null,
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
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ModuleType,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      compatibleVersions: null == compatibleVersions
          ? _self.compatibleVersions
          : compatibleVersions // ignore: cast_nullable_to_non_nullable
              as List<Version>,
      canBeRemoved: null == canBeRemoved
          ? _self.canBeRemoved
          : canBeRemoved // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ManualModuleInformation].
extension ManualModuleInformationPatterns on ManualModuleInformation {
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
    TResult Function(_ManualModuleInformation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ManualModuleInformation() when $default != null:
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
    TResult Function(_ManualModuleInformation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleInformation():
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
    TResult? Function(_ManualModuleInformation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleInformation() when $default != null:
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
            String description,
            String author,
            ModuleType type,
            @SemverJsonConverter() Version version,
            @SemverListJsonConverter() List<Version> compatibleVersions,
            bool canBeRemoved)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ManualModuleInformation() when $default != null:
        return $default(
            _that.moduleId,
            _that.name,
            _that.description,
            _that.author,
            _that.type,
            _that.version,
            _that.compatibleVersions,
            _that.canBeRemoved);
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
            String description,
            String author,
            ModuleType type,
            @SemverJsonConverter() Version version,
            @SemverListJsonConverter() List<Version> compatibleVersions,
            bool canBeRemoved)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleInformation():
        return $default(
            _that.moduleId,
            _that.name,
            _that.description,
            _that.author,
            _that.type,
            _that.version,
            _that.compatibleVersions,
            _that.canBeRemoved);
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
            String description,
            String author,
            ModuleType type,
            @SemverJsonConverter() Version version,
            @SemverListJsonConverter() List<Version> compatibleVersions,
            bool canBeRemoved)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ManualModuleInformation() when $default != null:
        return $default(
            _that.moduleId,
            _that.name,
            _that.description,
            _that.author,
            _that.type,
            _that.version,
            _that.compatibleVersions,
            _that.canBeRemoved);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ManualModuleInformation
    with DiagnosticableTreeMixin
    implements ManualModuleInformation {
  _ManualModuleInformation(
      {required this.moduleId,
      required this.name,
      required this.description,
      required this.author,
      required this.type,
      @SemverJsonConverter() required this.version,
      @SemverListJsonConverter()
      required final List<Version> compatibleVersions,
      this.canBeRemoved = true})
      : assert(compatibleVersions.isNotEmpty,
            'The module has no compatible versions.'),
        assert(compatibleVersions.contains(version),
            'The module is not compatible with the current version.'),
        _compatibleVersions = compatibleVersions;
  factory _ManualModuleInformation.fromJson(Map<String, dynamic> json) =>
      _$ManualModuleInformationFromJson(json);

  @override
  final String moduleId;
  @override
  final String name;
  @override
  final String description;
  @override
  final String author;
  @override
  final ModuleType type;
  @override
  @SemverJsonConverter()
  final Version version;
  final List<Version> _compatibleVersions;
  @override
  @SemverListJsonConverter()
  List<Version> get compatibleVersions {
    if (_compatibleVersions is EqualUnmodifiableListView)
      return _compatibleVersions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_compatibleVersions);
  }

  @override
  @JsonKey()
  final bool canBeRemoved;

  /// Create a copy of ManualModuleInformation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ManualModuleInformationCopyWith<_ManualModuleInformation> get copyWith =>
      __$ManualModuleInformationCopyWithImpl<_ManualModuleInformation>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ManualModuleInformationToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ManualModuleInformation'))
      ..add(DiagnosticsProperty('moduleId', moduleId))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('author', author))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('version', version))
      ..add(DiagnosticsProperty('compatibleVersions', compatibleVersions))
      ..add(DiagnosticsProperty('canBeRemoved', canBeRemoved));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ManualModuleInformation &&
            (identical(other.moduleId, moduleId) ||
                other.moduleId == moduleId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality()
                .equals(other._compatibleVersions, _compatibleVersions) &&
            (identical(other.canBeRemoved, canBeRemoved) ||
                other.canBeRemoved == canBeRemoved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      moduleId,
      name,
      description,
      author,
      type,
      version,
      const DeepCollectionEquality().hash(_compatibleVersions),
      canBeRemoved);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ManualModuleInformation(moduleId: $moduleId, name: $name, description: $description, author: $author, type: $type, version: $version, compatibleVersions: $compatibleVersions, canBeRemoved: $canBeRemoved)';
  }
}

/// @nodoc
abstract mixin class _$ManualModuleInformationCopyWith<$Res>
    implements $ManualModuleInformationCopyWith<$Res> {
  factory _$ManualModuleInformationCopyWith(_ManualModuleInformation value,
          $Res Function(_ManualModuleInformation) _then) =
      __$ManualModuleInformationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String moduleId,
      String name,
      String description,
      String author,
      ModuleType type,
      @SemverJsonConverter() Version version,
      @SemverListJsonConverter() List<Version> compatibleVersions,
      bool canBeRemoved});
}

/// @nodoc
class __$ManualModuleInformationCopyWithImpl<$Res>
    implements _$ManualModuleInformationCopyWith<$Res> {
  __$ManualModuleInformationCopyWithImpl(this._self, this._then);

  final _ManualModuleInformation _self;
  final $Res Function(_ManualModuleInformation) _then;

  /// Create a copy of ManualModuleInformation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? moduleId = null,
    Object? name = null,
    Object? description = null,
    Object? author = null,
    Object? type = null,
    Object? version = null,
    Object? compatibleVersions = null,
    Object? canBeRemoved = null,
  }) {
    return _then(_ManualModuleInformation(
      moduleId: null == moduleId
          ? _self.moduleId
          : moduleId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ModuleType,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as Version,
      compatibleVersions: null == compatibleVersions
          ? _self._compatibleVersions
          : compatibleVersions // ignore: cast_nullable_to_non_nullable
              as List<Version>,
      canBeRemoved: null == canBeRemoved
          ? _self.canBeRemoved
          : canBeRemoved // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
