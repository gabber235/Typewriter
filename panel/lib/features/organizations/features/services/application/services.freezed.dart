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

 skir.RecordId get serviceId; String get name; List<ServiceRole> get roles; DateTime get createdAt; skir.RecordId? get organization; ServiceRegistration? get registration; ServiceState? get state; skir.RecordId? get runsIn;
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
 skir.RecordId serviceId, String name, List<ServiceRole> roles, DateTime createdAt, skir.RecordId? organization, ServiceRegistration? registration, ServiceState? state, skir.RecordId? runsIn
});


$ServiceRegistrationCopyWith<$Res>? get registration;$ServiceStateCopyWith<$Res>? get state;

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
as List<ServiceRole>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,registration: freezed == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as ServiceRegistration?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ServiceState?,runsIn: freezed == runsIn ? _self.runsIn : runsIn // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,
  ));
}
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceRegistrationCopyWith<$Res>? get registration {
    if (_self.registration == null) {
    return null;
  }

  return $ServiceRegistrationCopyWith<$Res>(_self.registration!, (value) {
    return _then(_self.copyWith(registration: value));
  });
}/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceStateCopyWith<$Res>? get state {
    if (_self.state == null) {
    return null;
  }

  return $ServiceStateCopyWith<$Res>(_self.state!, (value) {
    return _then(_self.copyWith(state: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId serviceId,  String name,  List<ServiceRole> roles,  DateTime createdAt,  skir.RecordId? organization,  ServiceRegistration? registration,  ServiceState? state,  skir.RecordId? runsIn)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId serviceId,  String name,  List<ServiceRole> roles,  DateTime createdAt,  skir.RecordId? organization,  ServiceRegistration? registration,  ServiceState? state,  skir.RecordId? runsIn)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId serviceId,  String name,  List<ServiceRole> roles,  DateTime createdAt,  skir.RecordId? organization,  ServiceRegistration? registration,  ServiceState? state,  skir.RecordId? runsIn)?  $default,) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.serviceId,_that.name,_that.roles,_that.createdAt,_that.organization,_that.registration,_that.state,_that.runsIn);case _:
  return null;

}
}

}

/// @nodoc


class _Service extends Service {
   _Service({required this.serviceId, required this.name, required final  List<ServiceRole> roles, required this.createdAt, this.organization, this.registration, this.state, this.runsIn}): assert(name.isNotEmpty, 'Name must not be empty.'),assert(roles.isNotEmpty, 'Roles must not be empty.'),_roles = roles,super._();
  

@override final  skir.RecordId serviceId;
@override final  String name;
 final  List<ServiceRole> _roles;
@override List<ServiceRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override final  DateTime createdAt;
@override final  skir.RecordId? organization;
@override final  ServiceRegistration? registration;
@override final  ServiceState? state;
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
 skir.RecordId serviceId, String name, List<ServiceRole> roles, DateTime createdAt, skir.RecordId? organization, ServiceRegistration? registration, ServiceState? state, skir.RecordId? runsIn
});


