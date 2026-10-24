// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_text_sizing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResolvedTextSizing {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedTextSizing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ResolvedTextSizing()';
}


}

/// @nodoc
class $ResolvedTextSizingCopyWith<$Res>  {
$ResolvedTextSizingCopyWith(ResolvedTextSizing _, $Res Function(ResolvedTextSizing) __);
}


/// Adds pattern-matching-related methods to [ResolvedTextSizing].
extension ResolvedTextSizingPatterns on ResolvedTextSizing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExactTextSizing value)?  exact,TResult Function( FitTextSizing value)?  fit,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExactTextSizing() when exact != null:
return exact(_that);case FitTextSizing() when fit != null:
return fit(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExactTextSizing value)  exact,required TResult Function( FitTextSizing value)  fit,}){
final _that = this;
switch (_that) {
case ExactTextSizing():
return exact(_that);case FitTextSizing():
return fit(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExactTextSizing value)?  exact,TResult? Function( FitTextSizing value)?  fit,}){
final _that = this;
switch (_that) {
case ExactTextSizing() when exact != null:
return exact(_that);case FitTextSizing() when fit != null:
return fit(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double size)?  exact,TResult Function( double minimum,  double maximum)?  fit,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExactTextSizing() when exact != null:
return exact(_that.size);case FitTextSizing() when fit != null:
return fit(_that.minimum,_that.maximum);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double size)  exact,required TResult Function( double minimum,  double maximum)  fit,}) {final _that = this;
switch (_that) {
case ExactTextSizing():
return exact(_that.size);case FitTextSizing():
return fit(_that.minimum,_that.maximum);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double size)?  exact,TResult? Function( double minimum,  double maximum)?  fit,}) {final _that = this;
switch (_that) {
case ExactTextSizing() when exact != null:
return exact(_that.size);case FitTextSizing() when fit != null:
return fit(_that.minimum,_that.maximum);case _:
  return null;

}
}

}

/// @nodoc


class ExactTextSizing implements ResolvedTextSizing {
  const ExactTextSizing(this.size);
  

 final  double size;

/// Create a copy of ResolvedTextSizing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExactTextSizingCopyWith<ExactTextSizing> get copyWith => _$ExactTextSizingCopyWithImpl<ExactTextSizing>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExactTextSizing&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode {
    return Object.hash(runtimeType,size);
}

@override
String toString() {
    return 'ResolvedTextSizing.exact(size: $size)';
}


}

/// @nodoc
abstract mixin class $ExactTextSizingCopyWith<$Res> implements $ResolvedTextSizingCopyWith<$Res> {
  factory $ExactTextSizingCopyWith(ExactTextSizing value, $Res Function(ExactTextSizing) _then) = _$ExactTextSizingCopyWithImpl;
@useResult
$Res call({
 double size
});




}
/// @nodoc
class _$ExactTextSizingCopyWithImpl<$Res>
    implements $ExactTextSizingCopyWith<$Res> {
  _$ExactTextSizingCopyWithImpl(this._self, this._then);

  final ExactTextSizing _self;
  final $Res Function(ExactTextSizing) _then;

/// Create a copy of ResolvedTextSizing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? size = null,}) {
  return _then(ExactTextSizing(
null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class FitTextSizing implements ResolvedTextSizing {
  const FitTextSizing({required this.minimum, required this.maximum});
  

 final  double minimum;
 final  double maximum;

/// Create a copy of ResolvedTextSizing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FitTextSizingCopyWith<FitTextSizing> get copyWith => _$FitTextSizingCopyWithImpl<FitTextSizing>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FitTextSizing&&(identical(other.minimum, minimum) || other.minimum == minimum)&&(identical(other.maximum, maximum) || other.maximum == maximum));
}


@override
int get hashCode {
    return Object.hash(runtimeType,minimum,maximum);
}

@override
String toString() {
    return 'ResolvedTextSizing.fit(minimum: $minimum, maximum: $maximum)';
}


}

/// @nodoc
abstract mixin class $FitTextSizingCopyWith<$Res> implements $ResolvedTextSizingCopyWith<$Res> {
  factory $FitTextSizingCopyWith(FitTextSizing value, $Res Function(FitTextSizing) _then) = _$FitTextSizingCopyWithImpl;
@useResult
$Res call({
 double minimum, double maximum
});




}
/// @nodoc
class _$FitTextSizingCopyWithImpl<$Res>
    implements $FitTextSizingCopyWith<$Res> {
  _$FitTextSizingCopyWithImpl(this._self, this._then);

  final FitTextSizing _self;
  final $Res Function(FitTextSizing) _then;

/// Create a copy of ResolvedTextSizing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minimum = null,Object? maximum = null,}) {
  return _then(FitTextSizing(
minimum: null == minimum ? _self.minimum : minimum // ignore: cast_nullable_to_non_nullable
as double,maximum: null == maximum ? _self.maximum : maximum // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
