// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_placement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Placement {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Placement);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Placement()';
}


}

/// @nodoc
class $PlacementCopyWith<$Res>  {
$PlacementCopyWith(Placement _, $Res Function(Placement) __);
}


/// Adds pattern matching related methods to [Placement].
extension PlacementPatterns on Placement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GraphPlacement value)?  graph,TResult Function( TimelineEntryPlacement value)?  timelineEntry,TResult Function( TimelineSegmentPlacement value)?  timelineSegment,TResult Function( TimelineKeyframePlacement value)?  timelineKeyframe,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GraphPlacement() when graph != null:
return graph(_that);case TimelineEntryPlacement() when timelineEntry != null:
return timelineEntry(_that);case TimelineSegmentPlacement() when timelineSegment != null:
return timelineSegment(_that);case TimelineKeyframePlacement() when timelineKeyframe != null:
return timelineKeyframe(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GraphPlacement value)  graph,required TResult Function( TimelineEntryPlacement value)  timelineEntry,required TResult Function( TimelineSegmentPlacement value)  timelineSegment,required TResult Function( TimelineKeyframePlacement value)  timelineKeyframe,}){
final _that = this;
switch (_that) {
case GraphPlacement():
return graph(_that);case TimelineEntryPlacement():
return timelineEntry(_that);case TimelineSegmentPlacement():
return timelineSegment(_that);case TimelineKeyframePlacement():
return timelineKeyframe(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GraphPlacement value)?  graph,TResult? Function( TimelineEntryPlacement value)?  timelineEntry,TResult? Function( TimelineSegmentPlacement value)?  timelineSegment,TResult? Function( TimelineKeyframePlacement value)?  timelineKeyframe,}){
final _that = this;
switch (_that) {
case GraphPlacement() when graph != null:
return graph(_that);case TimelineEntryPlacement() when timelineEntry != null:
return timelineEntry(_that);case TimelineSegmentPlacement() when timelineSegment != null:
return timelineSegment(_that);case TimelineKeyframePlacement() when timelineKeyframe != null:
return timelineKeyframe(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int x,  int y,  int width,  int height)?  graph,TResult Function( int trackIndex)?  timelineEntry,TResult Function( int startFrame,  int endFrame)?  timelineSegment,TResult Function( int frame)?  timelineKeyframe,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GraphPlacement() when graph != null:
return graph(_that.x,_that.y,_that.width,_that.height);case TimelineEntryPlacement() when timelineEntry != null:
return timelineEntry(_that.trackIndex);case TimelineSegmentPlacement() when timelineSegment != null:
return timelineSegment(_that.startFrame,_that.endFrame);case TimelineKeyframePlacement() when timelineKeyframe != null:
return timelineKeyframe(_that.frame);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int x,  int y,  int width,  int height)  graph,required TResult Function( int trackIndex)  timelineEntry,required TResult Function( int startFrame,  int endFrame)  timelineSegment,required TResult Function( int frame)  timelineKeyframe,}) {final _that = this;
switch (_that) {
case GraphPlacement():
return graph(_that.x,_that.y,_that.width,_that.height);case TimelineEntryPlacement():
return timelineEntry(_that.trackIndex);case TimelineSegmentPlacement():
return timelineSegment(_that.startFrame,_that.endFrame);case TimelineKeyframePlacement():
return timelineKeyframe(_that.frame);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int x,  int y,  int width,  int height)?  graph,TResult? Function( int trackIndex)?  timelineEntry,TResult? Function( int startFrame,  int endFrame)?  timelineSegment,TResult? Function( int frame)?  timelineKeyframe,}) {final _that = this;
switch (_that) {
case GraphPlacement() when graph != null:
return graph(_that.x,_that.y,_that.width,_that.height);case TimelineEntryPlacement() when timelineEntry != null:
return timelineEntry(_that.trackIndex);case TimelineSegmentPlacement() when timelineSegment != null:
return timelineSegment(_that.startFrame,_that.endFrame);case TimelineKeyframePlacement() when timelineKeyframe != null:
return timelineKeyframe(_that.frame);case _:
  return null;

}
}

}

/// @nodoc


class GraphPlacement extends Placement {
  const GraphPlacement({required this.x, required this.y, required this.width, required this.height}): super._();


