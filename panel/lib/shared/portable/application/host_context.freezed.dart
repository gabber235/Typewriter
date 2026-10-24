// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'host_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HostContext {

/// The resource routed in the workspace.
 skir.ResourceId? get activeResource;/// How many resources the current selection holds.
 int? get selectionCount;
/// Create a copy of HostContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostContextCopyWith<HostContext> get copyWith => _$HostContextCopyWithImpl<HostContext>(this as HostContext, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HostContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostContext&&(identical(other.activeResource, _this.activeResource) || other.activeResource == _this.activeResource)&&(identical(other.selectionCount, _this.selectionCount) || other.selectionCount == _this.selectionCount));
}


@override
int get hashCode {
  final _this = this as HostContext;
  return Object.hash(runtimeType,_this.activeResource,_this.selectionCount);
}

@override
String toString() {
  final _this = this as HostContext;
  return 'HostContext(activeResource: ${_this.activeResource}, selectionCount: ${_this.selectionCount})';
}


}

/// @nodoc
abstract mixin class $HostContextCopyWith<$Res>  {
  factory $HostContextCopyWith(HostContext value, $Res Function(HostContext) _then) = _$HostContextCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId? activeResource, int? selectionCount
});




}
/// @nodoc
class _$HostContextCopyWithImpl<$Res>
    implements $HostContextCopyWith<$Res> {
  _$HostContextCopyWithImpl(this._self, this._then);

  final HostContext _self;
  final $Res Function(HostContext) _then;

/// Create a copy of HostContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeResource = freezed,Object? selectionCount = freezed,}) {
  return _then(HostContext(
activeResource: freezed == activeResource ? _self.activeResource : activeResource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,selectionCount: freezed == selectionCount ? _self.selectionCount : selectionCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HostContext].
extension HostContextPatterns on HostContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostContext value)  $default,){
final _that = this;
switch (_that) {
case _HostContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostContext value)?  $default,){
final _that = this;
switch (_that) {
case _HostContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId? activeResource,  int? selectionCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostContext() when $default != null:
return $default(_that.activeResource,_that.selectionCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId? activeResource,  int? selectionCount)  $default,) {final _that = this;
switch (_that) {
case _HostContext():
return $default(_that.activeResource,_that.selectionCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId? activeResource,  int? selectionCount)?  $default,) {final _that = this;
switch (_that) {
case _HostContext() when $default != null:
return $default(_that.activeResource,_that.selectionCount);case _:
  return null;

}
}

}

/// @nodoc


class _HostContext extends HostContext {
  const _HostContext({this.activeResource, this.selectionCount}): super._();
  

/// The resource routed in the workspace.
@override final  skir.ResourceId? activeResource;
/// How many resources the current selection holds.
@override final  int? selectionCount;

/// Create a copy of HostContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostContextCopyWith<_HostContext> get copyWith => __$HostContextCopyWithImpl<_HostContext>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostContext&&(identical(other.activeResource, activeResource) || other.activeResource == activeResource)&&(identical(other.selectionCount, selectionCount) || other.selectionCount == selectionCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activeResource,selectionCount);
}

@override
String toString() {
    return 'HostContext(activeResource: $activeResource, selectionCount: $selectionCount)';
}


}

/// @nodoc
abstract mixin class _$HostContextCopyWith<$Res> implements $HostContextCopyWith<$Res> {
  factory _$HostContextCopyWith(_HostContext value, $Res Function(_HostContext) _then) = __$HostContextCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId? activeResource, int? selectionCount
});




}
/// @nodoc
class __$HostContextCopyWithImpl<$Res>
    implements _$HostContextCopyWith<$Res> {
  __$HostContextCopyWithImpl(this._self, this._then);

  final _HostContext _self;
  final $Res Function(_HostContext) _then;

/// Create a copy of HostContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeResource = freezed,Object? selectionCount = freezed,}) {
  return _then(_HostContext(
activeResource: freezed == activeResource ? _self.activeResource : activeResource // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,selectionCount: freezed == selectionCount ? _self.selectionCount : selectionCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
