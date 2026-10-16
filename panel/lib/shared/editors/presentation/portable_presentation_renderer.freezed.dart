// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_presentation_renderer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CollectionGraphOccurrence {

 String get canonicalKey; List<String> get path; List<_CollectionGraphOccurrence> get children;
/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionGraphOccurrenceCopyWith<_CollectionGraphOccurrence> get copyWith => __$CollectionGraphOccurrenceCopyWithImpl<_CollectionGraphOccurrence>(this as _CollectionGraphOccurrence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionGraphOccurrence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionGraphOccurrence&&(identical(other.canonicalKey, _this.canonicalKey) || other.canonicalKey == _this.canonicalKey)&&const DeepCollectionEquality().equals(other.path, _this.path)&&const DeepCollectionEquality().equals(other.children, _this.children));
}


@override
int get hashCode {
  final _this = this as _CollectionGraphOccurrence;
  return Object.hash(runtimeType,_this.canonicalKey,const DeepCollectionEquality().hash(_this.path),const DeepCollectionEquality().hash(_this.children));
}

@override
String toString() {
  final _this = this as _CollectionGraphOccurrence;
  return '_CollectionGraphOccurrence(canonicalKey: ${_this.canonicalKey}, path: ${_this.path}, children: ${_this.children})';
}


}

/// @nodoc
abstract mixin class _$CollectionGraphOccurrenceCopyWith<$Res>  {
  factory _$CollectionGraphOccurrenceCopyWith(_CollectionGraphOccurrence value, $Res Function(_CollectionGraphOccurrence) _then) = __$CollectionGraphOccurrenceCopyWithImpl;
@useResult
$Res call({
 String canonicalKey, List<String> path, List<_CollectionGraphOccurrence> children
});




}
/// @nodoc
class __$CollectionGraphOccurrenceCopyWithImpl<$Res>
    implements _$CollectionGraphOccurrenceCopyWith<$Res> {
  __$CollectionGraphOccurrenceCopyWithImpl(this._self, this._then);

  final _CollectionGraphOccurrence _self;
  final $Res Function(_CollectionGraphOccurrence) _then;

/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canonicalKey = null,Object? path = null,Object? children = null,}) {
  return _then(_CollectionGraphOccurrence(
canonicalKey: null == canonicalKey ? _self.canonicalKey : canonicalKey // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<String>,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,
  ));
}

}


/// Adds pattern matching related methods to [_CollectionGraphOccurrence].
extension _CollectionGraphOccurrencePatterns on _CollectionGraphOccurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionGraphOccurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionGraphOccurrence value)  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionGraphOccurrence value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String canonicalKey,  List<String> path,  List<_CollectionGraphOccurrence> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
return $default(_that.canonicalKey,_that.path,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String canonicalKey,  List<String> path,  List<_CollectionGraphOccurrence> children)  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrence():
return $default(_that.canonicalKey,_that.path,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String canonicalKey,  List<String> path,  List<_CollectionGraphOccurrence> children)?  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrence() when $default != null:
return $default(_that.canonicalKey,_that.path,_that.children);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionGraphOccurrence implements _CollectionGraphOccurrence {
  const __CollectionGraphOccurrence({required this.canonicalKey, required  List<String> path, required  List<_CollectionGraphOccurrence> children}): _path = path,_children = children;


@override final  String canonicalKey;
 final  List<String> _path;
@override List<String> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}

 final  List<_CollectionGraphOccurrence> _children;
@override List<_CollectionGraphOccurrence> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionGraphOccurrenceCopyWith<__CollectionGraphOccurrence> get copyWith => __$_CollectionGraphOccurrenceCopyWithImpl<__CollectionGraphOccurrence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionGraphOccurrence&&(identical(other.canonicalKey, canonicalKey) || other.canonicalKey == canonicalKey)&&const DeepCollectionEquality().equals(other.path, _path)&&const DeepCollectionEquality().equals(other.children, _children));
}


@override
int get hashCode {
    return Object.hash(runtimeType,canonicalKey,const DeepCollectionEquality().hash(_path),const DeepCollectionEquality().hash(_children));
}

@override
String toString() {
    return '_CollectionGraphOccurrence(canonicalKey: $canonicalKey, path: $path, children: $children)';
}


}

/// @nodoc
abstract mixin class _$_CollectionGraphOccurrenceCopyWith<$Res> implements _$CollectionGraphOccurrenceCopyWith<$Res> {
  factory _$_CollectionGraphOccurrenceCopyWith(__CollectionGraphOccurrence value, $Res Function(__CollectionGraphOccurrence) _then) = __$_CollectionGraphOccurrenceCopyWithImpl;
@override @useResult
$Res call({
 String canonicalKey, List<String> path, List<_CollectionGraphOccurrence> children
});




}
/// @nodoc
class __$_CollectionGraphOccurrenceCopyWithImpl<$Res>
    implements _$_CollectionGraphOccurrenceCopyWith<$Res> {
  __$_CollectionGraphOccurrenceCopyWithImpl(this._self, this._then);

  final __CollectionGraphOccurrence _self;
  final $Res Function(__CollectionGraphOccurrence) _then;

/// Create a copy of _CollectionGraphOccurrence
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canonicalKey = null,Object? path = null,Object? children = null,}) {
  return _then(__CollectionGraphOccurrence(
canonicalKey: null == canonicalKey ? _self.canonicalKey : canonicalKey // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<String>,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,
  ));
}


}

/// @nodoc
mixin _$CollectionGraphProjection {

 List<_CollectionGraphOccurrence> get roots; bool get truncated;
/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionGraphProjectionCopyWith<_CollectionGraphProjection> get copyWith => __$CollectionGraphProjectionCopyWithImpl<_CollectionGraphProjection>(this as _CollectionGraphProjection, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionGraphProjection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionGraphProjection&&const DeepCollectionEquality().equals(other.roots, _this.roots)&&(identical(other.truncated, _this.truncated) || other.truncated == _this.truncated));
}


@override
int get hashCode {
  final _this = this as _CollectionGraphProjection;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.roots),_this.truncated);
}

@override
String toString() {
  final _this = this as _CollectionGraphProjection;
  return '_CollectionGraphProjection(roots: ${_this.roots}, truncated: ${_this.truncated})';
}


}

/// @nodoc
abstract mixin class _$CollectionGraphProjectionCopyWith<$Res>  {
  factory _$CollectionGraphProjectionCopyWith(_CollectionGraphProjection value, $Res Function(_CollectionGraphProjection) _then) = __$CollectionGraphProjectionCopyWithImpl;
@useResult
$Res call({
 List<_CollectionGraphOccurrence> roots, bool truncated
});




}
/// @nodoc
class __$CollectionGraphProjectionCopyWithImpl<$Res>
    implements _$CollectionGraphProjectionCopyWith<$Res> {
  __$CollectionGraphProjectionCopyWithImpl(this._self, this._then);

  final _CollectionGraphProjection _self;
  final $Res Function(_CollectionGraphProjection) _then;

/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roots = null,Object? truncated = null,}) {
  return _then(_CollectionGraphProjection(
roots: null == roots ? _self.roots : roots // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern matching related methods to [_CollectionGraphProjection].
extension _CollectionGraphProjectionPatterns on _CollectionGraphProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionGraphProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionGraphProjection value)  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionGraphProjection value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<_CollectionGraphOccurrence> roots,  bool truncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
return $default(_that.roots,_that.truncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<_CollectionGraphOccurrence> roots,  bool truncated)  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphProjection():
return $default(_that.roots,_that.truncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<_CollectionGraphOccurrence> roots,  bool truncated)?  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphProjection() when $default != null:
return $default(_that.roots,_that.truncated);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionGraphProjection implements _CollectionGraphProjection {
  const __CollectionGraphProjection({required  List<_CollectionGraphOccurrence> roots, required this.truncated}): _roots = roots;


 final  List<_CollectionGraphOccurrence> _roots;
@override List<_CollectionGraphOccurrence> get roots {
  if (_roots is EqualUnmodifiableListView) return _roots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roots);
}

@override final  bool truncated;

/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionGraphProjectionCopyWith<__CollectionGraphProjection> get copyWith => __$_CollectionGraphProjectionCopyWithImpl<__CollectionGraphProjection>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionGraphProjection&&const DeepCollectionEquality().equals(other.roots, _roots)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_roots),truncated);
}

@override
String toString() {
    return '_CollectionGraphProjection(roots: $roots, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class _$_CollectionGraphProjectionCopyWith<$Res> implements _$CollectionGraphProjectionCopyWith<$Res> {
  factory _$_CollectionGraphProjectionCopyWith(__CollectionGraphProjection value, $Res Function(__CollectionGraphProjection) _then) = __$_CollectionGraphProjectionCopyWithImpl;
@override @useResult
$Res call({
 List<_CollectionGraphOccurrence> roots, bool truncated
});




}
/// @nodoc
class __$_CollectionGraphProjectionCopyWithImpl<$Res>
    implements _$_CollectionGraphProjectionCopyWith<$Res> {
  __$_CollectionGraphProjectionCopyWithImpl(this._self, this._then);

  final __CollectionGraphProjection _self;
  final $Res Function(__CollectionGraphProjection) _then;

/// Create a copy of _CollectionGraphProjection
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roots = null,Object? truncated = null,}) {
  return _then(__CollectionGraphProjection(
roots: null == roots ? _self._roots : roots // ignore: cast_nullable_to_non_nullable
as List<_CollectionGraphOccurrence>,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CollectionGraphOccurrenceKey {

 Object get graph; Map<skir.ExpressionBindingId, Object> get invocation; List<String> get path;
/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionGraphOccurrenceKeyCopyWith<_CollectionGraphOccurrenceKey> get copyWith => __$CollectionGraphOccurrenceKeyCopyWithImpl<_CollectionGraphOccurrenceKey>(this as _CollectionGraphOccurrenceKey, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _CollectionGraphOccurrenceKey;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionGraphOccurrenceKey&&const DeepCollectionEquality().equals(other.graph, _this.graph)&&const DeepCollectionEquality().equals(other.invocation, _this.invocation)&&const DeepCollectionEquality().equals(other.path, _this.path));
}


@override
int get hashCode {
  final _this = this as _CollectionGraphOccurrenceKey;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.graph),const DeepCollectionEquality().hash(_this.invocation),const DeepCollectionEquality().hash(_this.path));
}

@override
String toString() {
  final _this = this as _CollectionGraphOccurrenceKey;
  return '_CollectionGraphOccurrenceKey(graph: ${_this.graph}, invocation: ${_this.invocation}, path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class _$CollectionGraphOccurrenceKeyCopyWith<$Res>  {
  factory _$CollectionGraphOccurrenceKeyCopyWith(_CollectionGraphOccurrenceKey value, $Res Function(_CollectionGraphOccurrenceKey) _then) = __$CollectionGraphOccurrenceKeyCopyWithImpl;
@useResult
$Res call({
 Object graph, Map<skir.ExpressionBindingId, Object> invocation, List<String> path
});




}
/// @nodoc
class __$CollectionGraphOccurrenceKeyCopyWithImpl<$Res>
    implements _$CollectionGraphOccurrenceKeyCopyWith<$Res> {
  __$CollectionGraphOccurrenceKeyCopyWithImpl(this._self, this._then);

  final _CollectionGraphOccurrenceKey _self;
  final $Res Function(_CollectionGraphOccurrenceKey) _then;

/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? graph = null,Object? invocation = null,Object? path = null,}) {
  return _then(_CollectionGraphOccurrenceKey(
graph: null == graph ? _self.graph : graph ,invocation: null == invocation ? _self.invocation : invocation // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, Object>,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern matching related methods to [_CollectionGraphOccurrenceKey].
extension _CollectionGraphOccurrenceKeyPatterns on _CollectionGraphOccurrenceKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __CollectionGraphOccurrenceKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __CollectionGraphOccurrenceKey value)  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __CollectionGraphOccurrenceKey value)?  $default,){
final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object graph,  Map<skir.ExpressionBindingId, Object> invocation,  List<String> path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
return $default(_that.graph,_that.invocation,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object graph,  Map<skir.ExpressionBindingId, Object> invocation,  List<String> path)  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey():
return $default(_that.graph,_that.invocation,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object graph,  Map<skir.ExpressionBindingId, Object> invocation,  List<String> path)?  $default,) {final _that = this;
switch (_that) {
case __CollectionGraphOccurrenceKey() when $default != null:
return $default(_that.graph,_that.invocation,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class __CollectionGraphOccurrenceKey implements _CollectionGraphOccurrenceKey {
  const __CollectionGraphOccurrenceKey({required this.graph, required  Map<skir.ExpressionBindingId, Object> invocation, required  List<String> path}): _invocation = invocation,_path = path;


@override final  Object graph;
 final  Map<skir.ExpressionBindingId, Object> _invocation;
@override Map<skir.ExpressionBindingId, Object> get invocation {
  if (_invocation is EqualUnmodifiableMapView) return _invocation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_invocation);
}

 final  List<String> _path;
@override List<String> get path {
  if (_path is EqualUnmodifiableListView) return _path;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_path);
}


/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_CollectionGraphOccurrenceKeyCopyWith<__CollectionGraphOccurrenceKey> get copyWith => __$_CollectionGraphOccurrenceKeyCopyWithImpl<__CollectionGraphOccurrenceKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __CollectionGraphOccurrenceKey&&const DeepCollectionEquality().equals(other.graph, graph)&&const DeepCollectionEquality().equals(other.invocation, _invocation)&&const DeepCollectionEquality().equals(other.path, _path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(graph),const DeepCollectionEquality().hash(_invocation),const DeepCollectionEquality().hash(_path));
}

@override
String toString() {
    return '_CollectionGraphOccurrenceKey(graph: $graph, invocation: $invocation, path: $path)';
}


}

/// @nodoc
abstract mixin class _$_CollectionGraphOccurrenceKeyCopyWith<$Res> implements _$CollectionGraphOccurrenceKeyCopyWith<$Res> {
  factory _$_CollectionGraphOccurrenceKeyCopyWith(__CollectionGraphOccurrenceKey value, $Res Function(__CollectionGraphOccurrenceKey) _then) = __$_CollectionGraphOccurrenceKeyCopyWithImpl;
@override @useResult
$Res call({
 Object graph, Map<skir.ExpressionBindingId, Object> invocation, List<String> path
});




}
/// @nodoc
class __$_CollectionGraphOccurrenceKeyCopyWithImpl<$Res>
    implements _$_CollectionGraphOccurrenceKeyCopyWith<$Res> {
  __$_CollectionGraphOccurrenceKeyCopyWithImpl(this._self, this._then);

  final __CollectionGraphOccurrenceKey _self;
  final $Res Function(__CollectionGraphOccurrenceKey) _then;

/// Create a copy of _CollectionGraphOccurrenceKey
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? graph = null,Object? invocation = null,Object? path = null,}) {
  return _then(__CollectionGraphOccurrenceKey(
graph: null == graph ? _self.graph : graph ,invocation: null == invocation ? _self._invocation : invocation // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, Object>,path: null == path ? _self._path : path // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$PortableAppearanceLayer {

 skir.InputAppearance get appearance; Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget;
/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableAppearanceLayerCopyWith<PortableAppearanceLayer> get copyWith => _$PortableAppearanceLayerCopyWithImpl<PortableAppearanceLayer>(this as PortableAppearanceLayer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableAppearanceLayer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableAppearanceLayer&&(identical(other.appearance, _this.appearance) || other.appearance == _this.appearance)&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget));
}


@override
int get hashCode {
  final _this = this as PortableAppearanceLayer;
  return Object.hash(runtimeType,_this.appearance,const DeepCollectionEquality().hash(_this.bindings),_this.budget);
}

@override
String toString() {
  final _this = this as PortableAppearanceLayer;
  return 'PortableAppearanceLayer(appearance: ${_this.appearance}, bindings: ${_this.bindings}, budget: ${_this.budget})';
}


}

/// @nodoc
abstract mixin class $PortableAppearanceLayerCopyWith<$Res>  {
  factory $PortableAppearanceLayerCopyWith(PortableAppearanceLayer value, $Res Function(PortableAppearanceLayer) _then) = _$PortableAppearanceLayerCopyWithImpl;
@useResult
$Res call({
 skir.InputAppearance appearance, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget
});




}
/// @nodoc
class _$PortableAppearanceLayerCopyWithImpl<$Res>
    implements $PortableAppearanceLayerCopyWith<$Res> {
  _$PortableAppearanceLayerCopyWithImpl(this._self, this._then);

  final PortableAppearanceLayer _self;
  final $Res Function(PortableAppearanceLayer) _then;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appearance = null,Object? bindings = null,Object? budget = null,}) {
  return _then(PortableAppearanceLayer(
appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.InputAppearance,bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,
  ));
}

}


/// Adds pattern matching related methods to [PortableAppearanceLayer].
extension PortableAppearanceLayerPatterns on PortableAppearanceLayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableAppearanceLayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableAppearanceLayer value)  $default,){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableAppearanceLayer value)?  $default,){
final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
return $default(_that.appearance,_that.bindings,_that.budget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)  $default,) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer():
return $default(_that.appearance,_that.bindings,_that.budget);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.InputAppearance appearance,  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,  skir.EvaluationBudget budget)?  $default,) {final _that = this;
switch (_that) {
case _PortableAppearanceLayer() when $default != null:
return $default(_that.appearance,_that.bindings,_that.budget);case _:
  return null;

}
}

}

/// @nodoc


class _PortableAppearanceLayer implements PortableAppearanceLayer {
  const _PortableAppearanceLayer({required this.appearance, required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget}): _bindings = bindings;


@override final  skir.InputAppearance appearance;
 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAppearanceLayerCopyWith<_PortableAppearanceLayer> get copyWith => __$PortableAppearanceLayerCopyWithImpl<_PortableAppearanceLayer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAppearanceLayer&&(identical(other.appearance, appearance) || other.appearance == appearance)&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget));
}


@override
int get hashCode {
    return Object.hash(runtimeType,appearance,const DeepCollectionEquality().hash(_bindings),budget);
}

@override
String toString() {
    return 'PortableAppearanceLayer(appearance: $appearance, bindings: $bindings, budget: $budget)';
}


}

/// @nodoc
abstract mixin class _$PortableAppearanceLayerCopyWith<$Res> implements $PortableAppearanceLayerCopyWith<$Res> {
  factory _$PortableAppearanceLayerCopyWith(_PortableAppearanceLayer value, $Res Function(_PortableAppearanceLayer) _then) = __$PortableAppearanceLayerCopyWithImpl;
@override @useResult
$Res call({
 skir.InputAppearance appearance, Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget
});




}
/// @nodoc
class __$PortableAppearanceLayerCopyWithImpl<$Res>
    implements _$PortableAppearanceLayerCopyWith<$Res> {
  __$PortableAppearanceLayerCopyWithImpl(this._self, this._then);

  final _PortableAppearanceLayer _self;
  final $Res Function(_PortableAppearanceLayer) _then;

/// Create a copy of PortableAppearanceLayer
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appearance = null,Object? bindings = null,Object? budget = null,}) {
  return _then(_PortableAppearanceLayer(
appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as skir.InputAppearance,bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,
  ));
}


}

/// @nodoc
mixin _$PortableControlStyle {

 InputDecoration get decoration; TextStyle get valueStyle; TextStyle get labelStyle; TextStyle get descriptionStyle; TextAlign get alignment; double get iconSize; Color? get iconColor; EdgeInsetsGeometry? get padding; bool? get dense;
/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableControlStyleCopyWith<_PortableControlStyle> get copyWith => __$PortableControlStyleCopyWithImpl<_PortableControlStyle>(this as _PortableControlStyle, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _PortableControlStyle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableControlStyle&&(identical(other.decoration, _this.decoration) || other.decoration == _this.decoration)&&(identical(other.valueStyle, _this.valueStyle) || other.valueStyle == _this.valueStyle)&&(identical(other.labelStyle, _this.labelStyle) || other.labelStyle == _this.labelStyle)&&(identical(other.descriptionStyle, _this.descriptionStyle) || other.descriptionStyle == _this.descriptionStyle)&&(identical(other.alignment, _this.alignment) || other.alignment == _this.alignment)&&(identical(other.iconSize, _this.iconSize) || other.iconSize == _this.iconSize)&&(identical(other.iconColor, _this.iconColor) || other.iconColor == _this.iconColor)&&(identical(other.padding, _this.padding) || other.padding == _this.padding)&&(identical(other.dense, _this.dense) || other.dense == _this.dense));
}