 final  int x;
 final  int y;
 final  int width;
 final  int height;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GraphPlacementCopyWith<GraphPlacement> get copyWith => _$GraphPlacementCopyWithImpl<GraphPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GraphPlacement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode {
    return Object.hash(runtimeType,x,y,width,height);
}

@override
String toString() {
    return 'Placement.graph(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $GraphPlacementCopyWith<$Res> implements $PlacementCopyWith<$Res> {
  factory $GraphPlacementCopyWith(GraphPlacement value, $Res Function(GraphPlacement) _then) = _$GraphPlacementCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$GraphPlacementCopyWithImpl<$Res>
    implements $GraphPlacementCopyWith<$Res> {
  _$GraphPlacementCopyWithImpl(this._self, this._then);

  final GraphPlacement _self;
  final $Res Function(GraphPlacement) _then;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(GraphPlacement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class TimelineEntryPlacement extends Placement {
  const TimelineEntryPlacement({required this.trackIndex}): super._();


 final  int trackIndex;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineEntryPlacementCopyWith<TimelineEntryPlacement> get copyWith => _$TimelineEntryPlacementCopyWithImpl<TimelineEntryPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineEntryPlacement&&(identical(other.trackIndex, trackIndex) || other.trackIndex == trackIndex));
}


@override
int get hashCode {
    return Object.hash(runtimeType,trackIndex);
}

@override
String toString() {
    return 'Placement.timelineEntry(trackIndex: $trackIndex)';
}


}

/// @nodoc
abstract mixin class $TimelineEntryPlacementCopyWith<$Res> implements $PlacementCopyWith<$Res> {
  factory $TimelineEntryPlacementCopyWith(TimelineEntryPlacement value, $Res Function(TimelineEntryPlacement) _then) = _$TimelineEntryPlacementCopyWithImpl;
@useResult
$Res call({
 int trackIndex
});




}
/// @nodoc
class _$TimelineEntryPlacementCopyWithImpl<$Res>
    implements $TimelineEntryPlacementCopyWith<$Res> {
  _$TimelineEntryPlacementCopyWithImpl(this._self, this._then);

  final TimelineEntryPlacement _self;
  final $Res Function(TimelineEntryPlacement) _then;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trackIndex = null,}) {
  return _then(TimelineEntryPlacement(
trackIndex: null == trackIndex ? _self.trackIndex : trackIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class TimelineSegmentPlacement extends Placement {
  const TimelineSegmentPlacement({required this.startFrame, required this.endFrame}): super._();


 final  int startFrame;
 final  int endFrame;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineSegmentPlacementCopyWith<TimelineSegmentPlacement> get copyWith => _$TimelineSegmentPlacementCopyWithImpl<TimelineSegmentPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineSegmentPlacement&&(identical(other.startFrame, startFrame) || other.startFrame == startFrame)&&(identical(other.endFrame, endFrame) || other.endFrame == endFrame));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startFrame,endFrame);
}

@override
String toString() {
    return 'Placement.timelineSegment(startFrame: $startFrame, endFrame: $endFrame)';
}


}

/// @nodoc
abstract mixin class $TimelineSegmentPlacementCopyWith<$Res> implements $PlacementCopyWith<$Res> {
  factory $TimelineSegmentPlacementCopyWith(TimelineSegmentPlacement value, $Res Function(TimelineSegmentPlacement) _then) = _$TimelineSegmentPlacementCopyWithImpl;
@useResult
$Res call({
 int startFrame, int endFrame
});




}
/// @nodoc
class _$TimelineSegmentPlacementCopyWithImpl<$Res>
    implements $TimelineSegmentPlacementCopyWith<$Res> {
  _$TimelineSegmentPlacementCopyWithImpl(this._self, this._then);

  final TimelineSegmentPlacement _self;
  final $Res Function(TimelineSegmentPlacement) _then;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startFrame = null,Object? endFrame = null,}) {
  return _then(TimelineSegmentPlacement(
startFrame: null == startFrame ? _self.startFrame : startFrame // ignore: cast_nullable_to_non_nullable
as int,endFrame: null == endFrame ? _self.endFrame : endFrame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class TimelineKeyframePlacement extends Placement {
  const TimelineKeyframePlacement({required this.frame}): super._();


 final  int frame;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineKeyframePlacementCopyWith<TimelineKeyframePlacement> get copyWith => _$TimelineKeyframePlacementCopyWithImpl<TimelineKeyframePlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineKeyframePlacement&&(identical(other.frame, frame) || other.frame == frame));
}


@override
int get hashCode {
    return Object.hash(runtimeType,frame);
}

@override
String toString() {
    return 'Placement.timelineKeyframe(frame: $frame)';
}


}

/// @nodoc
abstract mixin class $TimelineKeyframePlacementCopyWith<$Res> implements $PlacementCopyWith<$Res> {
  factory $TimelineKeyframePlacementCopyWith(TimelineKeyframePlacement value, $Res Function(TimelineKeyframePlacement) _then) = _$TimelineKeyframePlacementCopyWithImpl;
@useResult
$Res call({
 int frame
});




}
/// @nodoc
class _$TimelineKeyframePlacementCopyWithImpl<$Res>
    implements $TimelineKeyframePlacementCopyWith<$Res> {
  _$TimelineKeyframePlacementCopyWithImpl(this._self, this._then);

  final TimelineKeyframePlacement _self;
  final $Res Function(TimelineKeyframePlacement) _then;

/// Create a copy of Placement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? frame = null,}) {
  return _then(TimelineKeyframePlacement(
frame: null == frame ? _self.frame : frame // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
