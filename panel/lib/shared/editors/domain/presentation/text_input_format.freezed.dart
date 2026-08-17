// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_input_format.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TextInputFormat {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextInputFormat);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TextInputFormat()';
}


}

/// @nodoc
class $TextInputFormatCopyWith<$Res>  {
$TextInputFormatCopyWith(TextInputFormat _, $Res Function(TextInputFormat) __);
}


/// Adds pattern-matching-related methods to [TextInputFormat].
extension TextInputFormatPatterns on TextInputFormat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LowercaseTextInputFormat value)?  lowercase,TResult Function( UppercaseTextInputFormat value)?  uppercase,TResult Function( ReplaceTextInputFormat value)?  replace,TResult Function( AllowTextInputFormat value)?  allow,TResult Function( DenyTextInputFormat value)?  deny,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LowercaseTextInputFormat() when lowercase != null:
return lowercase(_that);case UppercaseTextInputFormat() when uppercase != null:
return uppercase(_that);case ReplaceTextInputFormat() when replace != null:
return replace(_that);case AllowTextInputFormat() when allow != null:
return allow(_that);case DenyTextInputFormat() when deny != null:
return deny(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LowercaseTextInputFormat value)  lowercase,required TResult Function( UppercaseTextInputFormat value)  uppercase,required TResult Function( ReplaceTextInputFormat value)  replace,required TResult Function( AllowTextInputFormat value)  allow,required TResult Function( DenyTextInputFormat value)  deny,}){
final _that = this;
switch (_that) {
case LowercaseTextInputFormat():
return lowercase(_that);case UppercaseTextInputFormat():
return uppercase(_that);case ReplaceTextInputFormat():
return replace(_that);case AllowTextInputFormat():
return allow(_that);case DenyTextInputFormat():
return deny(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LowercaseTextInputFormat value)?  lowercase,TResult? Function( UppercaseTextInputFormat value)?  uppercase,TResult? Function( ReplaceTextInputFormat value)?  replace,TResult? Function( AllowTextInputFormat value)?  allow,TResult? Function( DenyTextInputFormat value)?  deny,}){
final _that = this;
switch (_that) {
case LowercaseTextInputFormat() when lowercase != null:
return lowercase(_that);case UppercaseTextInputFormat() when uppercase != null:
return uppercase(_that);case ReplaceTextInputFormat() when replace != null:
return replace(_that);case AllowTextInputFormat() when allow != null:
return allow(_that);case DenyTextInputFormat() when deny != null:
return deny(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  lowercase,TResult Function()?  uppercase,TResult Function( String pattern,  String replacement)?  replace,TResult Function( String pattern)?  allow,TResult Function( String pattern)?  deny,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LowercaseTextInputFormat() when lowercase != null:
return lowercase();case UppercaseTextInputFormat() when uppercase != null:
return uppercase();case ReplaceTextInputFormat() when replace != null:
return replace(_that.pattern,_that.replacement);case AllowTextInputFormat() when allow != null:
return allow(_that.pattern);case DenyTextInputFormat() when deny != null:
return deny(_that.pattern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  lowercase,required TResult Function()  uppercase,required TResult Function( String pattern,  String replacement)  replace,required TResult Function( String pattern)  allow,required TResult Function( String pattern)  deny,}) {final _that = this;
switch (_that) {
case LowercaseTextInputFormat():
return lowercase();case UppercaseTextInputFormat():
return uppercase();case ReplaceTextInputFormat():
return replace(_that.pattern,_that.replacement);case AllowTextInputFormat():
return allow(_that.pattern);case DenyTextInputFormat():
return deny(_that.pattern);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  lowercase,TResult? Function()?  uppercase,TResult? Function( String pattern,  String replacement)?  replace,TResult? Function( String pattern)?  allow,TResult? Function( String pattern)?  deny,}) {final _that = this;
switch (_that) {
case LowercaseTextInputFormat() when lowercase != null:
return lowercase();case UppercaseTextInputFormat() when uppercase != null:
return uppercase();case ReplaceTextInputFormat() when replace != null:
return replace(_that.pattern,_that.replacement);case AllowTextInputFormat() when allow != null:
return allow(_that.pattern);case DenyTextInputFormat() when deny != null:
return deny(_that.pattern);case _:
  return null;

}
}

}

/// @nodoc


class LowercaseTextInputFormat implements TextInputFormat {
  const LowercaseTextInputFormat();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LowercaseTextInputFormat);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TextInputFormat.lowercase()';
}


}




/// @nodoc


class UppercaseTextInputFormat implements TextInputFormat {
  const UppercaseTextInputFormat();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UppercaseTextInputFormat);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TextInputFormat.uppercase()';
}


}




