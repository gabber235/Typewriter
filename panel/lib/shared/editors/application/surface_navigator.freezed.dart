// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'surface_navigator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SurfaceTarget {

 skir.ResourceId? get selected;
/// Create a copy of SurfaceTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurfaceTargetCopyWith<SurfaceTarget> get copyWith => _$SurfaceTargetCopyWithImpl<SurfaceTarget>(this as SurfaceTarget, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SurfaceTarget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurfaceTarget&&(identical(other.selected, _this.selected) || other.selected == _this.selected));
}


@override
int get hashCode {
  final _this = this as SurfaceTarget;
  return Object.hash(runtimeType,_this.selected);
}

@override
String toString() {
  final _this = this as SurfaceTarget;
  return 'SurfaceTarget(selected: ${_this.selected})';
}


}

/// @nodoc
abstract mixin class $SurfaceTargetCopyWith<$Res>  {
  factory $SurfaceTargetCopyWith(SurfaceTarget value, $Res Function(SurfaceTarget) _then) = _$SurfaceTargetCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId? selected
});




}
/// @nodoc
class _$SurfaceTargetCopyWithImpl<$Res>
    implements $SurfaceTargetCopyWith<$Res> {
  _$SurfaceTargetCopyWithImpl(this._self, this._then);

  final SurfaceTarget _self;
  final $Res Function(SurfaceTarget) _then;

/// Create a copy of SurfaceTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selected = freezed,}) {
  return _then(_self.copyWith(
selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,
  ));
}

}


/// Adds pattern-matching-related methods to [SurfaceTarget].
extension SurfaceTargetPatterns on SurfaceTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HomeTarget value)?  home,TResult Function( ResourceTarget value)?  resource,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HomeTarget() when home != null:
return home(_that);case ResourceTarget() when resource != null:
return resource(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HomeTarget value)  home,required TResult Function( ResourceTarget value)  resource,}){
final _that = this;
switch (_that) {
case HomeTarget():
return home(_that);case ResourceTarget():
return resource(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HomeTarget value)?  home,TResult? Function( ResourceTarget value)?  resource,}){
final _that = this;
switch (_that) {
case HomeTarget() when home != null:
return home(_that);case ResourceTarget() when resource != null:
return resource(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( skir.ResourceId? selected)?  home,TResult Function( skir.ResourceId routed,  skir.ResourceId? selected)?  resource,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HomeTarget() when home != null:
return home(_that.selected);case ResourceTarget() when resource != null:
return resource(_that.routed,_that.selected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( skir.ResourceId? selected)  home,required TResult Function( skir.ResourceId routed,  skir.ResourceId? selected)  resource,}) {final _that = this;
switch (_that) {
case HomeTarget():
return home(_that.selected);case ResourceTarget():
return resource(_that.routed,_that.selected);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( skir.ResourceId? selected)?  home,TResult? Function( skir.ResourceId routed,  skir.ResourceId? selected)?  resource,}) {final _that = this;
switch (_that) {
case HomeTarget() when home != null:
return home(_that.selected);case ResourceTarget() when resource != null:
return resource(_that.routed,_that.selected);case _:
  return null;

}
}

}

/// @nodoc


class HomeTarget implements SurfaceTarget {
  const HomeTarget({this.selected});
  

@override final  skir.ResourceId? selected;

/// Create a copy of SurfaceTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeTargetCopyWith<HomeTarget> get copyWith => _$HomeTargetCopyWithImpl<HomeTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeTarget&&(identical(other.selected, selected) || other.selected == selected));
}


@override
int get hashCode {
    return Object.hash(runtimeType,selected);
}

@override
String toString() {
    return 'SurfaceTarget.home(selected: $selected)';
}


}

/// @nodoc
abstract mixin class $HomeTargetCopyWith<$Res> implements $SurfaceTargetCopyWith<$Res> {
  factory $HomeTargetCopyWith(HomeTarget value, $Res Function(HomeTarget) _then) = _$HomeTargetCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId? selected
});




}
/// @nodoc
class _$HomeTargetCopyWithImpl<$Res>
    implements $HomeTargetCopyWith<$Res> {
  _$HomeTargetCopyWithImpl(this._self, this._then);

  final HomeTarget _self;
  final $Res Function(HomeTarget) _then;

/// Create a copy of SurfaceTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selected = freezed,}) {
  return _then(HomeTarget(
selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,
  ));
}


}

/// @nodoc


class ResourceTarget implements SurfaceTarget {
  const ResourceTarget({required this.routed, this.selected});
  

 final  skir.ResourceId routed;
@override final  skir.ResourceId? selected;

/// Create a copy of SurfaceTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResourceTargetCopyWith<ResourceTarget> get copyWith => _$ResourceTargetCopyWithImpl<ResourceTarget>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResourceTarget&&(identical(other.routed, routed) || other.routed == routed)&&(identical(other.selected, selected) || other.selected == selected));
}


@override
int get hashCode {
    return Object.hash(runtimeType,routed,selected);
}

@override
String toString() {
    return 'SurfaceTarget.resource(routed: $routed, selected: $selected)';
}


}

/// @nodoc
abstract mixin class $ResourceTargetCopyWith<$Res> implements $SurfaceTargetCopyWith<$Res> {
  factory $ResourceTargetCopyWith(ResourceTarget value, $Res Function(ResourceTarget) _then) = _$ResourceTargetCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId routed, skir.ResourceId? selected
});




}
/// @nodoc
class _$ResourceTargetCopyWithImpl<$Res>
    implements $ResourceTargetCopyWith<$Res> {
  _$ResourceTargetCopyWithImpl(this._self, this._then);

  final ResourceTarget _self;
  final $Res Function(ResourceTarget) _then;

/// Create a copy of SurfaceTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? routed = null,Object? selected = freezed,}) {
  return _then(ResourceTarget(
routed: null == routed ? _self.routed : routed // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as skir.ResourceId?,
  ));
}


}

// dart format on
