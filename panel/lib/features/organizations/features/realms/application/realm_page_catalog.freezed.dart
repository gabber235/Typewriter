// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_page_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PageKindRef {

 String get id; int get revision;
/// Create a copy of PageKindRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<PageKindRef> get copyWith => _$PageKindRefCopyWithImpl<PageKindRef>(this as PageKindRef, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PageKindRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageKindRef&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.revision, _this.revision) || other.revision == _this.revision));
}


@override
int get hashCode {
  final _this = this as PageKindRef;
  return Object.hash(runtimeType,_this.id,_this.revision);
}

@override
String toString() {
  final _this = this as PageKindRef;
  return 'PageKindRef(id: ${_this.id}, revision: ${_this.revision})';
}


}

/// @nodoc
abstract mixin class $PageKindRefCopyWith<$Res>  {
  factory $PageKindRefCopyWith(PageKindRef value, $Res Function(PageKindRef) _then) = _$PageKindRefCopyWithImpl;
@useResult
$Res call({
 String id, int revision
});




}
/// @nodoc
class _$PageKindRefCopyWithImpl<$Res>
    implements $PageKindRefCopyWith<$Res> {
  _$PageKindRefCopyWithImpl(this._self, this._then);

  final PageKindRef _self;
  final $Res Function(PageKindRef) _then;

/// Create a copy of PageKindRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? revision = null,}) {
  return _then(PageKindRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PageKindRef].
extension PageKindRefPatterns on PageKindRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageKindRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageKindRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageKindRef value)  $default,){
final _that = this;
switch (_that) {
case _PageKindRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageKindRef value)?  $default,){
final _that = this;
switch (_that) {
case _PageKindRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageKindRef() when $default != null:
return $default(_that.id,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int revision)  $default,) {final _that = this;
switch (_that) {
case _PageKindRef():
return $default(_that.id,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _PageKindRef() when $default != null:
return $default(_that.id,_that.revision);case _:
  return null;

}
}

}

/// @nodoc


class _PageKindRef extends PageKindRef {
  const _PageKindRef({required this.id, required this.revision}): super._();
  

@override final  String id;
@override final  int revision;

/// Create a copy of PageKindRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageKindRefCopyWith<_PageKindRef> get copyWith => __$PageKindRefCopyWithImpl<_PageKindRef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageKindRef&&(identical(other.id, id) || other.id == id)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,revision);
}

@override
String toString() {
    return 'PageKindRef(id: $id, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$PageKindRefCopyWith<$Res> implements $PageKindRefCopyWith<$Res> {
  factory _$PageKindRefCopyWith(_PageKindRef value, $Res Function(_PageKindRef) _then) = __$PageKindRefCopyWithImpl;
@override @useResult
$Res call({
 String id, int revision
});




}
/// @nodoc
class __$PageKindRefCopyWithImpl<$Res>
    implements _$PageKindRefCopyWith<$Res> {
  __$PageKindRefCopyWithImpl(this._self, this._then);

  final _PageKindRef _self;
  final $Res Function(_PageKindRef) _then;

/// Create a copy of PageKindRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? revision = null,}) {
  return _then(_PageKindRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$RealmPageEditor {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPageEditor);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmPageEditor()';
}


}

/// @nodoc
class $RealmPageEditorCopyWith<$Res>  {
$RealmPageEditorCopyWith(RealmPageEditor _, $Res Function(RealmPageEditor) __);
}


/// Adds pattern-matching-related methods to [RealmPageEditor].
extension RealmPageEditorPatterns on RealmPageEditor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmGraphPageEditor value)?  graph,TResult Function( RealmTimelinePageEditor value)?  timeline,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmGraphPageEditor() when graph != null:
return graph(_that);case RealmTimelinePageEditor() when timeline != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmGraphPageEditor value)  graph,required TResult Function( RealmTimelinePageEditor value)  timeline,}){
final _that = this;
switch (_that) {
case RealmGraphPageEditor():
return graph(_that);case RealmTimelinePageEditor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmGraphPageEditor value)?  graph,TResult? Function( RealmTimelinePageEditor value)?  timeline,}){
final _that = this;
switch (_that) {
case RealmGraphPageEditor() when graph != null:
return graph(_that);case RealmTimelinePageEditor() when timeline != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( GraphDirection direction,  List<ResolvedTypeRef> nodeTypes)?  graph,TResult Function( List<ResolvedTypeRef> trackTypes,  List<ResolvedTypeRef> segmentTypes,  List<ResolvedTypeRef> keyframeTypes)?  timeline,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmGraphPageEditor() when graph != null:
return graph(_that.direction,_that.nodeTypes);case RealmTimelinePageEditor() when timeline != null:
return timeline(_that.trackTypes,_that.segmentTypes,_that.keyframeTypes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( GraphDirection direction,  List<ResolvedTypeRef> nodeTypes)  graph,required TResult Function( List<ResolvedTypeRef> trackTypes,  List<ResolvedTypeRef> segmentTypes,  List<ResolvedTypeRef> keyframeTypes)  timeline,}) {final _that = this;
switch (_that) {
case RealmGraphPageEditor():
return graph(_that.direction,_that.nodeTypes);case RealmTimelinePageEditor():
return timeline(_that.trackTypes,_that.segmentTypes,_that.keyframeTypes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( GraphDirection direction,  List<ResolvedTypeRef> nodeTypes)?  graph,TResult? Function( List<ResolvedTypeRef> trackTypes,  List<ResolvedTypeRef> segmentTypes,  List<ResolvedTypeRef> keyframeTypes)?  timeline,}) {final _that = this;
switch (_that) {
case RealmGraphPageEditor() when graph != null:
return graph(_that.direction,_that.nodeTypes);case RealmTimelinePageEditor() when timeline != null:
return timeline(_that.trackTypes,_that.segmentTypes,_that.keyframeTypes);case _:
  return null;

}
}

}

/// @nodoc


class RealmGraphPageEditor implements RealmPageEditor {
  const RealmGraphPageEditor({required this.direction, required  List<ResolvedTypeRef> nodeTypes}): _nodeTypes = nodeTypes;
  

 final  GraphDirection direction;
 final  List<ResolvedTypeRef> _nodeTypes;
 List<ResolvedTypeRef> get nodeTypes {
  if (_nodeTypes is EqualUnmodifiableListView) return _nodeTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodeTypes);
}


/// Create a copy of RealmPageEditor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmGraphPageEditorCopyWith<RealmGraphPageEditor> get copyWith => _$RealmGraphPageEditorCopyWithImpl<RealmGraphPageEditor>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmGraphPageEditor&&(identical(other.direction, direction) || other.direction == direction)&&const DeepCollectionEquality().equals(other.nodeTypes, _nodeTypes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,direction,const DeepCollectionEquality().hash(_nodeTypes));
}

