// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_resource_drag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringResourceDragGroup {

 AuthoringResourceIdentifier get primary; Map<AuthoringResourceIdentifier, skir.LinkOccurrence> get memberships; bool Function()? get sourceCanMutate;
/// Create a copy of AuthoringResourceDragGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringResourceDragGroupCopyWith<AuthoringResourceDragGroup> get copyWith => _$AuthoringResourceDragGroupCopyWithImpl<AuthoringResourceDragGroup>(this as AuthoringResourceDragGroup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringResourceDragGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringResourceDragGroup&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&const DeepCollectionEquality().equals(other.memberships, _this.memberships)&&(identical(other.sourceCanMutate, _this.sourceCanMutate) || other.sourceCanMutate == _this.sourceCanMutate));
}


@override
int get hashCode {
  final _this = this as AuthoringResourceDragGroup;
  return Object.hash(runtimeType,_this.primary,const DeepCollectionEquality().hash(_this.memberships),_this.sourceCanMutate);
}

@override
String toString() {
  final _this = this as AuthoringResourceDragGroup;
  return 'AuthoringResourceDragGroup(primary: ${_this.primary}, memberships: ${_this.memberships}, sourceCanMutate: ${_this.sourceCanMutate})';
}


}

/// @nodoc
abstract mixin class $AuthoringResourceDragGroupCopyWith<$Res>  {
  factory $AuthoringResourceDragGroupCopyWith(AuthoringResourceDragGroup value, $Res Function(AuthoringResourceDragGroup) _then) = _$AuthoringResourceDragGroupCopyWithImpl;
@useResult
$Res call({
 AuthoringResourceIdentifier primary, Map<AuthoringResourceIdentifier, skir.LinkOccurrence> memberships, bool Function()? sourceCanMutate
});


$AuthoringResourceIdentifierCopyWith<$Res> get primary;

}
/// @nodoc
class _$AuthoringResourceDragGroupCopyWithImpl<$Res>
    implements $AuthoringResourceDragGroupCopyWith<$Res> {
  _$AuthoringResourceDragGroupCopyWithImpl(this._self, this._then);

  final AuthoringResourceDragGroup _self;
  final $Res Function(AuthoringResourceDragGroup) _then;

/// Create a copy of AuthoringResourceDragGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = null,Object? memberships = null,Object? sourceCanMutate = freezed,}) {
  return _then(AuthoringResourceDragGroup(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AuthoringResourceIdentifier,memberships: null == memberships ? _self.memberships : memberships // ignore: cast_nullable_to_non_nullable
as Map<AuthoringResourceIdentifier, skir.LinkOccurrence>,sourceCanMutate: freezed == sourceCanMutate ? _self.sourceCanMutate : sourceCanMutate // ignore: cast_nullable_to_non_nullable
as bool Function()?,
  ));
}
/// Create a copy of AuthoringResourceDragGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringResourceIdentifierCopyWith<$Res> get primary {
  
  return $AuthoringResourceIdentifierCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringResourceDragGroup].
extension AuthoringResourceDragGroupPatterns on AuthoringResourceDragGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringResourceDragGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringResourceDragGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringResourceDragGroup value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringResourceDragGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringResourceDragGroup value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringResourceDragGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringResourceIdentifier primary,  Map<AuthoringResourceIdentifier, skir.LinkOccurrence> memberships,  bool Function()? sourceCanMutate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringResourceDragGroup() when $default != null:
return $default(_that.primary,_that.memberships,_that.sourceCanMutate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringResourceIdentifier primary,  Map<AuthoringResourceIdentifier, skir.LinkOccurrence> memberships,  bool Function()? sourceCanMutate)  $default,) {final _that = this;
switch (_that) {
case _AuthoringResourceDragGroup():
return $default(_that.primary,_that.memberships,_that.sourceCanMutate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringResourceIdentifier primary,  Map<AuthoringResourceIdentifier, skir.LinkOccurrence> memberships,  bool Function()? sourceCanMutate)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringResourceDragGroup() when $default != null:
return $default(_that.primary,_that.memberships,_that.sourceCanMutate);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringResourceDragGroup extends AuthoringResourceDragGroup {
  const _AuthoringResourceDragGroup({required this.primary, required  Map<AuthoringResourceIdentifier, skir.LinkOccurrence> memberships, this.sourceCanMutate}): _memberships = memberships,super._();
  

@override final  AuthoringResourceIdentifier primary;
 final  Map<AuthoringResourceIdentifier, skir.LinkOccurrence> _memberships;
@override Map<AuthoringResourceIdentifier, skir.LinkOccurrence> get memberships {
  if (_memberships is EqualUnmodifiableMapView) return _memberships;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_memberships);
}

@override final  bool Function()? sourceCanMutate;

/// Create a copy of AuthoringResourceDragGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringResourceDragGroupCopyWith<_AuthoringResourceDragGroup> get copyWith => __$AuthoringResourceDragGroupCopyWithImpl<_AuthoringResourceDragGroup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringResourceDragGroup&&(identical(other.primary, primary) || other.primary == primary)&&const DeepCollectionEquality().equals(other.memberships, _memberships)&&(identical(other.sourceCanMutate, sourceCanMutate) || other.sourceCanMutate == sourceCanMutate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,primary,const DeepCollectionEquality().hash(_memberships),sourceCanMutate);
}

@override
String toString() {
    return 'AuthoringResourceDragGroup(primary: $primary, memberships: $memberships, sourceCanMutate: $sourceCanMutate)';
}


}

/// @nodoc
abstract mixin class _$AuthoringResourceDragGroupCopyWith<$Res> implements $AuthoringResourceDragGroupCopyWith<$Res> {
  factory _$AuthoringResourceDragGroupCopyWith(_AuthoringResourceDragGroup value, $Res Function(_AuthoringResourceDragGroup) _then) = __$AuthoringResourceDragGroupCopyWithImpl;
@override @useResult
$Res call({
 AuthoringResourceIdentifier primary, Map<AuthoringResourceIdentifier, skir.LinkOccurrence> memberships, bool Function()? sourceCanMutate
});


@override $AuthoringResourceIdentifierCopyWith<$Res> get primary;

}
/// @nodoc
class __$AuthoringResourceDragGroupCopyWithImpl<$Res>
    implements _$AuthoringResourceDragGroupCopyWith<$Res> {
  __$AuthoringResourceDragGroupCopyWithImpl(this._self, this._then);

  final _AuthoringResourceDragGroup _self;
  final $Res Function(_AuthoringResourceDragGroup) _then;

/// Create a copy of AuthoringResourceDragGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primary = null,Object? memberships = null,Object? sourceCanMutate = freezed,}) {
  return _then(_AuthoringResourceDragGroup(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AuthoringResourceIdentifier,memberships: null == memberships ? _self._memberships : memberships // ignore: cast_nullable_to_non_nullable
as Map<AuthoringResourceIdentifier, skir.LinkOccurrence>,sourceCanMutate: freezed == sourceCanMutate ? _self.sourceCanMutate : sourceCanMutate // ignore: cast_nullable_to_non_nullable
as bool Function()?,
  ));
}

/// Create a copy of AuthoringResourceDragGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringResourceIdentifierCopyWith<$Res> get primary {
  
  return $AuthoringResourceIdentifierCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}
}

// dart format on