@override
int get hashCode {
  final _this = this as _PortableControlStyle;
  return Object.hash(runtimeType,_this.decoration,_this.valueStyle,_this.labelStyle,_this.descriptionStyle,_this.alignment,_this.iconSize,_this.iconColor,_this.padding,_this.dense);
}

@override
String toString() {
  final _this = this as _PortableControlStyle;
  return '_PortableControlStyle(decoration: ${_this.decoration}, valueStyle: ${_this.valueStyle}, labelStyle: ${_this.labelStyle}, descriptionStyle: ${_this.descriptionStyle}, alignment: ${_this.alignment}, iconSize: ${_this.iconSize}, iconColor: ${_this.iconColor}, padding: ${_this.padding}, dense: ${_this.dense})';
}


}

/// @nodoc
abstract mixin class _$PortableControlStyleCopyWith<$Res>  {
  factory _$PortableControlStyleCopyWith(_PortableControlStyle value, $Res Function(_PortableControlStyle) _then) = __$PortableControlStyleCopyWithImpl;
@useResult
$Res call({
 InputDecoration decoration, TextStyle valueStyle, TextStyle labelStyle, TextStyle descriptionStyle, TextAlign alignment, double iconSize, Color? iconColor, EdgeInsetsGeometry? padding, bool? dense
});




}
/// @nodoc
class __$PortableControlStyleCopyWithImpl<$Res>
    implements _$PortableControlStyleCopyWith<$Res> {
  __$PortableControlStyleCopyWithImpl(this._self, this._then);

  final _PortableControlStyle _self;
  final $Res Function(_PortableControlStyle) _then;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decoration = null,Object? valueStyle = null,Object? labelStyle = null,Object? descriptionStyle = null,Object? alignment = null,Object? iconSize = null,Object? iconColor = freezed,Object? padding = freezed,Object? dense = freezed,}) {
  return _then(_PortableControlStyle(
decoration: null == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as InputDecoration,valueStyle: null == valueStyle ? _self.valueStyle : valueStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,labelStyle: null == labelStyle ? _self.labelStyle : labelStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,descriptionStyle: null == descriptionStyle ? _self.descriptionStyle : descriptionStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlign,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as Color?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as EdgeInsetsGeometry?,dense: freezed == dense ? _self.dense : dense // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern matching related methods to [_PortableControlStyle].
extension _PortableControlStylePatterns on _PortableControlStyle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedPortableControlStyle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedPortableControlStyle value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedPortableControlStyle value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)  $default,) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle():
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InputDecoration decoration,  TextStyle valueStyle,  TextStyle labelStyle,  TextStyle descriptionStyle,  TextAlign alignment,  double iconSize,  Color? iconColor,  EdgeInsetsGeometry? padding,  bool? dense)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedPortableControlStyle() when $default != null:
return $default(_that.decoration,_that.valueStyle,_that.labelStyle,_that.descriptionStyle,_that.alignment,_that.iconSize,_that.iconColor,_that.padding,_that.dense);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedPortableControlStyle implements _PortableControlStyle {
  const _ResolvedPortableControlStyle({required this.decoration, required this.valueStyle, required this.labelStyle, required this.descriptionStyle, required this.alignment, required this.iconSize, this.iconColor, this.padding, this.dense});


@override final  InputDecoration decoration;
@override final  TextStyle valueStyle;
@override final  TextStyle labelStyle;
@override final  TextStyle descriptionStyle;
@override final  TextAlign alignment;
@override final  double iconSize;
@override final  Color? iconColor;
@override final  EdgeInsetsGeometry? padding;
@override final  bool? dense;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedPortableControlStyleCopyWith<_ResolvedPortableControlStyle> get copyWith => __$ResolvedPortableControlStyleCopyWithImpl<_ResolvedPortableControlStyle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedPortableControlStyle&&(identical(other.decoration, decoration) || other.decoration == decoration)&&(identical(other.valueStyle, valueStyle) || other.valueStyle == valueStyle)&&(identical(other.labelStyle, labelStyle) || other.labelStyle == labelStyle)&&(identical(other.descriptionStyle, descriptionStyle) || other.descriptionStyle == descriptionStyle)&&(identical(other.alignment, alignment) || other.alignment == alignment)&&(identical(other.iconSize, iconSize) || other.iconSize == iconSize)&&(identical(other.iconColor, iconColor) || other.iconColor == iconColor)&&(identical(other.padding, padding) || other.padding == padding)&&(identical(other.dense, dense) || other.dense == dense));
}


@override
int get hashCode {
    return Object.hash(runtimeType,decoration,valueStyle,labelStyle,descriptionStyle,alignment,iconSize,iconColor,padding,dense);
}

@override
String toString() {
    return '_PortableControlStyle(decoration: $decoration, valueStyle: $valueStyle, labelStyle: $labelStyle, descriptionStyle: $descriptionStyle, alignment: $alignment, iconSize: $iconSize, iconColor: $iconColor, padding: $padding, dense: $dense)';
}


}

/// @nodoc
abstract mixin class _$ResolvedPortableControlStyleCopyWith<$Res> implements _$PortableControlStyleCopyWith<$Res> {
  factory _$ResolvedPortableControlStyleCopyWith(_ResolvedPortableControlStyle value, $Res Function(_ResolvedPortableControlStyle) _then) = __$ResolvedPortableControlStyleCopyWithImpl;
@override @useResult
$Res call({
 InputDecoration decoration, TextStyle valueStyle, TextStyle labelStyle, TextStyle descriptionStyle, TextAlign alignment, double iconSize, Color? iconColor, EdgeInsetsGeometry? padding, bool? dense
});




}
/// @nodoc
class __$ResolvedPortableControlStyleCopyWithImpl<$Res>
    implements _$ResolvedPortableControlStyleCopyWith<$Res> {
  __$ResolvedPortableControlStyleCopyWithImpl(this._self, this._then);

  final _ResolvedPortableControlStyle _self;
  final $Res Function(_ResolvedPortableControlStyle) _then;

/// Create a copy of _PortableControlStyle
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decoration = null,Object? valueStyle = null,Object? labelStyle = null,Object? descriptionStyle = null,Object? alignment = null,Object? iconSize = null,Object? iconColor = freezed,Object? padding = freezed,Object? dense = freezed,}) {
  return _then(_ResolvedPortableControlStyle(
decoration: null == decoration ? _self.decoration : decoration // ignore: cast_nullable_to_non_nullable
as InputDecoration,valueStyle: null == valueStyle ? _self.valueStyle : valueStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,labelStyle: null == labelStyle ? _self.labelStyle : labelStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,descriptionStyle: null == descriptionStyle ? _self.descriptionStyle : descriptionStyle // ignore: cast_nullable_to_non_nullable
as TextStyle,alignment: null == alignment ? _self.alignment : alignment // ignore: cast_nullable_to_non_nullable
as TextAlign,iconSize: null == iconSize ? _self.iconSize : iconSize // ignore: cast_nullable_to_non_nullable
as double,iconColor: freezed == iconColor ? _self.iconColor : iconColor // ignore: cast_nullable_to_non_nullable
as Color?,padding: freezed == padding ? _self.padding : padding // ignore: cast_nullable_to_non_nullable
as EdgeInsetsGeometry?,dense: freezed == dense ? _self.dense : dense // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$PortableOperationKey {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableOperationKey()';
}


}

/// @nodoc
class $PortableOperationKeyCopyWith<$Res>  {
$PortableOperationKeyCopyWith(PortableOperationKey _, $Res Function(PortableOperationKey) __);
}


/// Adds pattern matching related methods to [PortableOperationKey].
extension PortableOperationKeyPatterns on PortableOperationKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PortableWriteKey value)?  write,TResult Function( _PortableExecuteKey value)?  execute,TResult Function( _PortableAddItemKey value)?  addItem,TResult Function( _PortableAddMapRowKey value)?  addMapRow,TResult Function( _PortableMappingKey value)?  mapping,TResult Function( _PortableStatusKey value)?  status,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that);case _PortableExecuteKey() when execute != null:
return execute(_that);case _PortableAddItemKey() when addItem != null:
return addItem(_that);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that);case _PortableMappingKey() when mapping != null:
return mapping(_that);case _PortableStatusKey() when status != null:
return status(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PortableWriteKey value)  write,required TResult Function( _PortableExecuteKey value)  execute,required TResult Function( _PortableAddItemKey value)  addItem,required TResult Function( _PortableAddMapRowKey value)  addMapRow,required TResult Function( _PortableMappingKey value)  mapping,required TResult Function( _PortableStatusKey value)  status,}){
final _that = this;
switch (_that) {
case _PortableWriteKey():
return write(_that);case _PortableExecuteKey():
return execute(_that);case _PortableAddItemKey():
return addItem(_that);case _PortableAddMapRowKey():
return addMapRow(_that);case _PortableMappingKey():
return mapping(_that);case _PortableStatusKey():
return status(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PortableWriteKey value)?  write,TResult? Function( _PortableExecuteKey value)?  execute,TResult? Function( _PortableAddItemKey value)?  addItem,TResult? Function( _PortableAddMapRowKey value)?  addMapRow,TResult? Function( _PortableMappingKey value)?  mapping,TResult? Function( _PortableStatusKey value)?  status,}){
final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that);case _PortableExecuteKey() when execute != null:
return execute(_that);case _PortableAddItemKey() when addItem != null:
return addItem(_that);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that);case _PortableMappingKey() when mapping != null:
return mapping(_that);case _PortableStatusKey() when status != null:
return status(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PortableDiagnosticTarget target)?  write,TResult Function( skir.EditorAction action)?  execute,TResult Function( PortableDiagnosticTarget target)?  addItem,TResult Function( PortableDiagnosticTarget target)?  addMapRow,TResult Function( PortableDiagnosticTarget target,  bool completion)?  mapping,TResult Function()?  status,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that.target);case _PortableExecuteKey() when execute != null:
return execute(_that.action);case _PortableAddItemKey() when addItem != null:
return addItem(_that.target);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that.target);case _PortableMappingKey() when mapping != null:
return mapping(_that.target,_that.completion);case _PortableStatusKey() when status != null:
return status();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PortableDiagnosticTarget target)  write,required TResult Function( skir.EditorAction action)  execute,required TResult Function( PortableDiagnosticTarget target)  addItem,required TResult Function( PortableDiagnosticTarget target)  addMapRow,required TResult Function( PortableDiagnosticTarget target,  bool completion)  mapping,required TResult Function()  status,}) {final _that = this;
switch (_that) {
case _PortableWriteKey():
return write(_that.target);case _PortableExecuteKey():
return execute(_that.action);case _PortableAddItemKey():
return addItem(_that.target);case _PortableAddMapRowKey():
return addMapRow(_that.target);case _PortableMappingKey():
return mapping(_that.target,_that.completion);case _PortableStatusKey():
return status();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PortableDiagnosticTarget target)?  write,TResult? Function( skir.EditorAction action)?  execute,TResult? Function( PortableDiagnosticTarget target)?  addItem,TResult? Function( PortableDiagnosticTarget target)?  addMapRow,TResult? Function( PortableDiagnosticTarget target,  bool completion)?  mapping,TResult? Function()?  status,}) {final _that = this;
switch (_that) {
case _PortableWriteKey() when write != null:
return write(_that.target);case _PortableExecuteKey() when execute != null:
return execute(_that.action);case _PortableAddItemKey() when addItem != null:
return addItem(_that.target);case _PortableAddMapRowKey() when addMapRow != null:
return addMapRow(_that.target);case _PortableMappingKey() when mapping != null:
return mapping(_that.target,_that.completion);case _PortableStatusKey() when status != null:
return status();case _:
  return null;

}
}

}

/// @nodoc


class _PortableWriteKey implements PortableOperationKey {
  const _PortableWriteKey(this.target);


 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableWriteKeyCopyWith<_PortableWriteKey> get copyWith => __$PortableWriteKeyCopyWithImpl<_PortableWriteKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableWriteKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.write(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableWriteKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableWriteKeyCopyWith(_PortableWriteKey value, $Res Function(_PortableWriteKey) _then) = __$PortableWriteKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableWriteKeyCopyWithImpl<$Res>
    implements _$PortableWriteKeyCopyWith<$Res> {
  __$PortableWriteKeyCopyWithImpl(this._self, this._then);

  final _PortableWriteKey _self;
  final $Res Function(_PortableWriteKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableWriteKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableExecuteKey implements PortableOperationKey {
  const _PortableExecuteKey(this.action);


 final  skir.EditorAction action;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableExecuteKeyCopyWith<_PortableExecuteKey> get copyWith => __$PortableExecuteKeyCopyWithImpl<_PortableExecuteKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableExecuteKey&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode {
    return Object.hash(runtimeType,action);
}

@override
String toString() {
    return 'PortableOperationKey.execute(action: $action)';
}


}

/// @nodoc
abstract mixin class _$PortableExecuteKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableExecuteKeyCopyWith(_PortableExecuteKey value, $Res Function(_PortableExecuteKey) _then) = __$PortableExecuteKeyCopyWithImpl;
@useResult
$Res call({
 skir.EditorAction action
});




}
/// @nodoc
class __$PortableExecuteKeyCopyWithImpl<$Res>
    implements _$PortableExecuteKeyCopyWith<$Res> {
  __$PortableExecuteKeyCopyWithImpl(this._self, this._then);

  final _PortableExecuteKey _self;
  final $Res Function(_PortableExecuteKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(_PortableExecuteKey(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as skir.EditorAction,
  ));
}


}

/// @nodoc


class _PortableAddItemKey implements PortableOperationKey {
  const _PortableAddItemKey(this.target);


 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAddItemKeyCopyWith<_PortableAddItemKey> get copyWith => __$PortableAddItemKeyCopyWithImpl<_PortableAddItemKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAddItemKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.addItem(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableAddItemKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableAddItemKeyCopyWith(_PortableAddItemKey value, $Res Function(_PortableAddItemKey) _then) = __$PortableAddItemKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableAddItemKeyCopyWithImpl<$Res>
    implements _$PortableAddItemKeyCopyWith<$Res> {
  __$PortableAddItemKeyCopyWithImpl(this._self, this._then);

  final _PortableAddItemKey _self;
  final $Res Function(_PortableAddItemKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableAddItemKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableAddMapRowKey implements PortableOperationKey {
  const _PortableAddMapRowKey(this.target);


 final  PortableDiagnosticTarget target;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAddMapRowKeyCopyWith<_PortableAddMapRowKey> get copyWith => __$PortableAddMapRowKeyCopyWithImpl<_PortableAddMapRowKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAddMapRowKey&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'PortableOperationKey.addMapRow(target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableAddMapRowKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableAddMapRowKeyCopyWith(_PortableAddMapRowKey value, $Res Function(_PortableAddMapRowKey) _then) = __$PortableAddMapRowKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableAddMapRowKeyCopyWithImpl<$Res>
    implements _$PortableAddMapRowKeyCopyWith<$Res> {
  __$PortableAddMapRowKeyCopyWithImpl(this._self, this._then);

  final _PortableAddMapRowKey _self;
  final $Res Function(_PortableAddMapRowKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_PortableAddMapRowKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableMappingKey implements PortableOperationKey {
  const _PortableMappingKey(this.target, {required this.completion});


 final  PortableDiagnosticTarget target;
 final  bool completion;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableMappingKeyCopyWith<_PortableMappingKey> get copyWith => __$PortableMappingKeyCopyWithImpl<_PortableMappingKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableMappingKey&&(identical(other.target, target) || other.target == target)&&(identical(other.completion, completion) || other.completion == completion));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,completion);
}

@override
String toString() {
    return 'PortableOperationKey.mapping(target: $target, completion: $completion)';
}


}

/// @nodoc
abstract mixin class _$PortableMappingKeyCopyWith<$Res> implements $PortableOperationKeyCopyWith<$Res> {
  factory _$PortableMappingKeyCopyWith(_PortableMappingKey value, $Res Function(_PortableMappingKey) _then) = __$PortableMappingKeyCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, bool completion
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableMappingKeyCopyWithImpl<$Res>
    implements _$PortableMappingKeyCopyWith<$Res> {
  __$PortableMappingKeyCopyWithImpl(this._self, this._then);

  final _PortableMappingKey _self;
  final $Res Function(_PortableMappingKey) _then;

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,Object? completion = null,}) {
  return _then(_PortableMappingKey(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,completion: null == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PortableOperationKey
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc


class _PortableStatusKey implements PortableOperationKey {
  const _PortableStatusKey();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableStatusKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableOperationKey.status()';
}


}




/// @nodoc
mixin _$PortableOperationOutcome {

 Object get request; PortableDiagnosticObservation? get input; bool get pending; List<PortablePresentationDiagnostic> get diagnostics;
/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableOperationOutcomeCopyWith<PortableOperationOutcome> get copyWith => _$PortableOperationOutcomeCopyWithImpl<PortableOperationOutcome>(this as PortableOperationOutcome, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableOperationOutcome;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationOutcome&&const DeepCollectionEquality().equals(other.request, _this.request)&&(identical(other.input, _this.input) || other.input == _this.input)&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics));
}


@override
int get hashCode {
  final _this = this as PortableOperationOutcome;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.request),_this.input,_this.pending,const DeepCollectionEquality().hash(_this.diagnostics));
}

@override
String toString() {
  final _this = this as PortableOperationOutcome;
  return 'PortableOperationOutcome(request: ${_this.request}, input: ${_this.input}, pending: ${_this.pending}, diagnostics: ${_this.diagnostics})';
}


}

/// @nodoc
abstract mixin class $PortableOperationOutcomeCopyWith<$Res>  {
  factory $PortableOperationOutcomeCopyWith(PortableOperationOutcome value, $Res Function(PortableOperationOutcome) _then) = _$PortableOperationOutcomeCopyWithImpl;
@useResult
$Res call({
 Object request, PortableDiagnosticObservation? input, bool pending, List<PortablePresentationDiagnostic> diagnostics
});


$PortableDiagnosticObservationCopyWith<$Res>? get input;

}
/// @nodoc
class _$PortableOperationOutcomeCopyWithImpl<$Res>
    implements $PortableOperationOutcomeCopyWith<$Res> {
  _$PortableOperationOutcomeCopyWithImpl(this._self, this._then);

  final PortableOperationOutcome _self;
  final $Res Function(PortableOperationOutcome) _then;

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? request = null,Object? input = freezed,Object? pending = null,Object? diagnostics = null,}) {
  return _then(PortableOperationOutcome(
request: null == request ? _self.request : request ,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticObservation?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}
/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $PortableDiagnosticObservationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}


/// Adds pattern matching related methods to [PortableOperationOutcome].
extension PortableOperationOutcomePatterns on PortableOperationOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableOperationOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableOperationOutcome value)  $default,){
final _that = this;
switch (_that) {
case _PortableOperationOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableOperationOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)  $default,) {final _that = this;
switch (_that) {
case _PortableOperationOutcome():
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object request,  PortableDiagnosticObservation? input,  bool pending,  List<PortablePresentationDiagnostic> diagnostics)?  $default,) {final _that = this;
switch (_that) {
case _PortableOperationOutcome() when $default != null:
return $default(_that.request,_that.input,_that.pending,_that.diagnostics);case _:
  return null;

}
}

}

/// @nodoc


class _PortableOperationOutcome implements PortableOperationOutcome {
  const _PortableOperationOutcome({required this.request, this.input, this.pending = false,  List<PortablePresentationDiagnostic> diagnostics = const []}): _diagnostics = diagnostics;


@override final  Object request;
@override final  PortableDiagnosticObservation? input;
@override@JsonKey() final  bool pending;
 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}


/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableOperationOutcomeCopyWith<_PortableOperationOutcome> get copyWith => __$PortableOperationOutcomeCopyWithImpl<_PortableOperationOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableOperationOutcome&&const DeepCollectionEquality().equals(other.request, request)&&(identical(other.input, input) || other.input == input)&&(identical(other.pending, pending) || other.pending == pending)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(request),input,pending,const DeepCollectionEquality().hash(_diagnostics));
}

@override
String toString() {
    return 'PortableOperationOutcome(request: $request, input: $input, pending: $pending, diagnostics: $diagnostics)';
}


}

