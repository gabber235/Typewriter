// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Cue {

 String get id; ElementDefinition get elementDefinition; RecordValue get data; List<ElementLink> get inwardLinks; int get revision;
/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CueCopyWith<Cue> get copyWith => _$CueCopyWithImpl<Cue>(this as Cue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cue&&(identical(other.id, id) || other.id == id)&&(identical(other.elementDefinition, elementDefinition) || other.elementDefinition == elementDefinition)&&(identical(other.data, data) || other.data == data)&&const DeepCollectionEquality().equals(other.inwardLinks, inwardLinks)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode => Object.hash(runtimeType,id,elementDefinition,data,const DeepCollectionEquality().hash(inwardLinks),revision);

@override
String toString() {
  return 'Cue(id: $id, elementDefinition: $elementDefinition, data: $data, inwardLinks: $inwardLinks, revision: $revision)';
}


}

/// @nodoc
abstract mixin class $CueCopyWith<$Res>  {
  factory $CueCopyWith(Cue value, $Res Function(Cue) _then) = _$CueCopyWithImpl;
@useResult
$Res call({
 String id, ElementDefinition elementDefinition, RecordValue data, List<ElementLink> inwardLinks, int revision
});


$ElementDefinitionCopyWith<$Res> get elementDefinition;

}
/// @nodoc
class _$CueCopyWithImpl<$Res>
    implements $CueCopyWith<$Res> {
  _$CueCopyWithImpl(this._self, this._then);

  final Cue _self;
  final $Res Function(Cue) _then;

/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? elementDefinition = null,Object? data = null,Object? inwardLinks = null,Object? revision = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,elementDefinition: null == elementDefinition ? _self.elementDefinition : elementDefinition // ignore: cast_nullable_to_non_nullable
as ElementDefinition,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RecordValue,inwardLinks: null == inwardLinks ? _self.inwardLinks : inwardLinks // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementDefinitionCopyWith<$Res> get elementDefinition {

  return $ElementDefinitionCopyWith<$Res>(_self.elementDefinition, (value) {
    return _then(_self.copyWith(elementDefinition: value));
  });
}
}


/// Adds pattern-matching-related methods to [Cue].
extension CuePatterns on Cue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Segment value)?  segment,TResult Function( Keyframe value)?  keyframe,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Segment() when segment != null:
return segment(_that);case Keyframe() when keyframe != null:
return keyframe(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Segment value)  segment,required TResult Function( Keyframe value)  keyframe,}){
final _that = this;
switch (_that) {
case Segment():
return segment(_that);case Keyframe():
return keyframe(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Segment value)?  segment,TResult? Function( Keyframe value)?  keyframe,}){
final _that = this;
switch (_that) {
case Segment() when segment != null:
return segment(_that);case Keyframe() when keyframe != null:
return keyframe(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  int startFrame,  int endFrame,  ElementDefinition elementDefinition,  RecordValue data,  List<ElementLink> inwardLinks,  List<ElementLink> outwardLinks,  int revision)?  segment,TResult Function( String id,  int frame,  ElementDefinition elementDefinition,  RecordValue data,  List<ElementLink> inwardLinks,  int revision)?  keyframe,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Segment() when segment != null:
return segment(_that.id,_that.startFrame,_that.endFrame,_that.elementDefinition,_that.data,_that.inwardLinks,_that.outwardLinks,_that.revision);case Keyframe() when keyframe != null:
return keyframe(_that.id,_that.frame,_that.elementDefinition,_that.data,_that.inwardLinks,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  int startFrame,  int endFrame,  ElementDefinition elementDefinition,  RecordValue data,  List<ElementLink> inwardLinks,  List<ElementLink> outwardLinks,  int revision)  segment,required TResult Function( String id,  int frame,  ElementDefinition elementDefinition,  RecordValue data,  List<ElementLink> inwardLinks,  int revision)  keyframe,}) {final _that = this;
switch (_that) {
case Segment():
return segment(_that.id,_that.startFrame,_that.endFrame,_that.elementDefinition,_that.data,_that.inwardLinks,_that.outwardLinks,_that.revision);case Keyframe():
return keyframe(_that.id,_that.frame,_that.elementDefinition,_that.data,_that.inwardLinks,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  int startFrame,  int endFrame,  ElementDefinition elementDefinition,  RecordValue data,  List<ElementLink> inwardLinks,  List<ElementLink> outwardLinks,  int revision)?  segment,TResult? Function( String id,  int frame,  ElementDefinition elementDefinition,  RecordValue data,  List<ElementLink> inwardLinks,  int revision)?  keyframe,}) {final _that = this;
switch (_that) {
case Segment() when segment != null:
return segment(_that.id,_that.startFrame,_that.endFrame,_that.elementDefinition,_that.data,_that.inwardLinks,_that.outwardLinks,_that.revision);case Keyframe() when keyframe != null:
return keyframe(_that.id,_that.frame,_that.elementDefinition,_that.data,_that.inwardLinks,_that.revision);case _:
  return null;

}
}

}