@override
String toString() {
    return 'RealmPageEditor.graph(direction: $direction, nodeTypes: $nodeTypes)';
}


}

/// @nodoc
abstract mixin class $RealmGraphPageEditorCopyWith<$Res> implements $RealmPageEditorCopyWith<$Res> {
  factory $RealmGraphPageEditorCopyWith(RealmGraphPageEditor value, $Res Function(RealmGraphPageEditor) _then) = _$RealmGraphPageEditorCopyWithImpl;
@useResult
$Res call({
 GraphDirection direction, List<ResolvedTypeRef> nodeTypes
});




}
/// @nodoc
class _$RealmGraphPageEditorCopyWithImpl<$Res>
    implements $RealmGraphPageEditorCopyWith<$Res> {
  _$RealmGraphPageEditorCopyWithImpl(this._self, this._then);

  final RealmGraphPageEditor _self;
  final $Res Function(RealmGraphPageEditor) _then;

/// Create a copy of RealmPageEditor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? direction = null,Object? nodeTypes = null,}) {
  return _then(RealmGraphPageEditor(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as GraphDirection,nodeTypes: null == nodeTypes ? _self._nodeTypes : nodeTypes // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,
  ));
}


}

/// @nodoc


class RealmTimelinePageEditor implements RealmPageEditor {
  const RealmTimelinePageEditor({required  List<ResolvedTypeRef> trackTypes, required  List<ResolvedTypeRef> segmentTypes, required  List<ResolvedTypeRef> keyframeTypes}): _trackTypes = trackTypes,_segmentTypes = segmentTypes,_keyframeTypes = keyframeTypes;
  

