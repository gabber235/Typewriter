// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Page {

 skir.RecordId get pageId; skir.RecordId get bookId; String get name; PageType get type; String get chapter; int get priority;
/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageCopyWith<Page> get copyWith => _$PageCopyWithImpl<Page>(this as Page, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Page&&(identical(other.pageId, pageId) || other.pageId == pageId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,pageId,bookId,name,type,chapter,priority);

@override
String toString() {
  return 'Page(pageId: $pageId, bookId: $bookId, name: $name, type: $type, chapter: $chapter, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $PageCopyWith<$Res>  {
  factory $PageCopyWith(Page value, $Res Function(Page) _then) = _$PageCopyWithImpl;
@useResult
$Res call({
 skir.RecordId pageId, skir.RecordId bookId, String name, PageType type, String chapter, int priority
});




}
/// @nodoc
class _$PageCopyWithImpl<$Res>
    implements $PageCopyWith<$Res> {
  _$PageCopyWithImpl(this._self, this._then);

  final Page _self;
  final $Res Function(Page) _then;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageId = null,Object? bookId = null,Object? name = null,Object? type = null,Object? chapter = null,Object? priority = null,}) {
  return _then(_self.copyWith(
pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PageType,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Page].
extension PagePatterns on Page {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Page value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Page() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Page value)  $default,){
final _that = this;
switch (_that) {
case _Page():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Page value)?  $default,){
final _that = this;
switch (_that) {
case _Page() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.RecordId pageId,  skir.RecordId bookId,  String name,  PageType type,  String chapter,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Page() when $default != null:
return $default(_that.pageId,_that.bookId,_that.name,_that.type,_that.chapter,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.RecordId pageId,  skir.RecordId bookId,  String name,  PageType type,  String chapter,  int priority)  $default,) {final _that = this;
switch (_that) {
case _Page():
return $default(_that.pageId,_that.bookId,_that.name,_that.type,_that.chapter,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.RecordId pageId,  skir.RecordId bookId,  String name,  PageType type,  String chapter,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _Page() when $default != null:
return $default(_that.pageId,_that.bookId,_that.name,_that.type,_that.chapter,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _Page extends Page {
  const _Page({required this.pageId, required this.bookId, required this.name, required this.type, required this.chapter, required this.priority}): assert(name != "", 'Name must not be empty.'),super._();
  

@override final  skir.RecordId pageId;
@override final  skir.RecordId bookId;
@override final  String name;
@override final  PageType type;
@override final  String chapter;
@override final  int priority;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageCopyWith<_Page> get copyWith => __$PageCopyWithImpl<_Page>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Page&&(identical(other.pageId, pageId) || other.pageId == pageId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,pageId,bookId,name,type,chapter,priority);

@override
String toString() {
  return 'Page(pageId: $pageId, bookId: $bookId, name: $name, type: $type, chapter: $chapter, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$PageCopyWith<$Res> implements $PageCopyWith<$Res> {
  factory _$PageCopyWith(_Page value, $Res Function(_Page) _then) = __$PageCopyWithImpl;
@override @useResult
$Res call({
 skir.RecordId pageId, skir.RecordId bookId, String name, PageType type, String chapter, int priority
});




}
/// @nodoc
class __$PageCopyWithImpl<$Res>
    implements _$PageCopyWith<$Res> {
  __$PageCopyWithImpl(this._self, this._then);

  final _Page _self;
  final $Res Function(_Page) _then;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageId = null,Object? bookId = null,Object? name = null,Object? type = null,Object? chapter = null,Object? priority = null,}) {
  return _then(_Page(
pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PageType,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
