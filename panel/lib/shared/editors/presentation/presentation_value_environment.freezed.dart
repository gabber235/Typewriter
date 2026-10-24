// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_value_environment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationValueEnvironment {

 ThemeData get theme; SurfaceAppearance get appearance; PresentationInteraction get interaction;
/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationValueEnvironmentCopyWith<PresentationValueEnvironment> get copyWith => _$PresentationValueEnvironmentCopyWithImpl<PresentationValueEnvironment>(this as PresentationValueEnvironment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationValueEnvironment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationValueEnvironment&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.appearance, _this.appearance) || other.appearance == _this.appearance)&&(identical(other.interaction, _this.interaction) || other.interaction == _this.interaction));
}


@override
int get hashCode {
  final _this = this as PresentationValueEnvironment;
  return Object.hash(runtimeType,_this.theme,_this.appearance,_this.interaction);
}

@override
String toString() {
  final _this = this as PresentationValueEnvironment;
  return 'PresentationValueEnvironment(theme: ${_this.theme}, appearance: ${_this.appearance}, interaction: ${_this.interaction})';
}


}

/// @nodoc
abstract mixin class $PresentationValueEnvironmentCopyWith<$Res>  {
  factory $PresentationValueEnvironmentCopyWith(PresentationValueEnvironment value, $Res Function(PresentationValueEnvironment) _then) = _$PresentationValueEnvironmentCopyWithImpl;
@useResult
$Res call({
 ThemeData theme, SurfaceAppearance appearance, PresentationInteraction interaction
});


$SurfaceAppearanceCopyWith<$Res> get appearance;$PresentationInteractionCopyWith<$Res> get interaction;

}
/// @nodoc
class _$PresentationValueEnvironmentCopyWithImpl<$Res>
    implements $PresentationValueEnvironmentCopyWith<$Res> {
  _$PresentationValueEnvironmentCopyWithImpl(this._self, this._then);

  final PresentationValueEnvironment _self;
  final $Res Function(PresentationValueEnvironment) _then;

/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? appearance = null,Object? interaction = null,}) {
  return _then(PresentationValueEnvironment(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeData,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as SurfaceAppearance,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as PresentationInteraction,
  ));
}
/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SurfaceAppearanceCopyWith<$Res> get appearance {
  
  return $SurfaceAppearanceCopyWith<$Res>(_self.appearance, (value) {
    return _then(_self.copyWith(appearance: value));
  });
}/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationInteractionCopyWith<$Res> get interaction {
  
  return $PresentationInteractionCopyWith<$Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationValueEnvironment].
extension PresentationValueEnvironmentPatterns on PresentationValueEnvironment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationValueEnvironment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationValueEnvironment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationValueEnvironment value)  $default,){
final _that = this;
switch (_that) {
case _PresentationValueEnvironment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationValueEnvironment value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationValueEnvironment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeData theme,  SurfaceAppearance appearance,  PresentationInteraction interaction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationValueEnvironment() when $default != null:
return $default(_that.theme,_that.appearance,_that.interaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeData theme,  SurfaceAppearance appearance,  PresentationInteraction interaction)  $default,) {final _that = this;
switch (_that) {
case _PresentationValueEnvironment():
return $default(_that.theme,_that.appearance,_that.interaction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeData theme,  SurfaceAppearance appearance,  PresentationInteraction interaction)?  $default,) {final _that = this;
switch (_that) {
case _PresentationValueEnvironment() when $default != null:
return $default(_that.theme,_that.appearance,_that.interaction);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationValueEnvironment extends PresentationValueEnvironment {
  const _PresentationValueEnvironment({required this.theme, required this.appearance, required this.interaction}): super._();
  

@override final  ThemeData theme;
@override final  SurfaceAppearance appearance;
@override final  PresentationInteraction interaction;

/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationValueEnvironmentCopyWith<_PresentationValueEnvironment> get copyWith => __$PresentationValueEnvironmentCopyWithImpl<_PresentationValueEnvironment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationValueEnvironment&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.interaction, interaction) || other.interaction == interaction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,theme,appearance,interaction);
}

@override
String toString() {
    return 'PresentationValueEnvironment(theme: $theme, appearance: $appearance, interaction: $interaction)';
}


}

/// @nodoc
abstract mixin class _$PresentationValueEnvironmentCopyWith<$Res> implements $PresentationValueEnvironmentCopyWith<$Res> {
  factory _$PresentationValueEnvironmentCopyWith(_PresentationValueEnvironment value, $Res Function(_PresentationValueEnvironment) _then) = __$PresentationValueEnvironmentCopyWithImpl;
@override @useResult
$Res call({
 ThemeData theme, SurfaceAppearance appearance, PresentationInteraction interaction
});


@override $SurfaceAppearanceCopyWith<$Res> get appearance;@override $PresentationInteractionCopyWith<$Res> get interaction;

}
/// @nodoc
class __$PresentationValueEnvironmentCopyWithImpl<$Res>
    implements _$PresentationValueEnvironmentCopyWith<$Res> {
  __$PresentationValueEnvironmentCopyWithImpl(this._self, this._then);

  final _PresentationValueEnvironment _self;
  final $Res Function(_PresentationValueEnvironment) _then;

/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? appearance = null,Object? interaction = null,}) {
  return _then(_PresentationValueEnvironment(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeData,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as SurfaceAppearance,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as PresentationInteraction,
  ));
}

