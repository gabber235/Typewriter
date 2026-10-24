// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_publication_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PublicationObservation {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicationObservation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PublicationObservation()';
}


}

/// @nodoc
class $PublicationObservationCopyWith<$Res>  {
$PublicationObservationCopyWith(PublicationObservation _, $Res Function(PublicationObservation) __);
}


/// Adds pattern-matching-related methods to [PublicationObservation].
extension PublicationObservationPatterns on PublicationObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FetchingPublicationObservation value)?  fetching,TResult Function( AvailablePublicationObservation value)?  available,TResult Function( UnavailablePublicationObservation value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FetchingPublicationObservation() when fetching != null:
return fetching(_that);case AvailablePublicationObservation() when available != null:
return available(_that);case UnavailablePublicationObservation() when unavailable != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FetchingPublicationObservation value)  fetching,required TResult Function( AvailablePublicationObservation value)  available,required TResult Function( UnavailablePublicationObservation value)  unavailable,}){
final _that = this;
switch (_that) {
case FetchingPublicationObservation():
return fetching(_that);case AvailablePublicationObservation():
return available(_that);case UnavailablePublicationObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FetchingPublicationObservation value)?  fetching,TResult? Function( AvailablePublicationObservation value)?  available,TResult? Function( UnavailablePublicationObservation value)?  unavailable,}){
final _that = this;
switch (_that) {
case FetchingPublicationObservation() when fetching != null:
return fetching(_that);case AvailablePublicationObservation() when available != null:
return available(_that);case UnavailablePublicationObservation() when unavailable != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.PublicationViewId expected)?  fetching,TResult Function( skir.PublicationView view)?  available,TResult Function( String message)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FetchingPublicationObservation() when fetching != null:
return fetching(_that.expected);case AvailablePublicationObservation() when available != null:
return available(_that.view);case UnavailablePublicationObservation() when unavailable != null:
return unavailable(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.PublicationViewId expected)  fetching,required TResult Function( skir.PublicationView view)  available,required TResult Function( String message)  unavailable,}) {final _that = this;
switch (_that) {
case FetchingPublicationObservation():
return fetching(_that.expected);case AvailablePublicationObservation():
return available(_that.view);case UnavailablePublicationObservation():
return unavailable(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.PublicationViewId expected)?  fetching,TResult? Function( skir.PublicationView view)?  available,TResult? Function( String message)?  unavailable,}) {final _that = this;
switch (_that) {
case FetchingPublicationObservation() when fetching != null:
return fetching(_that.expected);case AvailablePublicationObservation() when available != null:
return available(_that.view);case UnavailablePublicationObservation() when unavailable != null:
return unavailable(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class FetchingPublicationObservation implements PublicationObservation {
  const FetchingPublicationObservation(this.expected);
  

 final  skir.PublicationViewId expected;

/// Create a copy of PublicationObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FetchingPublicationObservationCopyWith<FetchingPublicationObservation> get copyWith => _$FetchingPublicationObservationCopyWithImpl<FetchingPublicationObservation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FetchingPublicationObservation&&(identical(other.expected, expected) || other.expected == expected));
}


@override
int get hashCode {
    return Object.hash(runtimeType,expected);
}

@override
String toString() {
    return 'PublicationObservation.fetching(expected: $expected)';
}


}

/// @nodoc
abstract mixin class $FetchingPublicationObservationCopyWith<$Res> implements $PublicationObservationCopyWith<$Res> {
  factory $FetchingPublicationObservationCopyWith(FetchingPublicationObservation value, $Res Function(FetchingPublicationObservation) _then) = _$FetchingPublicationObservationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationViewId expected
});




}
/// @nodoc
class _$FetchingPublicationObservationCopyWithImpl<$Res>
    implements $FetchingPublicationObservationCopyWith<$Res> {
  _$FetchingPublicationObservationCopyWithImpl(this._self, this._then);

  final FetchingPublicationObservation _self;
  final $Res Function(FetchingPublicationObservation) _then;

/// Create a copy of PublicationObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expected = null,}) {
  return _then(FetchingPublicationObservation(
null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as skir.PublicationViewId,
  ));
}


}

/// @nodoc


class AvailablePublicationObservation implements PublicationObservation {
  const AvailablePublicationObservation(this.view);
  

