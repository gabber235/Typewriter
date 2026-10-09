// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'projection_reconciliation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectionDelivery {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectionDelivery);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectionDelivery()';
}


}

/// @nodoc
class $ProjectionDeliveryCopyWith<$Res>  {
$ProjectionDeliveryCopyWith(ProjectionDelivery _, $Res Function(ProjectionDelivery) __);
}


/// Adds pattern-matching-related methods to [ProjectionDelivery].
extension ProjectionDeliveryPatterns on ProjectionDelivery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectionDeliveryEphemeral value)?  ephemeral,TResult Function( ProjectionDeliveryOrdered value)?  ordered,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectionDeliveryEphemeral() when ephemeral != null:
return ephemeral(_that);case ProjectionDeliveryOrdered() when ordered != null:
return ordered(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectionDeliveryEphemeral value)  ephemeral,required TResult Function( ProjectionDeliveryOrdered value)  ordered,}){
final _that = this;
switch (_that) {
case ProjectionDeliveryEphemeral():
return ephemeral(_that);case ProjectionDeliveryOrdered():
return ordered(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectionDeliveryEphemeral value)?  ephemeral,TResult? Function( ProjectionDeliveryOrdered value)?  ordered,}){
final _that = this;
switch (_that) {
case ProjectionDeliveryEphemeral() when ephemeral != null:
return ephemeral(_that);case ProjectionDeliveryOrdered() when ordered != null:
return ordered(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ephemeral,TResult Function( String stream)?  ordered,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectionDeliveryEphemeral() when ephemeral != null:
return ephemeral();case ProjectionDeliveryOrdered() when ordered != null:
return ordered(_that.stream);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ephemeral,required TResult Function( String stream)  ordered,}) {final _that = this;
switch (_that) {
case ProjectionDeliveryEphemeral():
return ephemeral();case ProjectionDeliveryOrdered():
return ordered(_that.stream);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ephemeral,TResult? Function( String stream)?  ordered,}) {final _that = this;
switch (_that) {
case ProjectionDeliveryEphemeral() when ephemeral != null:
return ephemeral();case ProjectionDeliveryOrdered() when ordered != null:
return ordered(_that.stream);case _:
  return null;

}
}

}

/// @nodoc


class ProjectionDeliveryEphemeral implements ProjectionDelivery {
  const ProjectionDeliveryEphemeral();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectionDeliveryEphemeral);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectionDelivery.ephemeral()';
}


}




/// @nodoc


class ProjectionDeliveryOrdered implements ProjectionDelivery {
  const ProjectionDeliveryOrdered({required this.stream});


 final  String stream;

/// Create a copy of ProjectionDelivery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectionDeliveryOrderedCopyWith<ProjectionDeliveryOrdered> get copyWith => _$ProjectionDeliveryOrderedCopyWithImpl<ProjectionDeliveryOrdered>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectionDeliveryOrdered&&(identical(other.stream, stream) || other.stream == stream));
}


@override
int get hashCode {
    return Object.hash(runtimeType,stream);
}

@override
String toString() {
    return 'ProjectionDelivery.ordered(stream: $stream)';
}


}

/// @nodoc
abstract mixin class $ProjectionDeliveryOrderedCopyWith<$Res> implements $ProjectionDeliveryCopyWith<$Res> {
  factory $ProjectionDeliveryOrderedCopyWith(ProjectionDeliveryOrdered value, $Res Function(ProjectionDeliveryOrdered) _then) = _$ProjectionDeliveryOrderedCopyWithImpl;
@useResult
$Res call({
 String stream
});




}
/// @nodoc
class _$ProjectionDeliveryOrderedCopyWithImpl<$Res>
    implements $ProjectionDeliveryOrderedCopyWith<$Res> {
  _$ProjectionDeliveryOrderedCopyWithImpl(this._self, this._then);

  final ProjectionDeliveryOrdered _self;
  final $Res Function(ProjectionDeliveryOrdered) _then;

/// Create a copy of ProjectionDelivery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stream = null,}) {
  return _then(ProjectionDeliveryOrdered(
stream: null == stream ? _self.stream : stream // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ProjectionReconciliation<TData,TResponse,TEvent> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectionReconciliation<TData, TResponse, TEvent>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectionReconciliation<$TData, $TResponse, $TEvent>()';
}


}

/// @nodoc
class $ProjectionReconciliationCopyWith<TData,TResponse,TEvent,$Res>  {
$ProjectionReconciliationCopyWith(ProjectionReconciliation<TData, TResponse, TEvent> _, $Res Function(ProjectionReconciliation<TData, TResponse, TEvent>) __);
}


/// Adds pattern-matching-related methods to [ProjectionReconciliation].
extension ProjectionReconciliationPatterns<TData,TResponse,TEvent> on ProjectionReconciliation<TData, TResponse, TEvent> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectionLatest<TData, TResponse, TEvent> value)?  latest,TResult Function( ProjectionSequenced<TData, TResponse, TEvent> value)?  sequenced,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectionLatest() when latest != null:
return latest(_that);case ProjectionSequenced() when sequenced != null:
return sequenced(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectionLatest<TData, TResponse, TEvent> value)  latest,required TResult Function( ProjectionSequenced<TData, TResponse, TEvent> value)  sequenced,}){
final _that = this;
switch (_that) {
case ProjectionLatest():
return latest(_that);case ProjectionSequenced():
return sequenced(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectionLatest<TData, TResponse, TEvent> value)?  latest,TResult? Function( ProjectionSequenced<TData, TResponse, TEvent> value)?  sequenced,}){
final _that = this;
switch (_that) {
case ProjectionLatest() when latest != null:
return latest(_that);case ProjectionSequenced() when sequenced != null:
return sequenced(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  latest,TResult Function( int Function(TResponse) snapshotSequence,  int Function(TEvent) eventSequence,  SequencedCollection<TData> sequenceState)?  sequenced,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectionLatest() when latest != null:
return latest();case ProjectionSequenced() when sequenced != null:
return sequenced(_that.snapshotSequence,_that.eventSequence,_that.sequenceState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  latest,required TResult Function( int Function(TResponse) snapshotSequence,  int Function(TEvent) eventSequence,  SequencedCollection<TData> sequenceState)  sequenced,}) {final _that = this;
switch (_that) {
case ProjectionLatest():
return latest();case ProjectionSequenced():
return sequenced(_that.snapshotSequence,_that.eventSequence,_that.sequenceState);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  latest,TResult? Function( int Function(TResponse) snapshotSequence,  int Function(TEvent) eventSequence,  SequencedCollection<TData> sequenceState)?  sequenced,}) {final _that = this;
switch (_that) {
case ProjectionLatest() when latest != null:
return latest();case ProjectionSequenced() when sequenced != null:
return sequenced(_that.snapshotSequence,_that.eventSequence,_that.sequenceState);case _:
  return null;

}
}

}

/// @nodoc


class ProjectionLatest<TData,TResponse,TEvent> implements ProjectionReconciliation<TData, TResponse, TEvent> {
  const ProjectionLatest();







@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectionLatest<TData, TResponse, TEvent>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProjectionReconciliation<$TData, $TResponse, $TEvent>.latest()';
}


}