/// @nodoc


class Segment implements Cue {
  const Segment({required this.id, required this.startFrame, required this.endFrame, required this.elementDefinition, required this.data, required final  List<ElementLink> inwardLinks, required final  List<ElementLink> outwardLinks, this.revision = 1}): assert(id != "", 'ID must not be empty.'),assert(startFrame >= 0, 'Start frame must not be negative.'),assert(endFrame >= startFrame, 'End frame must not precede start frame.'),_inwardLinks = inwardLinks,_outwardLinks = outwardLinks;


@override final  String id;
 final  int startFrame;
 final  int endFrame;
@override final  ElementDefinition elementDefinition;
@override final  RecordValue data;
 final  List<ElementLink> _inwardLinks;
@override List<ElementLink> get inwardLinks {
  if (_inwardLinks is EqualUnmodifiableListView) return _inwardLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inwardLinks);
}

 final  List<ElementLink> _outwardLinks;
 List<ElementLink> get outwardLinks {
  if (_outwardLinks is EqualUnmodifiableListView) return _outwardLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outwardLinks);
}

@override@JsonKey() final  int revision;

/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SegmentCopyWith<Segment> get copyWith => _$SegmentCopyWithImpl<Segment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Segment&&(identical(other.id, id) || other.id == id)&&(identical(other.startFrame, startFrame) || other.startFrame == startFrame)&&(identical(other.endFrame, endFrame) || other.endFrame == endFrame)&&(identical(other.elementDefinition, elementDefinition) || other.elementDefinition == elementDefinition)&&(identical(other.data, data) || other.data == data)&&const DeepCollectionEquality().equals(other._inwardLinks, _inwardLinks)&&const DeepCollectionEquality().equals(other._outwardLinks, _outwardLinks)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode => Object.hash(runtimeType,id,startFrame,endFrame,elementDefinition,data,const DeepCollectionEquality().hash(_inwardLinks),const DeepCollectionEquality().hash(_outwardLinks),revision);

@override
String toString() {
  return 'Cue.segment(id: $id, startFrame: $startFrame, endFrame: $endFrame, elementDefinition: $elementDefinition, data: $data, inwardLinks: $inwardLinks, outwardLinks: $outwardLinks, revision: $revision)';
}


}

