// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_search_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreationReferenceConstraint {

 List<skir.EndpointId> get route; skir.ResourceId get target;
/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreationReferenceConstraintCopyWith<CreationReferenceConstraint> get copyWith => _$CreationReferenceConstraintCopyWithImpl<CreationReferenceConstraint>(this as CreationReferenceConstraint, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreationReferenceConstraint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreationReferenceConstraint&&const DeepCollectionEquality().equals(other.route, _this.route)&&(identical(other.target, _this.target) || other.target == _this.target));
}


@override
int get hashCode {
  final _this = this as CreationReferenceConstraint;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.route),_this.target);
}

@override
String toString() {
  final _this = this as CreationReferenceConstraint;
  return 'CreationReferenceConstraint(route: ${_this.route}, target: ${_this.target})';
}


}

/// @nodoc
abstract mixin class $CreationReferenceConstraintCopyWith<$Res>  {
  factory $CreationReferenceConstraintCopyWith(CreationReferenceConstraint value, $Res Function(CreationReferenceConstraint) _then) = _$CreationReferenceConstraintCopyWithImpl;
@useResult
$Res call({
 List<skir.EndpointId> route, skir.ResourceId target
});




}
/// @nodoc
class _$CreationReferenceConstraintCopyWithImpl<$Res>
    implements $CreationReferenceConstraintCopyWith<$Res> {
  _$CreationReferenceConstraintCopyWithImpl(this._self, this._then);

  final CreationReferenceConstraint _self;
  final $Res Function(CreationReferenceConstraint) _then;

/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? route = null,Object? target = null,}) {
  return _then(CreationReferenceConstraint(
route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as List<skir.EndpointId>,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}

}


/// Adds pattern matching related methods to [CreationReferenceConstraint].
extension CreationReferenceConstraintPatterns on CreationReferenceConstraint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreationReferenceConstraint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreationReferenceConstraint value)  $default,){
final _that = this;
switch (_that) {
case _CreationReferenceConstraint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreationReferenceConstraint value)?  $default,){
final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<skir.EndpointId> route,  skir.ResourceId target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
return $default(_that.route,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<skir.EndpointId> route,  skir.ResourceId target)  $default,) {final _that = this;
switch (_that) {
case _CreationReferenceConstraint():
return $default(_that.route,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<skir.EndpointId> route,  skir.ResourceId target)?  $default,) {final _that = this;
switch (_that) {
case _CreationReferenceConstraint() when $default != null:
return $default(_that.route,_that.target);case _:
  return null;

}
}

}

/// @nodoc


class _CreationReferenceConstraint implements CreationReferenceConstraint {
  const _CreationReferenceConstraint({required  List<skir.EndpointId> route, required this.target}): _route = route;


 final  List<skir.EndpointId> _route;
@override List<skir.EndpointId> get route {
  if (_route is EqualUnmodifiableListView) return _route;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_route);
}

@override final  skir.ResourceId target;

/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreationReferenceConstraintCopyWith<_CreationReferenceConstraint> get copyWith => __$CreationReferenceConstraintCopyWithImpl<_CreationReferenceConstraint>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreationReferenceConstraint&&const DeepCollectionEquality().equals(other.route, _route)&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_route),target);
}

@override
String toString() {
    return 'CreationReferenceConstraint(route: $route, target: $target)';
}


}

/// @nodoc
abstract mixin class _$CreationReferenceConstraintCopyWith<$Res> implements $CreationReferenceConstraintCopyWith<$Res> {
  factory _$CreationReferenceConstraintCopyWith(_CreationReferenceConstraint value, $Res Function(_CreationReferenceConstraint) _then) = __$CreationReferenceConstraintCopyWithImpl;
@override @useResult
$Res call({
 List<skir.EndpointId> route, skir.ResourceId target
});




}
/// @nodoc
class __$CreationReferenceConstraintCopyWithImpl<$Res>
    implements _$CreationReferenceConstraintCopyWith<$Res> {
  __$CreationReferenceConstraintCopyWithImpl(this._self, this._then);

  final _CreationReferenceConstraint _self;
  final $Res Function(_CreationReferenceConstraint) _then;

/// Create a copy of CreationReferenceConstraint
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? route = null,Object? target = null,}) {
  return _then(_CreationReferenceConstraint(
route: null == route ? _self._route : route // ignore: cast_nullable_to_non_nullable
as List<skir.EndpointId>,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,
  ));
}


}

