// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_path.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DataPath {

 List<DataPathSegment> get segments;
/// Create a copy of DataPath
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataPathCopyWith<DataPath> get copyWith => _$DataPathCopyWithImpl<DataPath>(this as DataPath, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataPath&&const DeepCollectionEquality().equals(other.segments, segments));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(segments));



}

/// @nodoc
abstract mixin class $DataPathCopyWith<$Res>  {
  factory $DataPathCopyWith(DataPath value, $Res Function(DataPath) _then) = _$DataPathCopyWithImpl;
@useResult
$Res call({
 List<DataPathSegment> segments
});




}
/// @nodoc
class _$DataPathCopyWithImpl<$Res>
    implements $DataPathCopyWith<$Res> {
  _$DataPathCopyWithImpl(this._self, this._then);

  final DataPath _self;
  final $Res Function(DataPath) _then;

/// Create a copy of DataPath
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segments = null,}) {
  return _then(_self.copyWith(
segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<DataPathSegment>,
  ));
}

}


/// Adds pattern-matching-related methods to [DataPath].
extension DataPathPatterns on DataPath {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DataPath value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DataPath() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DataPath value)  $default,){
final _that = this;
switch (_that) {
case _DataPath():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DataPath value)?  $default,){
final _that = this;
switch (_that) {
case _DataPath() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DataPathSegment> segments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DataPath() when $default != null:
return $default(_that.segments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DataPathSegment> segments)  $default,) {final _that = this;
switch (_that) {
case _DataPath():
return $default(_that.segments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DataPathSegment> segments)?  $default,) {final _that = this;
switch (_that) {
case _DataPath() when $default != null:
return $default(_that.segments);case _:
  return null;

}
}

}

/// @nodoc


class _DataPath extends DataPath {
  const _DataPath(final  List<DataPathSegment> segments): _segments = segments,super._();
  

 final  List<DataPathSegment> _segments;
@override List<DataPathSegment> get segments {
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segments);
}


/// Create a copy of DataPath
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataPathCopyWith<_DataPath> get copyWith => __$DataPathCopyWithImpl<_DataPath>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DataPath&&const DeepCollectionEquality().equals(other._segments, _segments));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_segments));



}

/// @nodoc
abstract mixin class _$DataPathCopyWith<$Res> implements $DataPathCopyWith<$Res> {
  factory _$DataPathCopyWith(_DataPath value, $Res Function(_DataPath) _then) = __$DataPathCopyWithImpl;
@override @useResult
$Res call({
 List<DataPathSegment> segments
});




}
/// @nodoc
class __$DataPathCopyWithImpl<$Res>
    implements _$DataPathCopyWith<$Res> {
  __$DataPathCopyWithImpl(this._self, this._then);

  final _DataPath _self;
  final $Res Function(_DataPath) _then;

/// Create a copy of DataPath
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segments = null,}) {
  return _then(_DataPath(
null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<DataPathSegment>,
  ));
}


}

/// @nodoc
mixin _$DataPathSegment {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataPathSegment);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $DataPathSegmentCopyWith<$Res>  {
$DataPathSegmentCopyWith(DataPathSegment _, $Res Function(DataPathSegment) __);
}


/// Adds pattern-matching-related methods to [DataPathSegment].
extension DataPathSegmentPatterns on DataPathSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FieldPathSegment value)?  field,TResult Function( IndexPathSegment value)?  index,TResult Function( MapKeyPathSegment value)?  mapKey,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FieldPathSegment() when field != null:
return field(_that);case IndexPathSegment() when index != null:
return index(_that);case MapKeyPathSegment() when mapKey != null:
return mapKey(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FieldPathSegment value)  field,required TResult Function( IndexPathSegment value)  index,required TResult Function( MapKeyPathSegment value)  mapKey,}){
final _that = this;
switch (_that) {
case FieldPathSegment():
return field(_that);case IndexPathSegment():
return index(_that);case MapKeyPathSegment():
return mapKey(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FieldPathSegment value)?  field,TResult? Function( IndexPathSegment value)?  index,TResult? Function( MapKeyPathSegment value)?  mapKey,}){
final _that = this;
switch (_that) {
case FieldPathSegment() when field != null:
return field(_that);case IndexPathSegment() when index != null:
return index(_that);case MapKeyPathSegment() when mapKey != null:
return mapKey(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name)?  field,TResult Function( int index)?  index,TResult Function( DataValue key)?  mapKey,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FieldPathSegment() when field != null:
return field(_that.name);case IndexPathSegment() when index != null:
return index(_that.index);case MapKeyPathSegment() when mapKey != null:
return mapKey(_that.key);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name)  field,required TResult Function( int index)  index,required TResult Function( DataValue key)  mapKey,}) {final _that = this;
switch (_that) {
case FieldPathSegment():
return field(_that.name);case IndexPathSegment():
return index(_that.index);case MapKeyPathSegment():
return mapKey(_that.key);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name)?  field,TResult? Function( int index)?  index,TResult? Function( DataValue key)?  mapKey,}) {final _that = this;
switch (_that) {
case FieldPathSegment() when field != null:
return field(_that.name);case IndexPathSegment() when index != null:
return index(_that.index);case MapKeyPathSegment() when mapKey != null:
return mapKey(_that.key);case _:
  return null;

}
}

}

