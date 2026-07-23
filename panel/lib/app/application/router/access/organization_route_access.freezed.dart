// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_route_access.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationRouteAccessState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'OrganizationRouteAccessState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationRouteAccessState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'OrganizationRouteAccessState()';
}


}

/// @nodoc
class $OrganizationRouteAccessStateCopyWith<$Res>  {
$OrganizationRouteAccessStateCopyWith(OrganizationRouteAccessState _, $Res Function(OrganizationRouteAccessState) __);
}


/// Adds pattern-matching-related methods to [OrganizationRouteAccessState].
extension OrganizationRouteAccessStatePatterns on OrganizationRouteAccessState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrganizationRouteAccessLoading value)?  loading,TResult Function( OrganizationRouteAccessUnavailable value)?  unavailable,TResult Function( OrganizationRouteAccessAvailable value)?  available,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrganizationRouteAccessLoading() when loading != null:
return loading(_that);case OrganizationRouteAccessUnavailable() when unavailable != null:
return unavailable(_that);case OrganizationRouteAccessAvailable() when available != null:
return available(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrganizationRouteAccessLoading value)  loading,required TResult Function( OrganizationRouteAccessUnavailable value)  unavailable,required TResult Function( OrganizationRouteAccessAvailable value)  available,}){
final _that = this;
switch (_that) {
case OrganizationRouteAccessLoading():
return loading(_that);case OrganizationRouteAccessUnavailable():
return unavailable(_that);case OrganizationRouteAccessAvailable():
return available(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrganizationRouteAccessLoading value)?  loading,TResult? Function( OrganizationRouteAccessUnavailable value)?  unavailable,TResult? Function( OrganizationRouteAccessAvailable value)?  available,}){
final _that = this;
switch (_that) {
case OrganizationRouteAccessLoading() when loading != null:
return loading(_that);case OrganizationRouteAccessUnavailable() when unavailable != null:
return unavailable(_that);case OrganizationRouteAccessAvailable() when available != null:
return available(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  unavailable,TResult Function( String? principalId,  Set<String> organizationIds)?  available,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrganizationRouteAccessLoading() when loading != null:
return loading();case OrganizationRouteAccessUnavailable() when unavailable != null:
return unavailable();case OrganizationRouteAccessAvailable() when available != null:
return available(_that.principalId,_that.organizationIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  unavailable,required TResult Function( String? principalId,  Set<String> organizationIds)  available,}) {final _that = this;
switch (_that) {
case OrganizationRouteAccessLoading():
return loading();case OrganizationRouteAccessUnavailable():
return unavailable();case OrganizationRouteAccessAvailable():
return available(_that.principalId,_that.organizationIds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  unavailable,TResult? Function( String? principalId,  Set<String> organizationIds)?  available,}) {final _that = this;
switch (_that) {
case OrganizationRouteAccessLoading() when loading != null:
return loading();case OrganizationRouteAccessUnavailable() when unavailable != null:
return unavailable();case OrganizationRouteAccessAvailable() when available != null:
return available(_that.principalId,_that.organizationIds);case _:
  return null;

}
}

}

/// @nodoc


class OrganizationRouteAccessLoading with DiagnosticableTreeMixin implements OrganizationRouteAccessState {
  const OrganizationRouteAccessLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'OrganizationRouteAccessState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationRouteAccessLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'OrganizationRouteAccessState.loading()';
}


}




/// @nodoc


class OrganizationRouteAccessUnavailable with DiagnosticableTreeMixin implements OrganizationRouteAccessState {
  const OrganizationRouteAccessUnavailable();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'OrganizationRouteAccessState.unavailable'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationRouteAccessUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'OrganizationRouteAccessState.unavailable()';
}


}




/// @nodoc


class OrganizationRouteAccessAvailable with DiagnosticableTreeMixin implements OrganizationRouteAccessState {
  const OrganizationRouteAccessAvailable({required this.principalId, required final  Set<String> organizationIds}): _organizationIds = organizationIds;
  

 final  String? principalId;
 final  Set<String> _organizationIds;
 Set<String> get organizationIds {
  if (_organizationIds is EqualUnmodifiableSetView) return _organizationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_organizationIds);
}


/// Create a copy of OrganizationRouteAccessState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationRouteAccessAvailableCopyWith<OrganizationRouteAccessAvailable> get copyWith => _$OrganizationRouteAccessAvailableCopyWithImpl<OrganizationRouteAccessAvailable>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'OrganizationRouteAccessState.available'))
    ..add(DiagnosticsProperty('principalId', principalId))..add(DiagnosticsProperty('organizationIds', organizationIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationRouteAccessAvailable&&(identical(other.principalId, principalId) || other.principalId == principalId)&&const DeepCollectionEquality().equals(other._organizationIds, _organizationIds));
}


@override
int get hashCode => Object.hash(runtimeType,principalId,const DeepCollectionEquality().hash(_organizationIds));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'OrganizationRouteAccessState.available(principalId: $principalId, organizationIds: $organizationIds)';
}


}

/// @nodoc
abstract mixin class $OrganizationRouteAccessAvailableCopyWith<$Res> implements $OrganizationRouteAccessStateCopyWith<$Res> {
  factory $OrganizationRouteAccessAvailableCopyWith(OrganizationRouteAccessAvailable value, $Res Function(OrganizationRouteAccessAvailable) _then) = _$OrganizationRouteAccessAvailableCopyWithImpl;
@useResult
$Res call({
 String? principalId, Set<String> organizationIds
});




}
/// @nodoc
class _$OrganizationRouteAccessAvailableCopyWithImpl<$Res>
    implements $OrganizationRouteAccessAvailableCopyWith<$Res> {
  _$OrganizationRouteAccessAvailableCopyWithImpl(this._self, this._then);

  final OrganizationRouteAccessAvailable _self;
  final $Res Function(OrganizationRouteAccessAvailable) _then;

/// Create a copy of OrganizationRouteAccessState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? principalId = freezed,Object? organizationIds = null,}) {
  return _then(OrganizationRouteAccessAvailable(
principalId: freezed == principalId ? _self.principalId : principalId // ignore: cast_nullable_to_non_nullable
as String?,organizationIds: null == organizationIds ? _self._organizationIds : organizationIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