 final  List<ResolvedTypeRef> _trackTypes;
 List<ResolvedTypeRef> get trackTypes {
  if (_trackTypes is EqualUnmodifiableListView) return _trackTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trackTypes);
}

 final  List<ResolvedTypeRef> _segmentTypes;
 List<ResolvedTypeRef> get segmentTypes {
  if (_segmentTypes is EqualUnmodifiableListView) return _segmentTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segmentTypes);
}

 final  List<ResolvedTypeRef> _keyframeTypes;
 List<ResolvedTypeRef> get keyframeTypes {
  if (_keyframeTypes is EqualUnmodifiableListView) return _keyframeTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyframeTypes);
}


/// Create a copy of RealmPageEditor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmTimelinePageEditorCopyWith<RealmTimelinePageEditor> get copyWith => _$RealmTimelinePageEditorCopyWithImpl<RealmTimelinePageEditor>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmTimelinePageEditor&&const DeepCollectionEquality().equals(other.trackTypes, _trackTypes)&&const DeepCollectionEquality().equals(other.segmentTypes, _segmentTypes)&&const DeepCollectionEquality().equals(other.keyframeTypes, _keyframeTypes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_trackTypes),const DeepCollectionEquality().hash(_segmentTypes),const DeepCollectionEquality().hash(_keyframeTypes));
}

@override
String toString() {
    return 'RealmPageEditor.timeline(trackTypes: $trackTypes, segmentTypes: $segmentTypes, keyframeTypes: $keyframeTypes)';
}


}

/// @nodoc
abstract mixin class $RealmTimelinePageEditorCopyWith<$Res> implements $RealmPageEditorCopyWith<$Res> {
  factory $RealmTimelinePageEditorCopyWith(RealmTimelinePageEditor value, $Res Function(RealmTimelinePageEditor) _then) = _$RealmTimelinePageEditorCopyWithImpl;
@useResult
$Res call({
 List<ResolvedTypeRef> trackTypes, List<ResolvedTypeRef> segmentTypes, List<ResolvedTypeRef> keyframeTypes
});




}
/// @nodoc
class _$RealmTimelinePageEditorCopyWithImpl<$Res>
    implements $RealmTimelinePageEditorCopyWith<$Res> {
  _$RealmTimelinePageEditorCopyWithImpl(this._self, this._then);

  final RealmTimelinePageEditor _self;
  final $Res Function(RealmTimelinePageEditor) _then;

/// Create a copy of RealmPageEditor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trackTypes = null,Object? segmentTypes = null,Object? keyframeTypes = null,}) {
  return _then(RealmTimelinePageEditor(
trackTypes: null == trackTypes ? _self._trackTypes : trackTypes // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,segmentTypes: null == segmentTypes ? _self._segmentTypes : segmentTypes // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,keyframeTypes: null == keyframeTypes ? _self._keyframeTypes : keyframeTypes // ignore: cast_nullable_to_non_nullable
as List<ResolvedTypeRef>,
  ));
}


}

/// @nodoc
mixin _$RealmPageDefinition {

 PageKindRef get kind; String get name; String? get description; IconValue get icon; Color get color; RealmPageEditor get editor; TypedCatalogPresentationSubject get presentationSubject; String get originArtifactId; String get sourcePart; List<RealmPageAuthoringRuleRef> get authoringRules;
/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPageDefinitionCopyWith<RealmPageDefinition> get copyWith => _$RealmPageDefinitionCopyWithImpl<RealmPageDefinition>(this as RealmPageDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmPageDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPageDefinition&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.editor, _this.editor) || other.editor == _this.editor)&&(identical(other.presentationSubject, _this.presentationSubject) || other.presentationSubject == _this.presentationSubject)&&(identical(other.originArtifactId, _this.originArtifactId) || other.originArtifactId == _this.originArtifactId)&&(identical(other.sourcePart, _this.sourcePart) || other.sourcePart == _this.sourcePart)&&const DeepCollectionEquality().equals(other.authoringRules, _this.authoringRules));
}