 final  skir.PublicationView view;

/// Create a copy of PublicationObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailablePublicationObservationCopyWith<AvailablePublicationObservation> get copyWith => _$AvailablePublicationObservationCopyWithImpl<AvailablePublicationObservation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailablePublicationObservation&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode {
    return Object.hash(runtimeType,view);
}

@override
String toString() {
    return 'PublicationObservation.available(view: $view)';
}


}

/// @nodoc
abstract mixin class $AvailablePublicationObservationCopyWith<$Res> implements $PublicationObservationCopyWith<$Res> {
  factory $AvailablePublicationObservationCopyWith(AvailablePublicationObservation value, $Res Function(AvailablePublicationObservation) _then) = _$AvailablePublicationObservationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationView view
});




}
/// @nodoc
class _$AvailablePublicationObservationCopyWithImpl<$Res>
    implements $AvailablePublicationObservationCopyWith<$Res> {
  _$AvailablePublicationObservationCopyWithImpl(this._self, this._then);

  final AvailablePublicationObservation _self;
  final $Res Function(AvailablePublicationObservation) _then;

/// Create a copy of PublicationObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(AvailablePublicationObservation(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as skir.PublicationView,
  ));
}


}

/// @nodoc


class UnavailablePublicationObservation implements PublicationObservation {
  const UnavailablePublicationObservation(this.message);
  

 final  String message;

/// Create a copy of PublicationObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnavailablePublicationObservationCopyWith<UnavailablePublicationObservation> get copyWith => _$UnavailablePublicationObservationCopyWithImpl<UnavailablePublicationObservation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnavailablePublicationObservation&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'PublicationObservation.unavailable(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnavailablePublicationObservationCopyWith<$Res> implements $PublicationObservationCopyWith<$Res> {
  factory $UnavailablePublicationObservationCopyWith(UnavailablePublicationObservation value, $Res Function(UnavailablePublicationObservation) _then) = _$UnavailablePublicationObservationCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UnavailablePublicationObservationCopyWithImpl<$Res>
    implements $UnavailablePublicationObservationCopyWith<$Res> {
  _$UnavailablePublicationObservationCopyWithImpl(this._self, this._then);

  final UnavailablePublicationObservation _self;
  final $Res Function(UnavailablePublicationObservation) _then;

/// Create a copy of PublicationObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UnavailablePublicationObservation(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RealmPublicationView {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmPublicationView);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmPublicationView()';
}


}

/// @nodoc
class $RealmPublicationViewCopyWith<$Res>  {
$RealmPublicationViewCopyWith(RealmPublicationView _, $Res Function(RealmPublicationView) __);
}