/// @nodoc


class FieldPathSegment extends DataPathSegment {
  const FieldPathSegment(this.name): assert(name != "", 'Field name must not be empty.'),super._();
  

 final  String name;

/// Create a copy of DataPathSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldPathSegmentCopyWith<FieldPathSegment> get copyWith => _$FieldPathSegmentCopyWithImpl<FieldPathSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldPathSegment&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);



}

/// @nodoc
abstract mixin class $FieldPathSegmentCopyWith<$Res> implements $DataPathSegmentCopyWith<$Res> {
  factory $FieldPathSegmentCopyWith(FieldPathSegment value, $Res Function(FieldPathSegment) _then) = _$FieldPathSegmentCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$FieldPathSegmentCopyWithImpl<$Res>
    implements $FieldPathSegmentCopyWith<$Res> {
  _$FieldPathSegmentCopyWithImpl(this._self, this._then);

  final FieldPathSegment _self;
  final $Res Function(FieldPathSegment) _then;

/// Create a copy of DataPathSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(FieldPathSegment(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class IndexPathSegment extends DataPathSegment {
  const IndexPathSegment(this.index): assert(index >= 0, 'List index must not be negative.'),super._();
  

 final  int index;

/// Create a copy of DataPathSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexPathSegmentCopyWith<IndexPathSegment> get copyWith => _$IndexPathSegmentCopyWithImpl<IndexPathSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexPathSegment&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,index);



}

/// @nodoc
abstract mixin class $IndexPathSegmentCopyWith<$Res> implements $DataPathSegmentCopyWith<$Res> {
  factory $IndexPathSegmentCopyWith(IndexPathSegment value, $Res Function(IndexPathSegment) _then) = _$IndexPathSegmentCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class _$IndexPathSegmentCopyWithImpl<$Res>
    implements $IndexPathSegmentCopyWith<$Res> {
  _$IndexPathSegmentCopyWithImpl(this._self, this._then);

  final IndexPathSegment _self;
  final $Res Function(IndexPathSegment) _then;

/// Create a copy of DataPathSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(IndexPathSegment(
null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class MapKeyPathSegment extends DataPathSegment {
  const MapKeyPathSegment(this.key): super._();
  

 final  DataValue key;

/// Create a copy of DataPathSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapKeyPathSegmentCopyWith<MapKeyPathSegment> get copyWith => _$MapKeyPathSegmentCopyWithImpl<MapKeyPathSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapKeyPathSegment&&(identical(other.key, key) || other.key == key));
}


@override
int get hashCode => Object.hash(runtimeType,key);



}

/// @nodoc
abstract mixin class $MapKeyPathSegmentCopyWith<$Res> implements $DataPathSegmentCopyWith<$Res> {
  factory $MapKeyPathSegmentCopyWith(MapKeyPathSegment value, $Res Function(MapKeyPathSegment) _then) = _$MapKeyPathSegmentCopyWithImpl;
@useResult
$Res call({
 DataValue key
});


$DataValueCopyWith<$Res> get key;

}
/// @nodoc
class _$MapKeyPathSegmentCopyWithImpl<$Res>
    implements $MapKeyPathSegmentCopyWith<$Res> {
  _$MapKeyPathSegmentCopyWithImpl(this._self, this._then);

  final MapKeyPathSegment _self;
  final $Res Function(MapKeyPathSegment) _then;

/// Create a copy of DataPathSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? key = null,}) {
  return _then(MapKeyPathSegment(
null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as DataValue,
  ));
}

/// Create a copy of DataPathSegment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataValueCopyWith<$Res> get key {
  
  return $DataValueCopyWith<$Res>(_self.key, (value) {
    return _then(_self.copyWith(key: value));
  });
}
}

// dart format on
