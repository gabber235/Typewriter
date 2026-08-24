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

 skir.RecordId get serviceId; int get revision; String get name; ServiceRole get role; DateTime get createdAt; skir.RecordId? get organization; ServiceRegistration? get registration; ServiceState? get state;
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCopyWith<Service> get copyWith => _$ServiceCopyWithImpl<Service>(this as Service, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Service&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.registration, registration) || other.registration == registration)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,serviceId,revision,name,role,createdAt,organization,registration,state);

@override
String toString() {
  return 'Service(serviceId: $serviceId, revision: $revision, name: $name, role: $role, createdAt: $createdAt, organization: $organization, registration: $registration, state: $state)';
}


}

/// @nodoc
abstract mixin class $ServiceCopyWith<$Res>  {
  factory $ServiceCopyWith(Service value, $Res Function(Service) _then) = _$ServiceCopyWithImpl;
@useResult
$Res call({
 skir.RecordId serviceId, int revision, String name, ServiceRole role, DateTime createdAt, skir.RecordId? organization, ServiceRegistration? registration, ServiceState? state
});


$ServiceRoleCopyWith<$Res> get role;$ServiceRegistrationCopyWith<$Res>? get registration;$ServiceStateCopyWith<$Res>? get state;

}
/// @nodoc
class _$ServiceCopyWithImpl<$Res>
    implements $ServiceCopyWith<$Res> {
  _$ServiceCopyWithImpl(this._self, this._then);

  final Service _self;
  final $Res Function(Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceId = null,Object? revision = null,Object? name = null,Object? role = null,Object? createdAt = null,Object? organization = freezed,Object? registration = freezed,Object? state = freezed,}) {
  return _then(_self.copyWith(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ServiceRole,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,registration: freezed == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as ServiceRegistration?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ServiceState?,
  ));
}
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceRoleCopyWith<$Res> get role {
  
  return $ServiceRoleCopyWith<$Res>(_self.role, (value) {
    return _then(_self.copyWith(role: value));
  });
}/// Create a copy of Service
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId serviceId,  int revision,  String name,  ServiceRole role,  DateTime createdAt,  skir.RecordId? organization,  ServiceRegistration? registration,  ServiceState? state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.serviceId,_that.revision,_that.name,_that.role,_that.createdAt,_that.organization,_that.registration,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId serviceId,  int revision,  String name,  ServiceRole role,  DateTime createdAt,  skir.RecordId? organization,  ServiceRegistration? registration,  ServiceState? state)  $default,) {final _that = this;
switch (_that) {
case _Service():
return $default(_that.serviceId,_that.revision,_that.name,_that.role,_that.createdAt,_that.organization,_that.registration,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId serviceId,  int revision,  String name,  ServiceRole role,  DateTime createdAt,  skir.RecordId? organization,  ServiceRegistration? registration,  ServiceState? state)?  $default,) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.serviceId,_that.revision,_that.name,_that.role,_that.createdAt,_that.organization,_that.registration,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _Service extends Service {
   _Service({required this.serviceId, required this.revision, required this.name, required this.role, required this.createdAt, this.organization, this.registration, this.state}): assert(name.isNotEmpty, 'Name must not be empty.'),super._();
  

@override final  skir.RecordId serviceId;
@override final  int revision;
@override final  String name;
@override final  ServiceRole role;
@override final  DateTime createdAt;
@override final  skir.RecordId? organization;
@override final  ServiceRegistration? registration;
@override final  ServiceState? state;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCopyWith<_Service> get copyWith => __$ServiceCopyWithImpl<_Service>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Service&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.registration, registration) || other.registration == registration)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,serviceId,revision,name,role,createdAt,organization,registration,state);

@override
String toString() {
  return 'Service(serviceId: $serviceId, revision: $revision, name: $name, role: $role, createdAt: $createdAt, organization: $organization, registration: $registration, state: $state)';
}


}

/// @nodoc
abstract mixin class _$ServiceCopyWith<$Res> implements $ServiceCopyWith<$Res> {
  factory _$ServiceCopyWith(_Service value, $Res Function(_Service) _then) = __$ServiceCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId serviceId, int revision, String name, ServiceRole role, DateTime createdAt, skir.RecordId? organization, ServiceRegistration? registration, ServiceState? state
});