@override $ServiceRegistrationCopyWith<$Res>? get registration;@override $ServiceStateCopyWith<$Res>? get state;

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
as List<ServiceRole>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,registration: freezed == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as ServiceRegistration?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ServiceState?,runsIn: freezed == runsIn ? _self.runsIn : runsIn // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,
  ));
}

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceRegistrationCopyWith<$Res>? get registration {
    if (_self.registration == null) {
    return null;
  }

  return $ServiceRegistrationCopyWith<$Res>(_self.registration!, (value) {
    return _then(_self.copyWith(registration: value));
  });
}/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceStateCopyWith<$Res>? get state {
    if (_self.state == null) {
    return null;
  }

  return $ServiceStateCopyWith<$Res>(_self.state!, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$ServiceRole {

 String get version;
/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceRoleCopyWith<ServiceRole> get copyWith => _$ServiceRoleCopyWithImpl<ServiceRole>(this as ServiceRole, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceRole&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,version);

@override
String toString() {
  return 'ServiceRole(version: $version)';
}


}

/// @nodoc
abstract mixin class $ServiceRoleCopyWith<$Res>  {
  factory $ServiceRoleCopyWith(ServiceRole value, $Res Function(ServiceRole) _then) = _$ServiceRoleCopyWithImpl;
@useResult
$Res call({
 String version
});




}
/// @nodoc
class _$ServiceRoleCopyWithImpl<$Res>
    implements $ServiceRoleCopyWith<$Res> {
  _$ServiceRoleCopyWithImpl(this._self, this._then);

  final ServiceRole _self;
  final $Res Function(ServiceRole) _then;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceRole].
extension ServiceRolePatterns on ServiceRole {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EngineServiceRole value)?  engine,TResult Function( RealmServiceRole value)?  realm,TResult Function( CustomServiceRole value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EngineServiceRole() when engine != null:
return engine(_that);case RealmServiceRole() when realm != null:
return realm(_that);case CustomServiceRole() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EngineServiceRole value)  engine,required TResult Function( RealmServiceRole value)  realm,required TResult Function( CustomServiceRole value)  custom,}){
final _that = this;
switch (_that) {
case EngineServiceRole():
return engine(_that);case RealmServiceRole():
return realm(_that);case CustomServiceRole():
return custom(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EngineServiceRole value)?  engine,TResult? Function( RealmServiceRole value)?  realm,TResult? Function( CustomServiceRole value)?  custom,}){
final _that = this;
switch (_that) {
case EngineServiceRole() when engine != null:
return engine(_that);case RealmServiceRole() when realm != null:
return realm(_that);case CustomServiceRole() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String version)?  engine,TResult Function( String version)?  realm,TResult Function( String version,  String name)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EngineServiceRole() when engine != null:
return engine(_that.version);case RealmServiceRole() when realm != null:
return realm(_that.version);case CustomServiceRole() when custom != null:
return custom(_that.version,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String version)  engine,required TResult Function( String version)  realm,required TResult Function( String version,  String name)  custom,}) {final _that = this;
switch (_that) {
case EngineServiceRole():
return engine(_that.version);case RealmServiceRole():
return realm(_that.version);case CustomServiceRole():
return custom(_that.version,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String version)?  engine,TResult? Function( String version)?  realm,TResult? Function( String version,  String name)?  custom,}) {final _that = this;
switch (_that) {
case EngineServiceRole() when engine != null:
return engine(_that.version);case RealmServiceRole() when realm != null:
return realm(_that.version);case CustomServiceRole() when custom != null:
return custom(_that.version,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class EngineServiceRole extends ServiceRole {
   EngineServiceRole({required this.version}): assert(version.isNotEmpty, 'Version must not be empty.'),super._();
  

@override final  String version;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EngineServiceRoleCopyWith<EngineServiceRole> get copyWith => _$EngineServiceRoleCopyWithImpl<EngineServiceRole>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EngineServiceRole&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,version);

@override
String toString() {
  return 'ServiceRole.engine(version: $version)';
}


}

/// @nodoc
abstract mixin class $EngineServiceRoleCopyWith<$Res> implements $ServiceRoleCopyWith<$Res> {
  factory $EngineServiceRoleCopyWith(EngineServiceRole value, $Res Function(EngineServiceRole) _then) = _$EngineServiceRoleCopyWithImpl;
@override @useResult
$Res call({
 String version
});




}
/// @nodoc
class _$EngineServiceRoleCopyWithImpl<$Res>
    implements $EngineServiceRoleCopyWith<$Res> {
  _$EngineServiceRoleCopyWithImpl(this._self, this._then);

  final EngineServiceRole _self;
  final $Res Function(EngineServiceRole) _then;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,}) {
  return _then(EngineServiceRole(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RealmServiceRole extends ServiceRole {
   RealmServiceRole({required this.version}): assert(version.isNotEmpty, 'Version must not be empty.'),super._();
  

@override final  String version;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmServiceRoleCopyWith<RealmServiceRole> get copyWith => _$RealmServiceRoleCopyWithImpl<RealmServiceRole>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmServiceRole&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,version);

@override
String toString() {
  return 'ServiceRole.realm(version: $version)';
}


}

/// @nodoc
abstract mixin class $RealmServiceRoleCopyWith<$Res> implements $ServiceRoleCopyWith<$Res> {
  factory $RealmServiceRoleCopyWith(RealmServiceRole value, $Res Function(RealmServiceRole) _then) = _$RealmServiceRoleCopyWithImpl;
@override @useResult
$Res call({
 String version
});




}
/// @nodoc
class _$RealmServiceRoleCopyWithImpl<$Res>
    implements $RealmServiceRoleCopyWith<$Res> {
  _$RealmServiceRoleCopyWithImpl(this._self, this._then);

  final RealmServiceRole _self;
  final $Res Function(RealmServiceRole) _then;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,}) {
  return _then(RealmServiceRole(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CustomServiceRole extends ServiceRole {
   CustomServiceRole({required this.version, required this.name}): assert(version.isNotEmpty, 'Version must not be empty.'),assert(name.isNotEmpty, 'Name must not be empty.'),super._();
  

@override final  String version;
 final  String name;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomServiceRoleCopyWith<CustomServiceRole> get copyWith => _$CustomServiceRoleCopyWithImpl<CustomServiceRole>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomServiceRole&&(identical(other.version, version) || other.version == version)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,version,name);

@override
String toString() {
  return 'ServiceRole.custom(version: $version, name: $name)';
}


}

/// @nodoc
abstract mixin class $CustomServiceRoleCopyWith<$Res> implements $ServiceRoleCopyWith<$Res> {
  factory $CustomServiceRoleCopyWith(CustomServiceRole value, $Res Function(CustomServiceRole) _then) = _$CustomServiceRoleCopyWithImpl;
@override @useResult
$Res call({
 String version, String name
});




}
/// @nodoc
class _$CustomServiceRoleCopyWithImpl<$Res>
    implements $CustomServiceRoleCopyWith<$Res> {
  _$CustomServiceRoleCopyWithImpl(this._self, this._then);

  final CustomServiceRole _self;
  final $Res Function(CustomServiceRole) _then;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? name = null,}) {
  return _then(CustomServiceRole(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ServiceRegistration {

 String get token; DateTime get expiresAt;
/// Create a copy of ServiceRegistration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceRegistrationCopyWith<ServiceRegistration> get copyWith => _$ServiceRegistrationCopyWithImpl<ServiceRegistration>(this as ServiceRegistration, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceRegistration&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,token,expiresAt);

@override
String toString() {
  return 'ServiceRegistration(token: $token, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ServiceRegistrationCopyWith<$Res>  {
  factory $ServiceRegistrationCopyWith(ServiceRegistration value, $Res Function(ServiceRegistration) _then) = _$ServiceRegistrationCopyWithImpl;
@useResult
$Res call({
 String token, DateTime expiresAt
});




}
/// @nodoc
class _$ServiceRegistrationCopyWithImpl<$Res>
    implements $ServiceRegistrationCopyWith<$Res> {
  _$ServiceRegistrationCopyWithImpl(this._self, this._then);

  final ServiceRegistration _self;
  final $Res Function(ServiceRegistration) _then;

/// Create a copy of ServiceRegistration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceRegistration].
extension ServiceRegistrationPatterns on ServiceRegistration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceRegistration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceRegistration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceRegistration value)  $default,){
final _that = this;
switch (_that) {
case _ServiceRegistration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceRegistration value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceRegistration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceRegistration() when $default != null:
return $default(_that.token,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ServiceRegistration():
return $default(_that.token,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ServiceRegistration() when $default != null:
return $default(_that.token,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceRegistration extends ServiceRegistration {
  const _ServiceRegistration({required this.token, required this.expiresAt}): super._();
  

@override final  String token;
@override final  DateTime expiresAt;

/// Create a copy of ServiceRegistration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceRegistrationCopyWith<_ServiceRegistration> get copyWith => __$ServiceRegistrationCopyWithImpl<_ServiceRegistration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceRegistration&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,token,expiresAt);

@override
String toString() {
  return 'ServiceRegistration(token: $token, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ServiceRegistrationCopyWith<$Res> implements $ServiceRegistrationCopyWith<$Res> {
  factory _$ServiceRegistrationCopyWith(_ServiceRegistration value, $Res Function(_ServiceRegistration) _then) = __$ServiceRegistrationCopyWithImpl;
@override @useResult
$Res call({
 String token, DateTime expiresAt
});




}
/// @nodoc
class __$ServiceRegistrationCopyWithImpl<$Res>
    implements _$ServiceRegistrationCopyWith<$Res> {
  __$ServiceRegistrationCopyWithImpl(this._self, this._then);

  final _ServiceRegistration _self;
  final $Res Function(_ServiceRegistration) _then;

/// Create a copy of ServiceRegistration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? expiresAt = null,}) {
  return _then(_ServiceRegistration(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ServiceState {

 ServiceStateStatus get status; DateTime get lastSeen;
/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceStateCopyWith<ServiceState> get copyWith => _$ServiceStateCopyWithImpl<ServiceState>(this as ServiceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceState&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}


@override
int get hashCode => Object.hash(runtimeType,status,lastSeen);

@override
String toString() {
  return 'ServiceState(status: $status, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class $ServiceStateCopyWith<$Res>  {
  factory $ServiceStateCopyWith(ServiceState value, $Res Function(ServiceState) _then) = _$ServiceStateCopyWithImpl;
@useResult
$Res call({
 ServiceStateStatus status, DateTime lastSeen
});




}
/// @nodoc
class _$ServiceStateCopyWithImpl<$Res>
    implements $ServiceStateCopyWith<$Res> {
  _$ServiceStateCopyWithImpl(this._self, this._then);

  final ServiceState _self;
  final $Res Function(ServiceState) _then;

/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? lastSeen = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ServiceStateStatus,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceState].
extension ServiceStatePatterns on ServiceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceState value)  $default,){
final _that = this;
switch (_that) {
case _ServiceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceState value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ServiceStateStatus status,  DateTime lastSeen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
return $default(_that.status,_that.lastSeen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ServiceStateStatus status,  DateTime lastSeen)  $default,) {final _that = this;
switch (_that) {
case _ServiceState():
return $default(_that.status,_that.lastSeen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ServiceStateStatus status,  DateTime lastSeen)?  $default,) {final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
return $default(_that.status,_that.lastSeen);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceState extends ServiceState {
  const _ServiceState({required this.status, required this.lastSeen}): super._();
  

@override final  ServiceStateStatus status;
@override final  DateTime lastSeen;

/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceStateCopyWith<_ServiceState> get copyWith => __$ServiceStateCopyWithImpl<_ServiceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceState&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen));
}


@override
int get hashCode => Object.hash(runtimeType,status,lastSeen);

@override
String toString() {
  return 'ServiceState(status: $status, lastSeen: $lastSeen)';
}


}

/// @nodoc
abstract mixin class _$ServiceStateCopyWith<$Res> implements $ServiceStateCopyWith<$Res> {
  factory _$ServiceStateCopyWith(_ServiceState value, $Res Function(_ServiceState) _then) = __$ServiceStateCopyWithImpl;
@override @useResult
$Res call({
 ServiceStateStatus status, DateTime lastSeen
});




}
/// @nodoc
class __$ServiceStateCopyWithImpl<$Res>
    implements _$ServiceStateCopyWith<$Res> {
  __$ServiceStateCopyWithImpl(this._self, this._then);

  final _ServiceState _self;
  final $Res Function(_ServiceState) _then;

/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? lastSeen = null,}) {
  return _then(_ServiceState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ServiceStateStatus,lastSeen: null == lastSeen ? _self.lastSeen : lastSeen // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