/// Adds pattern-matching-related methods to [RealmPublicationView].
extension RealmPublicationViewPatterns on RealmPublicationView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EmptyRealmPublication value)?  empty,TResult Function( CurrentRealmPublication value)?  current,TResult Function( ReadyRealmPublication value)?  ready,TResult Function( BlockedRealmPublication value)?  blocked,TResult Function( CheckingRealmPublication value)?  checking,TResult Function( PublishingRealmPublication value)?  publishing,TResult Function( UnavailableRealmPublication value)?  unavailable,TResult Function( RequestActiveRealmPublication value)?  requestActive,TResult Function( UncertainRealmPublication value)?  uncertain,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EmptyRealmPublication() when empty != null:
return empty(_that);case CurrentRealmPublication() when current != null:
return current(_that);case ReadyRealmPublication() when ready != null:
return ready(_that);case BlockedRealmPublication() when blocked != null:
return blocked(_that);case CheckingRealmPublication() when checking != null:
return checking(_that);case PublishingRealmPublication() when publishing != null:
return publishing(_that);case UnavailableRealmPublication() when unavailable != null:
return unavailable(_that);case RequestActiveRealmPublication() when requestActive != null:
return requestActive(_that);case UncertainRealmPublication() when uncertain != null:
return uncertain(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EmptyRealmPublication value)  empty,required TResult Function( CurrentRealmPublication value)  current,required TResult Function( ReadyRealmPublication value)  ready,required TResult Function( BlockedRealmPublication value)  blocked,required TResult Function( CheckingRealmPublication value)  checking,required TResult Function( PublishingRealmPublication value)  publishing,required TResult Function( UnavailableRealmPublication value)  unavailable,required TResult Function( RequestActiveRealmPublication value)  requestActive,required TResult Function( UncertainRealmPublication value)  uncertain,}){
final _that = this;
switch (_that) {
case EmptyRealmPublication():
return empty(_that);case CurrentRealmPublication():
return current(_that);case ReadyRealmPublication():
return ready(_that);case BlockedRealmPublication():
return blocked(_that);case CheckingRealmPublication():
return checking(_that);case PublishingRealmPublication():
return publishing(_that);case UnavailableRealmPublication():
return unavailable(_that);case RequestActiveRealmPublication():
return requestActive(_that);case UncertainRealmPublication():
return uncertain(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EmptyRealmPublication value)?  empty,TResult? Function( CurrentRealmPublication value)?  current,TResult? Function( ReadyRealmPublication value)?  ready,TResult? Function( BlockedRealmPublication value)?  blocked,TResult? Function( CheckingRealmPublication value)?  checking,TResult? Function( PublishingRealmPublication value)?  publishing,TResult? Function( UnavailableRealmPublication value)?  unavailable,TResult? Function( RequestActiveRealmPublication value)?  requestActive,TResult? Function( UncertainRealmPublication value)?  uncertain,}){
final _that = this;
switch (_that) {
case EmptyRealmPublication() when empty != null:
return empty(_that);case CurrentRealmPublication() when current != null:
return current(_that);case ReadyRealmPublication() when ready != null:
return ready(_that);case BlockedRealmPublication() when blocked != null:
return blocked(_that);case CheckingRealmPublication() when checking != null:
return checking(_that);case PublishingRealmPublication() when publishing != null:
return publishing(_that);case UnavailableRealmPublication() when unavailable != null:
return unavailable(_that);case RequestActiveRealmPublication() when requestActive != null:
return requestActive(_that);case UncertainRealmPublication() when uncertain != null:
return uncertain(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.PublicationStatus_Empty data)?  empty,TResult Function( skir.PublicationStatus_Current data)?  current,TResult Function( skir.PublicationStatus_Ready data,  RealmPublishCommand command)?  ready,TResult Function( skir.PublicationStatus_Blocked data)?  blocked,TResult Function( skir.PublicationStatus? display)?  checking,TResult Function( skir.PublicationStatus_Publishing data)?  publishing,TResult Function( String message,  skir.PublicationStatus? display)?  unavailable,TResult Function( skir.PublicationStatus? display)?  requestActive,TResult Function( String message,  skir.PublicationStatus? display)?  uncertain,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EmptyRealmPublication() when empty != null:
return empty(_that.data);case CurrentRealmPublication() when current != null:
return current(_that.data);case ReadyRealmPublication() when ready != null:
return ready(_that.data,_that.command);case BlockedRealmPublication() when blocked != null:
return blocked(_that.data);case CheckingRealmPublication() when checking != null:
return checking(_that.display);case PublishingRealmPublication() when publishing != null:
return publishing(_that.data);case UnavailableRealmPublication() when unavailable != null:
return unavailable(_that.message,_that.display);case RequestActiveRealmPublication() when requestActive != null:
return requestActive(_that.display);case UncertainRealmPublication() when uncertain != null:
return uncertain(_that.message,_that.display);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.PublicationStatus_Empty data)  empty,required TResult Function( skir.PublicationStatus_Current data)  current,required TResult Function( skir.PublicationStatus_Ready data,  RealmPublishCommand command)  ready,required TResult Function( skir.PublicationStatus_Blocked data)  blocked,required TResult Function( skir.PublicationStatus? display)  checking,required TResult Function( skir.PublicationStatus_Publishing data)  publishing,required TResult Function( String message,  skir.PublicationStatus? display)  unavailable,required TResult Function( skir.PublicationStatus? display)  requestActive,required TResult Function( String message,  skir.PublicationStatus? display)  uncertain,}) {final _that = this;
switch (_that) {
case EmptyRealmPublication():
return empty(_that.data);case CurrentRealmPublication():
return current(_that.data);case ReadyRealmPublication():
return ready(_that.data,_that.command);case BlockedRealmPublication():
return blocked(_that.data);case CheckingRealmPublication():
return checking(_that.display);case PublishingRealmPublication():
return publishing(_that.data);case UnavailableRealmPublication():
return unavailable(_that.message,_that.display);case RequestActiveRealmPublication():
return requestActive(_that.display);case UncertainRealmPublication():
return uncertain(_that.message,_that.display);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.PublicationStatus_Empty data)?  empty,TResult? Function( skir.PublicationStatus_Current data)?  current,TResult? Function( skir.PublicationStatus_Ready data,  RealmPublishCommand command)?  ready,TResult? Function( skir.PublicationStatus_Blocked data)?  blocked,TResult? Function( skir.PublicationStatus? display)?  checking,TResult? Function( skir.PublicationStatus_Publishing data)?  publishing,TResult? Function( String message,  skir.PublicationStatus? display)?  unavailable,TResult? Function( skir.PublicationStatus? display)?  requestActive,TResult? Function( String message,  skir.PublicationStatus? display)?  uncertain,}) {final _that = this;
switch (_that) {
case EmptyRealmPublication() when empty != null:
return empty(_that.data);case CurrentRealmPublication() when current != null:
return current(_that.data);case ReadyRealmPublication() when ready != null:
return ready(_that.data,_that.command);case BlockedRealmPublication() when blocked != null:
return blocked(_that.data);case CheckingRealmPublication() when checking != null:
return checking(_that.display);case PublishingRealmPublication() when publishing != null:
return publishing(_that.data);case UnavailableRealmPublication() when unavailable != null:
return unavailable(_that.message,_that.display);case RequestActiveRealmPublication() when requestActive != null:
return requestActive(_that.display);case UncertainRealmPublication() when uncertain != null:
return uncertain(_that.message,_that.display);case _:
  return null;

}
}

}