/// @nodoc
abstract mixin class _$PortableOperationOutcomeCopyWith<$Res> implements $PortableOperationOutcomeCopyWith<$Res> {
  factory _$PortableOperationOutcomeCopyWith(_PortableOperationOutcome value, $Res Function(_PortableOperationOutcome) _then) = __$PortableOperationOutcomeCopyWithImpl;
@override @useResult
$Res call({
 Object request, PortableDiagnosticObservation? input, bool pending, List<PortablePresentationDiagnostic> diagnostics
});


@override $PortableDiagnosticObservationCopyWith<$Res>? get input;

}
/// @nodoc
class __$PortableOperationOutcomeCopyWithImpl<$Res>
    implements _$PortableOperationOutcomeCopyWith<$Res> {
  __$PortableOperationOutcomeCopyWithImpl(this._self, this._then);

  final _PortableOperationOutcome _self;
  final $Res Function(_PortableOperationOutcome) _then;

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? request = null,Object? input = freezed,Object? pending = null,Object? diagnostics = null,}) {
  return _then(_PortableOperationOutcome(
request: null == request ? _self.request : request ,input: freezed == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticObservation?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

/// Create a copy of PortableOperationOutcome
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<$Res>? get input {
    if (_self.input == null) {
    return null;
  }

  return $PortableDiagnosticObservationCopyWith<$Res>(_self.input!, (value) {
    return _then(_self.copyWith(input: value));
  });
}
}

/// @nodoc
mixin _$PortableOperationState {

 Map<PortableOperationKey, PortableOperationOutcome> get outcomes;
/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableOperationStateCopyWith<PortableOperationState> get copyWith => _$PortableOperationStateCopyWithImpl<PortableOperationState>(this as PortableOperationState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableOperationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableOperationState&&const DeepCollectionEquality().equals(other.outcomes, _this.outcomes));
}


@override
int get hashCode {
  final _this = this as PortableOperationState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.outcomes));
}

@override
String toString() {
  final _this = this as PortableOperationState;
  return 'PortableOperationState(outcomes: ${_this.outcomes})';
}


}

/// @nodoc
abstract mixin class $PortableOperationStateCopyWith<$Res>  {
  factory $PortableOperationStateCopyWith(PortableOperationState value, $Res Function(PortableOperationState) _then) = _$PortableOperationStateCopyWithImpl;
@useResult
$Res call({
 Map<PortableOperationKey, PortableOperationOutcome> outcomes
});




}
/// @nodoc
class _$PortableOperationStateCopyWithImpl<$Res>
    implements $PortableOperationStateCopyWith<$Res> {
  _$PortableOperationStateCopyWithImpl(this._self, this._then);

  final PortableOperationState _self;
  final $Res Function(PortableOperationState) _then;

/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outcomes = null,}) {
  return _then(PortableOperationState(
outcomes: null == outcomes ? _self.outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<PortableOperationKey, PortableOperationOutcome>,
  ));
}

}


/// Adds pattern matching related methods to [PortableOperationState].
extension PortableOperationStatePatterns on PortableOperationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableOperationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableOperationState value)  $default,){
final _that = this;
switch (_that) {
case _PortableOperationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableOperationState value)?  $default,){
final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
return $default(_that.outcomes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)  $default,) {final _that = this;
switch (_that) {
case _PortableOperationState():
return $default(_that.outcomes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<PortableOperationKey, PortableOperationOutcome> outcomes)?  $default,) {final _that = this;
switch (_that) {
case _PortableOperationState() when $default != null:
return $default(_that.outcomes);case _:
  return null;

}
}

}

/// @nodoc


class _PortableOperationState extends PortableOperationState {
  const _PortableOperationState({ Map<PortableOperationKey, PortableOperationOutcome> outcomes = const {}}): _outcomes = outcomes,super._();


 final  Map<PortableOperationKey, PortableOperationOutcome> _outcomes;
@override@JsonKey() Map<PortableOperationKey, PortableOperationOutcome> get outcomes {
  if (_outcomes is EqualUnmodifiableMapView) return _outcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_outcomes);
}


/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableOperationStateCopyWith<_PortableOperationState> get copyWith => __$PortableOperationStateCopyWithImpl<_PortableOperationState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableOperationState&&const DeepCollectionEquality().equals(other.outcomes, _outcomes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_outcomes));
}

@override
String toString() {
    return 'PortableOperationState(outcomes: $outcomes)';
}


}

/// @nodoc
abstract mixin class _$PortableOperationStateCopyWith<$Res> implements $PortableOperationStateCopyWith<$Res> {
  factory _$PortableOperationStateCopyWith(_PortableOperationState value, $Res Function(_PortableOperationState) _then) = __$PortableOperationStateCopyWithImpl;
@override @useResult
$Res call({
 Map<PortableOperationKey, PortableOperationOutcome> outcomes
});




}
/// @nodoc
class __$PortableOperationStateCopyWithImpl<$Res>
    implements _$PortableOperationStateCopyWith<$Res> {
  __$PortableOperationStateCopyWithImpl(this._self, this._then);

  final _PortableOperationState _self;
  final $Res Function(_PortableOperationState) _then;

/// Create a copy of PortableOperationState
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outcomes = null,}) {
  return _then(_PortableOperationState(
outcomes: null == outcomes ? _self._outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as Map<PortableOperationKey, PortableOperationOutcome>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticObservation {

 PortableDiagnosticTarget get target; skir.DataValue? get value;
/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticObservationCopyWith<PortableDiagnosticObservation> get copyWith => _$PortableDiagnosticObservationCopyWithImpl<PortableDiagnosticObservation>(this as PortableDiagnosticObservation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticObservation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticObservation&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticObservation;
  return Object.hash(runtimeType,_this.target,_this.value);
}

@override
String toString() {
  final _this = this as PortableDiagnosticObservation;
  return 'PortableDiagnosticObservation(target: ${_this.target}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticObservationCopyWith<$Res>  {
  factory $PortableDiagnosticObservationCopyWith(PortableDiagnosticObservation value, $Res Function(PortableDiagnosticObservation) _then) = _$PortableDiagnosticObservationCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticTarget target, skir.DataValue? value
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$PortableDiagnosticObservationCopyWithImpl<$Res>
    implements $PortableDiagnosticObservationCopyWith<$Res> {
  _$PortableDiagnosticObservationCopyWithImpl(this._self, this._then);

  final PortableDiagnosticObservation _self;
  final $Res Function(PortableDiagnosticObservation) _then;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? target = null,Object? value = freezed,}) {
  return _then(PortableDiagnosticObservation(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue?,
  ));
}
/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern matching related methods to [PortableDiagnosticObservation].
extension PortableDiagnosticObservationPatterns on PortableDiagnosticObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticObservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticObservation value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticObservation value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableDiagnosticTarget target,  skir.DataValue? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
return $default(_that.target,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableDiagnosticTarget target,  skir.DataValue? value)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation():
return $default(_that.target,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableDiagnosticTarget target,  skir.DataValue? value)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticObservation() when $default != null:
return $default(_that.target,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticObservation extends PortableDiagnosticObservation {
  const _PortableDiagnosticObservation({required this.target, required this.value}): super._();


@override final  PortableDiagnosticTarget target;
@override final  skir.DataValue? value;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticObservationCopyWith<_PortableDiagnosticObservation> get copyWith => __$PortableDiagnosticObservationCopyWithImpl<_PortableDiagnosticObservation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticObservation&&(identical(other.target, target) || other.target == target)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target,value);
}

@override
String toString() {
    return 'PortableDiagnosticObservation(target: $target, value: $value)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticObservationCopyWith<$Res> implements $PortableDiagnosticObservationCopyWith<$Res> {
  factory _$PortableDiagnosticObservationCopyWith(_PortableDiagnosticObservation value, $Res Function(_PortableDiagnosticObservation) _then) = __$PortableDiagnosticObservationCopyWithImpl;
@override @useResult
$Res call({
 PortableDiagnosticTarget target, skir.DataValue? value
});


@override $PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableDiagnosticObservationCopyWithImpl<$Res>
    implements _$PortableDiagnosticObservationCopyWith<$Res> {
  __$PortableDiagnosticObservationCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticObservation _self;
  final $Res Function(_PortableDiagnosticObservation) _then;

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? target = null,Object? value = freezed,}) {
  return _then(_PortableDiagnosticObservation(
target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as skir.DataValue?,
  ));
}

/// Create a copy of PortableDiagnosticObservation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
mixin _$PortableDiagnosticNode {

 PortableDiagnosticNodeKind get kind; Object? get parent; List<PortableDiagnosticObservation> get observations; List<PortablePresentationDiagnostic> get diagnostics; PortableDiagnosticFallback get diagnosticFallback;
/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticNodeCopyWith<PortableDiagnosticNode> get copyWith => _$PortableDiagnosticNodeCopyWithImpl<PortableDiagnosticNode>(this as PortableDiagnosticNode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticNode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticNode&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.parent, _this.parent)&&const DeepCollectionEquality().equals(other.observations, _this.observations)&&const DeepCollectionEquality().equals(other.diagnostics, _this.diagnostics)&&(identical(other.diagnosticFallback, _this.diagnosticFallback) || other.diagnosticFallback == _this.diagnosticFallback));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticNode;
  return Object.hash(runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.parent),const DeepCollectionEquality().hash(_this.observations),const DeepCollectionEquality().hash(_this.diagnostics),_this.diagnosticFallback);
}

@override
String toString() {
  final _this = this as PortableDiagnosticNode;
  return 'PortableDiagnosticNode(kind: ${_this.kind}, parent: ${_this.parent}, observations: ${_this.observations}, diagnostics: ${_this.diagnostics}, diagnosticFallback: ${_this.diagnosticFallback})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticNodeCopyWith<$Res>  {
  factory $PortableDiagnosticNodeCopyWith(PortableDiagnosticNode value, $Res Function(PortableDiagnosticNode) _then) = _$PortableDiagnosticNodeCopyWithImpl;
@useResult
$Res call({
 PortableDiagnosticNodeKind kind, Object? parent, List<PortableDiagnosticObservation> observations, List<PortablePresentationDiagnostic> diagnostics, PortableDiagnosticFallback diagnosticFallback
});




}
/// @nodoc
class _$PortableDiagnosticNodeCopyWithImpl<$Res>
    implements $PortableDiagnosticNodeCopyWith<$Res> {
  _$PortableDiagnosticNodeCopyWithImpl(this._self, this._then);

  final PortableDiagnosticNode _self;
  final $Res Function(PortableDiagnosticNode) _then;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? parent = freezed,Object? observations = null,Object? diagnostics = null,Object? diagnosticFallback = null,}) {
  return _then(PortableDiagnosticNode(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticNodeKind,parent: freezed == parent ? _self.parent : parent ,observations: null == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticObservation>,diagnostics: null == diagnostics ? _self.diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,diagnosticFallback: null == diagnosticFallback ? _self.diagnosticFallback : diagnosticFallback // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticFallback,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticNode].
extension PortableDiagnosticNodePatterns on PortableDiagnosticNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticNode value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticNode value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics,_that.diagnosticFallback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode():
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics,_that.diagnosticFallback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableDiagnosticNodeKind kind,  Object? parent,  List<PortableDiagnosticObservation> observations,  List<PortablePresentationDiagnostic> diagnostics,  PortableDiagnosticFallback diagnosticFallback)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticNode() when $default != null:
return $default(_that.kind,_that.parent,_that.observations,_that.diagnostics,_that.diagnosticFallback);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticNode extends PortableDiagnosticNode {
  const _PortableDiagnosticNode({required this.kind, this.parent,  List<PortableDiagnosticObservation> observations = const [],  List<PortablePresentationDiagnostic> diagnostics = const [], this.diagnosticFallback = PortableDiagnosticFallback.presentation}): _observations = observations,_diagnostics = diagnostics,super._();


@override final  PortableDiagnosticNodeKind kind;
@override final  Object? parent;
 final  List<PortableDiagnosticObservation> _observations;
@override@JsonKey() List<PortableDiagnosticObservation> get observations {
  if (_observations is EqualUnmodifiableListView) return _observations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_observations);
}

 final  List<PortablePresentationDiagnostic> _diagnostics;
@override@JsonKey() List<PortablePresentationDiagnostic> get diagnostics {
  if (_diagnostics is EqualUnmodifiableListView) return _diagnostics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_diagnostics);
}

@override@JsonKey() final  PortableDiagnosticFallback diagnosticFallback;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticNodeCopyWith<_PortableDiagnosticNode> get copyWith => __$PortableDiagnosticNodeCopyWithImpl<_PortableDiagnosticNode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticNode&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.parent, parent)&&const DeepCollectionEquality().equals(other.observations, _observations)&&const DeepCollectionEquality().equals(other.diagnostics, _diagnostics)&&(identical(other.diagnosticFallback, diagnosticFallback) || other.diagnosticFallback == diagnosticFallback));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(parent),const DeepCollectionEquality().hash(_observations),const DeepCollectionEquality().hash(_diagnostics),diagnosticFallback);
}

@override
String toString() {
    return 'PortableDiagnosticNode(kind: $kind, parent: $parent, observations: $observations, diagnostics: $diagnostics, diagnosticFallback: $diagnosticFallback)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticNodeCopyWith<$Res> implements $PortableDiagnosticNodeCopyWith<$Res> {
  factory _$PortableDiagnosticNodeCopyWith(_PortableDiagnosticNode value, $Res Function(_PortableDiagnosticNode) _then) = __$PortableDiagnosticNodeCopyWithImpl;
@override @useResult
$Res call({
 PortableDiagnosticNodeKind kind, Object? parent, List<PortableDiagnosticObservation> observations, List<PortablePresentationDiagnostic> diagnostics, PortableDiagnosticFallback diagnosticFallback
});




}
/// @nodoc
class __$PortableDiagnosticNodeCopyWithImpl<$Res>
    implements _$PortableDiagnosticNodeCopyWith<$Res> {
  __$PortableDiagnosticNodeCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticNode _self;
  final $Res Function(_PortableDiagnosticNode) _then;

/// Create a copy of PortableDiagnosticNode
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? parent = freezed,Object? observations = null,Object? diagnostics = null,Object? diagnosticFallback = null,}) {
  return _then(_PortableDiagnosticNode(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticNodeKind,parent: freezed == parent ? _self.parent : parent ,observations: null == observations ? _self._observations : observations // ignore: cast_nullable_to_non_nullable
as List<PortableDiagnosticObservation>,diagnostics: null == diagnostics ? _self._diagnostics : diagnostics // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,diagnosticFallback: null == diagnosticFallback ? _self.diagnosticFallback : diagnosticFallback // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticFallback,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticPresentation {

 Map<Object, PortableDiagnosticNode> get nodes;
/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticPresentationCopyWith<PortableDiagnosticPresentation> get copyWith => _$PortableDiagnosticPresentationCopyWithImpl<PortableDiagnosticPresentation>(this as PortableDiagnosticPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticPresentation&&const DeepCollectionEquality().equals(other.nodes, _this.nodes));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticPresentation;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.nodes));
}

@override
String toString() {
  final _this = this as PortableDiagnosticPresentation;
  return 'PortableDiagnosticPresentation(nodes: ${_this.nodes})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticPresentationCopyWith<$Res>  {
  factory $PortableDiagnosticPresentationCopyWith(PortableDiagnosticPresentation value, $Res Function(PortableDiagnosticPresentation) _then) = _$PortableDiagnosticPresentationCopyWithImpl;
@useResult
$Res call({
 Map<Object, PortableDiagnosticNode> nodes
});




}
/// @nodoc
class _$PortableDiagnosticPresentationCopyWithImpl<$Res>
    implements $PortableDiagnosticPresentationCopyWith<$Res> {
  _$PortableDiagnosticPresentationCopyWithImpl(this._self, this._then);

  final PortableDiagnosticPresentation _self;
  final $Res Function(PortableDiagnosticPresentation) _then;

/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodes = null,}) {
  return _then(PortableDiagnosticPresentation(
nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticNode>,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticPresentation].
extension PortableDiagnosticPresentationPatterns on PortableDiagnosticPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticPresentation value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticNode> nodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
return $default(_that.nodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticNode> nodes)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation():
return $default(_that.nodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<Object, PortableDiagnosticNode> nodes)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPresentation() when $default != null:
return $default(_that.nodes);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticPresentation extends PortableDiagnosticPresentation {
  const _PortableDiagnosticPresentation({ Map<Object, PortableDiagnosticNode> nodes = const {}}): _nodes = nodes,super._();


 final  Map<Object, PortableDiagnosticNode> _nodes;
@override@JsonKey() Map<Object, PortableDiagnosticNode> get nodes {
  if (_nodes is EqualUnmodifiableMapView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nodes);
}


/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticPresentationCopyWith<_PortableDiagnosticPresentation> get copyWith => __$PortableDiagnosticPresentationCopyWithImpl<_PortableDiagnosticPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticPresentation&&const DeepCollectionEquality().equals(other.nodes, _nodes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_nodes));
}

@override
String toString() {
    return 'PortableDiagnosticPresentation(nodes: $nodes)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticPresentationCopyWith<$Res> implements $PortableDiagnosticPresentationCopyWith<$Res> {
  factory _$PortableDiagnosticPresentationCopyWith(_PortableDiagnosticPresentation value, $Res Function(_PortableDiagnosticPresentation) _then) = __$PortableDiagnosticPresentationCopyWithImpl;
@override @useResult
$Res call({
 Map<Object, PortableDiagnosticNode> nodes
});




}
/// @nodoc
class __$PortableDiagnosticPresentationCopyWithImpl<$Res>
    implements _$PortableDiagnosticPresentationCopyWith<$Res> {
  __$PortableDiagnosticPresentationCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticPresentation _self;
  final $Res Function(_PortableDiagnosticPresentation) _then;

/// Create a copy of PortableDiagnosticPresentation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodes = null,}) {
  return _then(_PortableDiagnosticPresentation(
nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticNode>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticSummary {

 List<PortablePresentationDiagnostic> get direct; List<PortablePresentationDiagnostic> get descendants;
/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticSummaryCopyWith<PortableDiagnosticSummary> get copyWith => _$PortableDiagnosticSummaryCopyWithImpl<PortableDiagnosticSummary>(this as PortableDiagnosticSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticSummary&&const DeepCollectionEquality().equals(other.direct, _this.direct)&&const DeepCollectionEquality().equals(other.descendants, _this.descendants));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticSummary;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.direct),const DeepCollectionEquality().hash(_this.descendants));
}

@override
String toString() {
  final _this = this as PortableDiagnosticSummary;
  return 'PortableDiagnosticSummary(direct: ${_this.direct}, descendants: ${_this.descendants})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticSummaryCopyWith<$Res>  {
  factory $PortableDiagnosticSummaryCopyWith(PortableDiagnosticSummary value, $Res Function(PortableDiagnosticSummary) _then) = _$PortableDiagnosticSummaryCopyWithImpl;
@useResult
$Res call({
 List<PortablePresentationDiagnostic> direct, List<PortablePresentationDiagnostic> descendants
});




}
/// @nodoc
class _$PortableDiagnosticSummaryCopyWithImpl<$Res>
    implements $PortableDiagnosticSummaryCopyWith<$Res> {
  _$PortableDiagnosticSummaryCopyWithImpl(this._self, this._then);

  final PortableDiagnosticSummary _self;
  final $Res Function(PortableDiagnosticSummary) _then;

/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direct = null,Object? descendants = null,}) {
  return _then(PortableDiagnosticSummary(
direct: null == direct ? _self.direct : direct // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,descendants: null == descendants ? _self.descendants : descendants // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticSummary].
extension PortableDiagnosticSummaryPatterns on PortableDiagnosticSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticSummary value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
return $default(_that.direct,_that.descendants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary():
return $default(_that.direct,_that.descendants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PortablePresentationDiagnostic> direct,  List<PortablePresentationDiagnostic> descendants)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticSummary() when $default != null:
return $default(_that.direct,_that.descendants);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticSummary extends PortableDiagnosticSummary {
  const _PortableDiagnosticSummary({ List<PortablePresentationDiagnostic> direct = const [],  List<PortablePresentationDiagnostic> descendants = const []}): _direct = direct,_descendants = descendants,super._();


 final  List<PortablePresentationDiagnostic> _direct;
@override@JsonKey() List<PortablePresentationDiagnostic> get direct {
  if (_direct is EqualUnmodifiableListView) return _direct;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_direct);
}

 final  List<PortablePresentationDiagnostic> _descendants;
@override@JsonKey() List<PortablePresentationDiagnostic> get descendants {
  if (_descendants is EqualUnmodifiableListView) return _descendants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_descendants);
}


/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticSummaryCopyWith<_PortableDiagnosticSummary> get copyWith => __$PortableDiagnosticSummaryCopyWithImpl<_PortableDiagnosticSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticSummary&&const DeepCollectionEquality().equals(other.direct, _direct)&&const DeepCollectionEquality().equals(other.descendants, _descendants));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_direct),const DeepCollectionEquality().hash(_descendants));
}