@override
int get hashCode {
  final _this = this as RealmPageDefinition;
  return Object.hash(runtimeType,_this.kind,_this.name,_this.description,_this.icon,_this.color,_this.editor,_this.presentationSubject,_this.originArtifactId,_this.sourcePart,const DeepCollectionEquality().hash(_this.authoringRules));
}

@override
String toString() {
  final _this = this as RealmPageDefinition;
  return 'RealmPageDefinition(kind: ${_this.kind}, name: ${_this.name}, description: ${_this.description}, icon: ${_this.icon}, color: ${_this.color}, editor: ${_this.editor}, presentationSubject: ${_this.presentationSubject}, originArtifactId: ${_this.originArtifactId}, sourcePart: ${_this.sourcePart}, authoringRules: ${_this.authoringRules})';
}


}

/// @nodoc
abstract mixin class $RealmPageDefinitionCopyWith<$Res>  {
  factory $RealmPageDefinitionCopyWith(RealmPageDefinition value, $Res Function(RealmPageDefinition) _then) = _$RealmPageDefinitionCopyWithImpl;
@useResult
$Res call({
 PageKindRef kind, String name, String? description, IconValue icon, Color color, RealmPageEditor editor, TypedCatalogPresentationSubject presentationSubject, String originArtifactId, String sourcePart, List<RealmPageAuthoringRuleRef> authoringRules
});


$PageKindRefCopyWith<$Res> get kind;$IconValueCopyWith<$Res> get icon;$RealmPageEditorCopyWith<$Res> get editor;

}
/// @nodoc
class _$RealmPageDefinitionCopyWithImpl<$Res>
    implements $RealmPageDefinitionCopyWith<$Res> {
  _$RealmPageDefinitionCopyWithImpl(this._self, this._then);

  final RealmPageDefinition _self;
  final $Res Function(RealmPageDefinition) _then;

/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? name = null,Object? description = freezed,Object? icon = null,Object? color = null,Object? editor = null,Object? presentationSubject = null,Object? originArtifactId = null,Object? sourcePart = null,Object? authoringRules = null,}) {
  return _then(RealmPageDefinition(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,editor: null == editor ? _self.editor : editor // ignore: cast_nullable_to_non_nullable
as RealmPageEditor,presentationSubject: null == presentationSubject ? _self.presentationSubject : presentationSubject // ignore: cast_nullable_to_non_nullable
as TypedCatalogPresentationSubject,originArtifactId: null == originArtifactId ? _self.originArtifactId : originArtifactId // ignore: cast_nullable_to_non_nullable
as String,sourcePart: null == sourcePart ? _self.sourcePart : sourcePart // ignore: cast_nullable_to_non_nullable
as String,authoringRules: null == authoringRules ? _self.authoringRules : authoringRules // ignore: cast_nullable_to_non_nullable
as List<RealmPageAuthoringRuleRef>,
  ));
}
/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<$Res> get kind {
  
  return $PageKindRefCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPageEditorCopyWith<$Res> get editor {
  
  return $RealmPageEditorCopyWith<$Res>(_self.editor, (value) {
    return _then(_self.copyWith(editor: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmPageDefinition].
extension RealmPageDefinitionPatterns on RealmPageDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmPageDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmPageDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmPageDefinition value)  $default,){
final _that = this;
switch (_that) {
case _RealmPageDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmPageDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _RealmPageDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PageKindRef kind,  String name,  String? description,  IconValue icon,  Color color,  RealmPageEditor editor,  TypedCatalogPresentationSubject presentationSubject,  String originArtifactId,  String sourcePart,  List<RealmPageAuthoringRuleRef> authoringRules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmPageDefinition() when $default != null:
return $default(_that.kind,_that.name,_that.description,_that.icon,_that.color,_that.editor,_that.presentationSubject,_that.originArtifactId,_that.sourcePart,_that.authoringRules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PageKindRef kind,  String name,  String? description,  IconValue icon,  Color color,  RealmPageEditor editor,  TypedCatalogPresentationSubject presentationSubject,  String originArtifactId,  String sourcePart,  List<RealmPageAuthoringRuleRef> authoringRules)  $default,) {final _that = this;
switch (_that) {
case _RealmPageDefinition():
return $default(_that.kind,_that.name,_that.description,_that.icon,_that.color,_that.editor,_that.presentationSubject,_that.originArtifactId,_that.sourcePart,_that.authoringRules);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PageKindRef kind,  String name,  String? description,  IconValue icon,  Color color,  RealmPageEditor editor,  TypedCatalogPresentationSubject presentationSubject,  String originArtifactId,  String sourcePart,  List<RealmPageAuthoringRuleRef> authoringRules)?  $default,) {final _that = this;
switch (_that) {
case _RealmPageDefinition() when $default != null:
return $default(_that.kind,_that.name,_that.description,_that.icon,_that.color,_that.editor,_that.presentationSubject,_that.originArtifactId,_that.sourcePart,_that.authoringRules);case _:
  return null;

}
}

}

/// @nodoc


class _RealmPageDefinition extends RealmPageDefinition {
  const _RealmPageDefinition({required this.kind, required this.name, required this.description, required this.icon, required this.color, required this.editor, required this.presentationSubject, required this.originArtifactId, required this.sourcePart,  List<RealmPageAuthoringRuleRef> authoringRules = const []}): _authoringRules = authoringRules,super._();
  

@override final  PageKindRef kind;
@override final  String name;
@override final  String? description;
@override final  IconValue icon;
@override final  Color color;
@override final  RealmPageEditor editor;
@override final  TypedCatalogPresentationSubject presentationSubject;
@override final  String originArtifactId;
@override final  String sourcePart;
 final  List<RealmPageAuthoringRuleRef> _authoringRules;
@override@JsonKey() List<RealmPageAuthoringRuleRef> get authoringRules {
  if (_authoringRules is EqualUnmodifiableListView) return _authoringRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authoringRules);
}


/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmPageDefinitionCopyWith<_RealmPageDefinition> get copyWith => __$RealmPageDefinitionCopyWithImpl<_RealmPageDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmPageDefinition&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.editor, editor) || other.editor == editor)&&(identical(other.presentationSubject, presentationSubject) || other.presentationSubject == presentationSubject)&&(identical(other.originArtifactId, originArtifactId) || other.originArtifactId == originArtifactId)&&(identical(other.sourcePart, sourcePart) || other.sourcePart == sourcePart)&&const DeepCollectionEquality().equals(other.authoringRules, _authoringRules));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,name,description,icon,color,editor,presentationSubject,originArtifactId,sourcePart,const DeepCollectionEquality().hash(_authoringRules));
}