/// @nodoc


class EmptyRealmPublication extends RealmPublicationView {
  const EmptyRealmPublication(this.data): super._();
  

 final  skir.PublicationStatus_Empty data;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmptyRealmPublicationCopyWith<EmptyRealmPublication> get copyWith => _$EmptyRealmPublicationCopyWithImpl<EmptyRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EmptyRealmPublication&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,data);
}

@override
String toString() {
    return 'RealmPublicationView.empty(data: $data)';
}


}

/// @nodoc
abstract mixin class $EmptyRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $EmptyRealmPublicationCopyWith(EmptyRealmPublication value, $Res Function(EmptyRealmPublication) _then) = _$EmptyRealmPublicationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationStatus_Empty data
});




}
/// @nodoc
class _$EmptyRealmPublicationCopyWithImpl<$Res>
    implements $EmptyRealmPublicationCopyWith<$Res> {
  _$EmptyRealmPublicationCopyWithImpl(this._self, this._then);

  final EmptyRealmPublication _self;
  final $Res Function(EmptyRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(EmptyRealmPublication(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus_Empty,
  ));
}


}

/// @nodoc


class CurrentRealmPublication extends RealmPublicationView {
  const CurrentRealmPublication(this.data): super._();
  

 final  skir.PublicationStatus_Current data;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrentRealmPublicationCopyWith<CurrentRealmPublication> get copyWith => _$CurrentRealmPublicationCopyWithImpl<CurrentRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrentRealmPublication&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,data);
}

@override
String toString() {
    return 'RealmPublicationView.current(data: $data)';
}


}

/// @nodoc
abstract mixin class $CurrentRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $CurrentRealmPublicationCopyWith(CurrentRealmPublication value, $Res Function(CurrentRealmPublication) _then) = _$CurrentRealmPublicationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationStatus_Current data
});




}
/// @nodoc
class _$CurrentRealmPublicationCopyWithImpl<$Res>
    implements $CurrentRealmPublicationCopyWith<$Res> {
  _$CurrentRealmPublicationCopyWithImpl(this._self, this._then);

  final CurrentRealmPublication _self;
  final $Res Function(CurrentRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(CurrentRealmPublication(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus_Current,
  ));
}


}

/// @nodoc


class ReadyRealmPublication extends RealmPublicationView {
  const ReadyRealmPublication(this.data, this.command): super._();
  

 final  skir.PublicationStatus_Ready data;
 final  RealmPublishCommand command;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadyRealmPublicationCopyWith<ReadyRealmPublication> get copyWith => _$ReadyRealmPublicationCopyWithImpl<ReadyRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadyRealmPublication&&(identical(other.data, data) || other.data == data)&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode {
    return Object.hash(runtimeType,data,command);
}

@override
String toString() {
    return 'RealmPublicationView.ready(data: $data, command: $command)';
}


}