@override
String toString() {
    return 'PortableDiagnosticSummary(direct: $direct, descendants: $descendants)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticSummaryCopyWith<$Res> implements $PortableDiagnosticSummaryCopyWith<$Res> {
  factory _$PortableDiagnosticSummaryCopyWith(_PortableDiagnosticSummary value, $Res Function(_PortableDiagnosticSummary) _then) = __$PortableDiagnosticSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<PortablePresentationDiagnostic> direct, List<PortablePresentationDiagnostic> descendants
});




}
/// @nodoc
class __$PortableDiagnosticSummaryCopyWithImpl<$Res>
    implements _$PortableDiagnosticSummaryCopyWith<$Res> {
  __$PortableDiagnosticSummaryCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticSummary _self;
  final $Res Function(_PortableDiagnosticSummary) _then;

/// Create a copy of PortableDiagnosticSummary
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direct = null,Object? descendants = null,}) {
  return _then(_PortableDiagnosticSummary(
direct: null == direct ? _self._direct : direct // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,descendants: null == descendants ? _self._descendants : descendants // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableDiagnosticPlacement {

 Map<Object, PortableDiagnosticSummary> get summaries; List<PortablePresentationDiagnostic> get general; List<PortablePresentationDiagnostic> get unplaced;
/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableDiagnosticPlacementCopyWith<PortableDiagnosticPlacement> get copyWith => _$PortableDiagnosticPlacementCopyWithImpl<PortableDiagnosticPlacement>(this as PortableDiagnosticPlacement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableDiagnosticPlacement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableDiagnosticPlacement&&const DeepCollectionEquality().equals(other.summaries, _this.summaries)&&const DeepCollectionEquality().equals(other.general, _this.general)&&const DeepCollectionEquality().equals(other.unplaced, _this.unplaced));
}


@override
int get hashCode {
  final _this = this as PortableDiagnosticPlacement;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.summaries),const DeepCollectionEquality().hash(_this.general),const DeepCollectionEquality().hash(_this.unplaced));
}

@override
String toString() {
  final _this = this as PortableDiagnosticPlacement;
  return 'PortableDiagnosticPlacement(summaries: ${_this.summaries}, general: ${_this.general}, unplaced: ${_this.unplaced})';
}


}

/// @nodoc
abstract mixin class $PortableDiagnosticPlacementCopyWith<$Res>  {
  factory $PortableDiagnosticPlacementCopyWith(PortableDiagnosticPlacement value, $Res Function(PortableDiagnosticPlacement) _then) = _$PortableDiagnosticPlacementCopyWithImpl;
@useResult
$Res call({
 Map<Object, PortableDiagnosticSummary> summaries, List<PortablePresentationDiagnostic> general, List<PortablePresentationDiagnostic> unplaced
});




}
/// @nodoc
class _$PortableDiagnosticPlacementCopyWithImpl<$Res>
    implements $PortableDiagnosticPlacementCopyWith<$Res> {
  _$PortableDiagnosticPlacementCopyWithImpl(this._self, this._then);

  final PortableDiagnosticPlacement _self;
  final $Res Function(PortableDiagnosticPlacement) _then;

/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summaries = null,Object? general = null,Object? unplaced = null,}) {
  return _then(PortableDiagnosticPlacement(
summaries: null == summaries ? _self.summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticSummary>,general: null == general ? _self.general : general // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,unplaced: null == unplaced ? _self.unplaced : unplaced // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}

}


/// Adds pattern matching related methods to [PortableDiagnosticPlacement].
extension PortableDiagnosticPlacementPatterns on PortableDiagnosticPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableDiagnosticPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableDiagnosticPlacement value)  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableDiagnosticPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general,  List<PortablePresentationDiagnostic> unplaced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
return $default(_that.summaries,_that.general,_that.unplaced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general,  List<PortablePresentationDiagnostic> unplaced)  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement():
return $default(_that.summaries,_that.general,_that.unplaced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<Object, PortableDiagnosticSummary> summaries,  List<PortablePresentationDiagnostic> general,  List<PortablePresentationDiagnostic> unplaced)?  $default,) {final _that = this;
switch (_that) {
case _PortableDiagnosticPlacement() when $default != null:
return $default(_that.summaries,_that.general,_that.unplaced);case _:
  return null;

}
}

}

/// @nodoc


class _PortableDiagnosticPlacement extends PortableDiagnosticPlacement {
  const _PortableDiagnosticPlacement({ Map<Object, PortableDiagnosticSummary> summaries = const {},  List<PortablePresentationDiagnostic> general = const [],  List<PortablePresentationDiagnostic> unplaced = const []}): _summaries = summaries,_general = general,_unplaced = unplaced,super._();


 final  Map<Object, PortableDiagnosticSummary> _summaries;
@override@JsonKey() Map<Object, PortableDiagnosticSummary> get summaries {
  if (_summaries is EqualUnmodifiableMapView) return _summaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_summaries);
}

 final  List<PortablePresentationDiagnostic> _general;
@override@JsonKey() List<PortablePresentationDiagnostic> get general {
  if (_general is EqualUnmodifiableListView) return _general;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_general);
}

 final  List<PortablePresentationDiagnostic> _unplaced;
@override@JsonKey() List<PortablePresentationDiagnostic> get unplaced {
  if (_unplaced is EqualUnmodifiableListView) return _unplaced;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unplaced);
}


/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableDiagnosticPlacementCopyWith<_PortableDiagnosticPlacement> get copyWith => __$PortableDiagnosticPlacementCopyWithImpl<_PortableDiagnosticPlacement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableDiagnosticPlacement&&const DeepCollectionEquality().equals(other.summaries, _summaries)&&const DeepCollectionEquality().equals(other.general, _general)&&const DeepCollectionEquality().equals(other.unplaced, _unplaced));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_summaries),const DeepCollectionEquality().hash(_general),const DeepCollectionEquality().hash(_unplaced));
}

@override
String toString() {
    return 'PortableDiagnosticPlacement(summaries: $summaries, general: $general, unplaced: $unplaced)';
}


}

/// @nodoc
abstract mixin class _$PortableDiagnosticPlacementCopyWith<$Res> implements $PortableDiagnosticPlacementCopyWith<$Res> {
  factory _$PortableDiagnosticPlacementCopyWith(_PortableDiagnosticPlacement value, $Res Function(_PortableDiagnosticPlacement) _then) = __$PortableDiagnosticPlacementCopyWithImpl;
@override @useResult
$Res call({
 Map<Object, PortableDiagnosticSummary> summaries, List<PortablePresentationDiagnostic> general, List<PortablePresentationDiagnostic> unplaced
});




}
/// @nodoc
class __$PortableDiagnosticPlacementCopyWithImpl<$Res>
    implements _$PortableDiagnosticPlacementCopyWith<$Res> {
  __$PortableDiagnosticPlacementCopyWithImpl(this._self, this._then);

  final _PortableDiagnosticPlacement _self;
  final $Res Function(_PortableDiagnosticPlacement) _then;

/// Create a copy of PortableDiagnosticPlacement
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summaries = null,Object? general = null,Object? unplaced = null,}) {
  return _then(_PortableDiagnosticPlacement(
summaries: null == summaries ? _self._summaries : summaries // ignore: cast_nullable_to_non_nullable
as Map<Object, PortableDiagnosticSummary>,general: null == general ? _self._general : general // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,unplaced: null == unplaced ? _self._unplaced : unplaced // ignore: cast_nullable_to_non_nullable
as List<PortablePresentationDiagnostic>,
  ));
}


}

/// @nodoc
mixin _$PortableControlValidationIdentity {

 Object get owner; PortableDiagnosticTarget get target;
/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableControlValidationIdentityCopyWith<PortableControlValidationIdentity> get copyWith => _$PortableControlValidationIdentityCopyWithImpl<PortableControlValidationIdentity>(this as PortableControlValidationIdentity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableControlValidationIdentity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableControlValidationIdentity&&const DeepCollectionEquality().equals(other.owner, _this.owner)&&(identical(other.target, _this.target) || other.target == _this.target));
}


@override
int get hashCode {
  final _this = this as PortableControlValidationIdentity;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.owner),_this.target);
}

@override
String toString() {
  final _this = this as PortableControlValidationIdentity;
  return 'PortableControlValidationIdentity(owner: ${_this.owner}, target: ${_this.target})';
}


}

/// @nodoc
abstract mixin class $PortableControlValidationIdentityCopyWith<$Res>  {
  factory $PortableControlValidationIdentityCopyWith(PortableControlValidationIdentity value, $Res Function(PortableControlValidationIdentity) _then) = _$PortableControlValidationIdentityCopyWithImpl;
@useResult
$Res call({
 Object owner, PortableDiagnosticTarget target
});


$PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$PortableControlValidationIdentityCopyWithImpl<$Res>
    implements $PortableControlValidationIdentityCopyWith<$Res> {
  _$PortableControlValidationIdentityCopyWithImpl(this._self, this._then);

  final PortableControlValidationIdentity _self;
  final $Res Function(PortableControlValidationIdentity) _then;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? target = null,}) {
  return _then(PortableControlValidationIdentity(
owner: null == owner ? _self.owner : owner ,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}
/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern matching related methods to [PortableControlValidationIdentity].
extension PortableControlValidationIdentityPatterns on PortableControlValidationIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableControlValidationIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableControlValidationIdentity value)  $default,){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableControlValidationIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object owner,  PortableDiagnosticTarget target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
return $default(_that.owner,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object owner,  PortableDiagnosticTarget target)  $default,) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity():
return $default(_that.owner,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object owner,  PortableDiagnosticTarget target)?  $default,) {final _that = this;
switch (_that) {
case _PortableControlValidationIdentity() when $default != null:
return $default(_that.owner,_that.target);case _:
  return null;

}
}

}

/// @nodoc


class _PortableControlValidationIdentity implements PortableControlValidationIdentity {
  const _PortableControlValidationIdentity({required this.owner, required this.target});


@override final  Object owner;
@override final  PortableDiagnosticTarget target;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableControlValidationIdentityCopyWith<_PortableControlValidationIdentity> get copyWith => __$PortableControlValidationIdentityCopyWithImpl<_PortableControlValidationIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableControlValidationIdentity&&const DeepCollectionEquality().equals(other.owner, owner)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(owner),target);
}

@override
String toString() {
    return 'PortableControlValidationIdentity(owner: $owner, target: $target)';
}


}

/// @nodoc
abstract mixin class _$PortableControlValidationIdentityCopyWith<$Res> implements $PortableControlValidationIdentityCopyWith<$Res> {
  factory _$PortableControlValidationIdentityCopyWith(_PortableControlValidationIdentity value, $Res Function(_PortableControlValidationIdentity) _then) = __$PortableControlValidationIdentityCopyWithImpl;
@override @useResult
$Res call({
 Object owner, PortableDiagnosticTarget target
});


@override $PortableDiagnosticTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$PortableControlValidationIdentityCopyWithImpl<$Res>
    implements _$PortableControlValidationIdentityCopyWith<$Res> {
  __$PortableControlValidationIdentityCopyWithImpl(this._self, this._then);

  final _PortableControlValidationIdentity _self;
  final $Res Function(_PortableControlValidationIdentity) _then;

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? target = null,}) {
  return _then(_PortableControlValidationIdentity(
owner: null == owner ? _self.owner : owner ,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableDiagnosticTarget,
  ));
}

/// Create a copy of PortableControlValidationIdentity
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableDiagnosticTargetCopyWith<$Res> get target {

  return $PortableDiagnosticTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
mixin _$ResolvedFieldAssociation {

 String? get label; String? get description; String? get semanticLabel; ScopedControlPrefix? get prefix;
/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedFieldAssociationCopyWith<ResolvedFieldAssociation> get copyWith => _$ResolvedFieldAssociationCopyWithImpl<ResolvedFieldAssociation>(this as ResolvedFieldAssociation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResolvedFieldAssociation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedFieldAssociation&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.semanticLabel, _this.semanticLabel) || other.semanticLabel == _this.semanticLabel)&&(identical(other.prefix, _this.prefix) || other.prefix == _this.prefix));
}


@override
int get hashCode {
  final _this = this as ResolvedFieldAssociation;
  return Object.hash(runtimeType,_this.label,_this.description,_this.semanticLabel,_this.prefix);
}

@override
String toString() {
  final _this = this as ResolvedFieldAssociation;
  return 'ResolvedFieldAssociation(label: ${_this.label}, description: ${_this.description}, semanticLabel: ${_this.semanticLabel}, prefix: ${_this.prefix})';
}


}

/// @nodoc
abstract mixin class $ResolvedFieldAssociationCopyWith<$Res>  {
  factory $ResolvedFieldAssociationCopyWith(ResolvedFieldAssociation value, $Res Function(ResolvedFieldAssociation) _then) = _$ResolvedFieldAssociationCopyWithImpl;
@useResult
$Res call({
 String? label, String? description, String? semanticLabel, ScopedControlPrefix? prefix
});


$ScopedControlPrefixCopyWith<$Res>? get prefix;

}
/// @nodoc
class _$ResolvedFieldAssociationCopyWithImpl<$Res>
    implements $ResolvedFieldAssociationCopyWith<$Res> {
  _$ResolvedFieldAssociationCopyWithImpl(this._self, this._then);

  final ResolvedFieldAssociation _self;
  final $Res Function(ResolvedFieldAssociation) _then;

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = freezed,Object? description = freezed,Object? semanticLabel = freezed,Object? prefix = freezed,}) {
  return _then(ResolvedFieldAssociation(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,semanticLabel: freezed == semanticLabel ? _self.semanticLabel : semanticLabel // ignore: cast_nullable_to_non_nullable
as String?,prefix: freezed == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as ScopedControlPrefix?,
  ));
}
/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopedControlPrefixCopyWith<$Res>? get prefix {
    if (_self.prefix == null) {
    return null;
  }

  return $ScopedControlPrefixCopyWith<$Res>(_self.prefix!, (value) {
    return _then(_self.copyWith(prefix: value));
  });
}
}


/// Adds pattern matching related methods to [ResolvedFieldAssociation].
extension ResolvedFieldAssociationPatterns on ResolvedFieldAssociation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedFieldAssociation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedFieldAssociation value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedFieldAssociation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedFieldAssociation value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? label,  String? description,  String? semanticLabel,  ScopedControlPrefix? prefix)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
return $default(_that.label,_that.description,_that.semanticLabel,_that.prefix);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? label,  String? description,  String? semanticLabel,  ScopedControlPrefix? prefix)  $default,) {final _that = this;
switch (_that) {
case _ResolvedFieldAssociation():
return $default(_that.label,_that.description,_that.semanticLabel,_that.prefix);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? label,  String? description,  String? semanticLabel,  ScopedControlPrefix? prefix)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedFieldAssociation() when $default != null:
return $default(_that.label,_that.description,_that.semanticLabel,_that.prefix);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedFieldAssociation extends ResolvedFieldAssociation {
  const _ResolvedFieldAssociation({this.label, this.description, this.semanticLabel, this.prefix}): super._();


@override final  String? label;
@override final  String? description;
@override final  String? semanticLabel;
@override final  ScopedControlPrefix? prefix;

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedFieldAssociationCopyWith<_ResolvedFieldAssociation> get copyWith => __$ResolvedFieldAssociationCopyWithImpl<_ResolvedFieldAssociation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedFieldAssociation&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.semanticLabel, semanticLabel) || other.semanticLabel == semanticLabel)&&(identical(other.prefix, prefix) || other.prefix == prefix));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,description,semanticLabel,prefix);
}

@override
String toString() {
    return 'ResolvedFieldAssociation(label: $label, description: $description, semanticLabel: $semanticLabel, prefix: $prefix)';
}


}

/// @nodoc
abstract mixin class _$ResolvedFieldAssociationCopyWith<$Res> implements $ResolvedFieldAssociationCopyWith<$Res> {
  factory _$ResolvedFieldAssociationCopyWith(_ResolvedFieldAssociation value, $Res Function(_ResolvedFieldAssociation) _then) = __$ResolvedFieldAssociationCopyWithImpl;
@override @useResult
$Res call({
 String? label, String? description, String? semanticLabel, ScopedControlPrefix? prefix
});


@override $ScopedControlPrefixCopyWith<$Res>? get prefix;

}
/// @nodoc
class __$ResolvedFieldAssociationCopyWithImpl<$Res>
    implements _$ResolvedFieldAssociationCopyWith<$Res> {
  __$ResolvedFieldAssociationCopyWithImpl(this._self, this._then);

  final _ResolvedFieldAssociation _self;
  final $Res Function(_ResolvedFieldAssociation) _then;

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = freezed,Object? description = freezed,Object? semanticLabel = freezed,Object? prefix = freezed,}) {
  return _then(_ResolvedFieldAssociation(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,semanticLabel: freezed == semanticLabel ? _self.semanticLabel : semanticLabel // ignore: cast_nullable_to_non_nullable
as String?,prefix: freezed == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as ScopedControlPrefix?,
  ));
}

/// Create a copy of ResolvedFieldAssociation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$ScopedControlPrefixCopyWith<$Res>? get prefix {
    if (_self.prefix == null) {
    return null;
  }

  return $ScopedControlPrefixCopyWith<$Res>(_self.prefix!, (value) {
    return _then(_self.copyWith(prefix: value));
  });
}
}

/// @nodoc
mixin _$ScopedControlPrefix {

 skir.PresentationNode get node; PortablePresentationScope get scope;
/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScopedControlPrefixCopyWith<ScopedControlPrefix> get copyWith => _$ScopedControlPrefixCopyWithImpl<ScopedControlPrefix>(this as ScopedControlPrefix, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ScopedControlPrefix;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScopedControlPrefix&&(identical(other.node, _this.node) || other.node == _this.node)&&(identical(other.scope, _this.scope) || other.scope == _this.scope));
}


@override
int get hashCode {
  final _this = this as ScopedControlPrefix;
  return Object.hash(runtimeType,_this.node,_this.scope);
}

@override
String toString() {
  final _this = this as ScopedControlPrefix;
  return 'ScopedControlPrefix(node: ${_this.node}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class $ScopedControlPrefixCopyWith<$Res>  {
  factory $ScopedControlPrefixCopyWith(ScopedControlPrefix value, $Res Function(ScopedControlPrefix) _then) = _$ScopedControlPrefixCopyWithImpl;
@useResult
$Res call({
 skir.PresentationNode node, PortablePresentationScope scope
});


$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$ScopedControlPrefixCopyWithImpl<$Res>
    implements $ScopedControlPrefixCopyWith<$Res> {
  _$ScopedControlPrefixCopyWithImpl(this._self, this._then);

  final ScopedControlPrefix _self;
  final $Res Function(ScopedControlPrefix) _then;

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? node = null,Object? scope = null,}) {
  return _then(ScopedControlPrefix(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}
/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {

  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern matching related methods to [ScopedControlPrefix].
extension ScopedControlPrefixPatterns on ScopedControlPrefix {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScopedControlPrefix value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScopedControlPrefix value)  $default,){
final _that = this;
switch (_that) {
case _ScopedControlPrefix():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScopedControlPrefix value)?  $default,){
final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationNode node,  PortablePresentationScope scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
return $default(_that.node,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationNode node,  PortablePresentationScope scope)  $default,) {final _that = this;
switch (_that) {
case _ScopedControlPrefix():
return $default(_that.node,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationNode node,  PortablePresentationScope scope)?  $default,) {final _that = this;
switch (_that) {
case _ScopedControlPrefix() when $default != null:
return $default(_that.node,_that.scope);case _:
  return null;

}
}

}

/// @nodoc


class _ScopedControlPrefix extends ScopedControlPrefix {
  const _ScopedControlPrefix({required this.node, required this.scope}): super._();


@override final  skir.PresentationNode node;
@override final  PortablePresentationScope scope;

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScopedControlPrefixCopyWith<_ScopedControlPrefix> get copyWith => __$ScopedControlPrefixCopyWithImpl<_ScopedControlPrefix>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScopedControlPrefix&&(identical(other.node, node) || other.node == node)&&(identical(other.scope, scope) || other.scope == scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,node,scope);
}

@override
String toString() {
    return 'ScopedControlPrefix(node: $node, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$ScopedControlPrefixCopyWith<$Res> implements $ScopedControlPrefixCopyWith<$Res> {
  factory _$ScopedControlPrefixCopyWith(_ScopedControlPrefix value, $Res Function(_ScopedControlPrefix) _then) = __$ScopedControlPrefixCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationNode node, PortablePresentationScope scope
});


@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$ScopedControlPrefixCopyWithImpl<$Res>
    implements _$ScopedControlPrefixCopyWith<$Res> {
  __$ScopedControlPrefixCopyWithImpl(this._self, this._then);

  final _ScopedControlPrefix _self;
  final $Res Function(_ScopedControlPrefix) _then;

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? node = null,Object? scope = null,}) {
  return _then(_ScopedControlPrefix(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as skir.PresentationNode,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}

/// Create a copy of ScopedControlPrefix
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {

  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$PortableRecordFieldOwner {

 skir.TypeSelection get type; String get field; AuthoredBindingAddress get address; PortablePresentationScope get scope;
/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableRecordFieldOwnerCopyWith<PortableRecordFieldOwner> get copyWith => _$PortableRecordFieldOwnerCopyWithImpl<PortableRecordFieldOwner>(this as PortableRecordFieldOwner, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableRecordFieldOwner;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableRecordFieldOwner&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.field, _this.field) || other.field == _this.field)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.scope, _this.scope) || other.scope == _this.scope));
}


