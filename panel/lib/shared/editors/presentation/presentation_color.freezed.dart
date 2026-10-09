// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presentation_color.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresentationColorEnvironment {

 ThemeData get theme; SurfaceAppearance get appearance; PresentationInteraction get interaction;
/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresentationColorEnvironmentCopyWith<PresentationColorEnvironment> get copyWith => _$PresentationColorEnvironmentCopyWithImpl<PresentationColorEnvironment>(this as PresentationColorEnvironment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PresentationColorEnvironment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresentationColorEnvironment&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.appearance, _this.appearance) || other.appearance == _this.appearance)&&(identical(other.interaction, _this.interaction) || other.interaction == _this.interaction));
}


@override
int get hashCode {
  final _this = this as PresentationColorEnvironment;
  return Object.hash(runtimeType,_this.theme,_this.appearance,_this.interaction);
}

@override
String toString() {
  final _this = this as PresentationColorEnvironment;
  return 'PresentationColorEnvironment(theme: ${_this.theme}, appearance: ${_this.appearance}, interaction: ${_this.interaction})';
}


}

/// @nodoc
abstract mixin class $PresentationColorEnvironmentCopyWith<$Res>  {
  factory $PresentationColorEnvironmentCopyWith(PresentationColorEnvironment value, $Res Function(PresentationColorEnvironment) _then) = _$PresentationColorEnvironmentCopyWithImpl;
@useResult
$Res call({
 ThemeData theme, SurfaceAppearance appearance, PresentationInteraction interaction
});


$SurfaceAppearanceCopyWith<$Res> get appearance;$PresentationInteractionCopyWith<$Res> get interaction;

}
/// @nodoc
class _$PresentationColorEnvironmentCopyWithImpl<$Res>
    implements $PresentationColorEnvironmentCopyWith<$Res> {
  _$PresentationColorEnvironmentCopyWithImpl(this._self, this._then);

  final PresentationColorEnvironment _self;
  final $Res Function(PresentationColorEnvironment) _then;

/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? appearance = null,Object? interaction = null,}) {
  return _then(PresentationColorEnvironment(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeData,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as SurfaceAppearance,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as PresentationInteraction,
  ));
}
/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SurfaceAppearanceCopyWith<$Res> get appearance {

  return $SurfaceAppearanceCopyWith<$Res>(_self.appearance, (value) {
    return _then(_self.copyWith(appearance: value));
  });
}/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationInteractionCopyWith<$Res> get interaction {

  return $PresentationInteractionCopyWith<$Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [PresentationColorEnvironment].
extension PresentationColorEnvironmentPatterns on PresentationColorEnvironment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresentationColorEnvironment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresentationColorEnvironment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresentationColorEnvironment value)  $default,){
final _that = this;
switch (_that) {
case _PresentationColorEnvironment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresentationColorEnvironment value)?  $default,){
final _that = this;
switch (_that) {
case _PresentationColorEnvironment() when $default != null:
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
case _PresentationColorEnvironment() when $default != null:
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
case _PresentationColorEnvironment():
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
case _PresentationColorEnvironment() when $default != null:
return $default(_that.theme,_that.appearance,_that.interaction);case _:
  return null;

}
}

}

/// @nodoc


class _PresentationColorEnvironment extends PresentationColorEnvironment {
  const _PresentationColorEnvironment({required this.theme, required this.appearance, required this.interaction}): super._();


@override final  ThemeData theme;
@override final  SurfaceAppearance appearance;
@override final  PresentationInteraction interaction;

/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresentationColorEnvironmentCopyWith<_PresentationColorEnvironment> get copyWith => __$PresentationColorEnvironmentCopyWithImpl<_PresentationColorEnvironment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresentationColorEnvironment&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.interaction, interaction) || other.interaction == interaction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,theme,appearance,interaction);
}

@override
String toString() {
    return 'PresentationColorEnvironment(theme: $theme, appearance: $appearance, interaction: $interaction)';
}


}

/// @nodoc
abstract mixin class _$PresentationColorEnvironmentCopyWith<$Res> implements $PresentationColorEnvironmentCopyWith<$Res> {
  factory _$PresentationColorEnvironmentCopyWith(_PresentationColorEnvironment value, $Res Function(_PresentationColorEnvironment) _then) = __$PresentationColorEnvironmentCopyWithImpl;
@override @useResult
$Res call({
 ThemeData theme, SurfaceAppearance appearance, PresentationInteraction interaction
});


@override $SurfaceAppearanceCopyWith<$Res> get appearance;@override $PresentationInteractionCopyWith<$Res> get interaction;

}
/// @nodoc
class __$PresentationColorEnvironmentCopyWithImpl<$Res>
    implements _$PresentationColorEnvironmentCopyWith<$Res> {
  __$PresentationColorEnvironmentCopyWithImpl(this._self, this._then);

  final _PresentationColorEnvironment _self;
  final $Res Function(_PresentationColorEnvironment) _then;

/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? appearance = null,Object? interaction = null,}) {
  return _then(_PresentationColorEnvironment(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeData,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as SurfaceAppearance,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as PresentationInteraction,
  ));
}

/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SurfaceAppearanceCopyWith<$Res> get appearance {

  return $SurfaceAppearanceCopyWith<$Res>(_self.appearance, (value) {
    return _then(_self.copyWith(appearance: value));
  });
}/// Create a copy of PresentationColorEnvironment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PresentationInteractionCopyWith<$Res> get interaction {

  return $PresentationInteractionCopyWith<$Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}
}

// dart format on
