// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_type_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmEditorLayout {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmEditorLayout);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmEditorLayout()';
}


}

/// @nodoc
class $RealmEditorLayoutCopyWith<$Res>  {
$RealmEditorLayoutCopyWith(RealmEditorLayout _, $Res Function(RealmEditorLayout) __);
}


/// Adds pattern-matching-related methods to [RealmEditorLayout].
extension RealmEditorLayoutPatterns on RealmEditorLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmGraphEditorLayout value)?  graph,TResult Function( RealmTimelineEditorLayout value)?  timeline,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmGraphEditorLayout() when graph != null:
return graph(_that);case RealmTimelineEditorLayout() when timeline != null:
return timeline(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmGraphEditorLayout value)  graph,required TResult Function( RealmTimelineEditorLayout value)  timeline,}){
final _that = this;
switch (_that) {
case RealmGraphEditorLayout():
return graph(_that);case RealmTimelineEditorLayout():
return timeline(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmGraphEditorLayout value)?  graph,TResult? Function( RealmTimelineEditorLayout value)?  timeline,}){
final _that = this;
switch (_that) {
case RealmGraphEditorLayout() when graph != null:
return graph(_that);case RealmTimelineEditorLayout() when timeline != null:
return timeline(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( GraphDirection direction)?  graph,TResult Function()?  timeline,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmGraphEditorLayout() when graph != null:
return graph(_that.direction);case RealmTimelineEditorLayout() when timeline != null:
return timeline();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( GraphDirection direction)  graph,required TResult Function()  timeline,}) {final _that = this;
switch (_that) {
case RealmGraphEditorLayout():
return graph(_that.direction);case RealmTimelineEditorLayout():
return timeline();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( GraphDirection direction)?  graph,TResult? Function()?  timeline,}) {final _that = this;
switch (_that) {
case RealmGraphEditorLayout() when graph != null:
return graph(_that.direction);case RealmTimelineEditorLayout() when timeline != null:
return timeline();case _:
  return null;

}
}

}

/// @nodoc


class RealmGraphEditorLayout implements RealmEditorLayout {
  const RealmGraphEditorLayout({required this.direction});


 final  GraphDirection direction;

/// Create a copy of RealmEditorLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmGraphEditorLayoutCopyWith<RealmGraphEditorLayout> get copyWith => _$RealmGraphEditorLayoutCopyWithImpl<RealmGraphEditorLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmGraphEditorLayout&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,direction);
}

@override
String toString() {
    return 'RealmEditorLayout.graph(direction: $direction)';
}


}

/// @nodoc
abstract mixin class $RealmGraphEditorLayoutCopyWith<$Res> implements $RealmEditorLayoutCopyWith<$Res> {
  factory $RealmGraphEditorLayoutCopyWith(RealmGraphEditorLayout value, $Res Function(RealmGraphEditorLayout) _then) = _$RealmGraphEditorLayoutCopyWithImpl;
@useResult
$Res call({
 GraphDirection direction
});




}
/// @nodoc
class _$RealmGraphEditorLayoutCopyWithImpl<$Res>
    implements $RealmGraphEditorLayoutCopyWith<$Res> {
  _$RealmGraphEditorLayoutCopyWithImpl(this._self, this._then);

  final RealmGraphEditorLayout _self;
  final $Res Function(RealmGraphEditorLayout) _then;

/// Create a copy of RealmEditorLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? direction = null,}) {
  return _then(RealmGraphEditorLayout(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as GraphDirection,
  ));
}


}

/// @nodoc


class RealmTimelineEditorLayout implements RealmEditorLayout {
  const RealmTimelineEditorLayout();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTimelineEditorLayout);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmEditorLayout.timeline()';
}


}




/// @nodoc
mixin _$RealmTypeEntry {

 TypeDefinition get definition; bool get eligible; List<String> get ineligibilityReasons; String? get description; IconValue? get icon; Color? get color; RealmEditorLayout? get editor; TypedCatalogPresentationSubject? get presentationSubject;
/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmTypeEntryCopyWith<RealmTypeEntry> get copyWith => _$RealmTypeEntryCopyWithImpl<RealmTypeEntry>(this as RealmTypeEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmTypeEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTypeEntry&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&(identical(other.eligible, _this.eligible) || other.eligible == _this.eligible)&&const DeepCollectionEquality().equals(other.ineligibilityReasons, _this.ineligibilityReasons)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.editor, _this.editor) || other.editor == _this.editor)&&(identical(other.presentationSubject, _this.presentationSubject) || other.presentationSubject == _this.presentationSubject));
}