@override
int get hashCode {
  final _this = this as PortableRecordFieldOwner;
  return Object.hash(runtimeType,_this.type,_this.field,_this.address,_this.scope);
}

@override
String toString() {
  final _this = this as PortableRecordFieldOwner;
  return 'PortableRecordFieldOwner(type: ${_this.type}, field: ${_this.field}, address: ${_this.address}, scope: ${_this.scope})';
}


}

/// @nodoc
abstract mixin class $PortableRecordFieldOwnerCopyWith<$Res>  {
  factory $PortableRecordFieldOwnerCopyWith(PortableRecordFieldOwner value, $Res Function(PortableRecordFieldOwner) _then) = _$PortableRecordFieldOwnerCopyWithImpl;
@useResult
$Res call({
 skir.TypeSelection type, String field, AuthoredBindingAddress address, PortablePresentationScope scope
});


$AuthoredBindingAddressCopyWith<$Res> get address;$PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class _$PortableRecordFieldOwnerCopyWithImpl<$Res>
    implements $PortableRecordFieldOwnerCopyWith<$Res> {
  _$PortableRecordFieldOwnerCopyWithImpl(this._self, this._then);

  final PortableRecordFieldOwner _self;
  final $Res Function(PortableRecordFieldOwner) _then;

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? field = null,Object? address = null,Object? scope = null,}) {
  return _then(PortableRecordFieldOwner(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}
/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get address {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {

  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}


/// Adds pattern matching related methods to [PortableRecordFieldOwner].
extension PortableRecordFieldOwnerPatterns on PortableRecordFieldOwner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableRecordFieldOwner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableRecordFieldOwner value)  $default,){
final _that = this;
switch (_that) {
case _PortableRecordFieldOwner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableRecordFieldOwner value)?  $default,){
final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.TypeSelection type,  String field,  AuthoredBindingAddress address,  PortablePresentationScope scope)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
return $default(_that.type,_that.field,_that.address,_that.scope);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.TypeSelection type,  String field,  AuthoredBindingAddress address,  PortablePresentationScope scope)  $default,) {final _that = this;
switch (_that) {
case _PortableRecordFieldOwner():
return $default(_that.type,_that.field,_that.address,_that.scope);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.TypeSelection type,  String field,  AuthoredBindingAddress address,  PortablePresentationScope scope)?  $default,) {final _that = this;
switch (_that) {
case _PortableRecordFieldOwner() when $default != null:
return $default(_that.type,_that.field,_that.address,_that.scope);case _:
  return null;

}
}

}

/// @nodoc


class _PortableRecordFieldOwner implements PortableRecordFieldOwner {
  const _PortableRecordFieldOwner({required this.type, required this.field, required this.address, required this.scope});


@override final  skir.TypeSelection type;
@override final  String field;
@override final  AuthoredBindingAddress address;
@override final  PortablePresentationScope scope;

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableRecordFieldOwnerCopyWith<_PortableRecordFieldOwner> get copyWith => __$PortableRecordFieldOwnerCopyWithImpl<_PortableRecordFieldOwner>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableRecordFieldOwner&&(identical(other.type, type) || other.type == type)&&(identical(other.field, field) || other.field == field)&&(identical(other.address, address) || other.address == address)&&(identical(other.scope, scope) || other.scope == scope));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,field,address,scope);
}

@override
String toString() {
    return 'PortableRecordFieldOwner(type: $type, field: $field, address: $address, scope: $scope)';
}


}

/// @nodoc
abstract mixin class _$PortableRecordFieldOwnerCopyWith<$Res> implements $PortableRecordFieldOwnerCopyWith<$Res> {
  factory _$PortableRecordFieldOwnerCopyWith(_PortableRecordFieldOwner value, $Res Function(_PortableRecordFieldOwner) _then) = __$PortableRecordFieldOwnerCopyWithImpl;
@override @useResult
$Res call({
 skir.TypeSelection type, String field, AuthoredBindingAddress address, PortablePresentationScope scope
});


@override $AuthoredBindingAddressCopyWith<$Res> get address;@override $PortablePresentationScopeCopyWith<$Res> get scope;

}
/// @nodoc
class __$PortableRecordFieldOwnerCopyWithImpl<$Res>
    implements _$PortableRecordFieldOwnerCopyWith<$Res> {
  __$PortableRecordFieldOwnerCopyWithImpl(this._self, this._then);

  final _PortableRecordFieldOwner _self;
  final $Res Function(_PortableRecordFieldOwner) _then;

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? field = null,Object? address = null,Object? scope = null,}) {
  return _then(_PortableRecordFieldOwner(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PortablePresentationScope,
  ));
}

/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get address {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of PortableRecordFieldOwner
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<$Res> get scope {

  return $PortablePresentationScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}
}

/// @nodoc
mixin _$ActiveFieldPresentation {

 EditorFieldPresentationIdentity get identity; AuthoredBindingAddress get owner;
/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveFieldPresentationCopyWith<ActiveFieldPresentation> get copyWith => _$ActiveFieldPresentationCopyWithImpl<ActiveFieldPresentation>(this as ActiveFieldPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActiveFieldPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveFieldPresentation&&(identical(other.identity, _this.identity) || other.identity == _this.identity)&&(identical(other.owner, _this.owner) || other.owner == _this.owner));
}


@override
int get hashCode {
  final _this = this as ActiveFieldPresentation;
  return Object.hash(runtimeType,_this.identity,_this.owner);
}

@override
String toString() {
  final _this = this as ActiveFieldPresentation;
  return 'ActiveFieldPresentation(identity: ${_this.identity}, owner: ${_this.owner})';
}


}

/// @nodoc
abstract mixin class $ActiveFieldPresentationCopyWith<$Res>  {
  factory $ActiveFieldPresentationCopyWith(ActiveFieldPresentation value, $Res Function(ActiveFieldPresentation) _then) = _$ActiveFieldPresentationCopyWithImpl;
@useResult
$Res call({
 EditorFieldPresentationIdentity identity, AuthoredBindingAddress owner
});


$EditorFieldPresentationIdentityCopyWith<$Res> get identity;$AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class _$ActiveFieldPresentationCopyWithImpl<$Res>
    implements $ActiveFieldPresentationCopyWith<$Res> {
  _$ActiveFieldPresentationCopyWithImpl(this._self, this._then);

  final ActiveFieldPresentation _self;
  final $Res Function(ActiveFieldPresentation) _then;

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identity = null,Object? owner = null,}) {
  return _then(ActiveFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}
/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {

  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern matching related methods to [ActiveFieldPresentation].
extension ActiveFieldPresentationPatterns on ActiveFieldPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveFieldPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveFieldPresentation value)  $default,){
final _that = this;
switch (_that) {
case _ActiveFieldPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveFieldPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EditorFieldPresentationIdentity identity,  AuthoredBindingAddress owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
return $default(_that.identity,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EditorFieldPresentationIdentity identity,  AuthoredBindingAddress owner)  $default,) {final _that = this;
switch (_that) {
case _ActiveFieldPresentation():
return $default(_that.identity,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EditorFieldPresentationIdentity identity,  AuthoredBindingAddress owner)?  $default,) {final _that = this;
switch (_that) {
case _ActiveFieldPresentation() when $default != null:
return $default(_that.identity,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveFieldPresentation implements ActiveFieldPresentation {
  const _ActiveFieldPresentation({required this.identity, required this.owner});


@override final  EditorFieldPresentationIdentity identity;
@override final  AuthoredBindingAddress owner;

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveFieldPresentationCopyWith<_ActiveFieldPresentation> get copyWith => __$ActiveFieldPresentationCopyWithImpl<_ActiveFieldPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveFieldPresentation&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,identity,owner);
}

@override
String toString() {
    return 'ActiveFieldPresentation(identity: $identity, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$ActiveFieldPresentationCopyWith<$Res> implements $ActiveFieldPresentationCopyWith<$Res> {
  factory _$ActiveFieldPresentationCopyWith(_ActiveFieldPresentation value, $Res Function(_ActiveFieldPresentation) _then) = __$ActiveFieldPresentationCopyWithImpl;
@override @useResult
$Res call({
 EditorFieldPresentationIdentity identity, AuthoredBindingAddress owner
});


@override $EditorFieldPresentationIdentityCopyWith<$Res> get identity;@override $AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$ActiveFieldPresentationCopyWithImpl<$Res>
    implements _$ActiveFieldPresentationCopyWith<$Res> {
  __$ActiveFieldPresentationCopyWithImpl(this._self, this._then);

  final _ActiveFieldPresentation _self;
  final $Res Function(_ActiveFieldPresentation) _then;

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? owner = null,}) {
  return _then(_ActiveFieldPresentation(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as EditorFieldPresentationIdentity,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}

/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$EditorFieldPresentationIdentityCopyWith<$Res> get identity {

  return $EditorFieldPresentationIdentityCopyWith<$Res>(_self.identity, (value) {
    return _then(_self.copyWith(identity: value));
  });
}/// Create a copy of ActiveFieldPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$PortableAuthoredPart {

 String get nodeId; skir.PresentationPartElement get part; AuthoredBindingAddress? get owner;
/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableAuthoredPartCopyWith<PortableAuthoredPart> get copyWith => _$PortableAuthoredPartCopyWithImpl<PortableAuthoredPart>(this as PortableAuthoredPart, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableAuthoredPart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableAuthoredPart&&(identical(other.nodeId, _this.nodeId) || other.nodeId == _this.nodeId)&&(identical(other.part, _this.part) || other.part == _this.part)&&(identical(other.owner, _this.owner) || other.owner == _this.owner));
}


@override
int get hashCode {
  final _this = this as PortableAuthoredPart;
  return Object.hash(runtimeType,_this.nodeId,_this.part,_this.owner);
}

@override
String toString() {
  final _this = this as PortableAuthoredPart;
  return 'PortableAuthoredPart(nodeId: ${_this.nodeId}, part: ${_this.part}, owner: ${_this.owner})';
}


}

/// @nodoc
abstract mixin class $PortableAuthoredPartCopyWith<$Res>  {
  factory $PortableAuthoredPartCopyWith(PortableAuthoredPart value, $Res Function(PortableAuthoredPart) _then) = _$PortableAuthoredPartCopyWithImpl;
@useResult
$Res call({
 String nodeId, skir.PresentationPartElement part, AuthoredBindingAddress? owner
});


$AuthoredBindingAddressCopyWith<$Res>? get owner;

}
/// @nodoc
class _$PortableAuthoredPartCopyWithImpl<$Res>
    implements $PortableAuthoredPartCopyWith<$Res> {
  _$PortableAuthoredPartCopyWithImpl(this._self, this._then);

  final PortableAuthoredPart _self;
  final $Res Function(PortableAuthoredPart) _then;

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodeId = null,Object? part = null,Object? owner = freezed,}) {
  return _then(PortableAuthoredPart(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartElement,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress?,
  ));
}
/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern matching related methods to [PortableAuthoredPart].
extension PortableAuthoredPartPatterns on PortableAuthoredPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableAuthoredPart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableAuthoredPart value)  $default,){
final _that = this;
switch (_that) {
case _PortableAuthoredPart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableAuthoredPart value)?  $default,){
final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nodeId,  skir.PresentationPartElement part,  AuthoredBindingAddress? owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
return $default(_that.nodeId,_that.part,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nodeId,  skir.PresentationPartElement part,  AuthoredBindingAddress? owner)  $default,) {final _that = this;
switch (_that) {
case _PortableAuthoredPart():
return $default(_that.nodeId,_that.part,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nodeId,  skir.PresentationPartElement part,  AuthoredBindingAddress? owner)?  $default,) {final _that = this;
switch (_that) {
case _PortableAuthoredPart() when $default != null:
return $default(_that.nodeId,_that.part,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _PortableAuthoredPart implements PortableAuthoredPart {
  const _PortableAuthoredPart({required this.nodeId, required this.part, required this.owner});


@override final  String nodeId;
@override final  skir.PresentationPartElement part;
@override final  AuthoredBindingAddress? owner;

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableAuthoredPartCopyWith<_PortableAuthoredPart> get copyWith => __$PortableAuthoredPartCopyWithImpl<_PortableAuthoredPart>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableAuthoredPart&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.part, part) || other.part == part)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nodeId,part,owner);
}

@override
String toString() {
    return 'PortableAuthoredPart(nodeId: $nodeId, part: $part, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$PortableAuthoredPartCopyWith<$Res> implements $PortableAuthoredPartCopyWith<$Res> {
  factory _$PortableAuthoredPartCopyWith(_PortableAuthoredPart value, $Res Function(_PortableAuthoredPart) _then) = __$PortableAuthoredPartCopyWithImpl;
@override @useResult
$Res call({
 String nodeId, skir.PresentationPartElement part, AuthoredBindingAddress? owner
});


@override $AuthoredBindingAddressCopyWith<$Res>? get owner;

}
/// @nodoc
class __$PortableAuthoredPartCopyWithImpl<$Res>
    implements _$PortableAuthoredPartCopyWith<$Res> {
  __$PortableAuthoredPartCopyWithImpl(this._self, this._then);

  final _PortableAuthoredPart _self;
  final $Res Function(_PortableAuthoredPart) _then;

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodeId = null,Object? part = null,Object? owner = freezed,}) {
  return _then(_PortableAuthoredPart(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartElement,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress?,
  ));
}

/// Create a copy of PortableAuthoredPart
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$PortableInspectorClaims {

 Set<String> get editedFields; Set<String> get reservedFields; Set<String> get excludedFields; Set<skir.PresentationPartId> get parts; Map<String, String> get problems;
/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableInspectorClaimsCopyWith<PortableInspectorClaims> get copyWith => _$PortableInspectorClaimsCopyWithImpl<PortableInspectorClaims>(this as PortableInspectorClaims, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableInspectorClaims;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableInspectorClaims&&const DeepCollectionEquality().equals(other.editedFields, _this.editedFields)&&const DeepCollectionEquality().equals(other.reservedFields, _this.reservedFields)&&const DeepCollectionEquality().equals(other.excludedFields, _this.excludedFields)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&const DeepCollectionEquality().equals(other.problems, _this.problems));
}


@override
int get hashCode {
  final _this = this as PortableInspectorClaims;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.editedFields),const DeepCollectionEquality().hash(_this.reservedFields),const DeepCollectionEquality().hash(_this.excludedFields),const DeepCollectionEquality().hash(_this.parts),const DeepCollectionEquality().hash(_this.problems));
}

@override
String toString() {
  final _this = this as PortableInspectorClaims;
  return 'PortableInspectorClaims(editedFields: ${_this.editedFields}, reservedFields: ${_this.reservedFields}, excludedFields: ${_this.excludedFields}, parts: ${_this.parts}, problems: ${_this.problems})';
}


}

/// @nodoc
abstract mixin class $PortableInspectorClaimsCopyWith<$Res>  {
  factory $PortableInspectorClaimsCopyWith(PortableInspectorClaims value, $Res Function(PortableInspectorClaims) _then) = _$PortableInspectorClaimsCopyWithImpl;
@useResult
$Res call({
 Set<String> editedFields, Set<String> reservedFields, Set<String> excludedFields, Set<skir.PresentationPartId> parts, Map<String, String> problems
});




}
/// @nodoc
class _$PortableInspectorClaimsCopyWithImpl<$Res>
    implements $PortableInspectorClaimsCopyWith<$Res> {
  _$PortableInspectorClaimsCopyWithImpl(this._self, this._then);

  final PortableInspectorClaims _self;
  final $Res Function(PortableInspectorClaims) _then;

/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? editedFields = null,Object? reservedFields = null,Object? excludedFields = null,Object? parts = null,Object? problems = null,}) {
  return _then(PortableInspectorClaims(
editedFields: null == editedFields ? _self.editedFields : editedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,reservedFields: null == reservedFields ? _self.reservedFields : reservedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedFields: null == excludedFields ? _self.excludedFields : excludedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationPartId>,problems: null == problems ? _self.problems : problems // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern matching related methods to [PortableInspectorClaims].
extension PortableInspectorClaimsPatterns on PortableInspectorClaims {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableInspectorClaims value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableInspectorClaims value)  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorClaims():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableInspectorClaims value)?  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> editedFields,  Set<String> reservedFields,  Set<String> excludedFields,  Set<skir.PresentationPartId> parts,  Map<String, String> problems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
return $default(_that.editedFields,_that.reservedFields,_that.excludedFields,_that.parts,_that.problems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> editedFields,  Set<String> reservedFields,  Set<String> excludedFields,  Set<skir.PresentationPartId> parts,  Map<String, String> problems)  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorClaims():
return $default(_that.editedFields,_that.reservedFields,_that.excludedFields,_that.parts,_that.problems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> editedFields,  Set<String> reservedFields,  Set<String> excludedFields,  Set<skir.PresentationPartId> parts,  Map<String, String> problems)?  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorClaims() when $default != null:
return $default(_that.editedFields,_that.reservedFields,_that.excludedFields,_that.parts,_that.problems);case _:
  return null;

}
}

}

/// @nodoc


class _PortableInspectorClaims implements PortableInspectorClaims {
  const _PortableInspectorClaims({ Set<String> editedFields = const {},  Set<String> reservedFields = const {},  Set<String> excludedFields = const {},  Set<skir.PresentationPartId> parts = const {},  Map<String, String> problems = const {}}): _editedFields = editedFields,_reservedFields = reservedFields,_excludedFields = excludedFields,_parts = parts,_problems = problems;


 final  Set<String> _editedFields;
@override@JsonKey() Set<String> get editedFields {
  if (_editedFields is EqualUnmodifiableSetView) return _editedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_editedFields);
}

 final  Set<String> _reservedFields;
@override@JsonKey() Set<String> get reservedFields {
  if (_reservedFields is EqualUnmodifiableSetView) return _reservedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_reservedFields);
}

 final  Set<String> _excludedFields;
@override@JsonKey() Set<String> get excludedFields {
  if (_excludedFields is EqualUnmodifiableSetView) return _excludedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_excludedFields);
}

 final  Set<skir.PresentationPartId> _parts;
@override@JsonKey() Set<skir.PresentationPartId> get parts {
  if (_parts is EqualUnmodifiableSetView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_parts);
}

 final  Map<String, String> _problems;
@override@JsonKey() Map<String, String> get problems {
  if (_problems is EqualUnmodifiableMapView) return _problems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_problems);
}


/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableInspectorClaimsCopyWith<_PortableInspectorClaims> get copyWith => __$PortableInspectorClaimsCopyWithImpl<_PortableInspectorClaims>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableInspectorClaims&&const DeepCollectionEquality().equals(other.editedFields, _editedFields)&&const DeepCollectionEquality().equals(other.reservedFields, _reservedFields)&&const DeepCollectionEquality().equals(other.excludedFields, _excludedFields)&&const DeepCollectionEquality().equals(other.parts, _parts)&&const DeepCollectionEquality().equals(other.problems, _problems));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_editedFields),const DeepCollectionEquality().hash(_reservedFields),const DeepCollectionEquality().hash(_excludedFields),const DeepCollectionEquality().hash(_parts),const DeepCollectionEquality().hash(_problems));
}

@override
String toString() {
    return 'PortableInspectorClaims(editedFields: $editedFields, reservedFields: $reservedFields, excludedFields: $excludedFields, parts: $parts, problems: $problems)';
}


}