@override $ServiceRoleCopyWith<$Res> get role;@override $ServiceRegistrationCopyWith<$Res>? get registration;@override $ServiceStateCopyWith<$Res>? get state;

}
/// @nodoc
class __$ServiceCopyWithImpl<$Res>
    implements _$ServiceCopyWith<$Res> {
  __$ServiceCopyWithImpl(this._self, this._then);

  final _Service _self;
  final $Res Function(_Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceId = null,Object? revision = null,Object? name = null,Object? role = null,Object? createdAt = null,Object? organization = freezed,Object? registration = freezed,Object? state = freezed,}) {
  return _then(_Service(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ServiceRole,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as skir.RecordId?,registration: freezed == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as ServiceRegistration?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ServiceState?,
  ));
}

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceRoleCopyWith<$Res> get role {
  
  return $ServiceRoleCopyWith<$Res>(_self.role, (value) {
    return _then(_self.copyWith(role: value));
  });
}/// Create a copy of Service
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HostServiceRole value)?  host,TResult Function( CustomServiceRole value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HostServiceRole() when host != null:
return host(_that);case CustomServiceRole() when custom != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HostServiceRole value)  host,required TResult Function( CustomServiceRole value)  custom,}){
final _that = this;
switch (_that) {
case HostServiceRole():
return host(_that);case CustomServiceRole():
return custom(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HostServiceRole value)?  host,TResult? Function( CustomServiceRole value)?  custom,}){
final _that = this;
switch (_that) {
case HostServiceRole() when host != null:
return host(_that);case CustomServiceRole() when custom != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String version)?  host,TResult Function( String version,  String name)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HostServiceRole() when host != null:
return host(_that.version);case CustomServiceRole() when custom != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String version)  host,required TResult Function( String version,  String name)  custom,}) {final _that = this;
switch (_that) {
case HostServiceRole():
return host(_that.version);case CustomServiceRole():
return custom(_that.version,_that.name);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String version)?  host,TResult? Function( String version,  String name)?  custom,}) {final _that = this;
switch (_that) {
case HostServiceRole() when host != null:
return host(_that.version);case CustomServiceRole() when custom != null:
return custom(_that.version,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class HostServiceRole extends ServiceRole {
   HostServiceRole({required this.version}): assert(version.isNotEmpty, 'Version must not be empty.'),super._();
  

@override final  String version;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostServiceRoleCopyWith<HostServiceRole> get copyWith => _$HostServiceRoleCopyWithImpl<HostServiceRole>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostServiceRole&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,version);

@override
String toString() {
  return 'ServiceRole.host(version: $version)';
}


}

/// @nodoc
abstract mixin class $HostServiceRoleCopyWith<$Res> implements $ServiceRoleCopyWith<$Res> {
  factory $HostServiceRoleCopyWith(HostServiceRole value, $Res Function(HostServiceRole) _then) = _$HostServiceRoleCopyWithImpl;
@override @useResult
$Res call({
 String version
});




}
/// @nodoc
class _$HostServiceRoleCopyWithImpl<$Res>
    implements $HostServiceRoleCopyWith<$Res> {
  _$HostServiceRoleCopyWithImpl(this._self, this._then);

  final HostServiceRole _self;
  final $Res Function(HostServiceRole) _then;

/// Create a copy of ServiceRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,}) {
  return _then(HostServiceRole(
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

/// @nodoc
mixin _$TopologyRevision {

 int get desired; int get applied;
/// Create a copy of TopologyRevision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyRevisionCopyWith<TopologyRevision> get copyWith => _$TopologyRevisionCopyWithImpl<TopologyRevision>(this as TopologyRevision, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyRevision&&(identical(other.desired, desired) || other.desired == desired)&&(identical(other.applied, applied) || other.applied == applied));
}


@override
int get hashCode => Object.hash(runtimeType,desired,applied);

@override
String toString() {
  return 'TopologyRevision(desired: $desired, applied: $applied)';
}


}

/// @nodoc
abstract mixin class $TopologyRevisionCopyWith<$Res>  {
  factory $TopologyRevisionCopyWith(TopologyRevision value, $Res Function(TopologyRevision) _then) = _$TopologyRevisionCopyWithImpl;
@useResult
$Res call({
 int desired, int applied
});




}
/// @nodoc
class _$TopologyRevisionCopyWithImpl<$Res>
    implements $TopologyRevisionCopyWith<$Res> {
  _$TopologyRevisionCopyWithImpl(this._self, this._then);

  final TopologyRevision _self;
  final $Res Function(TopologyRevision) _then;

/// Create a copy of TopologyRevision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? desired = null,Object? applied = null,}) {
  return _then(_self.copyWith(
desired: null == desired ? _self.desired : desired // ignore: cast_nullable_to_non_nullable
as int,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TopologyRevision].
extension TopologyRevisionPatterns on TopologyRevision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyRevision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyRevision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyRevision value)  $default,){
final _that = this;
switch (_that) {
case _TopologyRevision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyRevision value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyRevision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int desired,  int applied)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyRevision() when $default != null:
return $default(_that.desired,_that.applied);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int desired,  int applied)  $default,) {final _that = this;
switch (_that) {
case _TopologyRevision():
return $default(_that.desired,_that.applied);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int desired,  int applied)?  $default,) {final _that = this;
switch (_that) {
case _TopologyRevision() when $default != null:
return $default(_that.desired,_that.applied);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyRevision implements TopologyRevision {
  const _TopologyRevision({required this.desired, required this.applied});
  

@override final  int desired;
@override final  int applied;

/// Create a copy of TopologyRevision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyRevisionCopyWith<_TopologyRevision> get copyWith => __$TopologyRevisionCopyWithImpl<_TopologyRevision>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyRevision&&(identical(other.desired, desired) || other.desired == desired)&&(identical(other.applied, applied) || other.applied == applied));
}


@override
int get hashCode => Object.hash(runtimeType,desired,applied);

@override
String toString() {
  return 'TopologyRevision(desired: $desired, applied: $applied)';
}


}

/// @nodoc
abstract mixin class _$TopologyRevisionCopyWith<$Res> implements $TopologyRevisionCopyWith<$Res> {
  factory _$TopologyRevisionCopyWith(_TopologyRevision value, $Res Function(_TopologyRevision) _then) = __$TopologyRevisionCopyWithImpl;
@override @useResult
$Res call({
 int desired, int applied
});




}
/// @nodoc
class __$TopologyRevisionCopyWithImpl<$Res>
    implements _$TopologyRevisionCopyWith<$Res> {
  __$TopologyRevisionCopyWithImpl(this._self, this._then);

  final _TopologyRevision _self;
  final $Res Function(_TopologyRevision) _then;

/// Create a copy of TopologyRevision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? desired = null,Object? applied = null,}) {
  return _then(_TopologyRevision(
desired: null == desired ? _self.desired : desired // ignore: cast_nullable_to_non_nullable
as int,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TopologyEngineTarget {

 String get engineId; String get versionConstraint;
/// Create a copy of TopologyEngineTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyEngineTargetCopyWith<TopologyEngineTarget> get copyWith => _$TopologyEngineTargetCopyWithImpl<TopologyEngineTarget>(this as TopologyEngineTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyEngineTarget&&(identical(other.engineId, engineId) || other.engineId == engineId)&&(identical(other.versionConstraint, versionConstraint) || other.versionConstraint == versionConstraint));
}


@override
int get hashCode => Object.hash(runtimeType,engineId,versionConstraint);

@override
String toString() {
  return 'TopologyEngineTarget(engineId: $engineId, versionConstraint: $versionConstraint)';
}


}

/// @nodoc
abstract mixin class $TopologyEngineTargetCopyWith<$Res>  {
  factory $TopologyEngineTargetCopyWith(TopologyEngineTarget value, $Res Function(TopologyEngineTarget) _then) = _$TopologyEngineTargetCopyWithImpl;
@useResult
$Res call({
 String engineId, String versionConstraint
});




}
/// @nodoc
class _$TopologyEngineTargetCopyWithImpl<$Res>
    implements $TopologyEngineTargetCopyWith<$Res> {
  _$TopologyEngineTargetCopyWithImpl(this._self, this._then);

  final TopologyEngineTarget _self;
  final $Res Function(TopologyEngineTarget) _then;

/// Create a copy of TopologyEngineTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? engineId = null,Object? versionConstraint = null,}) {
  return _then(_self.copyWith(
engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String,versionConstraint: null == versionConstraint ? _self.versionConstraint : versionConstraint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TopologyEngineTarget].
extension TopologyEngineTargetPatterns on TopologyEngineTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyEngineTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyEngineTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyEngineTarget value)  $default,){
final _that = this;
switch (_that) {
case _TopologyEngineTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyEngineTarget value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyEngineTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String engineId,  String versionConstraint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyEngineTarget() when $default != null:
return $default(_that.engineId,_that.versionConstraint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String engineId,  String versionConstraint)  $default,) {final _that = this;
switch (_that) {
case _TopologyEngineTarget():
return $default(_that.engineId,_that.versionConstraint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String engineId,  String versionConstraint)?  $default,) {final _that = this;
switch (_that) {
case _TopologyEngineTarget() when $default != null:
return $default(_that.engineId,_that.versionConstraint);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyEngineTarget extends TopologyEngineTarget {
  const _TopologyEngineTarget({required this.engineId, required this.versionConstraint}): super._();
  

@override final  String engineId;
@override final  String versionConstraint;

/// Create a copy of TopologyEngineTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyEngineTargetCopyWith<_TopologyEngineTarget> get copyWith => __$TopologyEngineTargetCopyWithImpl<_TopologyEngineTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyEngineTarget&&(identical(other.engineId, engineId) || other.engineId == engineId)&&(identical(other.versionConstraint, versionConstraint) || other.versionConstraint == versionConstraint));
}


@override
int get hashCode => Object.hash(runtimeType,engineId,versionConstraint);

@override
String toString() {
  return 'TopologyEngineTarget(engineId: $engineId, versionConstraint: $versionConstraint)';
}


}

/// @nodoc
abstract mixin class _$TopologyEngineTargetCopyWith<$Res> implements $TopologyEngineTargetCopyWith<$Res> {
  factory _$TopologyEngineTargetCopyWith(_TopologyEngineTarget value, $Res Function(_TopologyEngineTarget) _then) = __$TopologyEngineTargetCopyWithImpl;
@override @useResult
$Res call({
 String engineId, String versionConstraint
});




}
/// @nodoc
class __$TopologyEngineTargetCopyWithImpl<$Res>
    implements _$TopologyEngineTargetCopyWith<$Res> {
  __$TopologyEngineTargetCopyWithImpl(this._self, this._then);

  final _TopologyEngineTarget _self;
  final $Res Function(_TopologyEngineTarget) _then;

/// Create a copy of TopologyEngineTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? engineId = null,Object? versionConstraint = null,}) {
  return _then(_TopologyEngineTarget(
engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String,versionConstraint: null == versionConstraint ? _self.versionConstraint : versionConstraint // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TopologySupportedEngine {

 String get engineId;
/// Create a copy of TopologySupportedEngine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologySupportedEngineCopyWith<TopologySupportedEngine> get copyWith => _$TopologySupportedEngineCopyWithImpl<TopologySupportedEngine>(this as TopologySupportedEngine, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologySupportedEngine&&(identical(other.engineId, engineId) || other.engineId == engineId));
}


@override
int get hashCode => Object.hash(runtimeType,engineId);

@override
String toString() {
  return 'TopologySupportedEngine(engineId: $engineId)';
}


}

/// @nodoc
abstract mixin class $TopologySupportedEngineCopyWith<$Res>  {
  factory $TopologySupportedEngineCopyWith(TopologySupportedEngine value, $Res Function(TopologySupportedEngine) _then) = _$TopologySupportedEngineCopyWithImpl;
@useResult
$Res call({
 String engineId
});




}
/// @nodoc
class _$TopologySupportedEngineCopyWithImpl<$Res>
    implements $TopologySupportedEngineCopyWith<$Res> {
  _$TopologySupportedEngineCopyWithImpl(this._self, this._then);

  final TopologySupportedEngine _self;
  final $Res Function(TopologySupportedEngine) _then;

/// Create a copy of TopologySupportedEngine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? engineId = null,}) {
  return _then(_self.copyWith(
engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TopologySupportedEngine].
extension TopologySupportedEnginePatterns on TopologySupportedEngine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologySupportedEngine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologySupportedEngine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologySupportedEngine value)  $default,){
final _that = this;
switch (_that) {
case _TopologySupportedEngine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologySupportedEngine value)?  $default,){
final _that = this;
switch (_that) {
case _TopologySupportedEngine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String engineId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologySupportedEngine() when $default != null:
return $default(_that.engineId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String engineId)  $default,) {final _that = this;
switch (_that) {
case _TopologySupportedEngine():
return $default(_that.engineId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String engineId)?  $default,) {final _that = this;
switch (_that) {
case _TopologySupportedEngine() when $default != null:
return $default(_that.engineId);case _:
  return null;

}
}

}

/// @nodoc


class _TopologySupportedEngine implements TopologySupportedEngine {
  const _TopologySupportedEngine({required this.engineId});
  

@override final  String engineId;

/// Create a copy of TopologySupportedEngine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologySupportedEngineCopyWith<_TopologySupportedEngine> get copyWith => __$TopologySupportedEngineCopyWithImpl<_TopologySupportedEngine>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologySupportedEngine&&(identical(other.engineId, engineId) || other.engineId == engineId));
}


@override
int get hashCode => Object.hash(runtimeType,engineId);

@override
String toString() {
  return 'TopologySupportedEngine(engineId: $engineId)';
}


}

/// @nodoc
abstract mixin class _$TopologySupportedEngineCopyWith<$Res> implements $TopologySupportedEngineCopyWith<$Res> {
  factory _$TopologySupportedEngineCopyWith(_TopologySupportedEngine value, $Res Function(_TopologySupportedEngine) _then) = __$TopologySupportedEngineCopyWithImpl;
@override @useResult
$Res call({
 String engineId
});




}
/// @nodoc
class __$TopologySupportedEngineCopyWithImpl<$Res>
    implements _$TopologySupportedEngineCopyWith<$Res> {
  __$TopologySupportedEngineCopyWithImpl(this._self, this._then);

  final _TopologySupportedEngine _self;
  final $Res Function(_TopologySupportedEngine) _then;

/// Create a copy of TopologySupportedEngine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? engineId = null,}) {
  return _then(_TopologySupportedEngine(
engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TopologyHostState {

 TopologyHostStatus get status; String? get message; DateTime get updatedAt;
/// Create a copy of TopologyHostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyHostStateCopyWith<TopologyHostState> get copyWith => _$TopologyHostStateCopyWithImpl<TopologyHostState>(this as TopologyHostState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyHostState&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,message,updatedAt);

@override
String toString() {
  return 'TopologyHostState(status: $status, message: $message, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TopologyHostStateCopyWith<$Res>  {
  factory $TopologyHostStateCopyWith(TopologyHostState value, $Res Function(TopologyHostState) _then) = _$TopologyHostStateCopyWithImpl;
@useResult
$Res call({
 TopologyHostStatus status, String? message, DateTime updatedAt
});




}
/// @nodoc
class _$TopologyHostStateCopyWithImpl<$Res>
    implements $TopologyHostStateCopyWith<$Res> {
  _$TopologyHostStateCopyWithImpl(this._self, this._then);

  final TopologyHostState _self;
  final $Res Function(TopologyHostState) _then;

/// Create a copy of TopologyHostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? message = freezed,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopologyHostStatus,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TopologyHostState].
extension TopologyHostStatePatterns on TopologyHostState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyHostState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyHostState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyHostState value)  $default,){
final _that = this;
switch (_that) {
case _TopologyHostState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyHostState value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyHostState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TopologyHostStatus status,  String? message,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyHostState() when $default != null:
return $default(_that.status,_that.message,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TopologyHostStatus status,  String? message,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TopologyHostState():
return $default(_that.status,_that.message,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TopologyHostStatus status,  String? message,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TopologyHostState() when $default != null:
return $default(_that.status,_that.message,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyHostState implements TopologyHostState {
  const _TopologyHostState({required this.status, required this.message, required this.updatedAt});
  

@override final  TopologyHostStatus status;
@override final  String? message;
@override final  DateTime updatedAt;

/// Create a copy of TopologyHostState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyHostStateCopyWith<_TopologyHostState> get copyWith => __$TopologyHostStateCopyWithImpl<_TopologyHostState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyHostState&&(identical(other.status, status) || other.status == status)&&(identical(other.message, message) || other.message == message)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,message,updatedAt);

@override
String toString() {
  return 'TopologyHostState(status: $status, message: $message, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TopologyHostStateCopyWith<$Res> implements $TopologyHostStateCopyWith<$Res> {
  factory _$TopologyHostStateCopyWith(_TopologyHostState value, $Res Function(_TopologyHostState) _then) = __$TopologyHostStateCopyWithImpl;
@override @useResult
$Res call({
 TopologyHostStatus status, String? message, DateTime updatedAt
});




}
/// @nodoc
class __$TopologyHostStateCopyWithImpl<$Res>
    implements _$TopologyHostStateCopyWith<$Res> {
  __$TopologyHostStateCopyWithImpl(this._self, this._then);

  final _TopologyHostState _self;
  final $Res Function(_TopologyHostState) _then;

/// Create a copy of TopologyHostState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? message = freezed,Object? updatedAt = null,}) {
  return _then(_TopologyHostState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopologyHostStatus,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$TopologyRuntimeState {

 TopologyRuntimeStatus get status; String? get activeArtifactVersion; String? get message; DateTime get updatedAt;
/// Create a copy of TopologyRuntimeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyRuntimeStateCopyWith<TopologyRuntimeState> get copyWith => _$TopologyRuntimeStateCopyWithImpl<TopologyRuntimeState>(this as TopologyRuntimeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyRuntimeState&&(identical(other.status, status) || other.status == status)&&(identical(other.activeArtifactVersion, activeArtifactVersion) || other.activeArtifactVersion == activeArtifactVersion)&&(identical(other.message, message) || other.message == message)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,activeArtifactVersion,message,updatedAt);

@override
String toString() {
  return 'TopologyRuntimeState(status: $status, activeArtifactVersion: $activeArtifactVersion, message: $message, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TopologyRuntimeStateCopyWith<$Res>  {
  factory $TopologyRuntimeStateCopyWith(TopologyRuntimeState value, $Res Function(TopologyRuntimeState) _then) = _$TopologyRuntimeStateCopyWithImpl;
@useResult
$Res call({
 TopologyRuntimeStatus status, String? activeArtifactVersion, String? message, DateTime updatedAt
});




}
/// @nodoc
class _$TopologyRuntimeStateCopyWithImpl<$Res>
    implements $TopologyRuntimeStateCopyWith<$Res> {
  _$TopologyRuntimeStateCopyWithImpl(this._self, this._then);

  final TopologyRuntimeState _self;
  final $Res Function(TopologyRuntimeState) _then;

/// Create a copy of TopologyRuntimeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? activeArtifactVersion = freezed,Object? message = freezed,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopologyRuntimeStatus,activeArtifactVersion: freezed == activeArtifactVersion ? _self.activeArtifactVersion : activeArtifactVersion // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TopologyRuntimeState].
extension TopologyRuntimeStatePatterns on TopologyRuntimeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyRuntimeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyRuntimeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyRuntimeState value)  $default,){
final _that = this;
switch (_that) {
case _TopologyRuntimeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyRuntimeState value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyRuntimeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TopologyRuntimeStatus status,  String? activeArtifactVersion,  String? message,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyRuntimeState() when $default != null:
return $default(_that.status,_that.activeArtifactVersion,_that.message,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TopologyRuntimeStatus status,  String? activeArtifactVersion,  String? message,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TopologyRuntimeState():
return $default(_that.status,_that.activeArtifactVersion,_that.message,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TopologyRuntimeStatus status,  String? activeArtifactVersion,  String? message,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TopologyRuntimeState() when $default != null:
return $default(_that.status,_that.activeArtifactVersion,_that.message,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyRuntimeState implements TopologyRuntimeState {
  const _TopologyRuntimeState({required this.status, required this.activeArtifactVersion, required this.message, required this.updatedAt});
  

@override final  TopologyRuntimeStatus status;
@override final  String? activeArtifactVersion;
@override final  String? message;
@override final  DateTime updatedAt;

/// Create a copy of TopologyRuntimeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyRuntimeStateCopyWith<_TopologyRuntimeState> get copyWith => __$TopologyRuntimeStateCopyWithImpl<_TopologyRuntimeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyRuntimeState&&(identical(other.status, status) || other.status == status)&&(identical(other.activeArtifactVersion, activeArtifactVersion) || other.activeArtifactVersion == activeArtifactVersion)&&(identical(other.message, message) || other.message == message)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,activeArtifactVersion,message,updatedAt);

@override
String toString() {
  return 'TopologyRuntimeState(status: $status, activeArtifactVersion: $activeArtifactVersion, message: $message, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TopologyRuntimeStateCopyWith<$Res> implements $TopologyRuntimeStateCopyWith<$Res> {
  factory _$TopologyRuntimeStateCopyWith(_TopologyRuntimeState value, $Res Function(_TopologyRuntimeState) _then) = __$TopologyRuntimeStateCopyWithImpl;
@override @useResult
$Res call({
 TopologyRuntimeStatus status, String? activeArtifactVersion, String? message, DateTime updatedAt
});




}
/// @nodoc
class __$TopologyRuntimeStateCopyWithImpl<$Res>
    implements _$TopologyRuntimeStateCopyWith<$Res> {
  __$TopologyRuntimeStateCopyWithImpl(this._self, this._then);

  final _TopologyRuntimeState _self;
  final $Res Function(_TopologyRuntimeState) _then;

/// Create a copy of TopologyRuntimeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? activeArtifactVersion = freezed,Object? message = freezed,Object? updatedAt = null,}) {
  return _then(_TopologyRuntimeState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopologyRuntimeStatus,activeArtifactVersion: freezed == activeArtifactVersion ? _self.activeArtifactVersion : activeArtifactVersion // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$TopologyOwnerHost {

 skir.RecordId get id; String get name;
/// Create a copy of TopologyOwnerHost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyOwnerHostCopyWith<TopologyOwnerHost> get copyWith => _$TopologyOwnerHostCopyWithImpl<TopologyOwnerHost>(this as TopologyOwnerHost, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyOwnerHost&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'TopologyOwnerHost(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $TopologyOwnerHostCopyWith<$Res>  {
  factory $TopologyOwnerHostCopyWith(TopologyOwnerHost value, $Res Function(TopologyOwnerHost) _then) = _$TopologyOwnerHostCopyWithImpl;
@useResult
$Res call({
 skir.RecordId id, String name
});




}
/// @nodoc
class _$TopologyOwnerHostCopyWithImpl<$Res>
    implements $TopologyOwnerHostCopyWith<$Res> {
  _$TopologyOwnerHostCopyWithImpl(this._self, this._then);

  final TopologyOwnerHost _self;
  final $Res Function(TopologyOwnerHost) _then;

/// Create a copy of TopologyOwnerHost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TopologyOwnerHost].
extension TopologyOwnerHostPatterns on TopologyOwnerHost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyOwnerHost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyOwnerHost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyOwnerHost value)  $default,){
final _that = this;
switch (_that) {
case _TopologyOwnerHost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyOwnerHost value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyOwnerHost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyOwnerHost() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId id,  String name)  $default,) {final _that = this;
switch (_that) {
case _TopologyOwnerHost():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _TopologyOwnerHost() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyOwnerHost implements TopologyOwnerHost {
  const _TopologyOwnerHost({required this.id, required this.name});
  

@override final  skir.RecordId id;
@override final  String name;

/// Create a copy of TopologyOwnerHost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyOwnerHostCopyWith<_TopologyOwnerHost> get copyWith => __$TopologyOwnerHostCopyWithImpl<_TopologyOwnerHost>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyOwnerHost&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'TopologyOwnerHost(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$TopologyOwnerHostCopyWith<$Res> implements $TopologyOwnerHostCopyWith<$Res> {
  factory _$TopologyOwnerHostCopyWith(_TopologyOwnerHost value, $Res Function(_TopologyOwnerHost) _then) = __$TopologyOwnerHostCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId id, String name
});




}
/// @nodoc
class __$TopologyOwnerHostCopyWithImpl<$Res>
    implements _$TopologyOwnerHostCopyWith<$Res> {
  __$TopologyOwnerHostCopyWithImpl(this._self, this._then);

  final _TopologyOwnerHost _self;
  final $Res Function(_TopologyOwnerHost) _then;

/// Create a copy of TopologyOwnerHost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_TopologyOwnerHost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TopologyRealmInfo {

 skir.RecordId get realmId; TopologyOwnerHost get ownerHost;
/// Create a copy of TopologyRealmInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyRealmInfoCopyWith<TopologyRealmInfo> get copyWith => _$TopologyRealmInfoCopyWithImpl<TopologyRealmInfo>(this as TopologyRealmInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyRealmInfo&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.ownerHost, ownerHost) || other.ownerHost == ownerHost));
}


@override
int get hashCode => Object.hash(runtimeType,realmId,ownerHost);

@override
String toString() {
  return 'TopologyRealmInfo(realmId: $realmId, ownerHost: $ownerHost)';
}


}

/// @nodoc
abstract mixin class $TopologyRealmInfoCopyWith<$Res>  {
  factory $TopologyRealmInfoCopyWith(TopologyRealmInfo value, $Res Function(TopologyRealmInfo) _then) = _$TopologyRealmInfoCopyWithImpl;
@useResult
$Res call({
 skir.RecordId realmId, TopologyOwnerHost ownerHost
});


$TopologyOwnerHostCopyWith<$Res> get ownerHost;

}
/// @nodoc
class _$TopologyRealmInfoCopyWithImpl<$Res>
    implements $TopologyRealmInfoCopyWith<$Res> {
  _$TopologyRealmInfoCopyWithImpl(this._self, this._then);

  final TopologyRealmInfo _self;
  final $Res Function(TopologyRealmInfo) _then;

/// Create a copy of TopologyRealmInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? realmId = null,Object? ownerHost = null,}) {
  return _then(_self.copyWith(
realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,ownerHost: null == ownerHost ? _self.ownerHost : ownerHost // ignore: cast_nullable_to_non_nullable
as TopologyOwnerHost,
  ));
}
/// Create a copy of TopologyRealmInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyOwnerHostCopyWith<$Res> get ownerHost {
  
  return $TopologyOwnerHostCopyWith<$Res>(_self.ownerHost, (value) {
    return _then(_self.copyWith(ownerHost: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopologyRealmInfo].
extension TopologyRealmInfoPatterns on TopologyRealmInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyRealmInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyRealmInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyRealmInfo value)  $default,){
final _that = this;
switch (_that) {
case _TopologyRealmInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyRealmInfo value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyRealmInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId realmId,  TopologyOwnerHost ownerHost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyRealmInfo() when $default != null:
return $default(_that.realmId,_that.ownerHost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId realmId,  TopologyOwnerHost ownerHost)  $default,) {final _that = this;
switch (_that) {
case _TopologyRealmInfo():
return $default(_that.realmId,_that.ownerHost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId realmId,  TopologyOwnerHost ownerHost)?  $default,) {final _that = this;
switch (_that) {
case _TopologyRealmInfo() when $default != null:
return $default(_that.realmId,_that.ownerHost);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyRealmInfo implements TopologyRealmInfo {
  const _TopologyRealmInfo({required this.realmId, required this.ownerHost});
  

@override final  skir.RecordId realmId;
@override final  TopologyOwnerHost ownerHost;

/// Create a copy of TopologyRealmInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyRealmInfoCopyWith<_TopologyRealmInfo> get copyWith => __$TopologyRealmInfoCopyWithImpl<_TopologyRealmInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyRealmInfo&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.ownerHost, ownerHost) || other.ownerHost == ownerHost));
}


@override
int get hashCode => Object.hash(runtimeType,realmId,ownerHost);

@override
String toString() {
  return 'TopologyRealmInfo(realmId: $realmId, ownerHost: $ownerHost)';
}


}

/// @nodoc
abstract mixin class _$TopologyRealmInfoCopyWith<$Res> implements $TopologyRealmInfoCopyWith<$Res> {
  factory _$TopologyRealmInfoCopyWith(_TopologyRealmInfo value, $Res Function(_TopologyRealmInfo) _then) = __$TopologyRealmInfoCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId realmId, TopologyOwnerHost ownerHost
});


@override $TopologyOwnerHostCopyWith<$Res> get ownerHost;

}
/// @nodoc
class __$TopologyRealmInfoCopyWithImpl<$Res>
    implements _$TopologyRealmInfoCopyWith<$Res> {
  __$TopologyRealmInfoCopyWithImpl(this._self, this._then);

  final _TopologyRealmInfo _self;
  final $Res Function(_TopologyRealmInfo) _then;

/// Create a copy of TopologyRealmInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? realmId = null,Object? ownerHost = null,}) {
  return _then(_TopologyRealmInfo(
realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,ownerHost: null == ownerHost ? _self.ownerHost : ownerHost // ignore: cast_nullable_to_non_nullable
as TopologyOwnerHost,
  ));
}

/// Create a copy of TopologyRealmInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyOwnerHostCopyWith<$Res> get ownerHost {
  
  return $TopologyOwnerHostCopyWith<$Res>(_self.ownerHost, (value) {
    return _then(_self.copyWith(ownerHost: value));
  });
}
}

/// @nodoc
mixin _$TopologyHost {

 skir.RecordId get hostId; skir.RecordId get serviceId; int get revision; String get entrypoint; bool get canHostRealm; List<TopologySupportedEngine> get supportedEngines; TopologyRevision get topologyRevision; TopologyHostState get state;
/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyHostCopyWith<TopologyHost> get copyWith => _$TopologyHostCopyWithImpl<TopologyHost>(this as TopologyHost, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyHost&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.entrypoint, entrypoint) || other.entrypoint == entrypoint)&&(identical(other.canHostRealm, canHostRealm) || other.canHostRealm == canHostRealm)&&const DeepCollectionEquality().equals(other.supportedEngines, supportedEngines)&&(identical(other.topologyRevision, topologyRevision) || other.topologyRevision == topologyRevision)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,hostId,serviceId,revision,entrypoint,canHostRealm,const DeepCollectionEquality().hash(supportedEngines),topologyRevision,state);

@override
String toString() {
  return 'TopologyHost(hostId: $hostId, serviceId: $serviceId, revision: $revision, entrypoint: $entrypoint, canHostRealm: $canHostRealm, supportedEngines: $supportedEngines, topologyRevision: $topologyRevision, state: $state)';
}


}

/// @nodoc
abstract mixin class $TopologyHostCopyWith<$Res>  {
  factory $TopologyHostCopyWith(TopologyHost value, $Res Function(TopologyHost) _then) = _$TopologyHostCopyWithImpl;
@useResult
$Res call({
 skir.RecordId hostId, skir.RecordId serviceId, int revision, String entrypoint, bool canHostRealm, List<TopologySupportedEngine> supportedEngines, TopologyRevision topologyRevision, TopologyHostState state
});


$TopologyRevisionCopyWith<$Res> get topologyRevision;$TopologyHostStateCopyWith<$Res> get state;

}
/// @nodoc
class _$TopologyHostCopyWithImpl<$Res>
    implements $TopologyHostCopyWith<$Res> {
  _$TopologyHostCopyWithImpl(this._self, this._then);

  final TopologyHost _self;
  final $Res Function(TopologyHost) _then;

/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hostId = null,Object? serviceId = null,Object? revision = null,Object? entrypoint = null,Object? canHostRealm = null,Object? supportedEngines = null,Object? topologyRevision = null,Object? state = null,}) {
  return _then(_self.copyWith(
hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,entrypoint: null == entrypoint ? _self.entrypoint : entrypoint // ignore: cast_nullable_to_non_nullable
as String,canHostRealm: null == canHostRealm ? _self.canHostRealm : canHostRealm // ignore: cast_nullable_to_non_nullable
as bool,supportedEngines: null == supportedEngines ? _self.supportedEngines : supportedEngines // ignore: cast_nullable_to_non_nullable
as List<TopologySupportedEngine>,topologyRevision: null == topologyRevision ? _self.topologyRevision : topologyRevision // ignore: cast_nullable_to_non_nullable
as TopologyRevision,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TopologyHostState,
  ));
}
/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRevisionCopyWith<$Res> get topologyRevision {
  
  return $TopologyRevisionCopyWith<$Res>(_self.topologyRevision, (value) {
    return _then(_self.copyWith(topologyRevision: value));
  });
}/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyHostStateCopyWith<$Res> get state {
  
  return $TopologyHostStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopologyHost].
extension TopologyHostPatterns on TopologyHost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyHost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyHost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyHost value)  $default,){
final _that = this;
switch (_that) {
case _TopologyHost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyHost value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyHost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId hostId,  skir.RecordId serviceId,  int revision,  String entrypoint,  bool canHostRealm,  List<TopologySupportedEngine> supportedEngines,  TopologyRevision topologyRevision,  TopologyHostState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyHost() when $default != null:
return $default(_that.hostId,_that.serviceId,_that.revision,_that.entrypoint,_that.canHostRealm,_that.supportedEngines,_that.topologyRevision,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId hostId,  skir.RecordId serviceId,  int revision,  String entrypoint,  bool canHostRealm,  List<TopologySupportedEngine> supportedEngines,  TopologyRevision topologyRevision,  TopologyHostState state)  $default,) {final _that = this;
switch (_that) {
case _TopologyHost():
return $default(_that.hostId,_that.serviceId,_that.revision,_that.entrypoint,_that.canHostRealm,_that.supportedEngines,_that.topologyRevision,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId hostId,  skir.RecordId serviceId,  int revision,  String entrypoint,  bool canHostRealm,  List<TopologySupportedEngine> supportedEngines,  TopologyRevision topologyRevision,  TopologyHostState state)?  $default,) {final _that = this;
switch (_that) {
case _TopologyHost() when $default != null:
return $default(_that.hostId,_that.serviceId,_that.revision,_that.entrypoint,_that.canHostRealm,_that.supportedEngines,_that.topologyRevision,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyHost implements TopologyHost {
  const _TopologyHost({required this.hostId, required this.serviceId, required this.revision, required this.entrypoint, required this.canHostRealm, required final  List<TopologySupportedEngine> supportedEngines, required this.topologyRevision, required this.state}): _supportedEngines = supportedEngines;
  

@override final  skir.RecordId hostId;
@override final  skir.RecordId serviceId;
@override final  int revision;
@override final  String entrypoint;
@override final  bool canHostRealm;
 final  List<TopologySupportedEngine> _supportedEngines;
@override List<TopologySupportedEngine> get supportedEngines {
  if (_supportedEngines is EqualUnmodifiableListView) return _supportedEngines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedEngines);
}

@override final  TopologyRevision topologyRevision;
@override final  TopologyHostState state;

/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyHostCopyWith<_TopologyHost> get copyWith => __$TopologyHostCopyWithImpl<_TopologyHost>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyHost&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.entrypoint, entrypoint) || other.entrypoint == entrypoint)&&(identical(other.canHostRealm, canHostRealm) || other.canHostRealm == canHostRealm)&&const DeepCollectionEquality().equals(other._supportedEngines, _supportedEngines)&&(identical(other.topologyRevision, topologyRevision) || other.topologyRevision == topologyRevision)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,hostId,serviceId,revision,entrypoint,canHostRealm,const DeepCollectionEquality().hash(_supportedEngines),topologyRevision,state);

@override
String toString() {
  return 'TopologyHost(hostId: $hostId, serviceId: $serviceId, revision: $revision, entrypoint: $entrypoint, canHostRealm: $canHostRealm, supportedEngines: $supportedEngines, topologyRevision: $topologyRevision, state: $state)';
}


}

/// @nodoc
abstract mixin class _$TopologyHostCopyWith<$Res> implements $TopologyHostCopyWith<$Res> {
  factory _$TopologyHostCopyWith(_TopologyHost value, $Res Function(_TopologyHost) _then) = __$TopologyHostCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId hostId, skir.RecordId serviceId, int revision, String entrypoint, bool canHostRealm, List<TopologySupportedEngine> supportedEngines, TopologyRevision topologyRevision, TopologyHostState state
});


@override $TopologyRevisionCopyWith<$Res> get topologyRevision;@override $TopologyHostStateCopyWith<$Res> get state;

}
/// @nodoc
class __$TopologyHostCopyWithImpl<$Res>
    implements _$TopologyHostCopyWith<$Res> {
  __$TopologyHostCopyWithImpl(this._self, this._then);

  final _TopologyHost _self;
  final $Res Function(_TopologyHost) _then;

/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hostId = null,Object? serviceId = null,Object? revision = null,Object? entrypoint = null,Object? canHostRealm = null,Object? supportedEngines = null,Object? topologyRevision = null,Object? state = null,}) {
  return _then(_TopologyHost(
hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,entrypoint: null == entrypoint ? _self.entrypoint : entrypoint // ignore: cast_nullable_to_non_nullable
as String,canHostRealm: null == canHostRealm ? _self.canHostRealm : canHostRealm // ignore: cast_nullable_to_non_nullable
as bool,supportedEngines: null == supportedEngines ? _self._supportedEngines : supportedEngines // ignore: cast_nullable_to_non_nullable
as List<TopologySupportedEngine>,topologyRevision: null == topologyRevision ? _self.topologyRevision : topologyRevision // ignore: cast_nullable_to_non_nullable
as TopologyRevision,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TopologyHostState,
  ));
}

/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRevisionCopyWith<$Res> get topologyRevision {
  
  return $TopologyRevisionCopyWith<$Res>(_self.topologyRevision, (value) {
    return _then(_self.copyWith(topologyRevision: value));
  });
}/// Create a copy of TopologyHost
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyHostStateCopyWith<$Res> get state {
  
  return $TopologyHostStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$TopologyRealm {

 skir.RecordId get realmId; TopologyOwnerHost get ownerHost; int get revision; TopologyEngineTarget get targetEngine; TopologyRuntimeState get state;
/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyRealmCopyWith<TopologyRealm> get copyWith => _$TopologyRealmCopyWithImpl<TopologyRealm>(this as TopologyRealm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyRealm&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.ownerHost, ownerHost) || other.ownerHost == ownerHost)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.targetEngine, targetEngine) || other.targetEngine == targetEngine)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,realmId,ownerHost,revision,targetEngine,state);

@override
String toString() {
  return 'TopologyRealm(realmId: $realmId, ownerHost: $ownerHost, revision: $revision, targetEngine: $targetEngine, state: $state)';
}


}

/// @nodoc
abstract mixin class $TopologyRealmCopyWith<$Res>  {
  factory $TopologyRealmCopyWith(TopologyRealm value, $Res Function(TopologyRealm) _then) = _$TopologyRealmCopyWithImpl;
@useResult
$Res call({
 skir.RecordId realmId, TopologyOwnerHost ownerHost, int revision, TopologyEngineTarget targetEngine, TopologyRuntimeState state
});


$TopologyOwnerHostCopyWith<$Res> get ownerHost;$TopologyEngineTargetCopyWith<$Res> get targetEngine;$TopologyRuntimeStateCopyWith<$Res> get state;

}
/// @nodoc
class _$TopologyRealmCopyWithImpl<$Res>
    implements $TopologyRealmCopyWith<$Res> {
  _$TopologyRealmCopyWithImpl(this._self, this._then);

  final TopologyRealm _self;
  final $Res Function(TopologyRealm) _then;

/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? realmId = null,Object? ownerHost = null,Object? revision = null,Object? targetEngine = null,Object? state = null,}) {
  return _then(_self.copyWith(
realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,ownerHost: null == ownerHost ? _self.ownerHost : ownerHost // ignore: cast_nullable_to_non_nullable
as TopologyOwnerHost,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,targetEngine: null == targetEngine ? _self.targetEngine : targetEngine // ignore: cast_nullable_to_non_nullable
as TopologyEngineTarget,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TopologyRuntimeState,
  ));
}
/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyOwnerHostCopyWith<$Res> get ownerHost {
  
  return $TopologyOwnerHostCopyWith<$Res>(_self.ownerHost, (value) {
    return _then(_self.copyWith(ownerHost: value));
  });
}/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyEngineTargetCopyWith<$Res> get targetEngine {
  
  return $TopologyEngineTargetCopyWith<$Res>(_self.targetEngine, (value) {
    return _then(_self.copyWith(targetEngine: value));
  });
}/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRuntimeStateCopyWith<$Res> get state {
  
  return $TopologyRuntimeStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopologyRealm].
extension TopologyRealmPatterns on TopologyRealm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyRealm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyRealm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyRealm value)  $default,){
final _that = this;
switch (_that) {
case _TopologyRealm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyRealm value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyRealm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId realmId,  TopologyOwnerHost ownerHost,  int revision,  TopologyEngineTarget targetEngine,  TopologyRuntimeState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyRealm() when $default != null:
return $default(_that.realmId,_that.ownerHost,_that.revision,_that.targetEngine,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId realmId,  TopologyOwnerHost ownerHost,  int revision,  TopologyEngineTarget targetEngine,  TopologyRuntimeState state)  $default,) {final _that = this;
switch (_that) {
case _TopologyRealm():
return $default(_that.realmId,_that.ownerHost,_that.revision,_that.targetEngine,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId realmId,  TopologyOwnerHost ownerHost,  int revision,  TopologyEngineTarget targetEngine,  TopologyRuntimeState state)?  $default,) {final _that = this;
switch (_that) {
case _TopologyRealm() when $default != null:
return $default(_that.realmId,_that.ownerHost,_that.revision,_that.targetEngine,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyRealm implements TopologyRealm {
  const _TopologyRealm({required this.realmId, required this.ownerHost, required this.revision, required this.targetEngine, required this.state});
  

@override final  skir.RecordId realmId;
@override final  TopologyOwnerHost ownerHost;
@override final  int revision;
@override final  TopologyEngineTarget targetEngine;
@override final  TopologyRuntimeState state;

/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyRealmCopyWith<_TopologyRealm> get copyWith => __$TopologyRealmCopyWithImpl<_TopologyRealm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyRealm&&(identical(other.realmId, realmId) || other.realmId == realmId)&&(identical(other.ownerHost, ownerHost) || other.ownerHost == ownerHost)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.targetEngine, targetEngine) || other.targetEngine == targetEngine)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,realmId,ownerHost,revision,targetEngine,state);

@override
String toString() {
  return 'TopologyRealm(realmId: $realmId, ownerHost: $ownerHost, revision: $revision, targetEngine: $targetEngine, state: $state)';
}


}

/// @nodoc
abstract mixin class _$TopologyRealmCopyWith<$Res> implements $TopologyRealmCopyWith<$Res> {
  factory _$TopologyRealmCopyWith(_TopologyRealm value, $Res Function(_TopologyRealm) _then) = __$TopologyRealmCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId realmId, TopologyOwnerHost ownerHost, int revision, TopologyEngineTarget targetEngine, TopologyRuntimeState state
});


@override $TopologyOwnerHostCopyWith<$Res> get ownerHost;@override $TopologyEngineTargetCopyWith<$Res> get targetEngine;@override $TopologyRuntimeStateCopyWith<$Res> get state;

}
/// @nodoc
class __$TopologyRealmCopyWithImpl<$Res>
    implements _$TopologyRealmCopyWith<$Res> {
  __$TopologyRealmCopyWithImpl(this._self, this._then);

  final _TopologyRealm _self;
  final $Res Function(_TopologyRealm) _then;

/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? realmId = null,Object? ownerHost = null,Object? revision = null,Object? targetEngine = null,Object? state = null,}) {
  return _then(_TopologyRealm(
realmId: null == realmId ? _self.realmId : realmId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,ownerHost: null == ownerHost ? _self.ownerHost : ownerHost // ignore: cast_nullable_to_non_nullable
as TopologyOwnerHost,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,targetEngine: null == targetEngine ? _self.targetEngine : targetEngine // ignore: cast_nullable_to_non_nullable
as TopologyEngineTarget,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TopologyRuntimeState,
  ));
}

/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyOwnerHostCopyWith<$Res> get ownerHost {
  
  return $TopologyOwnerHostCopyWith<$Res>(_self.ownerHost, (value) {
    return _then(_self.copyWith(ownerHost: value));
  });
}/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyEngineTargetCopyWith<$Res> get targetEngine {
  
  return $TopologyEngineTargetCopyWith<$Res>(_self.targetEngine, (value) {
    return _then(_self.copyWith(targetEngine: value));
  });
}/// Create a copy of TopologyRealm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRuntimeStateCopyWith<$Res> get state {
  
  return $TopologyRuntimeStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$TopologyEngine {

 skir.RecordId get engineId; TopologyOwnerHost get ownerHost; TopologyRealmInfo get realm; int get revision; TopologyEngineTarget get target; TopologyRuntimeState get state;
/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyEngineCopyWith<TopologyEngine> get copyWith => _$TopologyEngineCopyWithImpl<TopologyEngine>(this as TopologyEngine, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyEngine&&(identical(other.engineId, engineId) || other.engineId == engineId)&&(identical(other.ownerHost, ownerHost) || other.ownerHost == ownerHost)&&(identical(other.realm, realm) || other.realm == realm)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.target, target) || other.target == target)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,engineId,ownerHost,realm,revision,target,state);

@override
String toString() {
  return 'TopologyEngine(engineId: $engineId, ownerHost: $ownerHost, realm: $realm, revision: $revision, target: $target, state: $state)';
}


}

/// @nodoc
abstract mixin class $TopologyEngineCopyWith<$Res>  {
  factory $TopologyEngineCopyWith(TopologyEngine value, $Res Function(TopologyEngine) _then) = _$TopologyEngineCopyWithImpl;
@useResult
$Res call({
 skir.RecordId engineId, TopologyOwnerHost ownerHost, TopologyRealmInfo realm, int revision, TopologyEngineTarget target, TopologyRuntimeState state
});


$TopologyOwnerHostCopyWith<$Res> get ownerHost;$TopologyRealmInfoCopyWith<$Res> get realm;$TopologyEngineTargetCopyWith<$Res> get target;$TopologyRuntimeStateCopyWith<$Res> get state;

}
/// @nodoc
class _$TopologyEngineCopyWithImpl<$Res>
    implements $TopologyEngineCopyWith<$Res> {
  _$TopologyEngineCopyWithImpl(this._self, this._then);

  final TopologyEngine _self;
  final $Res Function(TopologyEngine) _then;

/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? engineId = null,Object? ownerHost = null,Object? realm = null,Object? revision = null,Object? target = null,Object? state = null,}) {
  return _then(_self.copyWith(
engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,ownerHost: null == ownerHost ? _self.ownerHost : ownerHost // ignore: cast_nullable_to_non_nullable
as TopologyOwnerHost,realm: null == realm ? _self.realm : realm // ignore: cast_nullable_to_non_nullable
as TopologyRealmInfo,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as TopologyEngineTarget,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TopologyRuntimeState,
  ));
}
/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyOwnerHostCopyWith<$Res> get ownerHost {
  
  return $TopologyOwnerHostCopyWith<$Res>(_self.ownerHost, (value) {
    return _then(_self.copyWith(ownerHost: value));
  });
}/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRealmInfoCopyWith<$Res> get realm {
  
  return $TopologyRealmInfoCopyWith<$Res>(_self.realm, (value) {
    return _then(_self.copyWith(realm: value));
  });
}/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyEngineTargetCopyWith<$Res> get target {
  
  return $TopologyEngineTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRuntimeStateCopyWith<$Res> get state {
  
  return $TopologyRuntimeStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopologyEngine].
extension TopologyEnginePatterns on TopologyEngine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyEngine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyEngine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyEngine value)  $default,){
final _that = this;
switch (_that) {
case _TopologyEngine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyEngine value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyEngine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId engineId,  TopologyOwnerHost ownerHost,  TopologyRealmInfo realm,  int revision,  TopologyEngineTarget target,  TopologyRuntimeState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyEngine() when $default != null:
return $default(_that.engineId,_that.ownerHost,_that.realm,_that.revision,_that.target,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId engineId,  TopologyOwnerHost ownerHost,  TopologyRealmInfo realm,  int revision,  TopologyEngineTarget target,  TopologyRuntimeState state)  $default,) {final _that = this;
switch (_that) {
case _TopologyEngine():
return $default(_that.engineId,_that.ownerHost,_that.realm,_that.revision,_that.target,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId engineId,  TopologyOwnerHost ownerHost,  TopologyRealmInfo realm,  int revision,  TopologyEngineTarget target,  TopologyRuntimeState state)?  $default,) {final _that = this;
switch (_that) {
case _TopologyEngine() when $default != null:
return $default(_that.engineId,_that.ownerHost,_that.realm,_that.revision,_that.target,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyEngine implements TopologyEngine {
  const _TopologyEngine({required this.engineId, required this.ownerHost, required this.realm, required this.revision, required this.target, required this.state});
  

@override final  skir.RecordId engineId;
@override final  TopologyOwnerHost ownerHost;
@override final  TopologyRealmInfo realm;
@override final  int revision;
@override final  TopologyEngineTarget target;
@override final  TopologyRuntimeState state;

/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyEngineCopyWith<_TopologyEngine> get copyWith => __$TopologyEngineCopyWithImpl<_TopologyEngine>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyEngine&&(identical(other.engineId, engineId) || other.engineId == engineId)&&(identical(other.ownerHost, ownerHost) || other.ownerHost == ownerHost)&&(identical(other.realm, realm) || other.realm == realm)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.target, target) || other.target == target)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,engineId,ownerHost,realm,revision,target,state);

@override
String toString() {
  return 'TopologyEngine(engineId: $engineId, ownerHost: $ownerHost, realm: $realm, revision: $revision, target: $target, state: $state)';
}


}

/// @nodoc
abstract mixin class _$TopologyEngineCopyWith<$Res> implements $TopologyEngineCopyWith<$Res> {
  factory _$TopologyEngineCopyWith(_TopologyEngine value, $Res Function(_TopologyEngine) _then) = __$TopologyEngineCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId engineId, TopologyOwnerHost ownerHost, TopologyRealmInfo realm, int revision, TopologyEngineTarget target, TopologyRuntimeState state
});


@override $TopologyOwnerHostCopyWith<$Res> get ownerHost;@override $TopologyRealmInfoCopyWith<$Res> get realm;@override $TopologyEngineTargetCopyWith<$Res> get target;@override $TopologyRuntimeStateCopyWith<$Res> get state;

}
/// @nodoc
class __$TopologyEngineCopyWithImpl<$Res>
    implements _$TopologyEngineCopyWith<$Res> {
  __$TopologyEngineCopyWithImpl(this._self, this._then);

  final _TopologyEngine _self;
  final $Res Function(_TopologyEngine) _then;

/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? engineId = null,Object? ownerHost = null,Object? realm = null,Object? revision = null,Object? target = null,Object? state = null,}) {
  return _then(_TopologyEngine(
engineId: null == engineId ? _self.engineId : engineId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,ownerHost: null == ownerHost ? _self.ownerHost : ownerHost // ignore: cast_nullable_to_non_nullable
as TopologyOwnerHost,realm: null == realm ? _self.realm : realm // ignore: cast_nullable_to_non_nullable
as TopologyRealmInfo,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as TopologyEngineTarget,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TopologyRuntimeState,
  ));
}

/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyOwnerHostCopyWith<$Res> get ownerHost {
  
  return $TopologyOwnerHostCopyWith<$Res>(_self.ownerHost, (value) {
    return _then(_self.copyWith(ownerHost: value));
  });
}/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRealmInfoCopyWith<$Res> get realm {
  
  return $TopologyRealmInfoCopyWith<$Res>(_self.realm, (value) {
    return _then(_self.copyWith(realm: value));
  });
}/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyEngineTargetCopyWith<$Res> get target {
  
  return $TopologyEngineTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of TopologyEngine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRuntimeStateCopyWith<$Res> get state {
  
  return $TopologyRuntimeStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$TopologyConfigurationResult {

 TopologyHost get host; TopologyRealm? get realm; TopologyEngine? get engine;
/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopologyConfigurationResultCopyWith<TopologyConfigurationResult> get copyWith => _$TopologyConfigurationResultCopyWithImpl<TopologyConfigurationResult>(this as TopologyConfigurationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopologyConfigurationResult&&(identical(other.host, host) || other.host == host)&&(identical(other.realm, realm) || other.realm == realm)&&(identical(other.engine, engine) || other.engine == engine));
}


@override
int get hashCode => Object.hash(runtimeType,host,realm,engine);

@override
String toString() {
  return 'TopologyConfigurationResult(host: $host, realm: $realm, engine: $engine)';
}


}

/// @nodoc
abstract mixin class $TopologyConfigurationResultCopyWith<$Res>  {
  factory $TopologyConfigurationResultCopyWith(TopologyConfigurationResult value, $Res Function(TopologyConfigurationResult) _then) = _$TopologyConfigurationResultCopyWithImpl;
@useResult
$Res call({
 TopologyHost host, TopologyRealm? realm, TopologyEngine? engine
});


$TopologyHostCopyWith<$Res> get host;$TopologyRealmCopyWith<$Res>? get realm;$TopologyEngineCopyWith<$Res>? get engine;

}
/// @nodoc
class _$TopologyConfigurationResultCopyWithImpl<$Res>
    implements $TopologyConfigurationResultCopyWith<$Res> {
  _$TopologyConfigurationResultCopyWithImpl(this._self, this._then);

  final TopologyConfigurationResult _self;
  final $Res Function(TopologyConfigurationResult) _then;

/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? host = null,Object? realm = freezed,Object? engine = freezed,}) {
  return _then(_self.copyWith(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as TopologyHost,realm: freezed == realm ? _self.realm : realm // ignore: cast_nullable_to_non_nullable
as TopologyRealm?,engine: freezed == engine ? _self.engine : engine // ignore: cast_nullable_to_non_nullable
as TopologyEngine?,
  ));
}
/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyHostCopyWith<$Res> get host {
  
  return $TopologyHostCopyWith<$Res>(_self.host, (value) {
    return _then(_self.copyWith(host: value));
  });
}/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRealmCopyWith<$Res>? get realm {
    if (_self.realm == null) {
    return null;
  }

  return $TopologyRealmCopyWith<$Res>(_self.realm!, (value) {
    return _then(_self.copyWith(realm: value));
  });
}/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyEngineCopyWith<$Res>? get engine {
    if (_self.engine == null) {
    return null;
  }

  return $TopologyEngineCopyWith<$Res>(_self.engine!, (value) {
    return _then(_self.copyWith(engine: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopologyConfigurationResult].
extension TopologyConfigurationResultPatterns on TopologyConfigurationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopologyConfigurationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopologyConfigurationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopologyConfigurationResult value)  $default,){
final _that = this;
switch (_that) {
case _TopologyConfigurationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopologyConfigurationResult value)?  $default,){
final _that = this;
switch (_that) {
case _TopologyConfigurationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TopologyHost host,  TopologyRealm? realm,  TopologyEngine? engine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopologyConfigurationResult() when $default != null:
return $default(_that.host,_that.realm,_that.engine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TopologyHost host,  TopologyRealm? realm,  TopologyEngine? engine)  $default,) {final _that = this;
switch (_that) {
case _TopologyConfigurationResult():
return $default(_that.host,_that.realm,_that.engine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TopologyHost host,  TopologyRealm? realm,  TopologyEngine? engine)?  $default,) {final _that = this;
switch (_that) {
case _TopologyConfigurationResult() when $default != null:
return $default(_that.host,_that.realm,_that.engine);case _:
  return null;

}
}

}

/// @nodoc


class _TopologyConfigurationResult implements TopologyConfigurationResult {
  const _TopologyConfigurationResult({required this.host, required this.realm, required this.engine});
  

@override final  TopologyHost host;
@override final  TopologyRealm? realm;
@override final  TopologyEngine? engine;

/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopologyConfigurationResultCopyWith<_TopologyConfigurationResult> get copyWith => __$TopologyConfigurationResultCopyWithImpl<_TopologyConfigurationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopologyConfigurationResult&&(identical(other.host, host) || other.host == host)&&(identical(other.realm, realm) || other.realm == realm)&&(identical(other.engine, engine) || other.engine == engine));
}


@override
int get hashCode => Object.hash(runtimeType,host,realm,engine);

@override
String toString() {
  return 'TopologyConfigurationResult(host: $host, realm: $realm, engine: $engine)';
}


}

/// @nodoc
abstract mixin class _$TopologyConfigurationResultCopyWith<$Res> implements $TopologyConfigurationResultCopyWith<$Res> {
  factory _$TopologyConfigurationResultCopyWith(_TopologyConfigurationResult value, $Res Function(_TopologyConfigurationResult) _then) = __$TopologyConfigurationResultCopyWithImpl;
@override @useResult
$Res call({
 TopologyHost host, TopologyRealm? realm, TopologyEngine? engine
});


@override $TopologyHostCopyWith<$Res> get host;@override $TopologyRealmCopyWith<$Res>? get realm;@override $TopologyEngineCopyWith<$Res>? get engine;

}
/// @nodoc
class __$TopologyConfigurationResultCopyWithImpl<$Res>
    implements _$TopologyConfigurationResultCopyWith<$Res> {
  __$TopologyConfigurationResultCopyWithImpl(this._self, this._then);

  final _TopologyConfigurationResult _self;
  final $Res Function(_TopologyConfigurationResult) _then;

/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? host = null,Object? realm = freezed,Object? engine = freezed,}) {
  return _then(_TopologyConfigurationResult(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as TopologyHost,realm: freezed == realm ? _self.realm : realm // ignore: cast_nullable_to_non_nullable
as TopologyRealm?,engine: freezed == engine ? _self.engine : engine // ignore: cast_nullable_to_non_nullable
as TopologyEngine?,
  ));
}

/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyHostCopyWith<$Res> get host {
  
  return $TopologyHostCopyWith<$Res>(_self.host, (value) {
    return _then(_self.copyWith(host: value));
  });
}/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyRealmCopyWith<$Res>? get realm {
    if (_self.realm == null) {
    return null;
  }

  return $TopologyRealmCopyWith<$Res>(_self.realm!, (value) {
    return _then(_self.copyWith(realm: value));
  });
}/// Create a copy of TopologyConfigurationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopologyEngineCopyWith<$Res>? get engine {
    if (_self.engine == null) {
    return null;
  }

  return $TopologyEngineCopyWith<$Res>(_self.engine!, (value) {
    return _then(_self.copyWith(engine: value));
  });
}
}

/// @nodoc
mixin _$OrganizationTopology {

 List<TopologyHost> get hosts; List<TopologyRealm> get realmInstances; List<TopologyEngine> get engineInstances;
/// Create a copy of OrganizationTopology
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationTopologyCopyWith<OrganizationTopology> get copyWith => _$OrganizationTopologyCopyWithImpl<OrganizationTopology>(this as OrganizationTopology, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationTopology&&const DeepCollectionEquality().equals(other.hosts, hosts)&&const DeepCollectionEquality().equals(other.realmInstances, realmInstances)&&const DeepCollectionEquality().equals(other.engineInstances, engineInstances));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(hosts),const DeepCollectionEquality().hash(realmInstances),const DeepCollectionEquality().hash(engineInstances));

@override
String toString() {
  return 'OrganizationTopology(hosts: $hosts, realmInstances: $realmInstances, engineInstances: $engineInstances)';
}


}

/// @nodoc
abstract mixin class $OrganizationTopologyCopyWith<$Res>  {
  factory $OrganizationTopologyCopyWith(OrganizationTopology value, $Res Function(OrganizationTopology) _then) = _$OrganizationTopologyCopyWithImpl;
@useResult
$Res call({
 List<TopologyHost> hosts, List<TopologyRealm> realmInstances, List<TopologyEngine> engineInstances
});




}
/// @nodoc
class _$OrganizationTopologyCopyWithImpl<$Res>
    implements $OrganizationTopologyCopyWith<$Res> {
  _$OrganizationTopologyCopyWithImpl(this._self, this._then);

  final OrganizationTopology _self;
  final $Res Function(OrganizationTopology) _then;

/// Create a copy of OrganizationTopology
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hosts = null,Object? realmInstances = null,Object? engineInstances = null,}) {
  return _then(_self.copyWith(
hosts: null == hosts ? _self.hosts : hosts // ignore: cast_nullable_to_non_nullable
as List<TopologyHost>,realmInstances: null == realmInstances ? _self.realmInstances : realmInstances // ignore: cast_nullable_to_non_nullable
as List<TopologyRealm>,engineInstances: null == engineInstances ? _self.engineInstances : engineInstances // ignore: cast_nullable_to_non_nullable
as List<TopologyEngine>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationTopology].
extension OrganizationTopologyPatterns on OrganizationTopology {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationTopology value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationTopology() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationTopology value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationTopology():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationTopology value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationTopology() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TopologyHost> hosts,  List<TopologyRealm> realmInstances,  List<TopologyEngine> engineInstances)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationTopology() when $default != null:
return $default(_that.hosts,_that.realmInstances,_that.engineInstances);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TopologyHost> hosts,  List<TopologyRealm> realmInstances,  List<TopologyEngine> engineInstances)  $default,) {final _that = this;
switch (_that) {
case _OrganizationTopology():
return $default(_that.hosts,_that.realmInstances,_that.engineInstances);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TopologyHost> hosts,  List<TopologyRealm> realmInstances,  List<TopologyEngine> engineInstances)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationTopology() when $default != null:
return $default(_that.hosts,_that.realmInstances,_that.engineInstances);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationTopology extends OrganizationTopology {
  const _OrganizationTopology({required final  List<TopologyHost> hosts, required final  List<TopologyRealm> realmInstances, required final  List<TopologyEngine> engineInstances}): _hosts = hosts,_realmInstances = realmInstances,_engineInstances = engineInstances,super._();
  

 final  List<TopologyHost> _hosts;
@override List<TopologyHost> get hosts {
  if (_hosts is EqualUnmodifiableListView) return _hosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hosts);
}

 final  List<TopologyRealm> _realmInstances;
@override List<TopologyRealm> get realmInstances {
  if (_realmInstances is EqualUnmodifiableListView) return _realmInstances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_realmInstances);
}

 final  List<TopologyEngine> _engineInstances;
@override List<TopologyEngine> get engineInstances {
  if (_engineInstances is EqualUnmodifiableListView) return _engineInstances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_engineInstances);
}


/// Create a copy of OrganizationTopology
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationTopologyCopyWith<_OrganizationTopology> get copyWith => __$OrganizationTopologyCopyWithImpl<_OrganizationTopology>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationTopology&&const DeepCollectionEquality().equals(other._hosts, _hosts)&&const DeepCollectionEquality().equals(other._realmInstances, _realmInstances)&&const DeepCollectionEquality().equals(other._engineInstances, _engineInstances));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_hosts),const DeepCollectionEquality().hash(_realmInstances),const DeepCollectionEquality().hash(_engineInstances));