@override
int get hashCode {
  final _this = this as RealmTypeEntry;
  return Object.hash(runtimeType,_this.definition,_this.eligible,const DeepCollectionEquality().hash(_this.ineligibilityReasons),_this.description,_this.icon,_this.color,_this.editor,_this.presentationSubject);
}

@override
String toString() {
  final _this = this as RealmTypeEntry;
  return 'RealmTypeEntry(definition: ${_this.definition}, eligible: ${_this.eligible}, ineligibilityReasons: ${_this.ineligibilityReasons}, description: ${_this.description}, icon: ${_this.icon}, color: ${_this.color}, editor: ${_this.editor}, presentationSubject: ${_this.presentationSubject})';
}


}

/// @nodoc
abstract mixin class $RealmTypeEntryCopyWith<$Res>  {
  factory $RealmTypeEntryCopyWith(RealmTypeEntry value, $Res Function(RealmTypeEntry) _then) = _$RealmTypeEntryCopyWithImpl;
@useResult
$Res call({
 TypeDefinition definition, bool eligible, List<String> ineligibilityReasons, String? description, IconValue? icon, Color? color, RealmEditorLayout? editor, TypedCatalogPresentationSubject? presentationSubject
});


$TypeDefinitionCopyWith<$Res> get definition;$IconValueCopyWith<$Res>? get icon;$RealmEditorLayoutCopyWith<$Res>? get editor;

}
/// @nodoc
class _$RealmTypeEntryCopyWithImpl<$Res>
    implements $RealmTypeEntryCopyWith<$Res> {
  _$RealmTypeEntryCopyWithImpl(this._self, this._then);

  final RealmTypeEntry _self;
  final $Res Function(RealmTypeEntry) _then;

/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definition = null,Object? eligible = null,Object? ineligibilityReasons = null,Object? description = freezed,Object? icon = freezed,Object? color = freezed,Object? editor = freezed,Object? presentationSubject = freezed,}) {
  return _then(RealmTypeEntry(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as TypeDefinition,eligible: null == eligible ? _self.eligible : eligible // ignore: cast_nullable_to_non_nullable
as bool,ineligibilityReasons: null == ineligibilityReasons ? _self.ineligibilityReasons : ineligibilityReasons // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,editor: freezed == editor ? _self.editor : editor // ignore: cast_nullable_to_non_nullable
as RealmEditorLayout?,presentationSubject: freezed == presentationSubject ? _self.presentationSubject : presentationSubject // ignore: cast_nullable_to_non_nullable
as TypedCatalogPresentationSubject?,
  ));
}
/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeDefinitionCopyWith<$Res> get definition {

  return $TypeDefinitionCopyWith<$Res>(_self.definition, (value) {
    return _then(_self.copyWith(definition: value));
  });
}/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res>? get icon {
    if (_self.icon == null) {
    return null;
  }

  return $IconValueCopyWith<$Res>(_self.icon!, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorLayoutCopyWith<$Res>? get editor {
    if (_self.editor == null) {
    return null;
  }

  return $RealmEditorLayoutCopyWith<$Res>(_self.editor!, (value) {
    return _then(_self.copyWith(editor: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmTypeEntry].
extension RealmTypeEntryPatterns on RealmTypeEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmTypeEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmTypeEntry() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmTypeEntry value)  $default,){
final _that = this;
switch (_that) {
case _RealmTypeEntry():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmTypeEntry value)?  $default,){
final _that = this;
switch (_that) {
case _RealmTypeEntry() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeDefinition definition,  bool eligible,  List<String> ineligibilityReasons,  String? description,  IconValue? icon,  Color? color,  RealmEditorLayout? editor,  TypedCatalogPresentationSubject? presentationSubject)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmTypeEntry() when $default != null:
return $default(_that.definition,_that.eligible,_that.ineligibilityReasons,_that.description,_that.icon,_that.color,_that.editor,_that.presentationSubject);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeDefinition definition,  bool eligible,  List<String> ineligibilityReasons,  String? description,  IconValue? icon,  Color? color,  RealmEditorLayout? editor,  TypedCatalogPresentationSubject? presentationSubject)  $default,) {final _that = this;
switch (_that) {
case _RealmTypeEntry():
return $default(_that.definition,_that.eligible,_that.ineligibilityReasons,_that.description,_that.icon,_that.color,_that.editor,_that.presentationSubject);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeDefinition definition,  bool eligible,  List<String> ineligibilityReasons,  String? description,  IconValue? icon,  Color? color,  RealmEditorLayout? editor,  TypedCatalogPresentationSubject? presentationSubject)?  $default,) {final _that = this;
switch (_that) {
case _RealmTypeEntry() when $default != null:
return $default(_that.definition,_that.eligible,_that.ineligibilityReasons,_that.description,_that.icon,_that.color,_that.editor,_that.presentationSubject);case _:
  return null;

}
}

}

/// @nodoc


class _RealmTypeEntry extends RealmTypeEntry {
  const _RealmTypeEntry({required this.definition, required this.eligible,  List<String> ineligibilityReasons = const [], this.description, this.icon, this.color, this.editor, this.presentationSubject}): _ineligibilityReasons = ineligibilityReasons,super._();


@override final  TypeDefinition definition;
@override final  bool eligible;
 final  List<String> _ineligibilityReasons;
@override@JsonKey() List<String> get ineligibilityReasons {
  if (_ineligibilityReasons is EqualUnmodifiableListView) return _ineligibilityReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ineligibilityReasons);
}

@override final  String? description;
@override final  IconValue? icon;
@override final  Color? color;
@override final  RealmEditorLayout? editor;
@override final  TypedCatalogPresentationSubject? presentationSubject;

/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmTypeEntryCopyWith<_RealmTypeEntry> get copyWith => __$RealmTypeEntryCopyWithImpl<_RealmTypeEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmTypeEntry&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.eligible, eligible) || other.eligible == eligible)&&const DeepCollectionEquality().equals(other.ineligibilityReasons, _ineligibilityReasons)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.editor, editor) || other.editor == editor)&&(identical(other.presentationSubject, presentationSubject) || other.presentationSubject == presentationSubject));
}


