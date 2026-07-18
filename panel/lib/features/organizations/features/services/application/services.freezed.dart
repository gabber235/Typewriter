// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'services.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Service {

 skir.RecordId get serviceId; String get name; List<skir.ServiceRole> get roles; DateTime get createdAt; skir.RecordId? get organization; skir.ServiceRegistration? get registration; skir.ServiceState? get state; skir.RecordId? get runsIn;
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCopyWith<Service> get copyWith => _$ServiceCopyWithImpl<Service>(this as Service, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Service&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.registration, registration) || other.registration == registration)&&(identical(other.state, state) || other.state == state)&&(identical(other.runsIn, runsIn) || other.runsIn == runsIn));
}


@override
int get hashCode => Object.hash(runtimeType,serviceId,name,const DeepCollectionEquality().hash(roles),createdAt,organization,registration,state,runsIn);

@override
String toString() {
  return 'Service(serviceId: $serviceId, name: $name, roles: $roles, createdAt: $createdAt, organization: $organization, registration: $registration, state: $state, runsIn: $runsIn)';
}


}

/// @nodoc
abstract mixin class $ServiceCopyWith<$Res>  {
  factory $ServiceCopyWith(Service value, $Res Function(Service) _then) = _$ServiceCopyWithImpl;
@useResult
$Res call({
 skir.RecordId serviceId, String name, List<skir.ServiceRole> roles, DateTime createdAt, skir.RecordId? organization, skir.ServiceRegistration? registration, skir.ServiceState? state, skir.RecordId? runsIn
});




}
/// @nodoc
class _$ServiceCopyWithImpl<$Res>
    implements $ServiceCopyWith<$Res> {
  _$ServiceCopyWithImpl(this._self, this._then);

  final Service _self;
  final $Res Function(Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceId = null,Object? name = null,Object? roles = null,Object? createdAt = null,Object? organization = freezed,Object? registration = freezed,Object? state = freezed,Object? runsIn = freezed,}) {
  return _then(_self.copyWith(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<skir.ServiceRole>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,registration: freezed == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as skir.ServiceRegistration?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as skir.ServiceState?,runsIn: freezed == runsIn ? _self.runsIn : runsIn // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,
  ));
}

}


/// Adds pattern-matching-related methods to [Service].
extension ServicePatterns on Service {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Service value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Service value)  $default,){
final _that = this;
switch (_that) {
case _Service():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Service value)?  $default,){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId serviceId,  String name,  List<skir.ServiceRole> roles,  DateTime createdAt,  skir.RecordId? organization,  skir.ServiceRegistration? registration,  skir.ServiceState? state,  skir.RecordId? runsIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.serviceId,_that.name,_that.roles,_that.createdAt,_that.organization,_that.registration,_that.state,_that.runsIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId serviceId,  String name,  List<skir.ServiceRole> roles,  DateTime createdAt,  skir.RecordId? organization,  skir.ServiceRegistration? registration,  skir.ServiceState? state,  skir.RecordId? runsIn)  $default,) {final _that = this;
switch (_that) {
case _Service():
return $default(_that.serviceId,_that.name,_that.roles,_that.createdAt,_that.organization,_that.registration,_that.state,_that.runsIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId serviceId,  String name,  List<skir.ServiceRole> roles,  DateTime createdAt,  skir.RecordId? organization,  skir.ServiceRegistration? registration,  skir.ServiceState? state,  skir.RecordId? runsIn)?  $default,) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.serviceId,_that.name,_that.roles,_that.createdAt,_that.organization,_that.registration,_that.state,_that.runsIn);case _:
  return null;

}
}

}

/// @nodoc


class _Service extends Service {
  const _Service({required this.serviceId, required this.name, required final  List<skir.ServiceRole> roles, required this.createdAt, this.organization, this.registration, this.state, this.runsIn}): _roles = roles,super._();
  

@override final  skir.RecordId serviceId;
@override final  String name;
 final  List<skir.ServiceRole> _roles;
@override List<skir.ServiceRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  DateTime createdAt;
@override final  skir.RecordId? organization;
@override final  skir.ServiceRegistration? registration;
@override final  skir.ServiceState? state;
@override final  skir.RecordId? runsIn;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCopyWith<_Service> get copyWith => __$ServiceCopyWithImpl<_Service>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Service&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.registration, registration) || other.registration == registration)&&(identical(other.state, state) || other.state == state)&&(identical(other.runsIn, runsIn) || other.runsIn == runsIn));
}


@override
int get hashCode => Object.hash(runtimeType,serviceId,name,const DeepCollectionEquality().hash(_roles),createdAt,organization,registration,state,runsIn);

@override
String toString() {
  return 'Service(serviceId: $serviceId, name: $name, roles: $roles, createdAt: $createdAt, organization: $organization, registration: $registration, state: $state, runsIn: $runsIn)';
}


}

/// @nodoc
abstract mixin class _$ServiceCopyWith<$Res> implements $ServiceCopyWith<$Res> {
  factory _$ServiceCopyWith(_Service value, $Res Function(_Service) _then) = __$ServiceCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId serviceId, String name, List<skir.ServiceRole> roles, DateTime createdAt, skir.RecordId? organization, skir.ServiceRegistration? registration, skir.ServiceState? state, skir.RecordId? runsIn
});




}
/// @nodoc
class __$ServiceCopyWithImpl<$Res>
    implements _$ServiceCopyWith<$Res> {
  __$ServiceCopyWithImpl(this._self, this._then);

  final _Service _self;
  final $Res Function(_Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceId = null,Object? name = null,Object? roles = null,Object? createdAt = null,Object? organization = freezed,Object? registration = freezed,Object? state = freezed,Object? runsIn = freezed,}) {
  return _then(_Service(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<skir.ServiceRole>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,registration: freezed == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as skir.ServiceRegistration?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as skir.ServiceState?,runsIn: freezed == runsIn ? _self.runsIn : runsIn // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,
  ));
}


}

// dart format on