/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SurfaceAppearanceCopyWith<$Res> get appearance {
  
  return $SurfaceAppearanceCopyWith<$Res>(_self.appearance, (value) {
    return _then(_self.copyWith(appearance: value));
  });
}/// Create a copy of PresentationValueEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationInteractionCopyWith<$Res> get interaction {
  
  return $PresentationInteractionCopyWith<$Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}
}

/// @nodoc
mixin _$PresentationMotion {

 Duration get duration; Curve get curve;
/// Create a copy of PresentationMotion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationMotionCopyWith<PresentationMotion> get copyWith => _$PresentationMotionCopyWithImpl<PresentationMotion>(this as PresentationMotion, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationMotion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationMotion&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.curve, _this.curve) || other.curve == _this.curve));
}


@override
int get hashCode {
  final _this = this as PresentationMotion;
  return Object.hash(runtimeType,_this.duration,_this.curve);
}

@override
String toString() {
  final _this = this as PresentationMotion;
  return 'PresentationMotion(duration: ${_this.duration}, curve: ${_this.curve})';
}


}

/// @nodoc
abstract mixin class $PresentationMotionCopyWith<$Res>  {
  factory $PresentationMotionCopyWith(PresentationMotion value, $Res Function(PresentationMotion) _then) = _$PresentationMotionCopyWithImpl;
@useResult
$Res call({
 Duration duration, Curve curve
});




}
/// @nodoc
class _$PresentationMotionCopyWithImpl<$Res>
    implements $PresentationMotionCopyWith<$Res> {
  _$PresentationMotionCopyWithImpl(this._self, this._then);

  final PresentationMotion _self;
  final $Res Function(PresentationMotion) _then;

/// Create a copy of PresentationMotion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,Object? curve = null,}) {
  return _then(PresentationMotion(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,curve: null == curve ? _self.curve : curve // ignore: cast_nullable_to_non_nullable
as Curve,
  ));
}

}


/// Adds pattern-matching-related methods to [PresentationMotion].
extension PresentationMotionPatterns on PresentationMotion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationMotion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationMotion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationMotion value)  $default,){
final _that = this;
switch (_that) {
case _PresentationMotion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationMotion value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationMotion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration duration,  Curve curve)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresentationMotion() when $default != null:
return $default(_that.duration,_that.curve);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration duration,  Curve curve)  $default,) {final _that = this;
switch (_that) {
case _PresentationMotion():
return $default(_that.duration,_that.curve);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration duration,  Curve curve)?  $default,) {final _that = this;
switch (_that) {
case _PresentationMotion() when $default != null:
return $default(_that.duration,_that.curve);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationMotion implements PresentationMotion {
  const _PresentationMotion({required this.duration, required this.curve});
  

@override final  Duration duration;
@override final  Curve curve;

/// Create a copy of PresentationMotion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationMotionCopyWith<_PresentationMotion> get copyWith => __$PresentationMotionCopyWithImpl<_PresentationMotion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationMotion&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.curve, curve) || other.curve == curve));
}


@override
int get hashCode {
    return Object.hash(runtimeType,duration,curve);
}

@override
String toString() {
    return 'PresentationMotion(duration: $duration, curve: $curve)';
}


}

/// @nodoc
abstract mixin class _$PresentationMotionCopyWith<$Res> implements $PresentationMotionCopyWith<$Res> {
  factory _$PresentationMotionCopyWith(_PresentationMotion value, $Res Function(_PresentationMotion) _then) = __$PresentationMotionCopyWithImpl;
@override @useResult
$Res call({
 Duration duration, Curve curve
});




}
/// @nodoc
class __$PresentationMotionCopyWithImpl<$Res>
    implements _$PresentationMotionCopyWith<$Res> {
  __$PresentationMotionCopyWithImpl(this._self, this._then);

  final _PresentationMotion _self;
  final $Res Function(_PresentationMotion) _then;

/// Create a copy of PresentationMotion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = null,Object? curve = null,}) {
  return _then(_PresentationMotion(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,curve: null == curve ? _self.curve : curve // ignore: cast_nullable_to_non_nullable
as Curve,
  ));
}


}

// dart format on