/// @nodoc
abstract mixin class $SegmentCopyWith<$Res> implements $CueCopyWith<$Res> {
  factory $SegmentCopyWith(Segment value, $Res Function(Segment) _then) = _$SegmentCopyWithImpl;
@override @useResult
$Res call({
 String id, int startFrame, int endFrame, ElementDefinition elementDefinition, RecordValue data, List<ElementLink> inwardLinks, List<ElementLink> outwardLinks, int revision
});


@override $ElementDefinitionCopyWith<$Res> get elementDefinition;

}
/// @nodoc
class _$SegmentCopyWithImpl<$Res>
    implements $SegmentCopyWith<$Res> {
  _$SegmentCopyWithImpl(this._self, this._then);

  final Segment _self;
  final $Res Function(Segment) _then;

/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startFrame = null,Object? endFrame = null,Object? elementDefinition = null,Object? data = null,Object? inwardLinks = null,Object? outwardLinks = null,Object? revision = null,}) {
  return _then(Segment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startFrame: null == startFrame ? _self.startFrame : startFrame // ignore: cast_nullable_to_non_nullable
as int,endFrame: null == endFrame ? _self.endFrame : endFrame // ignore: cast_nullable_to_non_nullable
as int,elementDefinition: null == elementDefinition ? _self.elementDefinition : elementDefinition // ignore: cast_nullable_to_non_nullable
as ElementDefinition,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RecordValue,inwardLinks: null == inwardLinks ? _self._inwardLinks : inwardLinks // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,outwardLinks: null == outwardLinks ? _self._outwardLinks : outwardLinks // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementDefinitionCopyWith<$Res> get elementDefinition {

  return $ElementDefinitionCopyWith<$Res>(_self.elementDefinition, (value) {
    return _then(_self.copyWith(elementDefinition: value));
  });
}
}

/// @nodoc


class Keyframe implements Cue {
  const Keyframe({required this.id, required this.frame, required this.elementDefinition, required this.data, required final  List<ElementLink> inwardLinks, this.revision = 1}): assert(id != "", 'ID must not be empty.'),assert(frame >= 0, 'Frame must not be negative.'),_inwardLinks = inwardLinks;


@override final  String id;
 final  int frame;
@override final  ElementDefinition elementDefinition;
@override final  RecordValue data;
 final  List<ElementLink> _inwardLinks;
@override List<ElementLink> get inwardLinks {
  if (_inwardLinks is EqualUnmodifiableListView) return _inwardLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inwardLinks);
}

@override@JsonKey() final  int revision;

/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyframeCopyWith<Keyframe> get copyWith => _$KeyframeCopyWithImpl<Keyframe>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Keyframe&&(identical(other.id, id) || other.id == id)&&(identical(other.frame, frame) || other.frame == frame)&&(identical(other.elementDefinition, elementDefinition) || other.elementDefinition == elementDefinition)&&(identical(other.data, data) || other.data == data)&&const DeepCollectionEquality().equals(other._inwardLinks, _inwardLinks)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode => Object.hash(runtimeType,id,frame,elementDefinition,data,const DeepCollectionEquality().hash(_inwardLinks),revision);

@override
String toString() {
  return 'Cue.keyframe(id: $id, frame: $frame, elementDefinition: $elementDefinition, data: $data, inwardLinks: $inwardLinks, revision: $revision)';
}


}

/// @nodoc
abstract mixin class $KeyframeCopyWith<$Res> implements $CueCopyWith<$Res> {
  factory $KeyframeCopyWith(Keyframe value, $Res Function(Keyframe) _then) = _$KeyframeCopyWithImpl;
@override @useResult
$Res call({
 String id, int frame, ElementDefinition elementDefinition, RecordValue data, List<ElementLink> inwardLinks, int revision
});


@override $ElementDefinitionCopyWith<$Res> get elementDefinition;

}
/// @nodoc
class _$KeyframeCopyWithImpl<$Res>
    implements $KeyframeCopyWith<$Res> {
  _$KeyframeCopyWithImpl(this._self, this._then);

  final Keyframe _self;
  final $Res Function(Keyframe) _then;

/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? frame = null,Object? elementDefinition = null,Object? data = null,Object? inwardLinks = null,Object? revision = null,}) {
  return _then(Keyframe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as int,elementDefinition: null == elementDefinition ? _self.elementDefinition : elementDefinition // ignore: cast_nullable_to_non_nullable
as ElementDefinition,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RecordValue,inwardLinks: null == inwardLinks ? _self._inwardLinks : inwardLinks // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Cue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementDefinitionCopyWith<$Res> get elementDefinition {

  return $ElementDefinitionCopyWith<$Res>(_self.elementDefinition, (value) {
    return _then(_self.copyWith(elementDefinition: value));
  });
}
}

// dart format on
