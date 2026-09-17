// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_commands.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PageCreationInput {

 String get name; PageKindRef get kind; String get chapter; int get priority;
/// Create a copy of PageCreationInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageCreationInputCopyWith<PageCreationInput> get copyWith => _$PageCreationInputCopyWithImpl<PageCreationInput>(this as PageCreationInput, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PageCreationInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageCreationInput&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.chapter, _this.chapter) || other.chapter == _this.chapter)&&(identical(other.priority, _this.priority) || other.priority == _this.priority));
}


@override
int get hashCode {
  final _this = this as PageCreationInput;
  return Object.hash(runtimeType,_this.name,_this.kind,_this.chapter,_this.priority);
}

@override
String toString() {
  final _this = this as PageCreationInput;
  return 'PageCreationInput(name: ${_this.name}, kind: ${_this.kind}, chapter: ${_this.chapter}, priority: ${_this.priority})';
}


}

/// @nodoc
abstract mixin class $PageCreationInputCopyWith<$Res>  {
  factory $PageCreationInputCopyWith(PageCreationInput value, $Res Function(PageCreationInput) _then) = _$PageCreationInputCopyWithImpl;
@useResult
$Res call({
 String name, PageKindRef kind, String chapter, int priority
});


$PageKindRefCopyWith<$Res> get kind;

}
/// @nodoc
class _$PageCreationInputCopyWithImpl<$Res>
    implements $PageCreationInputCopyWith<$Res> {
  _$PageCreationInputCopyWithImpl(this._self, this._then);

  final PageCreationInput _self;
  final $Res Function(PageCreationInput) _then;

/// Create a copy of PageCreationInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? kind = null,Object? chapter = null,Object? priority = null,}) {
  return _then(PageCreationInput(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of PageCreationInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<$Res> get kind {
  
  return $PageKindRefCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}


/// Adds pattern-matching-related methods to [PageCreationInput].
extension PageCreationInputPatterns on PageCreationInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageCreationInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageCreationInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageCreationInput value)  $default,){
final _that = this;
switch (_that) {
case _PageCreationInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageCreationInput value)?  $default,){
final _that = this;
switch (_that) {
case _PageCreationInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  PageKindRef kind,  String chapter,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageCreationInput() when $default != null:
return $default(_that.name,_that.kind,_that.chapter,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  PageKindRef kind,  String chapter,  int priority)  $default,) {final _that = this;
switch (_that) {
case _PageCreationInput():
return $default(_that.name,_that.kind,_that.chapter,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  PageKindRef kind,  String chapter,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _PageCreationInput() when $default != null:
return $default(_that.name,_that.kind,_that.chapter,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _PageCreationInput implements PageCreationInput {
  const _PageCreationInput({required this.name, required this.kind, required this.chapter, required this.priority});
  

@override final  String name;
@override final  PageKindRef kind;
@override final  String chapter;
@override final  int priority;

/// Create a copy of PageCreationInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageCreationInputCopyWith<_PageCreationInput> get copyWith => __$PageCreationInputCopyWithImpl<_PageCreationInput>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageCreationInput&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,kind,chapter,priority);
}

@override
String toString() {
    return 'PageCreationInput(name: $name, kind: $kind, chapter: $chapter, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$PageCreationInputCopyWith<$Res> implements $PageCreationInputCopyWith<$Res> {
  factory _$PageCreationInputCopyWith(_PageCreationInput value, $Res Function(_PageCreationInput) _then) = __$PageCreationInputCopyWithImpl;
@override @useResult
$Res call({
 String name, PageKindRef kind, String chapter, int priority
});


@override $PageKindRefCopyWith<$Res> get kind;

}
/// @nodoc
class __$PageCreationInputCopyWithImpl<$Res>
    implements _$PageCreationInputCopyWith<$Res> {
  __$PageCreationInputCopyWithImpl(this._self, this._then);

  final _PageCreationInput _self;
  final $Res Function(_PageCreationInput) _then;

/// Create a copy of PageCreationInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? kind = null,Object? chapter = null,Object? priority = null,}) {
  return _then(_PageCreationInput(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of PageCreationInput
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<$Res> get kind {
  
  return $PageKindRefCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}

// dart format on