/// @nodoc
abstract mixin class _$PortableInspectorClaimsCopyWith<$Res> implements $PortableInspectorClaimsCopyWith<$Res> {
  factory _$PortableInspectorClaimsCopyWith(_PortableInspectorClaims value, $Res Function(_PortableInspectorClaims) _then) = __$PortableInspectorClaimsCopyWithImpl;
@override @useResult
$Res call({
 Set<String> editedFields, Set<String> reservedFields, Set<String> excludedFields, Set<skir.PresentationPartId> parts, Map<String, String> problems
});




}
/// @nodoc
class __$PortableInspectorClaimsCopyWithImpl<$Res>
    implements _$PortableInspectorClaimsCopyWith<$Res> {
  __$PortableInspectorClaimsCopyWithImpl(this._self, this._then);

  final _PortableInspectorClaims _self;
  final $Res Function(_PortableInspectorClaims) _then;

/// Create a copy of PortableInspectorClaims
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? editedFields = null,Object? reservedFields = null,Object? excludedFields = null,Object? parts = null,Object? problems = null,}) {
  return _then(_PortableInspectorClaims(
editedFields: null == editedFields ? _self._editedFields : editedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,reservedFields: null == reservedFields ? _self._reservedFields : reservedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedFields: null == excludedFields ? _self._excludedFields : excludedFields // ignore: cast_nullable_to_non_nullable
as Set<String>,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationPartId>,problems: null == problems ? _self._problems : problems // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc
mixin _$PortableInspectorFrame {

 AuthoredBindingAddress get owner; skir.TypeSelection get actualType; skir.PresentationTarget get sourceTarget; skir.PresentationId get source; PortableInspectorClaims get higher;
/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableInspectorFrameCopyWith<PortableInspectorFrame> get copyWith => _$PortableInspectorFrameCopyWithImpl<PortableInspectorFrame>(this as PortableInspectorFrame, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortableInspectorFrame;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableInspectorFrame&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.actualType, _this.actualType) || other.actualType == _this.actualType)&&(identical(other.sourceTarget, _this.sourceTarget) || other.sourceTarget == _this.sourceTarget)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.higher, _this.higher) || other.higher == _this.higher));
}


@override
int get hashCode {
  final _this = this as PortableInspectorFrame;
  return Object.hash(runtimeType,_this.owner,_this.actualType,_this.sourceTarget,_this.source,_this.higher);
}

@override
String toString() {
  final _this = this as PortableInspectorFrame;
  return 'PortableInspectorFrame(owner: ${_this.owner}, actualType: ${_this.actualType}, sourceTarget: ${_this.sourceTarget}, source: ${_this.source}, higher: ${_this.higher})';
}


}

/// @nodoc
abstract mixin class $PortableInspectorFrameCopyWith<$Res>  {
  factory $PortableInspectorFrameCopyWith(PortableInspectorFrame value, $Res Function(PortableInspectorFrame) _then) = _$PortableInspectorFrameCopyWithImpl;
@useResult
$Res call({
 AuthoredBindingAddress owner, skir.TypeSelection actualType, skir.PresentationTarget sourceTarget, skir.PresentationId source, PortableInspectorClaims higher
});


$AuthoredBindingAddressCopyWith<$Res> get owner;$PortableInspectorClaimsCopyWith<$Res> get higher;

}
/// @nodoc
class _$PortableInspectorFrameCopyWithImpl<$Res>
    implements $PortableInspectorFrameCopyWith<$Res> {
  _$PortableInspectorFrameCopyWithImpl(this._self, this._then);

  final PortableInspectorFrame _self;
  final $Res Function(PortableInspectorFrame) _then;

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? actualType = null,Object? sourceTarget = null,Object? source = null,Object? higher = null,}) {
  return _then(PortableInspectorFrame(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,actualType: null == actualType ? _self.actualType : actualType // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,sourceTarget: null == sourceTarget ? _self.sourceTarget : sourceTarget // ignore: cast_nullable_to_non_nullable
as skir.PresentationTarget,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,higher: null == higher ? _self.higher : higher // ignore: cast_nullable_to_non_nullable
as PortableInspectorClaims,
  ));
}
/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorClaimsCopyWith<$Res> get higher {

  return $PortableInspectorClaimsCopyWith<$Res>(_self.higher, (value) {
    return _then(_self.copyWith(higher: value));
  });
}
}


/// Adds pattern matching related methods to [PortableInspectorFrame].
extension PortableInspectorFramePatterns on PortableInspectorFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortableInspectorFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortableInspectorFrame value)  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortableInspectorFrame value)?  $default,){
final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoredBindingAddress owner,  skir.TypeSelection actualType,  skir.PresentationTarget sourceTarget,  skir.PresentationId source,  PortableInspectorClaims higher)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
return $default(_that.owner,_that.actualType,_that.sourceTarget,_that.source,_that.higher);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoredBindingAddress owner,  skir.TypeSelection actualType,  skir.PresentationTarget sourceTarget,  skir.PresentationId source,  PortableInspectorClaims higher)  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorFrame():
return $default(_that.owner,_that.actualType,_that.sourceTarget,_that.source,_that.higher);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoredBindingAddress owner,  skir.TypeSelection actualType,  skir.PresentationTarget sourceTarget,  skir.PresentationId source,  PortableInspectorClaims higher)?  $default,) {final _that = this;
switch (_that) {
case _PortableInspectorFrame() when $default != null:
return $default(_that.owner,_that.actualType,_that.sourceTarget,_that.source,_that.higher);case _:
  return null;

}
}

}

/// @nodoc


class _PortableInspectorFrame implements PortableInspectorFrame {
  const _PortableInspectorFrame({required this.owner, required this.actualType, required this.sourceTarget, required this.source, this.higher = const PortableInspectorClaims()});


@override final  AuthoredBindingAddress owner;
@override final  skir.TypeSelection actualType;
@override final  skir.PresentationTarget sourceTarget;
@override final  skir.PresentationId source;
@override@JsonKey() final  PortableInspectorClaims higher;

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortableInspectorFrameCopyWith<_PortableInspectorFrame> get copyWith => __$PortableInspectorFrameCopyWithImpl<_PortableInspectorFrame>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortableInspectorFrame&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.actualType, actualType) || other.actualType == actualType)&&(identical(other.sourceTarget, sourceTarget) || other.sourceTarget == sourceTarget)&&(identical(other.source, source) || other.source == source)&&(identical(other.higher, higher) || other.higher == higher));
}


@override
int get hashCode {
    return Object.hash(runtimeType,owner,actualType,sourceTarget,source,higher);
}

@override
String toString() {
    return 'PortableInspectorFrame(owner: $owner, actualType: $actualType, sourceTarget: $sourceTarget, source: $source, higher: $higher)';
}


}

/// @nodoc
abstract mixin class _$PortableInspectorFrameCopyWith<$Res> implements $PortableInspectorFrameCopyWith<$Res> {
  factory _$PortableInspectorFrameCopyWith(_PortableInspectorFrame value, $Res Function(_PortableInspectorFrame) _then) = __$PortableInspectorFrameCopyWithImpl;
@override @useResult
$Res call({
 AuthoredBindingAddress owner, skir.TypeSelection actualType, skir.PresentationTarget sourceTarget, skir.PresentationId source, PortableInspectorClaims higher
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;@override $PortableInspectorClaimsCopyWith<$Res> get higher;

}
/// @nodoc
class __$PortableInspectorFrameCopyWithImpl<$Res>
    implements _$PortableInspectorFrameCopyWith<$Res> {
  __$PortableInspectorFrameCopyWithImpl(this._self, this._then);

  final _PortableInspectorFrame _self;
  final $Res Function(_PortableInspectorFrame) _then;

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? actualType = null,Object? sourceTarget = null,Object? source = null,Object? higher = null,}) {
  return _then(_PortableInspectorFrame(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,actualType: null == actualType ? _self.actualType : actualType // ignore: cast_nullable_to_non_nullable
as skir.TypeSelection,sourceTarget: null == sourceTarget ? _self.sourceTarget : sourceTarget // ignore: cast_nullable_to_non_nullable
as skir.PresentationTarget,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,higher: null == higher ? _self.higher : higher // ignore: cast_nullable_to_non_nullable
as PortableInspectorClaims,
  ));
}

/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of PortableInspectorFrame
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorClaimsCopyWith<$Res> get higher {

  return $PortableInspectorClaimsCopyWith<$Res>(_self.higher, (value) {
    return _then(_self.copyWith(higher: value));
  });
}
}

/// @nodoc
mixin _$ActiveInspectorLayout {

 skir.PresentationId get source; AuthoredBindingAddress get owner;
/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveInspectorLayoutCopyWith<ActiveInspectorLayout> get copyWith => _$ActiveInspectorLayoutCopyWithImpl<ActiveInspectorLayout>(this as ActiveInspectorLayout, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActiveInspectorLayout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveInspectorLayout&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.owner, _this.owner) || other.owner == _this.owner));
}


@override
int get hashCode {
  final _this = this as ActiveInspectorLayout;
  return Object.hash(runtimeType,_this.source,_this.owner);
}

@override
String toString() {
  final _this = this as ActiveInspectorLayout;
  return 'ActiveInspectorLayout(source: ${_this.source}, owner: ${_this.owner})';
}


}

/// @nodoc
abstract mixin class $ActiveInspectorLayoutCopyWith<$Res>  {
  factory $ActiveInspectorLayoutCopyWith(ActiveInspectorLayout value, $Res Function(ActiveInspectorLayout) _then) = _$ActiveInspectorLayoutCopyWithImpl;
@useResult
$Res call({
 skir.PresentationId source, AuthoredBindingAddress owner
});


$AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class _$ActiveInspectorLayoutCopyWithImpl<$Res>
    implements $ActiveInspectorLayoutCopyWith<$Res> {
  _$ActiveInspectorLayoutCopyWithImpl(this._self, this._then);

  final ActiveInspectorLayout _self;
  final $Res Function(ActiveInspectorLayout) _then;

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? owner = null,}) {
  return _then(ActiveInspectorLayout(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}
/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern matching related methods to [ActiveInspectorLayout].
extension ActiveInspectorLayoutPatterns on ActiveInspectorLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveInspectorLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveInspectorLayout value)  $default,){
final _that = this;
switch (_that) {
case _ActiveInspectorLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveInspectorLayout value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationId source,  AuthoredBindingAddress owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
return $default(_that.source,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationId source,  AuthoredBindingAddress owner)  $default,) {final _that = this;
switch (_that) {
case _ActiveInspectorLayout():
return $default(_that.source,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationId source,  AuthoredBindingAddress owner)?  $default,) {final _that = this;
switch (_that) {
case _ActiveInspectorLayout() when $default != null:
return $default(_that.source,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveInspectorLayout implements ActiveInspectorLayout {
  const _ActiveInspectorLayout({required this.source, required this.owner});


@override final  skir.PresentationId source;
@override final  AuthoredBindingAddress owner;

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveInspectorLayoutCopyWith<_ActiveInspectorLayout> get copyWith => __$ActiveInspectorLayoutCopyWithImpl<_ActiveInspectorLayout>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveInspectorLayout&&(identical(other.source, source) || other.source == source)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,source,owner);
}

@override
String toString() {
    return 'ActiveInspectorLayout(source: $source, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$ActiveInspectorLayoutCopyWith<$Res> implements $ActiveInspectorLayoutCopyWith<$Res> {
  factory _$ActiveInspectorLayoutCopyWith(_ActiveInspectorLayout value, $Res Function(_ActiveInspectorLayout) _then) = __$ActiveInspectorLayoutCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationId source, AuthoredBindingAddress owner
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$ActiveInspectorLayoutCopyWithImpl<$Res>
    implements _$ActiveInspectorLayoutCopyWith<$Res> {
  __$ActiveInspectorLayoutCopyWithImpl(this._self, this._then);

  final _ActiveInspectorLayout _self;
  final $Res Function(_ActiveInspectorLayout) _then;

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? owner = null,}) {
  return _then(_ActiveInspectorLayout(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as skir.PresentationId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,
  ));
}

/// Create a copy of ActiveInspectorLayout
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$ActivePartPresentation {

 skir.PresentationPartId get key; AuthoredBindingAddress get owner; skir.PresentationRole get role;
/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePartPresentationCopyWith<ActivePartPresentation> get copyWith => _$ActivePartPresentationCopyWithImpl<ActivePartPresentation>(this as ActivePartPresentation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActivePartPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePartPresentation&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&(identical(other.role, _this.role) || other.role == _this.role));
}


@override
int get hashCode {
  final _this = this as ActivePartPresentation;
  return Object.hash(runtimeType,_this.key,_this.owner,_this.role);
}

@override
String toString() {
  final _this = this as ActivePartPresentation;
  return 'ActivePartPresentation(key: ${_this.key}, owner: ${_this.owner}, role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $ActivePartPresentationCopyWith<$Res>  {
  factory $ActivePartPresentationCopyWith(ActivePartPresentation value, $Res Function(ActivePartPresentation) _then) = _$ActivePartPresentationCopyWithImpl;
@useResult
$Res call({
 skir.PresentationPartId key, AuthoredBindingAddress owner, skir.PresentationRole role
});


$AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class _$ActivePartPresentationCopyWithImpl<$Res>
    implements $ActivePartPresentationCopyWith<$Res> {
  _$ActivePartPresentationCopyWithImpl(this._self, this._then);

  final ActivePartPresentation _self;
  final $Res Function(ActivePartPresentation) _then;

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? owner = null,Object? role = null,}) {
  return _then(ActivePartPresentation(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole,
  ));
}
/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern matching related methods to [ActivePartPresentation].
extension ActivePartPresentationPatterns on ActivePartPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePartPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePartPresentation value)  $default,){
final _that = this;
switch (_that) {
case _ActivePartPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePartPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.PresentationPartId key,  AuthoredBindingAddress owner,  skir.PresentationRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
return $default(_that.key,_that.owner,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.PresentationPartId key,  AuthoredBindingAddress owner,  skir.PresentationRole role)  $default,) {final _that = this;
switch (_that) {
case _ActivePartPresentation():
return $default(_that.key,_that.owner,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.PresentationPartId key,  AuthoredBindingAddress owner,  skir.PresentationRole role)?  $default,) {final _that = this;
switch (_that) {
case _ActivePartPresentation() when $default != null:
return $default(_that.key,_that.owner,_that.role);case _:
  return null;

}
}

}

/// @nodoc


class _ActivePartPresentation implements ActivePartPresentation {
  const _ActivePartPresentation({required this.key, required this.owner, required this.role});


@override final  skir.PresentationPartId key;
@override final  AuthoredBindingAddress owner;
@override final  skir.PresentationRole role;

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePartPresentationCopyWith<_ActivePartPresentation> get copyWith => __$ActivePartPresentationCopyWithImpl<_ActivePartPresentation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePartPresentation&&(identical(other.key, key) || other.key == key)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.role, role) || other.role == role));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,owner,role);
}

@override
String toString() {
    return 'ActivePartPresentation(key: $key, owner: $owner, role: $role)';
}


}

/// @nodoc
abstract mixin class _$ActivePartPresentationCopyWith<$Res> implements $ActivePartPresentationCopyWith<$Res> {
  factory _$ActivePartPresentationCopyWith(_ActivePartPresentation value, $Res Function(_ActivePartPresentation) _then) = __$ActivePartPresentationCopyWithImpl;
@override @useResult
$Res call({
 skir.PresentationPartId key, AuthoredBindingAddress owner, skir.PresentationRole role
});


@override $AuthoredBindingAddressCopyWith<$Res> get owner;

}
/// @nodoc
class __$ActivePartPresentationCopyWithImpl<$Res>
    implements _$ActivePartPresentationCopyWith<$Res> {
  __$ActivePartPresentationCopyWithImpl(this._self, this._then);

  final _ActivePartPresentation _self;
  final $Res Function(_ActivePartPresentation) _then;

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? owner = null,Object? role = null,}) {
  return _then(_ActivePartPresentation(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as skir.PresentationPartId,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as AuthoredBindingAddress,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole,
  ));
}

/// Create a copy of ActivePartPresentation
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredBindingAddressCopyWith<$Res> get owner {

  return $AuthoredBindingAddressCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

/// @nodoc
mixin _$AuthoredLinkDecision {

 PortableLinkPlan get plan; PortableLinkTargetChoice get target; PortableLinkCounterpartRequest get counterpart;
/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredLinkDecisionCopyWith<_AuthoredLinkDecision> get copyWith => __$AuthoredLinkDecisionCopyWithImpl<_AuthoredLinkDecision>(this as _AuthoredLinkDecision, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _AuthoredLinkDecision;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredLinkDecision&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.counterpart, _this.counterpart) || other.counterpart == _this.counterpart));
}


@override
int get hashCode {
  final _this = this as _AuthoredLinkDecision;
  return Object.hash(runtimeType,_this.plan,_this.target,_this.counterpart);
}

@override
String toString() {
  final _this = this as _AuthoredLinkDecision;
  return '_AuthoredLinkDecision(plan: ${_this.plan}, target: ${_this.target}, counterpart: ${_this.counterpart})';
}


}

/// @nodoc
abstract mixin class _$AuthoredLinkDecisionCopyWith<$Res>  {
  factory _$AuthoredLinkDecisionCopyWith(_AuthoredLinkDecision value, $Res Function(_AuthoredLinkDecision) _then) = __$AuthoredLinkDecisionCopyWithImpl;
@useResult
$Res call({
 PortableLinkPlan plan, PortableLinkTargetChoice target, PortableLinkCounterpartRequest counterpart
});


$PortableLinkPlanCopyWith<$Res> get plan;$PortableLinkTargetChoiceCopyWith<$Res> get target;$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart;

}
/// @nodoc
class __$AuthoredLinkDecisionCopyWithImpl<$Res>
    implements _$AuthoredLinkDecisionCopyWith<$Res> {
  __$AuthoredLinkDecisionCopyWithImpl(this._self, this._then);

  final _AuthoredLinkDecision _self;
  final $Res Function(_AuthoredLinkDecision) _then;

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? target = null,Object? counterpart = null,}) {
  return _then(_AuthoredLinkDecision(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,counterpart: null == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PortableLinkCounterpartRequest,
  ));
}
/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {

  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {

  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart {

  return $PortableLinkCounterpartRequestCopyWith<$Res>(_self.counterpart, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}
}


/// Adds pattern matching related methods to [_AuthoredLinkDecision].
extension _AuthoredLinkDecisionPatterns on _AuthoredLinkDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __AuthoredLinkDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __AuthoredLinkDecision value)  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkDecision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __AuthoredLinkDecision value)?  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
return $default(_that.plan,_that.target,_that.counterpart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart)  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkDecision():
return $default(_that.plan,_that.target,_that.counterpart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PortableLinkPlan plan,  PortableLinkTargetChoice target,  PortableLinkCounterpartRequest counterpart)?  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkDecision() when $default != null:
return $default(_that.plan,_that.target,_that.counterpart);case _:
  return null;

}
}

}

/// @nodoc


class __AuthoredLinkDecision implements _AuthoredLinkDecision {
  const __AuthoredLinkDecision({required this.plan, required this.target, required this.counterpart});


@override final  PortableLinkPlan plan;
@override final  PortableLinkTargetChoice target;
@override final  PortableLinkCounterpartRequest counterpart;

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_AuthoredLinkDecisionCopyWith<__AuthoredLinkDecision> get copyWith => __$_AuthoredLinkDecisionCopyWithImpl<__AuthoredLinkDecision>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __AuthoredLinkDecision&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.target, target) || other.target == target)&&(identical(other.counterpart, counterpart) || other.counterpart == counterpart));
}


@override
int get hashCode {
    return Object.hash(runtimeType,plan,target,counterpart);
}

@override
String toString() {
    return '_AuthoredLinkDecision(plan: $plan, target: $target, counterpart: $counterpart)';
}


}

/// @nodoc
abstract mixin class _$_AuthoredLinkDecisionCopyWith<$Res> implements _$AuthoredLinkDecisionCopyWith<$Res> {
  factory _$_AuthoredLinkDecisionCopyWith(__AuthoredLinkDecision value, $Res Function(__AuthoredLinkDecision) _then) = __$_AuthoredLinkDecisionCopyWithImpl;
@override @useResult
$Res call({
 PortableLinkPlan plan, PortableLinkTargetChoice target, PortableLinkCounterpartRequest counterpart
});


@override $PortableLinkPlanCopyWith<$Res> get plan;@override $PortableLinkTargetChoiceCopyWith<$Res> get target;@override $PortableLinkCounterpartRequestCopyWith<$Res> get counterpart;

}
/// @nodoc
class __$_AuthoredLinkDecisionCopyWithImpl<$Res>
    implements _$_AuthoredLinkDecisionCopyWith<$Res> {
  __$_AuthoredLinkDecisionCopyWithImpl(this._self, this._then);

  final __AuthoredLinkDecision _self;
  final $Res Function(__AuthoredLinkDecision) _then;

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? target = null,Object? counterpart = null,}) {
  return _then(__AuthoredLinkDecision(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,counterpart: null == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PortableLinkCounterpartRequest,
  ));
}