@override
int get hashCode {
    return Object.hash(runtimeType,definition,eligible,const DeepCollectionEquality().hash(_ineligibilityReasons),description,icon,color,editor,presentationSubject);
}

@override
String toString() {
    return 'RealmTypeEntry(definition: $definition, eligible: $eligible, ineligibilityReasons: $ineligibilityReasons, description: $description, icon: $icon, color: $color, editor: $editor, presentationSubject: $presentationSubject)';
}


}

/// @nodoc
abstract mixin class _$RealmTypeEntryCopyWith<$Res> implements $RealmTypeEntryCopyWith<$Res> {
  factory _$RealmTypeEntryCopyWith(_RealmTypeEntry value, $Res Function(_RealmTypeEntry) _then) = __$RealmTypeEntryCopyWithImpl;
@override @useResult
$Res call({
 TypeDefinition definition, bool eligible, List<String> ineligibilityReasons, String? description, IconValue? icon, Color? color, RealmEditorLayout? editor, TypedCatalogPresentationSubject? presentationSubject
});


@override $TypeDefinitionCopyWith<$Res> get definition;@override $IconValueCopyWith<$Res>? get icon;@override $RealmEditorLayoutCopyWith<$Res>? get editor;

}
/// @nodoc
class __$RealmTypeEntryCopyWithImpl<$Res>
    implements _$RealmTypeEntryCopyWith<$Res> {
  __$RealmTypeEntryCopyWithImpl(this._self, this._then);

  final _RealmTypeEntry _self;
  final $Res Function(_RealmTypeEntry) _then;

/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definition = null,Object? eligible = null,Object? ineligibilityReasons = null,Object? description = freezed,Object? icon = freezed,Object? color = freezed,Object? editor = freezed,Object? presentationSubject = freezed,}) {
  return _then(_RealmTypeEntry(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as TypeDefinition,eligible: null == eligible ? _self.eligible : eligible // ignore: cast_nullable_to_non_nullable
as bool,ineligibilityReasons: null == ineligibilityReasons ? _self._ineligibilityReasons : ineligibilityReasons // ignore: cast_nullable_to_non_nullable
as List<String>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,editor: freezed == editor ? _self.editor : editor // ignore: cast_nullable_to_non_nullable
as RealmEditorLayout?,presentationSubject: freezed == presentationSubject ? _self.presentationSubject : presentationSubject // ignore: cast_nullable_to_non_nullable
as TypedCatalogPresentationSubject?,
  ));
}

/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TypeDefinitionCopyWith<$Res> get definition {

  return $TypeDefinitionCopyWith<$Res>(_self.definition, (value) {
    return _then(_self.copyWith(definition: value));
  });
}/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res>? get icon {
    if (_self.icon == null) {
    return null;
  }

  return $IconValueCopyWith<$Res>(_self.icon!, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of RealmTypeEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmEditorLayoutCopyWith<$Res>? get editor {
    if (_self.editor == null) {
    return null;
  }

  return $RealmEditorLayoutCopyWith<$Res>(_self.editor!, (value) {
    return _then(_self.copyWith(editor: value));
  });
}
}

// dart format on