@override
String toString() {
    return 'RealmPageDefinition(kind: $kind, name: $name, description: $description, icon: $icon, color: $color, editor: $editor, presentationSubject: $presentationSubject, originArtifactId: $originArtifactId, sourcePart: $sourcePart, authoringRules: $authoringRules)';
}


}

/// @nodoc
abstract mixin class _$RealmPageDefinitionCopyWith<$Res> implements $RealmPageDefinitionCopyWith<$Res> {
  factory _$RealmPageDefinitionCopyWith(_RealmPageDefinition value, $Res Function(_RealmPageDefinition) _then) = __$RealmPageDefinitionCopyWithImpl;
@override @useResult
$Res call({
 PageKindRef kind, String name, String? description, IconValue icon, Color color, RealmPageEditor editor, TypedCatalogPresentationSubject presentationSubject, String originArtifactId, String sourcePart, List<RealmPageAuthoringRuleRef> authoringRules
});


@override $PageKindRefCopyWith<$Res> get kind;@override $IconValueCopyWith<$Res> get icon;@override $RealmPageEditorCopyWith<$Res> get editor;

}
/// @nodoc
class __$RealmPageDefinitionCopyWithImpl<$Res>
    implements _$RealmPageDefinitionCopyWith<$Res> {
  __$RealmPageDefinitionCopyWithImpl(this._self, this._then);

  final _RealmPageDefinition _self;
  final $Res Function(_RealmPageDefinition) _then;

/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? name = null,Object? description = freezed,Object? icon = null,Object? color = null,Object? editor = null,Object? presentationSubject = null,Object? originArtifactId = null,Object? sourcePart = null,Object? authoringRules = null,}) {
  return _then(_RealmPageDefinition(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as IconValue,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,editor: null == editor ? _self.editor : editor // ignore: cast_nullable_to_non_nullable
as RealmPageEditor,presentationSubject: null == presentationSubject ? _self.presentationSubject : presentationSubject // ignore: cast_nullable_to_non_nullable
as TypedCatalogPresentationSubject,originArtifactId: null == originArtifactId ? _self.originArtifactId : originArtifactId // ignore: cast_nullable_to_non_nullable
as String,sourcePart: null == sourcePart ? _self.sourcePart : sourcePart // ignore: cast_nullable_to_non_nullable
as String,authoringRules: null == authoringRules ? _self._authoringRules : authoringRules // ignore: cast_nullable_to_non_nullable
as List<RealmPageAuthoringRuleRef>,
  ));
}