/// @nodoc
abstract mixin class $ReadyRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $ReadyRealmPublicationCopyWith(ReadyRealmPublication value, $Res Function(ReadyRealmPublication) _then) = _$ReadyRealmPublicationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationStatus_Ready data, RealmPublishCommand command
});




}
/// @nodoc
class _$ReadyRealmPublicationCopyWithImpl<$Res>
    implements $ReadyRealmPublicationCopyWith<$Res> {
  _$ReadyRealmPublicationCopyWithImpl(this._self, this._then);

  final ReadyRealmPublication _self;
  final $Res Function(ReadyRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,Object? command = null,}) {
  return _then(ReadyRealmPublication(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus_Ready,null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as RealmPublishCommand,
  ));
}


}

/// @nodoc


class BlockedRealmPublication extends RealmPublicationView {
  const BlockedRealmPublication(this.data): super._();
  

 final  skir.PublicationStatus_Blocked data;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockedRealmPublicationCopyWith<BlockedRealmPublication> get copyWith => _$BlockedRealmPublicationCopyWithImpl<BlockedRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockedRealmPublication&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,data);
}

@override
String toString() {
    return 'RealmPublicationView.blocked(data: $data)';
}


}

/// @nodoc
abstract mixin class $BlockedRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $BlockedRealmPublicationCopyWith(BlockedRealmPublication value, $Res Function(BlockedRealmPublication) _then) = _$BlockedRealmPublicationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationStatus_Blocked data
});




}
/// @nodoc
class _$BlockedRealmPublicationCopyWithImpl<$Res>
    implements $BlockedRealmPublicationCopyWith<$Res> {
  _$BlockedRealmPublicationCopyWithImpl(this._self, this._then);

  final BlockedRealmPublication _self;
  final $Res Function(BlockedRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(BlockedRealmPublication(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus_Blocked,
  ));
}


}

/// @nodoc


class CheckingRealmPublication extends RealmPublicationView {
  const CheckingRealmPublication({this.display}): super._();
  

 final  skir.PublicationStatus? display;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckingRealmPublicationCopyWith<CheckingRealmPublication> get copyWith => _$CheckingRealmPublicationCopyWithImpl<CheckingRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckingRealmPublication&&(identical(other.display, display) || other.display == display));
}


@override
int get hashCode {
    return Object.hash(runtimeType,display);
}

@override
String toString() {
    return 'RealmPublicationView.checking(display: $display)';
}


}

/// @nodoc
abstract mixin class $CheckingRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $CheckingRealmPublicationCopyWith(CheckingRealmPublication value, $Res Function(CheckingRealmPublication) _then) = _$CheckingRealmPublicationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationStatus? display
});




}
/// @nodoc
class _$CheckingRealmPublicationCopyWithImpl<$Res>
    implements $CheckingRealmPublicationCopyWith<$Res> {
  _$CheckingRealmPublicationCopyWithImpl(this._self, this._then);

  final CheckingRealmPublication _self;
  final $Res Function(CheckingRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? display = freezed,}) {
  return _then(CheckingRealmPublication(
display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus?,
  ));
}


}

/// @nodoc


class PublishingRealmPublication extends RealmPublicationView {
  const PublishingRealmPublication(this.data): super._();
  

 final  skir.PublicationStatus_Publishing data;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublishingRealmPublicationCopyWith<PublishingRealmPublication> get copyWith => _$PublishingRealmPublicationCopyWithImpl<PublishingRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PublishingRealmPublication&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode {
    return Object.hash(runtimeType,data);
}

@override
String toString() {
    return 'RealmPublicationView.publishing(data: $data)';
}


}

/// @nodoc
abstract mixin class $PublishingRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $PublishingRealmPublicationCopyWith(PublishingRealmPublication value, $Res Function(PublishingRealmPublication) _then) = _$PublishingRealmPublicationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationStatus_Publishing data
});




}
/// @nodoc
class _$PublishingRealmPublicationCopyWithImpl<$Res>
    implements $PublishingRealmPublicationCopyWith<$Res> {
  _$PublishingRealmPublicationCopyWithImpl(this._self, this._then);

  final PublishingRealmPublication _self;
  final $Res Function(PublishingRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(PublishingRealmPublication(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus_Publishing,
  ));
}


}

/// @nodoc