/// @nodoc


class ProjectionSequenced<TData,TResponse,TEvent> implements ProjectionReconciliation<TData, TResponse, TEvent> {
  const ProjectionSequenced({required this.snapshotSequence, required this.eventSequence, required this.sequenceState});


 final  int Function(TResponse) snapshotSequence;
 final  int Function(TEvent) eventSequence;
 final  SequencedCollection<TData> sequenceState;

/// Create a copy of ProjectionReconciliation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectionSequencedCopyWith<TData, TResponse, TEvent, ProjectionSequenced<TData, TResponse, TEvent>> get copyWith => _$ProjectionSequencedCopyWithImpl<TData, TResponse, TEvent, ProjectionSequenced<TData, TResponse, TEvent>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectionSequenced<TData, TResponse, TEvent>&&(identical(other.snapshotSequence, snapshotSequence) || other.snapshotSequence == snapshotSequence)&&(identical(other.eventSequence, eventSequence) || other.eventSequence == eventSequence)&&(identical(other.sequenceState, sequenceState) || other.sequenceState == sequenceState));
}


@override
int get hashCode {
    return Object.hash(runtimeType,snapshotSequence,eventSequence,sequenceState);
}

@override
String toString() {
    return 'ProjectionReconciliation<$TData, $TResponse, $TEvent>.sequenced(snapshotSequence: $snapshotSequence, eventSequence: $eventSequence, sequenceState: $sequenceState)';
}


}

/// @nodoc
abstract mixin class $ProjectionSequencedCopyWith<TData,TResponse,TEvent,$Res> implements $ProjectionReconciliationCopyWith<TData, TResponse, TEvent, $Res> {
  factory $ProjectionSequencedCopyWith(ProjectionSequenced<TData, TResponse, TEvent> value, $Res Function(ProjectionSequenced<TData, TResponse, TEvent>) _then) = _$ProjectionSequencedCopyWithImpl;
@useResult
$Res call({
 int Function(TResponse) snapshotSequence, int Function(TEvent) eventSequence, SequencedCollection<TData> sequenceState
});




}
/// @nodoc
class _$ProjectionSequencedCopyWithImpl<TData,TResponse,TEvent,$Res>
    implements $ProjectionSequencedCopyWith<TData, TResponse, TEvent, $Res> {
  _$ProjectionSequencedCopyWithImpl(this._self, this._then);

  final ProjectionSequenced<TData, TResponse, TEvent> _self;
  final $Res Function(ProjectionSequenced<TData, TResponse, TEvent>) _then;

/// Create a copy of ProjectionReconciliation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? snapshotSequence = null,Object? eventSequence = null,Object? sequenceState = null,}) {
  return _then(ProjectionSequenced<TData, TResponse, TEvent>(
snapshotSequence: null == snapshotSequence ? _self.snapshotSequence : snapshotSequence // ignore: cast_nullable_to_non_nullable
as int Function(TResponse),eventSequence: null == eventSequence ? _self.eventSequence : eventSequence // ignore: cast_nullable_to_non_nullable
as int Function(TEvent),sequenceState: null == sequenceState ? _self.sequenceState : sequenceState // ignore: cast_nullable_to_non_nullable
as SequencedCollection<TData>,
  ));
}


}

// dart format on
