// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resource_drop_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResourceDropHover {

 bool get accepted; bool get rejected;/// The hover hint of the single offer, or a count of the offers.
 String? get hint;
/// Create a copy of ResourceDropHover
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceDropHoverCopyWith<ResourceDropHover> get copyWith => _$ResourceDropHoverCopyWithImpl<ResourceDropHover>(this as ResourceDropHover, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResourceDropHover;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceDropHover&&(identical(other.accepted, _this.accepted) || other.accepted == _this.accepted)&&(identical(other.rejected, _this.rejected) || other.rejected == _this.rejected)&&(identical(other.hint, _this.hint) || other.hint == _this.hint));
}


@override
int get hashCode {
  final _this = this as ResourceDropHover;
  return Object.hash(runtimeType,_this.accepted,_this.rejected,_this.hint);
}

@override
String toString() {
  final _this = this as ResourceDropHover;
  return 'ResourceDropHover(accepted: ${_this.accepted}, rejected: ${_this.rejected}, hint: ${_this.hint})';
}


}

/// @nodoc
abstract mixin class $ResourceDropHoverCopyWith<$Res>  {
  factory $ResourceDropHoverCopyWith(ResourceDropHover value, $Res Function(ResourceDropHover) _then) = _$ResourceDropHoverCopyWithImpl;
@useResult
$Res call({
 bool accepted, bool rejected, String? hint
});




}
/// @nodoc
class _$ResourceDropHoverCopyWithImpl<$Res>
    implements $ResourceDropHoverCopyWith<$Res> {
  _$ResourceDropHoverCopyWithImpl(this._self, this._then);

  final ResourceDropHover _self;
  final $Res Function(ResourceDropHover) _then;

/// Create a copy of ResourceDropHover
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accepted = null,Object? rejected = null,Object? hint = freezed,}) {
  return _then(ResourceDropHover(
accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as bool,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as bool,hint: freezed == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResourceDropHover].
extension ResourceDropHoverPatterns on ResourceDropHover {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResourceDropHover value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResourceDropHover() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResourceDropHover value)  $default,){
final _that = this;
switch (_that) {
case _ResourceDropHover():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResourceDropHover value)?  $default,){
final _that = this;
switch (_that) {
case _ResourceDropHover() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool accepted,  bool rejected,  String? hint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResourceDropHover() when $default != null:
return $default(_that.accepted,_that.rejected,_that.hint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool accepted,  bool rejected,  String? hint)  $default,) {final _that = this;
switch (_that) {
case _ResourceDropHover():
return $default(_that.accepted,_that.rejected,_that.hint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool accepted,  bool rejected,  String? hint)?  $default,) {final _that = this;
switch (_that) {
case _ResourceDropHover() when $default != null:
return $default(_that.accepted,_that.rejected,_that.hint);case _:
  return null;

}
}

}

/// @nodoc


class _ResourceDropHover extends ResourceDropHover {
  const _ResourceDropHover({this.accepted = false, this.rejected = false, this.hint}): super._();
  

@override@JsonKey() final  bool accepted;
@override@JsonKey() final  bool rejected;
/// The hover hint of the single offer, or a count of the offers.
@override final  String? hint;

/// Create a copy of ResourceDropHover
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResourceDropHoverCopyWith<_ResourceDropHover> get copyWith => __$ResourceDropHoverCopyWithImpl<_ResourceDropHover>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResourceDropHover&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.rejected, rejected) || other.rejected == rejected)&&(identical(other.hint, hint) || other.hint == hint));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accepted,rejected,hint);
}

@override
String toString() {
    return 'ResourceDropHover(accepted: $accepted, rejected: $rejected, hint: $hint)';
}


}

/// @nodoc
abstract mixin class _$ResourceDropHoverCopyWith<$Res> implements $ResourceDropHoverCopyWith<$Res> {
  factory _$ResourceDropHoverCopyWith(_ResourceDropHover value, $Res Function(_ResourceDropHover) _then) = __$ResourceDropHoverCopyWithImpl;
@override @useResult
$Res call({
 bool accepted, bool rejected, String? hint
});




}
/// @nodoc
class __$ResourceDropHoverCopyWithImpl<$Res>
    implements _$ResourceDropHoverCopyWith<$Res> {
  __$ResourceDropHoverCopyWithImpl(this._self, this._then);

  final _ResourceDropHover _self;
  final $Res Function(_ResourceDropHover) _then;

/// Create a copy of ResourceDropHover
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accepted = null,Object? rejected = null,Object? hint = freezed,}) {
  return _then(_ResourceDropHover(
accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as bool,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as bool,hint: freezed == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