/// @nodoc


class ReplaceTextInputFormat implements TextInputFormat {
  const ReplaceTextInputFormat({required this.pattern, required this.replacement});
  

 final  String pattern;
 final  String replacement;

/// Create a copy of TextInputFormat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplaceTextInputFormatCopyWith<ReplaceTextInputFormat> get copyWith => _$ReplaceTextInputFormatCopyWithImpl<ReplaceTextInputFormat>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReplaceTextInputFormat&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.replacement, replacement) || other.replacement == replacement));
}


@override
int get hashCode => Object.hash(runtimeType,pattern,replacement);

@override
String toString() {
  return 'TextInputFormat.replace(pattern: $pattern, replacement: $replacement)';
}


}

/// @nodoc
abstract mixin class $ReplaceTextInputFormatCopyWith<$Res> implements $TextInputFormatCopyWith<$Res> {
  factory $ReplaceTextInputFormatCopyWith(ReplaceTextInputFormat value, $Res Function(ReplaceTextInputFormat) _then) = _$ReplaceTextInputFormatCopyWithImpl;
@useResult
$Res call({
 String pattern, String replacement
});




}
/// @nodoc
class _$ReplaceTextInputFormatCopyWithImpl<$Res>
    implements $ReplaceTextInputFormatCopyWith<$Res> {
  _$ReplaceTextInputFormatCopyWithImpl(this._self, this._then);

  final ReplaceTextInputFormat _self;
  final $Res Function(ReplaceTextInputFormat) _then;

/// Create a copy of TextInputFormat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pattern = null,Object? replacement = null,}) {
  return _then(ReplaceTextInputFormat(
pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,replacement: null == replacement ? _self.replacement : replacement // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AllowTextInputFormat implements TextInputFormat {
  const AllowTextInputFormat(this.pattern);
  

 final  String pattern;

/// Create a copy of TextInputFormat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllowTextInputFormatCopyWith<AllowTextInputFormat> get copyWith => _$AllowTextInputFormatCopyWithImpl<AllowTextInputFormat>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllowTextInputFormat&&(identical(other.pattern, pattern) || other.pattern == pattern));
}


@override
int get hashCode => Object.hash(runtimeType,pattern);

@override
String toString() {
  return 'TextInputFormat.allow(pattern: $pattern)';
}


}

/// @nodoc
abstract mixin class $AllowTextInputFormatCopyWith<$Res> implements $TextInputFormatCopyWith<$Res> {
  factory $AllowTextInputFormatCopyWith(AllowTextInputFormat value, $Res Function(AllowTextInputFormat) _then) = _$AllowTextInputFormatCopyWithImpl;
@useResult
$Res call({
 String pattern
});




}
/// @nodoc
class _$AllowTextInputFormatCopyWithImpl<$Res>
    implements $AllowTextInputFormatCopyWith<$Res> {
  _$AllowTextInputFormatCopyWithImpl(this._self, this._then);

  final AllowTextInputFormat _self;
  final $Res Function(AllowTextInputFormat) _then;

/// Create a copy of TextInputFormat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pattern = null,}) {
  return _then(AllowTextInputFormat(
null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DenyTextInputFormat implements TextInputFormat {
  const DenyTextInputFormat(this.pattern);
  

 final  String pattern;

/// Create a copy of TextInputFormat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DenyTextInputFormatCopyWith<DenyTextInputFormat> get copyWith => _$DenyTextInputFormatCopyWithImpl<DenyTextInputFormat>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DenyTextInputFormat&&(identical(other.pattern, pattern) || other.pattern == pattern));
}


@override
int get hashCode => Object.hash(runtimeType,pattern);

@override
String toString() {
  return 'TextInputFormat.deny(pattern: $pattern)';
}


}

/// @nodoc
abstract mixin class $DenyTextInputFormatCopyWith<$Res> implements $TextInputFormatCopyWith<$Res> {
  factory $DenyTextInputFormatCopyWith(DenyTextInputFormat value, $Res Function(DenyTextInputFormat) _then) = _$DenyTextInputFormatCopyWithImpl;
@useResult
$Res call({
 String pattern
});




}
/// @nodoc
class _$DenyTextInputFormatCopyWithImpl<$Res>
    implements $DenyTextInputFormatCopyWith<$Res> {
  _$DenyTextInputFormatCopyWithImpl(this._self, this._then);

  final DenyTextInputFormat _self;
  final $Res Function(DenyTextInputFormat) _then;

/// Create a copy of TextInputFormat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pattern = null,}) {
  return _then(DenyTextInputFormat(
null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