/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {

  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {

  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkDecision
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkCounterpartRequestCopyWith<$Res> get counterpart {

  return $PortableLinkCounterpartRequestCopyWith<$Res>(_self.counterpart, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}
}

/// @nodoc
mixin _$AuthoredLinkChoice {

 String get id; String get widgetKey; PortableLinkPlan get plan; PortableLinkTargetChoice get target; _AuthoredLinkChoiceKind get kind; String get label; String get typeLabel; String get subtitle; String get searchText; _AuthoredCollectionRow? get row; skir.PresentationCollectionDefinition? get definition; skir.LinkOccurrence? get occurrence; PortableNewCounterpartChoice? get slot; skir.ValueLocation? get collection; String? get disabledReason;
/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoredLinkChoiceCopyWith<_AuthoredLinkChoice> get copyWith => __$AuthoredLinkChoiceCopyWithImpl<_AuthoredLinkChoice>(this as _AuthoredLinkChoice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as _AuthoredLinkChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoredLinkChoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.widgetKey, _this.widgetKey) || other.widgetKey == _this.widgetKey)&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.typeLabel, _this.typeLabel) || other.typeLabel == _this.typeLabel)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.searchText, _this.searchText) || other.searchText == _this.searchText)&&(identical(other.row, _this.row) || other.row == _this.row)&&(identical(other.definition, _this.definition) || other.definition == _this.definition)&&(identical(other.occurrence, _this.occurrence) || other.occurrence == _this.occurrence)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.collection, _this.collection) || other.collection == _this.collection)&&(identical(other.disabledReason, _this.disabledReason) || other.disabledReason == _this.disabledReason));
}


@override
int get hashCode {
  final _this = this as _AuthoredLinkChoice;
  return Object.hash(runtimeType,_this.id,_this.widgetKey,_this.plan,_this.target,_this.kind,_this.label,_this.typeLabel,_this.subtitle,_this.searchText,_this.row,_this.definition,_this.occurrence,_this.slot,_this.collection,_this.disabledReason);
}

@override
String toString() {
  final _this = this as _AuthoredLinkChoice;
  return '_AuthoredLinkChoice(id: ${_this.id}, widgetKey: ${_this.widgetKey}, plan: ${_this.plan}, target: ${_this.target}, kind: ${_this.kind}, label: ${_this.label}, typeLabel: ${_this.typeLabel}, subtitle: ${_this.subtitle}, searchText: ${_this.searchText}, row: ${_this.row}, definition: ${_this.definition}, occurrence: ${_this.occurrence}, slot: ${_this.slot}, collection: ${_this.collection}, disabledReason: ${_this.disabledReason})';
}


}

/// @nodoc
abstract mixin class _$AuthoredLinkChoiceCopyWith<$Res>  {
  factory _$AuthoredLinkChoiceCopyWith(_AuthoredLinkChoice value, $Res Function(_AuthoredLinkChoice) _then) = __$AuthoredLinkChoiceCopyWithImpl;
@useResult
$Res call({
 String id, String widgetKey, PortableLinkPlan plan, PortableLinkTargetChoice target, _AuthoredLinkChoiceKind kind, String label, String typeLabel, String subtitle, String searchText, _AuthoredCollectionRow? row, skir.PresentationCollectionDefinition? definition, skir.LinkOccurrence? occurrence, PortableNewCounterpartChoice? slot, skir.ValueLocation? collection, String? disabledReason
});


$PortableLinkPlanCopyWith<$Res> get plan;$PortableLinkTargetChoiceCopyWith<$Res> get target;$PortableNewCounterpartChoiceCopyWith<$Res>? get slot;

}
/// @nodoc
class __$AuthoredLinkChoiceCopyWithImpl<$Res>
    implements _$AuthoredLinkChoiceCopyWith<$Res> {
  __$AuthoredLinkChoiceCopyWithImpl(this._self, this._then);

  final _AuthoredLinkChoice _self;
  final $Res Function(_AuthoredLinkChoice) _then;

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? widgetKey = null,Object? plan = null,Object? target = null,Object? kind = null,Object? label = null,Object? typeLabel = null,Object? subtitle = null,Object? searchText = null,Object? row = freezed,Object? definition = freezed,Object? occurrence = freezed,Object? slot = freezed,Object? collection = freezed,Object? disabledReason = freezed,}) {
  return _then(_AuthoredLinkChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,widgetKey: null == widgetKey ? _self.widgetKey : widgetKey // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as _AuthoredLinkChoiceKind,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,row: freezed == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as _AuthoredCollectionRow?,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.PresentationCollectionDefinition?,occurrence: freezed == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence?,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as PortableNewCounterpartChoice?,collection: freezed == collection ? _self.collection : collection // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {

  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {

  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<$Res>? get slot {
    if (_self.slot == null) {
    return null;
  }

  return $PortableNewCounterpartChoiceCopyWith<$Res>(_self.slot!, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}


/// Adds pattern matching related methods to [_AuthoredLinkChoice].
extension _AuthoredLinkChoicePatterns on _AuthoredLinkChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( __AuthoredLinkChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( __AuthoredLinkChoice value)  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( __AuthoredLinkChoice value)?  $default,){
final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String widgetKey,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  _AuthoredLinkChoiceKind kind,  String label,  String typeLabel,  String subtitle,  String searchText,  _AuthoredCollectionRow? row,  skir.PresentationCollectionDefinition? definition,  skir.LinkOccurrence? occurrence,  PortableNewCounterpartChoice? slot,  skir.ValueLocation? collection,  String? disabledReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
return $default(_that.id,_that.widgetKey,_that.plan,_that.target,_that.kind,_that.label,_that.typeLabel,_that.subtitle,_that.searchText,_that.row,_that.definition,_that.occurrence,_that.slot,_that.collection,_that.disabledReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String widgetKey,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  _AuthoredLinkChoiceKind kind,  String label,  String typeLabel,  String subtitle,  String searchText,  _AuthoredCollectionRow? row,  skir.PresentationCollectionDefinition? definition,  skir.LinkOccurrence? occurrence,  PortableNewCounterpartChoice? slot,  skir.ValueLocation? collection,  String? disabledReason)  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkChoice():
return $default(_that.id,_that.widgetKey,_that.plan,_that.target,_that.kind,_that.label,_that.typeLabel,_that.subtitle,_that.searchText,_that.row,_that.definition,_that.occurrence,_that.slot,_that.collection,_that.disabledReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String widgetKey,  PortableLinkPlan plan,  PortableLinkTargetChoice target,  _AuthoredLinkChoiceKind kind,  String label,  String typeLabel,  String subtitle,  String searchText,  _AuthoredCollectionRow? row,  skir.PresentationCollectionDefinition? definition,  skir.LinkOccurrence? occurrence,  PortableNewCounterpartChoice? slot,  skir.ValueLocation? collection,  String? disabledReason)?  $default,) {final _that = this;
switch (_that) {
case __AuthoredLinkChoice() when $default != null:
return $default(_that.id,_that.widgetKey,_that.plan,_that.target,_that.kind,_that.label,_that.typeLabel,_that.subtitle,_that.searchText,_that.row,_that.definition,_that.occurrence,_that.slot,_that.collection,_that.disabledReason);case _:
  return null;

}
}

}

/// @nodoc


class __AuthoredLinkChoice implements _AuthoredLinkChoice {
  const __AuthoredLinkChoice({required this.id, required this.widgetKey, required this.plan, required this.target, required this.kind, required this.label, required this.typeLabel, required this.subtitle, required this.searchText, this.row, this.definition, this.occurrence, this.slot, this.collection, this.disabledReason});


@override final  String id;
@override final  String widgetKey;
@override final  PortableLinkPlan plan;
@override final  PortableLinkTargetChoice target;
@override final  _AuthoredLinkChoiceKind kind;
@override final  String label;
@override final  String typeLabel;
@override final  String subtitle;
@override final  String searchText;
@override final  _AuthoredCollectionRow? row;
@override final  skir.PresentationCollectionDefinition? definition;
@override final  skir.LinkOccurrence? occurrence;
@override final  PortableNewCounterpartChoice? slot;
@override final  skir.ValueLocation? collection;
@override final  String? disabledReason;

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$_AuthoredLinkChoiceCopyWith<__AuthoredLinkChoice> get copyWith => __$_AuthoredLinkChoiceCopyWithImpl<__AuthoredLinkChoice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is __AuthoredLinkChoice&&(identical(other.id, id) || other.id == id)&&(identical(other.widgetKey, widgetKey) || other.widgetKey == widgetKey)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.target, target) || other.target == target)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.searchText, searchText) || other.searchText == searchText)&&(identical(other.row, row) || other.row == row)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.occurrence, occurrence) || other.occurrence == occurrence)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.collection, collection) || other.collection == collection)&&(identical(other.disabledReason, disabledReason) || other.disabledReason == disabledReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,widgetKey,plan,target,kind,label,typeLabel,subtitle,searchText,row,definition,occurrence,slot,collection,disabledReason);
}

@override
String toString() {
    return '_AuthoredLinkChoice(id: $id, widgetKey: $widgetKey, plan: $plan, target: $target, kind: $kind, label: $label, typeLabel: $typeLabel, subtitle: $subtitle, searchText: $searchText, row: $row, definition: $definition, occurrence: $occurrence, slot: $slot, collection: $collection, disabledReason: $disabledReason)';
}


}

/// @nodoc
abstract mixin class _$_AuthoredLinkChoiceCopyWith<$Res> implements _$AuthoredLinkChoiceCopyWith<$Res> {
  factory _$_AuthoredLinkChoiceCopyWith(__AuthoredLinkChoice value, $Res Function(__AuthoredLinkChoice) _then) = __$_AuthoredLinkChoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String widgetKey, PortableLinkPlan plan, PortableLinkTargetChoice target, _AuthoredLinkChoiceKind kind, String label, String typeLabel, String subtitle, String searchText, _AuthoredCollectionRow? row, skir.PresentationCollectionDefinition? definition, skir.LinkOccurrence? occurrence, PortableNewCounterpartChoice? slot, skir.ValueLocation? collection, String? disabledReason
});


@override $PortableLinkPlanCopyWith<$Res> get plan;@override $PortableLinkTargetChoiceCopyWith<$Res> get target;@override $PortableNewCounterpartChoiceCopyWith<$Res>? get slot;

}
/// @nodoc
class __$_AuthoredLinkChoiceCopyWithImpl<$Res>
    implements _$_AuthoredLinkChoiceCopyWith<$Res> {
  __$_AuthoredLinkChoiceCopyWithImpl(this._self, this._then);

  final __AuthoredLinkChoice _self;
  final $Res Function(__AuthoredLinkChoice) _then;

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? widgetKey = null,Object? plan = null,Object? target = null,Object? kind = null,Object? label = null,Object? typeLabel = null,Object? subtitle = null,Object? searchText = null,Object? row = freezed,Object? definition = freezed,Object? occurrence = freezed,Object? slot = freezed,Object? collection = freezed,Object? disabledReason = freezed,}) {
  return _then(__AuthoredLinkChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,widgetKey: null == widgetKey ? _self.widgetKey : widgetKey // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PortableLinkPlan,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as PortableLinkTargetChoice,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as _AuthoredLinkChoiceKind,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,row: freezed == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as _AuthoredCollectionRow?,definition: freezed == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as skir.PresentationCollectionDefinition?,occurrence: freezed == occurrence ? _self.occurrence : occurrence // ignore: cast_nullable_to_non_nullable
as skir.LinkOccurrence?,slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as PortableNewCounterpartChoice?,collection: freezed == collection ? _self.collection : collection // ignore: cast_nullable_to_non_nullable
as skir.ValueLocation?,disabledReason: freezed == disabledReason ? _self.disabledReason : disabledReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkPlanCopyWith<$Res> get plan {

  return $PortableLinkPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableLinkTargetChoiceCopyWith<$Res> get target {

  return $PortableLinkTargetChoiceCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of _AuthoredLinkChoice
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableNewCounterpartChoiceCopyWith<$Res>? get slot {
    if (_self.slot == null) {
    return null;
  }

  return $PortableNewCounterpartChoiceCopyWith<$Res>(_self.slot!, (value) {
    return _then(_self.copyWith(slot: value));
  });
}
}

/// @nodoc
mixin _$PortablePresentationScope {

 Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings; skir.EvaluationBudget get budget; PortableOperationResults get operations; List<PortableAppearanceLayer> get appearanceLayers; Map<skir.ExpressionBindingId, AuthoredBindingAddress> get authoredAliases; AuthoredPresentationIndex? get authoredIndex; AuthoredPresentationIndex? get independentAuthoredIndex; List<PortableAuthoredPart> get authoredParts; PortableInspectorFrame? get inspectorFrame; Set<ActiveInspectorLayout> get activeInspectorLayouts; Set<ActivePartPresentation> get activeParts; bool get readOnly; bool get enabled; Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? get watchSearch; ValueChanged<String>? get reportStatus; CheckedEditorCatalog? get catalog; PortableExpressionQueries? get queries; ResourceDiagnosticReader get resourceDiagnostics; skir.ResourceId? get resource; String? get searchHistoryNamespace; ValueChanged<skir.ResourceId>? get openResource; skir.PresentationRole? get role; skir.PresentationMaterial? get material; Set<skir.PresentationId> get activePresentations; Set<ActiveFieldPresentation> get activeFieldPresentations; skir.BoundControl? get associatedControl; ResolvedFieldAssociation? get fieldAssociation; Map<String, skir.PresentationNode> get slots; Map<String, PortableSlotBuilder> get slotBuilders; PortablePresentationHost? get host; Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters;
/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortablePresentationScopeCopyWith<PortablePresentationScope> get copyWith => _$PortablePresentationScopeCopyWithImpl<PortablePresentationScope>(this as PortablePresentationScope, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortablePresentationScope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _this.bindings)&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.operations, _this.operations) || other.operations == _this.operations)&&const DeepCollectionEquality().equals(other.appearanceLayers, _this.appearanceLayers)&&const DeepCollectionEquality().equals(other.authoredAliases, _this.authoredAliases)&&(identical(other.authoredIndex, _this.authoredIndex) || other.authoredIndex == _this.authoredIndex)&&(identical(other.independentAuthoredIndex, _this.independentAuthoredIndex) || other.independentAuthoredIndex == _this.independentAuthoredIndex)&&const DeepCollectionEquality().equals(other.authoredParts, _this.authoredParts)&&(identical(other.inspectorFrame, _this.inspectorFrame) || other.inspectorFrame == _this.inspectorFrame)&&const DeepCollectionEquality().equals(other.activeInspectorLayouts, _this.activeInspectorLayouts)&&const DeepCollectionEquality().equals(other.activeParts, _this.activeParts)&&(identical(other.readOnly, _this.readOnly) || other.readOnly == _this.readOnly)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.watchSearch, _this.watchSearch) || other.watchSearch == _this.watchSearch)&&(identical(other.reportStatus, _this.reportStatus) || other.reportStatus == _this.reportStatus)&&(identical(other.catalog, _this.catalog) || other.catalog == _this.catalog)&&(identical(other.queries, _this.queries) || other.queries == _this.queries)&&(identical(other.resourceDiagnostics, _this.resourceDiagnostics) || other.resourceDiagnostics == _this.resourceDiagnostics)&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.searchHistoryNamespace, _this.searchHistoryNamespace) || other.searchHistoryNamespace == _this.searchHistoryNamespace)&&(identical(other.openResource, _this.openResource) || other.openResource == _this.openResource)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.material, _this.material) || other.material == _this.material)&&const DeepCollectionEquality().equals(other.activePresentations, _this.activePresentations)&&const DeepCollectionEquality().equals(other.activeFieldPresentations, _this.activeFieldPresentations)&&(identical(other.associatedControl, _this.associatedControl) || other.associatedControl == _this.associatedControl)&&(identical(other.fieldAssociation, _this.fieldAssociation) || other.fieldAssociation == _this.fieldAssociation)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _this.slotBuilders)&&(identical(other.host, _this.host) || other.host == _this.host)&&const DeepCollectionEquality().equals(other.projectedWriters, _this.projectedWriters));
}


@override
int get hashCode {
  final _this = this as PortablePresentationScope;
  return Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_this.bindings),_this.budget,_this.operations,const DeepCollectionEquality().hash(_this.appearanceLayers),const DeepCollectionEquality().hash(_this.authoredAliases),_this.authoredIndex,_this.independentAuthoredIndex,const DeepCollectionEquality().hash(_this.authoredParts),_this.inspectorFrame,const DeepCollectionEquality().hash(_this.activeInspectorLayouts),const DeepCollectionEquality().hash(_this.activeParts),_this.readOnly,_this.enabled,_this.watchSearch,_this.reportStatus,_this.catalog,_this.queries,_this.resourceDiagnostics,_this.resource,_this.searchHistoryNamespace,_this.openResource,_this.role,_this.material,const DeepCollectionEquality().hash(_this.activePresentations),const DeepCollectionEquality().hash(_this.activeFieldPresentations),_this.associatedControl,_this.fieldAssociation,const DeepCollectionEquality().hash(_this.slots),const DeepCollectionEquality().hash(_this.slotBuilders),_this.host,const DeepCollectionEquality().hash(_this.projectedWriters)]);
}

@override
String toString() {
  final _this = this as PortablePresentationScope;
  return 'PortablePresentationScope(bindings: ${_this.bindings}, budget: ${_this.budget}, operations: ${_this.operations}, appearanceLayers: ${_this.appearanceLayers}, authoredAliases: ${_this.authoredAliases}, authoredIndex: ${_this.authoredIndex}, independentAuthoredIndex: ${_this.independentAuthoredIndex}, authoredParts: ${_this.authoredParts}, inspectorFrame: ${_this.inspectorFrame}, activeInspectorLayouts: ${_this.activeInspectorLayouts}, activeParts: ${_this.activeParts}, readOnly: ${_this.readOnly}, enabled: ${_this.enabled}, watchSearch: ${_this.watchSearch}, reportStatus: ${_this.reportStatus}, catalog: ${_this.catalog}, queries: ${_this.queries}, resourceDiagnostics: ${_this.resourceDiagnostics}, resource: ${_this.resource}, searchHistoryNamespace: ${_this.searchHistoryNamespace}, openResource: ${_this.openResource}, role: ${_this.role}, material: ${_this.material}, activePresentations: ${_this.activePresentations}, activeFieldPresentations: ${_this.activeFieldPresentations}, associatedControl: ${_this.associatedControl}, fieldAssociation: ${_this.fieldAssociation}, slots: ${_this.slots}, slotBuilders: ${_this.slotBuilders}, host: ${_this.host}, projectedWriters: ${_this.projectedWriters})';
}


}

/// @nodoc
abstract mixin class $PortablePresentationScopeCopyWith<$Res>  {
  factory $PortablePresentationScopeCopyWith(PortablePresentationScope value, $Res Function(PortablePresentationScope) _then) = _$PortablePresentationScopeCopyWithImpl;
@useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableOperationResults operations, List<PortableAppearanceLayer> appearanceLayers, Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, AuthoredPresentationIndex? authoredIndex, AuthoredPresentationIndex? independentAuthoredIndex, List<PortableAuthoredPart> authoredParts, PortableInspectorFrame? inspectorFrame, Set<ActiveInspectorLayout> activeInspectorLayouts, Set<ActivePartPresentation> activeParts, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, CheckedEditorCatalog? catalog, PortableExpressionQueries? queries, ResourceDiagnosticReader resourceDiagnostics, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Set<ActiveFieldPresentation> activeFieldPresentations, skir.BoundControl? associatedControl, ResolvedFieldAssociation? fieldAssociation, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});