/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<$Res> get kind {
  
  return $PageKindRefCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IconValueCopyWith<$Res> get icon {
  
  return $IconValueCopyWith<$Res>(_self.icon, (value) {
    return _then(_self.copyWith(icon: value));
  });
}/// Create a copy of RealmPageDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPageEditorCopyWith<$Res> get editor {
  
  return $RealmPageEditorCopyWith<$Res>(_self.editor, (value) {
    return _then(_self.copyWith(editor: value));
  });
}
}

/// @nodoc
mixin _$RealmPageDiagnostic {

 String get code; String get message; String? get originArtifactId; String? get sourcePart; String? get declarationName; PageKindRef? get kind;
/// Create a copy of RealmPageDiagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPageDiagnosticCopyWith<RealmPageDiagnostic> get copyWith => _$RealmPageDiagnosticCopyWithImpl<RealmPageDiagnostic>(this as RealmPageDiagnostic, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmPageDiagnostic;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPageDiagnostic&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.originArtifactId, _this.originArtifactId) || other.originArtifactId == _this.originArtifactId)&&(identical(other.sourcePart, _this.sourcePart) || other.sourcePart == _this.sourcePart)&&(identical(other.declarationName, _this.declarationName) || other.declarationName == _this.declarationName)&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}


@override
int get hashCode {
  final _this = this as RealmPageDiagnostic;
  return Object.hash(runtimeType,_this.code,_this.message,_this.originArtifactId,_this.sourcePart,_this.declarationName,_this.kind);
}

@override
String toString() {
  final _this = this as RealmPageDiagnostic;
  return 'RealmPageDiagnostic(code: ${_this.code}, message: ${_this.message}, originArtifactId: ${_this.originArtifactId}, sourcePart: ${_this.sourcePart}, declarationName: ${_this.declarationName}, kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $RealmPageDiagnosticCopyWith<$Res>  {
  factory $RealmPageDiagnosticCopyWith(RealmPageDiagnostic value, $Res Function(RealmPageDiagnostic) _then) = _$RealmPageDiagnosticCopyWithImpl;
@useResult
$Res call({
 String code, String message, String? originArtifactId, String? sourcePart, String? declarationName, PageKindRef? kind
});


$PageKindRefCopyWith<$Res>? get kind;

}
/// @nodoc
class _$RealmPageDiagnosticCopyWithImpl<$Res>
    implements $RealmPageDiagnosticCopyWith<$Res> {
  _$RealmPageDiagnosticCopyWithImpl(this._self, this._then);

  final RealmPageDiagnostic _self;
  final $Res Function(RealmPageDiagnostic) _then;

/// Create a copy of RealmPageDiagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? originArtifactId = freezed,Object? sourcePart = freezed,Object? declarationName = freezed,Object? kind = freezed,}) {
  return _then(RealmPageDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,originArtifactId: freezed == originArtifactId ? _self.originArtifactId : originArtifactId // ignore: cast_nullable_to_non_nullable
as String?,sourcePart: freezed == sourcePart ? _self.sourcePart : sourcePart // ignore: cast_nullable_to_non_nullable
as String?,declarationName: freezed == declarationName ? _self.declarationName : declarationName // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef?,
  ));
}
/// Create a copy of RealmPageDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<$Res>? get kind {
    if (_self.kind == null) {
    return null;
  }

  return $PageKindRefCopyWith<$Res>(_self.kind!, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmPageDiagnostic].