class UnavailableRealmPublication extends RealmPublicationView {
  const UnavailableRealmPublication(this.message, {this.display}): super._();
  

 final  String message;
 final  skir.PublicationStatus? display;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnavailableRealmPublicationCopyWith<UnavailableRealmPublication> get copyWith => _$UnavailableRealmPublicationCopyWithImpl<UnavailableRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnavailableRealmPublication&&(identical(other.message, message) || other.message == message)&&(identical(other.display, display) || other.display == display));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,display);
}

@override
String toString() {
    return 'RealmPublicationView.unavailable(message: $message, display: $display)';
}


}

/// @nodoc
abstract mixin class $UnavailableRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $UnavailableRealmPublicationCopyWith(UnavailableRealmPublication value, $Res Function(UnavailableRealmPublication) _then) = _$UnavailableRealmPublicationCopyWithImpl;
@useResult
$Res call({
 String message, skir.PublicationStatus? display
});




}
/// @nodoc
class _$UnavailableRealmPublicationCopyWithImpl<$Res>
    implements $UnavailableRealmPublicationCopyWith<$Res> {
  _$UnavailableRealmPublicationCopyWithImpl(this._self, this._then);

  final UnavailableRealmPublication _self;
  final $Res Function(UnavailableRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? display = freezed,}) {
  return _then(UnavailableRealmPublication(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus?,
  ));
}


}

/// @nodoc


class RequestActiveRealmPublication extends RealmPublicationView {
  const RequestActiveRealmPublication({this.display}): super._();
  

 final  skir.PublicationStatus? display;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestActiveRealmPublicationCopyWith<RequestActiveRealmPublication> get copyWith => _$RequestActiveRealmPublicationCopyWithImpl<RequestActiveRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestActiveRealmPublication&&(identical(other.display, display) || other.display == display));
}


@override
int get hashCode {
    return Object.hash(runtimeType,display);
}

@override
String toString() {
    return 'RealmPublicationView.requestActive(display: $display)';
}


}

/// @nodoc
abstract mixin class $RequestActiveRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $RequestActiveRealmPublicationCopyWith(RequestActiveRealmPublication value, $Res Function(RequestActiveRealmPublication) _then) = _$RequestActiveRealmPublicationCopyWithImpl;
@useResult
$Res call({
 skir.PublicationStatus? display
});




}
/// @nodoc
class _$RequestActiveRealmPublicationCopyWithImpl<$Res>
    implements $RequestActiveRealmPublicationCopyWith<$Res> {
  _$RequestActiveRealmPublicationCopyWithImpl(this._self, this._then);

  final RequestActiveRealmPublication _self;
  final $Res Function(RequestActiveRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? display = freezed,}) {
  return _then(RequestActiveRealmPublication(
display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus?,
  ));
}


}

/// @nodoc


class UncertainRealmPublication extends RealmPublicationView {
  const UncertainRealmPublication(this.message, {this.display}): super._();
  

 final  String message;
 final  skir.PublicationStatus? display;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UncertainRealmPublicationCopyWith<UncertainRealmPublication> get copyWith => _$UncertainRealmPublicationCopyWithImpl<UncertainRealmPublication>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UncertainRealmPublication&&(identical(other.message, message) || other.message == message)&&(identical(other.display, display) || other.display == display));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,display);
}

@override
String toString() {
    return 'RealmPublicationView.uncertain(message: $message, display: $display)';
}


}

/// @nodoc
abstract mixin class $UncertainRealmPublicationCopyWith<$Res> implements $RealmPublicationViewCopyWith<$Res> {
  factory $UncertainRealmPublicationCopyWith(UncertainRealmPublication value, $Res Function(UncertainRealmPublication) _then) = _$UncertainRealmPublicationCopyWithImpl;
@useResult
$Res call({
 String message, skir.PublicationStatus? display
});




}
/// @nodoc
class _$UncertainRealmPublicationCopyWithImpl<$Res>
    implements $UncertainRealmPublicationCopyWith<$Res> {
  _$UncertainRealmPublicationCopyWithImpl(this._self, this._then);

  final UncertainRealmPublication _self;
  final $Res Function(UncertainRealmPublication) _then;

/// Create a copy of RealmPublicationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? display = freezed,}) {
  return _then(UncertainRealmPublication(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as skir.PublicationStatus?,
  ));
}


}

// dart format on