$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex;$AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex;$PortableInspectorFrameCopyWith<$Res>? get inspectorFrame;$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation;

}
/// @nodoc
class _$PortablePresentationScopeCopyWithImpl<$Res>
    implements $PortablePresentationScopeCopyWith<$Res> {
  _$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final PortablePresentationScope _self;
  final $Res Function(PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bindings = null,Object? budget = null,Object? operations = null,Object? appearanceLayers = null,Object? authoredAliases = null,Object? authoredIndex = freezed,Object? independentAuthoredIndex = freezed,Object? authoredParts = null,Object? inspectorFrame = freezed,Object? activeInspectorLayouts = null,Object? activeParts = null,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? catalog = freezed,Object? queries = freezed,Object? resourceDiagnostics = null,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? activeFieldPresentations = null,Object? associatedControl = freezed,Object? fieldAssociation = freezed,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? projectedWriters = null,}) {
  return _then(PortablePresentationScope(
bindings: null == bindings ? _self.bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as PortableOperationResults,appearanceLayers: null == appearanceLayers ? _self.appearanceLayers : appearanceLayers // ignore: cast_nullable_to_non_nullable
as List<PortableAppearanceLayer>,authoredAliases: null == authoredAliases ? _self.authoredAliases : authoredAliases // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, AuthoredBindingAddress>,authoredIndex: freezed == authoredIndex ? _self.authoredIndex : authoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,independentAuthoredIndex: freezed == independentAuthoredIndex ? _self.independentAuthoredIndex : independentAuthoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,authoredParts: null == authoredParts ? _self.authoredParts : authoredParts // ignore: cast_nullable_to_non_nullable
as List<PortableAuthoredPart>,inspectorFrame: freezed == inspectorFrame ? _self.inspectorFrame : inspectorFrame // ignore: cast_nullable_to_non_nullable
as PortableInspectorFrame?,activeInspectorLayouts: null == activeInspectorLayouts ? _self.activeInspectorLayouts : activeInspectorLayouts // ignore: cast_nullable_to_non_nullable
as Set<ActiveInspectorLayout>,activeParts: null == activeParts ? _self.activeParts : activeParts // ignore: cast_nullable_to_non_nullable
as Set<ActivePartPresentation>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,queries: freezed == queries ? _self.queries : queries // ignore: cast_nullable_to_non_nullable
as PortableExpressionQueries?,resourceDiagnostics: null == resourceDiagnostics ? _self.resourceDiagnostics : resourceDiagnostics // ignore: cast_nullable_to_non_nullable
as ResourceDiagnosticReader,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self.activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,activeFieldPresentations: null == activeFieldPresentations ? _self.activeFieldPresentations : activeFieldPresentations // ignore: cast_nullable_to_non_nullable
as Set<ActiveFieldPresentation>,associatedControl: freezed == associatedControl ? _self.associatedControl : associatedControl // ignore: cast_nullable_to_non_nullable
as skir.BoundControl?,fieldAssociation: freezed == fieldAssociation ? _self.fieldAssociation : fieldAssociation // ignore: cast_nullable_to_non_nullable
as ResolvedFieldAssociation?,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self.slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,projectedWriters: null == projectedWriters ? _self.projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}
/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex {
    if (_self.authoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.authoredIndex!, (value) {
    return _then(_self.copyWith(authoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex {
    if (_self.independentAuthoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.independentAuthoredIndex!, (value) {
    return _then(_self.copyWith(independentAuthoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorFrameCopyWith<$Res>? get inspectorFrame {
    if (_self.inspectorFrame == null) {
    return null;
  }

  return $PortableInspectorFrameCopyWith<$Res>(_self.inspectorFrame!, (value) {
    return _then(_self.copyWith(inspectorFrame: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation {
    if (_self.fieldAssociation == null) {
    return null;
  }

  return $ResolvedFieldAssociationCopyWith<$Res>(_self.fieldAssociation!, (value) {
    return _then(_self.copyWith(fieldAssociation: value));
  });
}
}



/// @nodoc


class _PortablePresentationScope extends PortablePresentationScope {
  const _PortablePresentationScope({required  Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, required this.budget, required this.operations, required  List<PortableAppearanceLayer> appearanceLayers, required  Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, required this.authoredIndex, required this.independentAuthoredIndex, required  List<PortableAuthoredPart> authoredParts, required this.inspectorFrame, required  Set<ActiveInspectorLayout> activeInspectorLayouts, required  Set<ActivePartPresentation> activeParts, required this.readOnly, required this.enabled, required this.watchSearch, required this.reportStatus, required this.catalog, required this.queries, required this.resourceDiagnostics, required this.resource, required this.searchHistoryNamespace, required this.openResource, required this.role, required this.material, required  Set<skir.PresentationId> activePresentations, required  Set<ActiveFieldPresentation> activeFieldPresentations, required this.associatedControl, required this.fieldAssociation, required  Map<String, skir.PresentationNode> slots, required  Map<String, PortableSlotBuilder> slotBuilders, required this.host, required  Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters}): _bindings = bindings,_appearanceLayers = appearanceLayers,_authoredAliases = authoredAliases,_authoredParts = authoredParts,_activeInspectorLayouts = activeInspectorLayouts,_activeParts = activeParts,_activePresentations = activePresentations,_activeFieldPresentations = activeFieldPresentations,_slots = slots,_slotBuilders = slotBuilders,_projectedWriters = projectedWriters,super._();


 final  Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
@override Map<skir.ExpressionBindingId, PortableExpressionBinding> get bindings {
  if (_bindings is EqualUnmodifiableMapView) return _bindings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_bindings);
}

@override final  skir.EvaluationBudget budget;
@override final  PortableOperationResults operations;
 final  List<PortableAppearanceLayer> _appearanceLayers;
@override List<PortableAppearanceLayer> get appearanceLayers {
  if (_appearanceLayers is EqualUnmodifiableListView) return _appearanceLayers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appearanceLayers);
}

 final  Map<skir.ExpressionBindingId, AuthoredBindingAddress> _authoredAliases;
@override Map<skir.ExpressionBindingId, AuthoredBindingAddress> get authoredAliases {
  if (_authoredAliases is EqualUnmodifiableMapView) return _authoredAliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_authoredAliases);
}

@override final  AuthoredPresentationIndex? authoredIndex;
@override final  AuthoredPresentationIndex? independentAuthoredIndex;
 final  List<PortableAuthoredPart> _authoredParts;
@override List<PortableAuthoredPart> get authoredParts {
  if (_authoredParts is EqualUnmodifiableListView) return _authoredParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authoredParts);
}

@override final  PortableInspectorFrame? inspectorFrame;
 final  Set<ActiveInspectorLayout> _activeInspectorLayouts;
@override Set<ActiveInspectorLayout> get activeInspectorLayouts {
  if (_activeInspectorLayouts is EqualUnmodifiableSetView) return _activeInspectorLayouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeInspectorLayouts);
}

 final  Set<ActivePartPresentation> _activeParts;
@override Set<ActivePartPresentation> get activeParts {
  if (_activeParts is EqualUnmodifiableSetView) return _activeParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeParts);
}

@override final  bool readOnly;
@override final  bool enabled;
@override final  Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch;
@override final  ValueChanged<String>? reportStatus;
@override final  CheckedEditorCatalog? catalog;
@override final  PortableExpressionQueries? queries;
@override final  ResourceDiagnosticReader resourceDiagnostics;
@override final  skir.ResourceId? resource;
@override final  String? searchHistoryNamespace;
@override final  ValueChanged<skir.ResourceId>? openResource;
@override final  skir.PresentationRole? role;
@override final  skir.PresentationMaterial? material;
 final  Set<skir.PresentationId> _activePresentations;
@override Set<skir.PresentationId> get activePresentations {
  if (_activePresentations is EqualUnmodifiableSetView) return _activePresentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activePresentations);
}

 final  Set<ActiveFieldPresentation> _activeFieldPresentations;
@override Set<ActiveFieldPresentation> get activeFieldPresentations {
  if (_activeFieldPresentations is EqualUnmodifiableSetView) return _activeFieldPresentations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeFieldPresentations);
}

@override final  skir.BoundControl? associatedControl;
@override final  ResolvedFieldAssociation? fieldAssociation;
 final  Map<String, skir.PresentationNode> _slots;
@override Map<String, skir.PresentationNode> get slots {
  if (_slots is EqualUnmodifiableMapView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slots);
}

 final  Map<String, PortableSlotBuilder> _slotBuilders;
@override Map<String, PortableSlotBuilder> get slotBuilders {
  if (_slotBuilders is EqualUnmodifiableMapView) return _slotBuilders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_slotBuilders);
}

@override final  PortablePresentationHost? host;
 final  Map<skir.ExpressionBindingId, PortableBindingSetter> _projectedWriters;
@override Map<skir.ExpressionBindingId, PortableBindingSetter> get projectedWriters {
  if (_projectedWriters is EqualUnmodifiableMapView) return _projectedWriters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_projectedWriters);
}


/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortablePresentationScopeCopyWith<_PortablePresentationScope> get copyWith => __$PortablePresentationScopeCopyWithImpl<_PortablePresentationScope>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortablePresentationScope&&const DeepCollectionEquality().equals(other.bindings, _bindings)&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.operations, operations) || other.operations == operations)&&const DeepCollectionEquality().equals(other.appearanceLayers, _appearanceLayers)&&const DeepCollectionEquality().equals(other.authoredAliases, _authoredAliases)&&(identical(other.authoredIndex, authoredIndex) || other.authoredIndex == authoredIndex)&&(identical(other.independentAuthoredIndex, independentAuthoredIndex) || other.independentAuthoredIndex == independentAuthoredIndex)&&const DeepCollectionEquality().equals(other.authoredParts, _authoredParts)&&(identical(other.inspectorFrame, inspectorFrame) || other.inspectorFrame == inspectorFrame)&&const DeepCollectionEquality().equals(other.activeInspectorLayouts, _activeInspectorLayouts)&&const DeepCollectionEquality().equals(other.activeParts, _activeParts)&&(identical(other.readOnly, readOnly) || other.readOnly == readOnly)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.watchSearch, watchSearch) || other.watchSearch == watchSearch)&&(identical(other.reportStatus, reportStatus) || other.reportStatus == reportStatus)&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.queries, queries) || other.queries == queries)&&(identical(other.resourceDiagnostics, resourceDiagnostics) || other.resourceDiagnostics == resourceDiagnostics)&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.searchHistoryNamespace, searchHistoryNamespace) || other.searchHistoryNamespace == searchHistoryNamespace)&&(identical(other.openResource, openResource) || other.openResource == openResource)&&(identical(other.role, role) || other.role == role)&&(identical(other.material, material) || other.material == material)&&const DeepCollectionEquality().equals(other.activePresentations, _activePresentations)&&const DeepCollectionEquality().equals(other.activeFieldPresentations, _activeFieldPresentations)&&(identical(other.associatedControl, associatedControl) || other.associatedControl == associatedControl)&&(identical(other.fieldAssociation, fieldAssociation) || other.fieldAssociation == fieldAssociation)&&const DeepCollectionEquality().equals(other.slots, _slots)&&const DeepCollectionEquality().equals(other.slotBuilders, _slotBuilders)&&(identical(other.host, host) || other.host == host)&&const DeepCollectionEquality().equals(other.projectedWriters, _projectedWriters));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_bindings),budget,operations,const DeepCollectionEquality().hash(_appearanceLayers),const DeepCollectionEquality().hash(_authoredAliases),authoredIndex,independentAuthoredIndex,const DeepCollectionEquality().hash(_authoredParts),inspectorFrame,const DeepCollectionEquality().hash(_activeInspectorLayouts),const DeepCollectionEquality().hash(_activeParts),readOnly,enabled,watchSearch,reportStatus,catalog,queries,resourceDiagnostics,resource,searchHistoryNamespace,openResource,role,material,const DeepCollectionEquality().hash(_activePresentations),const DeepCollectionEquality().hash(_activeFieldPresentations),associatedControl,fieldAssociation,const DeepCollectionEquality().hash(_slots),const DeepCollectionEquality().hash(_slotBuilders),host,const DeepCollectionEquality().hash(_projectedWriters)]);
}

@override
String toString() {
    return 'PortablePresentationScope._value(bindings: $bindings, budget: $budget, operations: $operations, appearanceLayers: $appearanceLayers, authoredAliases: $authoredAliases, authoredIndex: $authoredIndex, independentAuthoredIndex: $independentAuthoredIndex, authoredParts: $authoredParts, inspectorFrame: $inspectorFrame, activeInspectorLayouts: $activeInspectorLayouts, activeParts: $activeParts, readOnly: $readOnly, enabled: $enabled, watchSearch: $watchSearch, reportStatus: $reportStatus, catalog: $catalog, queries: $queries, resourceDiagnostics: $resourceDiagnostics, resource: $resource, searchHistoryNamespace: $searchHistoryNamespace, openResource: $openResource, role: $role, material: $material, activePresentations: $activePresentations, activeFieldPresentations: $activeFieldPresentations, associatedControl: $associatedControl, fieldAssociation: $fieldAssociation, slots: $slots, slotBuilders: $slotBuilders, host: $host, projectedWriters: $projectedWriters)';
}


}

/// @nodoc
abstract mixin class _$PortablePresentationScopeCopyWith<$Res> implements $PortablePresentationScopeCopyWith<$Res> {
  factory _$PortablePresentationScopeCopyWith(_PortablePresentationScope value, $Res Function(_PortablePresentationScope) _then) = __$PortablePresentationScopeCopyWithImpl;
@override @useResult
$Res call({
 Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, skir.EvaluationBudget budget, PortableOperationResults operations, List<PortableAppearanceLayer> appearanceLayers, Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases, AuthoredPresentationIndex? authoredIndex, AuthoredPresentationIndex? independentAuthoredIndex, List<PortableAuthoredPart> authoredParts, PortableInspectorFrame? inspectorFrame, Set<ActiveInspectorLayout> activeInspectorLayouts, Set<ActivePartPresentation> activeParts, bool readOnly, bool enabled, Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)? watchSearch, ValueChanged<String>? reportStatus, CheckedEditorCatalog? catalog, PortableExpressionQueries? queries, ResourceDiagnosticReader resourceDiagnostics, skir.ResourceId? resource, String? searchHistoryNamespace, ValueChanged<skir.ResourceId>? openResource, skir.PresentationRole? role, skir.PresentationMaterial? material, Set<skir.PresentationId> activePresentations, Set<ActiveFieldPresentation> activeFieldPresentations, skir.BoundControl? associatedControl, ResolvedFieldAssociation? fieldAssociation, Map<String, skir.PresentationNode> slots, Map<String, PortableSlotBuilder> slotBuilders, PortablePresentationHost? host, Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters
});


@override $AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex;@override $AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex;@override $PortableInspectorFrameCopyWith<$Res>? get inspectorFrame;@override $ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation;

}
/// @nodoc
class __$PortablePresentationScopeCopyWithImpl<$Res>
    implements _$PortablePresentationScopeCopyWith<$Res> {
  __$PortablePresentationScopeCopyWithImpl(this._self, this._then);

  final _PortablePresentationScope _self;
  final $Res Function(_PortablePresentationScope) _then;

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bindings = null,Object? budget = null,Object? operations = null,Object? appearanceLayers = null,Object? authoredAliases = null,Object? authoredIndex = freezed,Object? independentAuthoredIndex = freezed,Object? authoredParts = null,Object? inspectorFrame = freezed,Object? activeInspectorLayouts = null,Object? activeParts = null,Object? readOnly = null,Object? enabled = null,Object? watchSearch = freezed,Object? reportStatus = freezed,Object? catalog = freezed,Object? queries = freezed,Object? resourceDiagnostics = null,Object? resource = freezed,Object? searchHistoryNamespace = freezed,Object? openResource = freezed,Object? role = freezed,Object? material = freezed,Object? activePresentations = null,Object? activeFieldPresentations = null,Object? associatedControl = freezed,Object? fieldAssociation = freezed,Object? slots = null,Object? slotBuilders = null,Object? host = freezed,Object? projectedWriters = null,}) {
  return _then(_PortablePresentationScope(
bindings: null == bindings ? _self._bindings : bindings // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableExpressionBinding>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as skir.EvaluationBudget,operations: null == operations ? _self.operations : operations // ignore: cast_nullable_to_non_nullable
as PortableOperationResults,appearanceLayers: null == appearanceLayers ? _self._appearanceLayers : appearanceLayers // ignore: cast_nullable_to_non_nullable
as List<PortableAppearanceLayer>,authoredAliases: null == authoredAliases ? _self._authoredAliases : authoredAliases // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, AuthoredBindingAddress>,authoredIndex: freezed == authoredIndex ? _self.authoredIndex : authoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,independentAuthoredIndex: freezed == independentAuthoredIndex ? _self.independentAuthoredIndex : independentAuthoredIndex // ignore: cast_nullable_to_non_nullable
as AuthoredPresentationIndex?,authoredParts: null == authoredParts ? _self._authoredParts : authoredParts // ignore: cast_nullable_to_non_nullable
as List<PortableAuthoredPart>,inspectorFrame: freezed == inspectorFrame ? _self.inspectorFrame : inspectorFrame // ignore: cast_nullable_to_non_nullable
as PortableInspectorFrame?,activeInspectorLayouts: null == activeInspectorLayouts ? _self._activeInspectorLayouts : activeInspectorLayouts // ignore: cast_nullable_to_non_nullable
as Set<ActiveInspectorLayout>,activeParts: null == activeParts ? _self._activeParts : activeParts // ignore: cast_nullable_to_non_nullable
as Set<ActivePartPresentation>,readOnly: null == readOnly ? _self.readOnly : readOnly // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,watchSearch: freezed == watchSearch ? _self.watchSearch : watchSearch // ignore: cast_nullable_to_non_nullable
as Stream<skir.RealmPresentationSearchUpdate> Function(skir.RealmPresentationSearchRequest request)?,reportStatus: freezed == reportStatus ? _self.reportStatus : reportStatus // ignore: cast_nullable_to_non_nullable
as ValueChanged<String>?,catalog: freezed == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as CheckedEditorCatalog?,queries: freezed == queries ? _self.queries : queries // ignore: cast_nullable_to_non_nullable
as PortableExpressionQueries?,resourceDiagnostics: null == resourceDiagnostics ? _self.resourceDiagnostics : resourceDiagnostics // ignore: cast_nullable_to_non_nullable
as ResourceDiagnosticReader,resource: freezed == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,searchHistoryNamespace: freezed == searchHistoryNamespace ? _self.searchHistoryNamespace : searchHistoryNamespace // ignore: cast_nullable_to_non_nullable
as String?,openResource: freezed == openResource ? _self.openResource : openResource // ignore: cast_nullable_to_non_nullable
as ValueChanged<skir.ResourceId>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as skir.PresentationRole?,material: freezed == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as skir.PresentationMaterial?,activePresentations: null == activePresentations ? _self._activePresentations : activePresentations // ignore: cast_nullable_to_non_nullable
as Set<skir.PresentationId>,activeFieldPresentations: null == activeFieldPresentations ? _self._activeFieldPresentations : activeFieldPresentations // ignore: cast_nullable_to_non_nullable
as Set<ActiveFieldPresentation>,associatedControl: freezed == associatedControl ? _self.associatedControl : associatedControl // ignore: cast_nullable_to_non_nullable
as skir.BoundControl?,fieldAssociation: freezed == fieldAssociation ? _self.fieldAssociation : fieldAssociation // ignore: cast_nullable_to_non_nullable
as ResolvedFieldAssociation?,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as Map<String, skir.PresentationNode>,slotBuilders: null == slotBuilders ? _self._slotBuilders : slotBuilders // ignore: cast_nullable_to_non_nullable
as Map<String, PortableSlotBuilder>,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as PortablePresentationHost?,projectedWriters: null == projectedWriters ? _self._projectedWriters : projectedWriters // ignore: cast_nullable_to_non_nullable
as Map<skir.ExpressionBindingId, PortableBindingSetter>,
  ));
}

/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get authoredIndex {
    if (_self.authoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.authoredIndex!, (value) {
    return _then(_self.copyWith(authoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoredPresentationIndexCopyWith<$Res>? get independentAuthoredIndex {
    if (_self.independentAuthoredIndex == null) {
    return null;
  }

  return $AuthoredPresentationIndexCopyWith<$Res>(_self.independentAuthoredIndex!, (value) {
    return _then(_self.copyWith(independentAuthoredIndex: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$PortableInspectorFrameCopyWith<$Res>? get inspectorFrame {
    if (_self.inspectorFrame == null) {
    return null;
  }

  return $PortableInspectorFrameCopyWith<$Res>(_self.inspectorFrame!, (value) {
    return _then(_self.copyWith(inspectorFrame: value));
  });
}/// Create a copy of PortablePresentationScope
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$ResolvedFieldAssociationCopyWith<$Res>? get fieldAssociation {
    if (_self.fieldAssociation == null) {
    return null;
  }

  return $ResolvedFieldAssociationCopyWith<$Res>(_self.fieldAssociation!, (value) {
    return _then(_self.copyWith(fieldAssociation: value));
  });
}
}

// dart format on
