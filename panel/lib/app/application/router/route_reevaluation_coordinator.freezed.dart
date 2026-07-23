// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_reevaluation_coordinator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteReevaluationState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteReevaluationState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteReevaluationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteReevaluationState()';
}


}

/// @nodoc
class $RouteReevaluationStateCopyWith<$Res>  {
$RouteReevaluationStateCopyWith(RouteReevaluationState _, $Res Function(RouteReevaluationState) __);
}


/// Adds pattern-matching-related methods to [RouteReevaluationState].
extension RouteReevaluationStatePatterns on RouteReevaluationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RouteReevaluationIdle value)?  idle,TResult Function( RouteReevaluationRunning value)?  running,TResult Function( RouteReevaluationDisposed value)?  disposed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RouteReevaluationIdle() when idle != null:
return idle(_that);case RouteReevaluationRunning() when running != null:
return running(_that);case RouteReevaluationDisposed() when disposed != null:
return disposed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RouteReevaluationIdle value)  idle,required TResult Function( RouteReevaluationRunning value)  running,required TResult Function( RouteReevaluationDisposed value)  disposed,}){
final _that = this;
switch (_that) {
case RouteReevaluationIdle():
return idle(_that);case RouteReevaluationRunning():
return running(_that);case RouteReevaluationDisposed():
return disposed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RouteReevaluationIdle value)?  idle,TResult? Function( RouteReevaluationRunning value)?  running,TResult? Function( RouteReevaluationDisposed value)?  disposed,}){
final _that = this;
switch (_that) {
case RouteReevaluationIdle() when idle != null:
return idle(_that);case RouteReevaluationRunning() when running != null:
return running(_that);case RouteReevaluationDisposed() when disposed != null:
return disposed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( bool followUpRequested)?  running,TResult Function()?  disposed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RouteReevaluationIdle() when idle != null:
return idle();case RouteReevaluationRunning() when running != null:
return running(_that.followUpRequested);case RouteReevaluationDisposed() when disposed != null:
return disposed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( bool followUpRequested)  running,required TResult Function()  disposed,}) {final _that = this;
switch (_that) {
case RouteReevaluationIdle():
return idle();case RouteReevaluationRunning():
return running(_that.followUpRequested);case RouteReevaluationDisposed():
return disposed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( bool followUpRequested)?  running,TResult? Function()?  disposed,}) {final _that = this;
switch (_that) {
case RouteReevaluationIdle() when idle != null:
return idle();case RouteReevaluationRunning() when running != null:
return running(_that.followUpRequested);case RouteReevaluationDisposed() when disposed != null:
return disposed();case _:
  return null;

}
}

}

/// @nodoc


class RouteReevaluationIdle with DiagnosticableTreeMixin implements RouteReevaluationState {
  const RouteReevaluationIdle();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteReevaluationState.idle'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteReevaluationIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteReevaluationState.idle()';
}


}




/// @nodoc


class RouteReevaluationRunning with DiagnosticableTreeMixin implements RouteReevaluationState {
  const RouteReevaluationRunning({this.followUpRequested = false});
  

@JsonKey() final  bool followUpRequested;

/// Create a copy of RouteReevaluationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteReevaluationRunningCopyWith<RouteReevaluationRunning> get copyWith => _$RouteReevaluationRunningCopyWithImpl<RouteReevaluationRunning>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteReevaluationState.running'))
    ..add(DiagnosticsProperty('followUpRequested', followUpRequested));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteReevaluationRunning&&(identical(other.followUpRequested, followUpRequested) || other.followUpRequested == followUpRequested));
}


@override
int get hashCode => Object.hash(runtimeType,followUpRequested);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteReevaluationState.running(followUpRequested: $followUpRequested)';
}


}

/// @nodoc
abstract mixin class $RouteReevaluationRunningCopyWith<$Res> implements $RouteReevaluationStateCopyWith<$Res> {
  factory $RouteReevaluationRunningCopyWith(RouteReevaluationRunning value, $Res Function(RouteReevaluationRunning) _then) = _$RouteReevaluationRunningCopyWithImpl;
@useResult
$Res call({
 bool followUpRequested
});




}
/// @nodoc
class _$RouteReevaluationRunningCopyWithImpl<$Res>
    implements $RouteReevaluationRunningCopyWith<$Res> {
  _$RouteReevaluationRunningCopyWithImpl(this._self, this._then);

  final RouteReevaluationRunning _self;
  final $Res Function(RouteReevaluationRunning) _then;

/// Create a copy of RouteReevaluationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? followUpRequested = null,}) {
  return _then(RouteReevaluationRunning(
followUpRequested: null == followUpRequested ? _self.followUpRequested : followUpRequested // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class RouteReevaluationDisposed with DiagnosticableTreeMixin implements RouteReevaluationState {
  const RouteReevaluationDisposed();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RouteReevaluationState.disposed'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteReevaluationDisposed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RouteReevaluationState.disposed()';
}


}




// dart format on