extension RealmPageDiagnosticPatterns on RealmPageDiagnostic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmPageDiagnostic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmPageDiagnostic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmPageDiagnostic value)  $default,){
final _that = this;
switch (_that) {
case _RealmPageDiagnostic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmPageDiagnostic value)?  $default,){
final _that = this;
switch (_that) {
case _RealmPageDiagnostic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message,  String? originArtifactId,  String? sourcePart,  String? declarationName,  PageKindRef? kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmPageDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.originArtifactId,_that.sourcePart,_that.declarationName,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message,  String? originArtifactId,  String? sourcePart,  String? declarationName,  PageKindRef? kind)  $default,) {final _that = this;
switch (_that) {
case _RealmPageDiagnostic():
return $default(_that.code,_that.message,_that.originArtifactId,_that.sourcePart,_that.declarationName,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message,  String? originArtifactId,  String? sourcePart,  String? declarationName,  PageKindRef? kind)?  $default,) {final _that = this;
switch (_that) {
case _RealmPageDiagnostic() when $default != null:
return $default(_that.code,_that.message,_that.originArtifactId,_that.sourcePart,_that.declarationName,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _RealmPageDiagnostic implements RealmPageDiagnostic {
  const _RealmPageDiagnostic({required this.code, required this.message, required this.originArtifactId, required this.sourcePart, required this.declarationName, required this.kind});
  

@override final  String code;
@override final  String message;
@override final  String? originArtifactId;
@override final  String? sourcePart;
@override final  String? declarationName;
@override final  PageKindRef? kind;

/// Create a copy of RealmPageDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmPageDiagnosticCopyWith<_RealmPageDiagnostic> get copyWith => __$RealmPageDiagnosticCopyWithImpl<_RealmPageDiagnostic>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmPageDiagnostic&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.originArtifactId, originArtifactId) || other.originArtifactId == originArtifactId)&&(identical(other.sourcePart, sourcePart) || other.sourcePart == sourcePart)&&(identical(other.declarationName, declarationName) || other.declarationName == declarationName)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode {
    return Object.hash(runtimeType,code,message,originArtifactId,sourcePart,declarationName,kind);
}

@override
String toString() {
    return 'RealmPageDiagnostic(code: $code, message: $message, originArtifactId: $originArtifactId, sourcePart: $sourcePart, declarationName: $declarationName, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$RealmPageDiagnosticCopyWith<$Res> implements $RealmPageDiagnosticCopyWith<$Res> {
  factory _$RealmPageDiagnosticCopyWith(_RealmPageDiagnostic value, $Res Function(_RealmPageDiagnostic) _then) = __$RealmPageDiagnosticCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, String? originArtifactId, String? sourcePart, String? declarationName, PageKindRef? kind
});


@override $PageKindRefCopyWith<$Res>? get kind;

}
/// @nodoc
class __$RealmPageDiagnosticCopyWithImpl<$Res>
    implements _$RealmPageDiagnosticCopyWith<$Res> {
  __$RealmPageDiagnosticCopyWithImpl(this._self, this._then);

  final _RealmPageDiagnostic _self;
  final $Res Function(_RealmPageDiagnostic) _then;

/// Create a copy of RealmPageDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? originArtifactId = freezed,Object? sourcePart = freezed,Object? declarationName = freezed,Object? kind = freezed,}) {
  return _then(_RealmPageDiagnostic(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,originArtifactId: freezed == originArtifactId ? _self.originArtifactId : originArtifactId // ignore: cast_nullable_to_non_nullable
as String?,sourcePart: freezed == sourcePart ? _self.sourcePart : sourcePart // ignore: cast_nullable_to_non_nullable
as String?,declarationName: freezed == declarationName ? _self.declarationName : declarationName // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef?,
  ));
}

/// Create a copy of RealmPageDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<$Res>? get kind {
    if (_self.kind == null) {
    return null;
  }

  return $PageKindRefCopyWith<$Res>(_self.kind!, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}

/// @nodoc
mixin _$RealmPageCatalog {

 Map<PageKindRef, RealmPageDefinition> get definitions; List<RealmPageDiagnostic> get diagnostics;
/// Create a copy of RealmPageCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmPageCatalogCopyWith<RealmPageCatalog> get copyWith => _$RealmPageCatalogCopyWithImpl<RealmPageCatalog>(this as RealmPageCatalog, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmPageCatalog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPageCatalog&&const DeepCollectionEquality().equals(other.definitions, _this.definitions)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as RealmPageCatalog;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.definitions),const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as RealmPageCatalog;
  return 'RealmPageCatalog(definitions: ${_this.definitions}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $RealmPageCatalogCopyWith<$Res>  {
  factory $RealmPageCatalogCopyWith(RealmPageCatalog value, $Res Function(RealmPageCatalog) _then) = _$RealmPageCatalogCopyWithImpl;
@useResult
$Res call({
 Map<PageKindRef, RealmPageDefinition> definitions, List<RealmPageDiagnostic> diagnostics
});




}
/// @nodoc
class _$RealmPageCatalogCopyWithImpl<$Res>
    implements $RealmPageCatalogCopyWith<$Res> {
  _$RealmPageCatalogCopyWithImpl(this._self, this._then);

  final RealmPageCatalog _self;
  final $Res Function(RealmPageCatalog) _then;

/// Create a copy of RealmPageCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitions = null,Object? diagnostics = null,}) {
  return _then(RealmPageCatalog(
definitions: null == definitions ? _self.definitions : definitions // ignore: cast_nullable_to_non_nullable
as Map<PageKindRef, RealmPageDefinition>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<RealmPageDiagnostic>,
  ));
}

}


/// Adds pattern-matching-related methods to [RealmPageCatalog].
extension RealmPageCatalogPatterns on RealmPageCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmPageCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmPageCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmPageCatalog value)  $default,){
final _that = this;
switch (_that) {
case _RealmPageCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmPageCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _RealmPageCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<PageKindRef, RealmPageDefinition> definitions,  List<RealmPageDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmPageCatalog() when $default != null:
return $default(_that.definitions,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<PageKindRef, RealmPageDefinition> definitions,  List<RealmPageDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _RealmPageCatalog():
return $default(_that.definitions,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<PageKindRef, RealmPageDefinition> definitions,  List<RealmPageDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _RealmPageCatalog() when $default != null:
return $default(_that.definitions,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _RealmPageCatalog implements RealmPageCatalog {
  const _RealmPageCatalog({ Map<PageKindRef, RealmPageDefinition> definitions = const {},  List<RealmPageDiagnostic> diagnostics = const []}): _definitions = definitions,_diagnostics = diagnostics;
  

 final  Map<PageKindRef, RealmPageDefinition> _definitions;
@override@JsonKey() Map<PageKindRef, RealmPageDefinition> get definitions {
  if (_definitions is EqualUnmodifiableMapView) return _definitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_definitions);
}

 final  List<RealmPageDiagnostic> _diagnostics;
@override@JsonKey() List<RealmPageDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of RealmPageCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmPageCatalogCopyWith<_RealmPageCatalog> get copyWith => __$RealmPageCatalogCopyWithImpl<_RealmPageCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmPageCatalog&&const DeepCollectionEquality().equals(other.definitions, _definitions)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_definitions),const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'RealmPageCatalog(definitions: $definitions, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$RealmPageCatalogCopyWith<$Res> implements $RealmPageCatalogCopyWith<$Res> {
  factory _$RealmPageCatalogCopyWith(_RealmPageCatalog value, $Res Function(_RealmPageCatalog) _then) = __$RealmPageCatalogCopyWithImpl;
@override @useResult
$Res call({
 Map<PageKindRef, RealmPageDefinition> definitions, List<RealmPageDiagnostic> diagnostics
});




}
/// @nodoc
class __$RealmPageCatalogCopyWithImpl<$Res>
    implements _$RealmPageCatalogCopyWith<$Res> {
  __$RealmPageCatalogCopyWithImpl(this._self, this._then);

  final _RealmPageCatalog _self;
  final $Res Function(_RealmPageCatalog) _then;

/// Create a copy of RealmPageCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitions = null,Object? diagnostics = null,}) {
  return _then(_RealmPageCatalog(
definitions: null == definitions ? _self._definitions : definitions // ignore: cast_nullable_to_non_nullable
as Map<PageKindRef, RealmPageDefinition>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<RealmPageDiagnostic>,
  ));
}


}

// dart format on