@override
String toString() {
  return 'OrganizationTopology(hosts: $hosts, realmInstances: $realmInstances, engineInstances: $engineInstances)';
}


}

/// @nodoc
abstract mixin class _$OrganizationTopologyCopyWith<$Res> implements $OrganizationTopologyCopyWith<$Res> {
  factory _$OrganizationTopologyCopyWith(_OrganizationTopology value, $Res Function(_OrganizationTopology) _then) = __$OrganizationTopologyCopyWithImpl;
@override @useResult
$Res call({
 List<TopologyHost> hosts, List<TopologyRealm> realmInstances, List<TopologyEngine> engineInstances
});




}
/// @nodoc
class __$OrganizationTopologyCopyWithImpl<$Res>
    implements _$OrganizationTopologyCopyWith<$Res> {
  __$OrganizationTopologyCopyWithImpl(this._self, this._then);

  final _OrganizationTopology _self;
  final $Res Function(_OrganizationTopology) _then;

/// Create a copy of OrganizationTopology
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hosts = null,Object? realmInstances = null,Object? engineInstances = null,}) {
  return _then(_OrganizationTopology(
hosts: null == hosts ? _self._hosts : hosts // ignore: cast_nullable_to_non_nullable
as List<TopologyHost>,realmInstances: null == realmInstances ? _self._realmInstances : realmInstances // ignore: cast_nullable_to_non_nullable
as List<TopologyRealm>,engineInstances: null == engineInstances ? _self._engineInstances : engineInstances // ignore: cast_nullable_to_non_nullable
as List<TopologyEngine>,
  ));
}


}

// dart format on