/// @nodoc
mixin _$CreationContext {

 List<CreationReferenceConstraint> get constraints; List<skir.ResourceId> get preferredResources;
/// Create a copy of CreationContext
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreationContextCopyWith<CreationContext> get copyWith => _$CreationContextCopyWithImpl<CreationContext>(this as CreationContext, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreationContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreationContext&&const DeepCollectionEquality().equals(other.constraints, _this.constraints)&&const DeepCollectionEquality().equals(other.preferredResources, _this.preferredResources));
}


@override
int get hashCode {
  final _this = this as CreationContext;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.constraints),const DeepCollectionEquality().hash(_this.preferredResources));
}

@override
String toString() {
  final _this = this as CreationContext;
  return 'CreationContext(constraints: ${_this.constraints}, preferredResources: ${_this.preferredResources})';
}


}

/// @nodoc
abstract mixin class $CreationContextCopyWith<$Res>  {
  factory $CreationContextCopyWith(CreationContext value, $Res Function(CreationContext) _then) = _$CreationContextCopyWithImpl;
@useResult
$Res call({
 List<CreationReferenceConstraint> constraints, List<skir.ResourceId> preferredResources
});




}
/// @nodoc
class _$CreationContextCopyWithImpl<$Res>
    implements $CreationContextCopyWith<$Res> {
  _$CreationContextCopyWithImpl(this._self, this._then);

  final CreationContext _self;
  final $Res Function(CreationContext) _then;

/// Create a copy of CreationContext
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? constraints = null,Object? preferredResources = null,}) {
  return _then(CreationContext(
constraints: null == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<CreationReferenceConstraint>,preferredResources: null == preferredResources ? _self.preferredResources : preferredResources // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}

}


/// Adds pattern matching related methods to [CreationContext].
extension CreationContextPatterns on CreationContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreationContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreationContext value)  $default,){
final _that = this;
switch (_that) {
case _CreationContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreationContext value)?  $default,){
final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CreationReferenceConstraint> constraints,  List<skir.ResourceId> preferredResources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
return $default(_that.constraints,_that.preferredResources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CreationReferenceConstraint> constraints,  List<skir.ResourceId> preferredResources)  $default,) {final _that = this;
switch (_that) {
case _CreationContext():
return $default(_that.constraints,_that.preferredResources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CreationReferenceConstraint> constraints,  List<skir.ResourceId> preferredResources)?  $default,) {final _that = this;
switch (_that) {
case _CreationContext() when $default != null:
return $default(_that.constraints,_that.preferredResources);case _:
  return null;

}
}

}

/// @nodoc


class _CreationContext extends CreationContext {
  const _CreationContext({ List<CreationReferenceConstraint> constraints = const [],  List<skir.ResourceId> preferredResources = const []}): _constraints = constraints,_preferredResources = preferredResources,super._();


 final  List<CreationReferenceConstraint> _constraints;
@override@JsonKey() List<CreationReferenceConstraint> get constraints {
  if (_constraints is EqualUnmodifiableListView) return _constraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_constraints);
}

 final  List<skir.ResourceId> _preferredResources;
@override@JsonKey() List<skir.ResourceId> get preferredResources {
  if (_preferredResources is EqualUnmodifiableListView) return _preferredResources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredResources);
}


/// Create a copy of CreationContext
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreationContextCopyWith<_CreationContext> get copyWith => __$CreationContextCopyWithImpl<_CreationContext>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreationContext&&const DeepCollectionEquality().equals(other.constraints, _constraints)&&const DeepCollectionEquality().equals(other.preferredResources, _preferredResources));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_constraints),const DeepCollectionEquality().hash(_preferredResources));
}

@override
String toString() {
    return 'CreationContext(constraints: $constraints, preferredResources: $preferredResources)';
}


}

/// @nodoc
abstract mixin class _$CreationContextCopyWith<$Res> implements $CreationContextCopyWith<$Res> {
  factory _$CreationContextCopyWith(_CreationContext value, $Res Function(_CreationContext) _then) = __$CreationContextCopyWithImpl;
@override @useResult
$Res call({
 List<CreationReferenceConstraint> constraints, List<skir.ResourceId> preferredResources
});




}
/// @nodoc
class __$CreationContextCopyWithImpl<$Res>
    implements _$CreationContextCopyWith<$Res> {
  __$CreationContextCopyWithImpl(this._self, this._then);

  final _CreationContext _self;
  final $Res Function(_CreationContext) _then;

/// Create a copy of CreationContext
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? constraints = null,Object? preferredResources = null,}) {
  return _then(_CreationContext(
constraints: null == constraints ? _self._constraints : constraints // ignore: cast_nullable_to_non_nullable
as List<CreationReferenceConstraint>,preferredResources: null == preferredResources ? _self._preferredResources : preferredResources // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}


}

// dart format on
