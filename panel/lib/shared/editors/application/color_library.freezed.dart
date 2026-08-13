// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'color_library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ColorLibraryState {

 List<int> get recent; List<int> get favorites; ColorFieldFormat get format;
/// Create a copy of ColorLibraryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorLibraryStateCopyWith<ColorLibraryState> get copyWith => _$ColorLibraryStateCopyWithImpl<ColorLibraryState>(this as ColorLibraryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorLibraryState&&const DeepCollectionEquality().equals(other.recent, recent)&&const DeepCollectionEquality().equals(other.favorites, favorites)&&(identical(other.format, format) || other.format == format));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(recent),const DeepCollectionEquality().hash(favorites),format);

@override
String toString() {
  return 'ColorLibraryState(recent: $recent, favorites: $favorites, format: $format)';
}


}

/// @nodoc
abstract mixin class $ColorLibraryStateCopyWith<$Res>  {
  factory $ColorLibraryStateCopyWith(ColorLibraryState value, $Res Function(ColorLibraryState) _then) = _$ColorLibraryStateCopyWithImpl;
@useResult
$Res call({
 List<int> recent, List<int> favorites, ColorFieldFormat format
});




}
/// @nodoc
class _$ColorLibraryStateCopyWithImpl<$Res>
    implements $ColorLibraryStateCopyWith<$Res> {
  _$ColorLibraryStateCopyWithImpl(this._self, this._then);

  final ColorLibraryState _self;
  final $Res Function(ColorLibraryState) _then;

/// Create a copy of ColorLibraryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recent = null,Object? favorites = null,Object? format = null,}) {
  return _then(_self.copyWith(
recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<int>,favorites: null == favorites ? _self.favorites : favorites // ignore: cast_nullable_to_non_nullable
as List<int>,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ColorFieldFormat,
  ));
}

}


/// Adds pattern-matching-related methods to [ColorLibraryState].
extension ColorLibraryStatePatterns on ColorLibraryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ColorLibraryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ColorLibraryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ColorLibraryState value)  $default,){
final _that = this;
switch (_that) {
case _ColorLibraryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ColorLibraryState value)?  $default,){
final _that = this;
switch (_that) {
case _ColorLibraryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> recent,  List<int> favorites,  ColorFieldFormat format)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ColorLibraryState() when $default != null:
return $default(_that.recent,_that.favorites,_that.format);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> recent,  List<int> favorites,  ColorFieldFormat format)  $default,) {final _that = this;
switch (_that) {
case _ColorLibraryState():
return $default(_that.recent,_that.favorites,_that.format);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> recent,  List<int> favorites,  ColorFieldFormat format)?  $default,) {final _that = this;
switch (_that) {
case _ColorLibraryState() when $default != null:
return $default(_that.recent,_that.favorites,_that.format);case _:
  return null;

}
}

}

/// @nodoc


class _ColorLibraryState implements ColorLibraryState {
  const _ColorLibraryState({final  List<int> recent = const [], final  List<int> favorites = const [], this.format = ColorFieldFormat.hex}): _recent = recent,_favorites = favorites;


 final  List<int> _recent;
@override@JsonKey() List<int> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}

 final  List<int> _favorites;
@override@JsonKey() List<int> get favorites {
  if (_favorites is EqualUnmodifiableListView) return _favorites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favorites);
}

@override@JsonKey() final  ColorFieldFormat format;

/// Create a copy of ColorLibraryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ColorLibraryStateCopyWith<_ColorLibraryState> get copyWith => __$ColorLibraryStateCopyWithImpl<_ColorLibraryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ColorLibraryState&&const DeepCollectionEquality().equals(other._recent, _recent)&&const DeepCollectionEquality().equals(other._favorites, _favorites)&&(identical(other.format, format) || other.format == format));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recent),const DeepCollectionEquality().hash(_favorites),format);

@override
String toString() {
  return 'ColorLibraryState(recent: $recent, favorites: $favorites, format: $format)';
}


}

/// @nodoc
abstract mixin class _$ColorLibraryStateCopyWith<$Res> implements $ColorLibraryStateCopyWith<$Res> {
  factory _$ColorLibraryStateCopyWith(_ColorLibraryState value, $Res Function(_ColorLibraryState) _then) = __$ColorLibraryStateCopyWithImpl;
@override @useResult
$Res call({
 List<int> recent, List<int> favorites, ColorFieldFormat format
});




}
/// @nodoc
class __$ColorLibraryStateCopyWithImpl<$Res>
    implements _$ColorLibraryStateCopyWith<$Res> {
  __$ColorLibraryStateCopyWithImpl(this._self, this._then);

  final _ColorLibraryState _self;
  final $Res Function(_ColorLibraryState) _then;

/// Create a copy of ColorLibraryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recent = null,Object? favorites = null,Object? format = null,}) {
  return _then(_ColorLibraryState(
recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<int>,favorites: null == favorites ? _self._favorites : favorites // ignore: cast_nullable_to_non_nullable
as List<int>,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ColorFieldFormat,
  ));
}


}

// dart format on
