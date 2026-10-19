// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portable_regex.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortableRegexNormalization {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableRegexNormalization);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PortableRegexNormalization()';
}


}

/// @nodoc
class $PortableRegexNormalizationCopyWith<$Res>  {
$PortableRegexNormalizationCopyWith(PortableRegexNormalization _, $Res Function(PortableRegexNormalization) __);
}


/// Adds pattern-matching-related methods to [PortableRegexNormalization].
extension PortableRegexNormalizationPatterns on PortableRegexNormalization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PortableRegexReady value)?  ready,TResult Function( PortableRegexInvalid value)?  invalid,TResult Function( PortableRegexUnsupported value)?  unsupported,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PortableRegexReady() when ready != null:
return ready(_that);case PortableRegexInvalid() when invalid != null:
return invalid(_that);case PortableRegexUnsupported() when unsupported != null:
return unsupported(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PortableRegexReady value)  ready,required TResult Function( PortableRegexInvalid value)  invalid,required TResult Function( PortableRegexUnsupported value)  unsupported,}){
final _that = this;
switch (_that) {
case PortableRegexReady():
return ready(_that);case PortableRegexInvalid():
return invalid(_that);case PortableRegexUnsupported():
return unsupported(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PortableRegexReady value)?  ready,TResult? Function( PortableRegexInvalid value)?  invalid,TResult? Function( PortableRegexUnsupported value)?  unsupported,}){
final _that = this;
switch (_that) {
case PortableRegexReady() when ready != null:
return ready(_that);case PortableRegexInvalid() when invalid != null:
return invalid(_that);case PortableRegexUnsupported() when unsupported != null:
return unsupported(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String pattern)?  ready,TResult Function( String reason)?  invalid,TResult Function( String reason)?  unsupported,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PortableRegexReady() when ready != null:
return ready(_that.pattern);case PortableRegexInvalid() when invalid != null:
return invalid(_that.reason);case PortableRegexUnsupported() when unsupported != null:
return unsupported(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String pattern)  ready,required TResult Function( String reason)  invalid,required TResult Function( String reason)  unsupported,}) {final _that = this;
switch (_that) {
case PortableRegexReady():
return ready(_that.pattern);case PortableRegexInvalid():
return invalid(_that.reason);case PortableRegexUnsupported():
return unsupported(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String pattern)?  ready,TResult? Function( String reason)?  invalid,TResult? Function( String reason)?  unsupported,}) {final _that = this;
switch (_that) {
case PortableRegexReady() when ready != null:
return ready(_that.pattern);case PortableRegexInvalid() when invalid != null:
return invalid(_that.reason);case PortableRegexUnsupported() when unsupported != null:
return unsupported(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class PortableRegexReady implements PortableRegexNormalization {
  const PortableRegexReady(this.pattern);
  

 final  String pattern;

/// Create a copy of PortableRegexNormalization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableRegexReadyCopyWith<PortableRegexReady> get copyWith => _$PortableRegexReadyCopyWithImpl<PortableRegexReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableRegexReady&&(identical(other.pattern, pattern) || other.pattern == pattern));
}


@override
int get hashCode {
    return Object.hash(runtimeType,pattern);
}

@override
String toString() {
    return 'PortableRegexNormalization.ready(pattern: $pattern)';
}


}

/// @nodoc
abstract mixin class $PortableRegexReadyCopyWith<$Res> implements $PortableRegexNormalizationCopyWith<$Res> {
  factory $PortableRegexReadyCopyWith(PortableRegexReady value, $Res Function(PortableRegexReady) _then) = _$PortableRegexReadyCopyWithImpl;
@useResult
$Res call({
 String pattern
});




}
/// @nodoc
class _$PortableRegexReadyCopyWithImpl<$Res>
    implements $PortableRegexReadyCopyWith<$Res> {
  _$PortableRegexReadyCopyWithImpl(this._self, this._then);

  final PortableRegexReady _self;
  final $Res Function(PortableRegexReady) _then;

/// Create a copy of PortableRegexNormalization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pattern = null,}) {
  return _then(PortableRegexReady(
null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PortableRegexInvalid implements PortableRegexNormalization {
  const PortableRegexInvalid(this.reason);
  

 final  String reason;

/// Create a copy of PortableRegexNormalization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableRegexInvalidCopyWith<PortableRegexInvalid> get copyWith => _$PortableRegexInvalidCopyWithImpl<PortableRegexInvalid>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableRegexInvalid&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString() {
    return 'PortableRegexNormalization.invalid(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PortableRegexInvalidCopyWith<$Res> implements $PortableRegexNormalizationCopyWith<$Res> {
  factory $PortableRegexInvalidCopyWith(PortableRegexInvalid value, $Res Function(PortableRegexInvalid) _then) = _$PortableRegexInvalidCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$PortableRegexInvalidCopyWithImpl<$Res>
    implements $PortableRegexInvalidCopyWith<$Res> {
  _$PortableRegexInvalidCopyWithImpl(this._self, this._then);

  final PortableRegexInvalid _self;
  final $Res Function(PortableRegexInvalid) _then;

/// Create a copy of PortableRegexNormalization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(PortableRegexInvalid(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PortableRegexUnsupported implements PortableRegexNormalization {
  const PortableRegexUnsupported(this.reason);
  

 final  String reason;

/// Create a copy of PortableRegexNormalization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortableRegexUnsupportedCopyWith<PortableRegexUnsupported> get copyWith => _$PortableRegexUnsupportedCopyWithImpl<PortableRegexUnsupported>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PortableRegexUnsupported&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString() {
    return 'PortableRegexNormalization.unsupported(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PortableRegexUnsupportedCopyWith<$Res> implements $PortableRegexNormalizationCopyWith<$Res> {
  factory $PortableRegexUnsupportedCopyWith(PortableRegexUnsupported value, $Res Function(PortableRegexUnsupported) _then) = _$PortableRegexUnsupportedCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$PortableRegexUnsupportedCopyWithImpl<$Res>
    implements $PortableRegexUnsupportedCopyWith<$Res> {
  _$PortableRegexUnsupportedCopyWithImpl(this._self, this._then);

  final PortableRegexUnsupported _self;
  final $Res Function(PortableRegexUnsupported) _then;

/// Create a copy of PortableRegexNormalization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(PortableRegexUnsupported(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
