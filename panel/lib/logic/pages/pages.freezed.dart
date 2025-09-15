// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Page {
  String get id;
  @JsonKey(name: "name")
  String get pageName;
  PageType get type;
  @NullableColorConverter()
  Color? get color;
  String get chapter;
  int get priority;

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PageCopyWith<Page> get copyWith =>
      _$PageCopyWithImpl<Page>(this as Page, _$identity);

  /// Serializes this Page to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Page &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pageName, pageName) ||
                other.pageName == pageName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.chapter, chapter) || other.chapter == chapter) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, pageName, type, color, chapter, priority);

  @override
  String toString() {
    return 'Page(id: $id, pageName: $pageName, type: $type, color: $color, chapter: $chapter, priority: $priority)';
  }
}

/// @nodoc
abstract mixin class $PageCopyWith<$Res> {
  factory $PageCopyWith(Page value, $Res Function(Page) _then) =
      _$PageCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: "name") String pageName,
      PageType type,
      @NullableColorConverter() Color? color,
      String chapter,
      int priority});
}

/// @nodoc
class _$PageCopyWithImpl<$Res> implements $PageCopyWith<$Res> {
  _$PageCopyWithImpl(this._self, this._then);

  final Page _self;
  final $Res Function(Page) _then;

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pageName = null,
    Object? type = null,
    Object? color = freezed,
    Object? chapter = null,
    Object? priority = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageName: null == pageName
          ? _self.pageName
          : pageName // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as PageType,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      chapter: null == chapter
          ? _self.chapter
          : chapter // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [Page].
extension PagePatterns on Page {
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
    TResult Function(_Page value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Page() when $default != null:
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
    TResult Function(_Page value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Page():
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
    TResult? Function(_Page value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Page() when $default != null:
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
            @JsonKey(name: "name") String pageName,
            PageType type,
            @NullableColorConverter() Color? color,
            String chapter,
            int priority)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Page() when $default != null:
        return $default(_that.id, _that.pageName, _that.type, _that.color,
            _that.chapter, _that.priority);
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
            @JsonKey(name: "name") String pageName,
            PageType type,
            @NullableColorConverter() Color? color,
            String chapter,
            int priority)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Page():
        return $default(_that.id, _that.pageName, _that.type, _that.color,
            _that.chapter, _that.priority);
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
            @JsonKey(name: "name") String pageName,
            PageType type,
            @NullableColorConverter() Color? color,
            String chapter,
            int priority)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Page() when $default != null:
        return $default(_that.id, _that.pageName, _that.type, _that.color,
            _that.chapter, _that.priority);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Page implements Page {
  const _Page(
      {required this.id,
      @JsonKey(name: "name") required this.pageName,
      required this.type,
      @NullableColorConverter() this.color,
      this.chapter = "",
      this.priority = 0});
  factory _Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: "name")
  final String pageName;
  @override
  final PageType type;
  @override
  @NullableColorConverter()
  final Color? color;
  @override
  @JsonKey()
  final String chapter;
  @override
  @JsonKey()
  final int priority;

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PageCopyWith<_Page> get copyWith =>
      __$PageCopyWithImpl<_Page>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PageToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Page &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pageName, pageName) ||
                other.pageName == pageName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.chapter, chapter) || other.chapter == chapter) &&
            (identical(other.priority, priority) ||
                other.priority == priority));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, pageName, type, color, chapter, priority);

  @override
  String toString() {
    return 'Page(id: $id, pageName: $pageName, type: $type, color: $color, chapter: $chapter, priority: $priority)';
  }
}

/// @nodoc
abstract mixin class _$PageCopyWith<$Res> implements $PageCopyWith<$Res> {
  factory _$PageCopyWith(_Page value, $Res Function(_Page) _then) =
      __$PageCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: "name") String pageName,
      PageType type,
      @NullableColorConverter() Color? color,
      String chapter,
      int priority});
}

/// @nodoc
class __$PageCopyWithImpl<$Res> implements _$PageCopyWith<$Res> {
  __$PageCopyWithImpl(this._self, this._then);

  final _Page _self;
  final $Res Function(_Page) _then;

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? pageName = null,
    Object? type = null,
    Object? color = freezed,
    Object? chapter = null,
    Object? priority = null,
  }) {
    return _then(_Page(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageName: null == pageName
          ? _self.pageName
          : pageName // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as PageType,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
      chapter: null == chapter
          ? _self.chapter
          : chapter // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
