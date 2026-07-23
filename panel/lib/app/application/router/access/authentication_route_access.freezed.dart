// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authentication_route_access.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteAuthenticationDecision implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteAuthenticationDecision'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteAuthenticationDecision);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteAuthenticationDecision()';
}


}

/// @nodoc
class $RouteAuthenticationDecisionCopyWith<$Res>  {
$RouteAuthenticationDecisionCopyWith(RouteAuthenticationDecision _, $Res Function(RouteAuthenticationDecision) __);
}


/// Adds pattern-matching-related methods to [RouteAuthenticationDecision].
extension RouteAuthenticationDecisionPatterns on RouteAuthenticationDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RouteAuthenticationLoading value)?  loading,TResult Function( RouteAuthenticationAuthenticated value)?  authenticated,TResult Function( RouteAuthenticationUnauthenticated value)?  unauthenticated,TResult Function( RouteAuthenticationUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RouteAuthenticationLoading() when loading != null:
return loading(_that);case RouteAuthenticationAuthenticated() when authenticated != null:
return authenticated(_that);case RouteAuthenticationUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case RouteAuthenticationUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RouteAuthenticationLoading value)  loading,required TResult Function( RouteAuthenticationAuthenticated value)  authenticated,required TResult Function( RouteAuthenticationUnauthenticated value)  unauthenticated,required TResult Function( RouteAuthenticationUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case RouteAuthenticationLoading():
return loading(_that);case RouteAuthenticationAuthenticated():
return authenticated(_that);case RouteAuthenticationUnauthenticated():
return unauthenticated(_that);case RouteAuthenticationUnavailable():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RouteAuthenticationLoading value)?  loading,TResult? Function( RouteAuthenticationAuthenticated value)?  authenticated,TResult? Function( RouteAuthenticationUnauthenticated value)?  unauthenticated,TResult? Function( RouteAuthenticationUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case RouteAuthenticationLoading() when loading != null:
return loading(_that);case RouteAuthenticationAuthenticated() when authenticated != null:
return authenticated(_that);case RouteAuthenticationUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case RouteAuthenticationUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  authenticated,TResult Function()?  unauthenticated,TResult Function()?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RouteAuthenticationLoading() when loading != null:
return loading();case RouteAuthenticationAuthenticated() when authenticated != null:
return authenticated();case RouteAuthenticationUnauthenticated() when unauthenticated != null:
return unauthenticated();case RouteAuthenticationUnavailable() when unavailable != null:
return unavailable();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  authenticated,required TResult Function()  unauthenticated,required TResult Function()  unavailable,}) {final _that = this;
switch (_that) {
case RouteAuthenticationLoading():
return loading();case RouteAuthenticationAuthenticated():
return authenticated();case RouteAuthenticationUnauthenticated():
return unauthenticated();case RouteAuthenticationUnavailable():
return unavailable();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  authenticated,TResult? Function()?  unauthenticated,TResult? Function()?  unavailable,}) {final _that = this;
switch (_that) {
case RouteAuthenticationLoading() when loading != null:
return loading();case RouteAuthenticationAuthenticated() when authenticated != null:
return authenticated();case RouteAuthenticationUnauthenticated() when unauthenticated != null:
return unauthenticated();case RouteAuthenticationUnavailable() when unavailable != null:
return unavailable();case _:
  return null;

}
}

}

/// @nodoc


class RouteAuthenticationLoading with DiagnosticableTreeMixin implements RouteAuthenticationDecision {
  const RouteAuthenticationLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteAuthenticationDecision.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteAuthenticationLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteAuthenticationDecision.loading()';
}


}




/// @nodoc


class RouteAuthenticationAuthenticated with DiagnosticableTreeMixin implements RouteAuthenticationDecision {
  const RouteAuthenticationAuthenticated();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteAuthenticationDecision.authenticated'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteAuthenticationAuthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteAuthenticationDecision.authenticated()';
}


}




/// @nodoc


class RouteAuthenticationUnauthenticated with DiagnosticableTreeMixin implements RouteAuthenticationDecision {
  const RouteAuthenticationUnauthenticated();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteAuthenticationDecision.unauthenticated'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteAuthenticationUnauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteAuthenticationDecision.unauthenticated()';
}


}




/// @nodoc


class RouteAuthenticationUnavailable with DiagnosticableTreeMixin implements RouteAuthenticationDecision {
  const RouteAuthenticationUnavailable();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteAuthenticationDecision.unavailable'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteAuthenticationUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteAuthenticationDecision.unavailable()';
}


}




// dart format on
