// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Page {

 skir.ResourceId get pageId; skir.ResourceId get bookId; String get name; PageKindRef get kind; String get chapter; int get priority;
/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageCopyWith<Page> get copyWith => _$PageCopyWithImpl<Page>(this as Page, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Page;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Page&&(identical(other.pageId, _this.pageId) || other.pageId == _this.pageId)&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.chapter, _this.chapter) || other.chapter == _this.chapter)&&(identical(other.priority, _this.priority) || other.priority == _this.priority));
}


@override
int get hashCode {
  final _this = this as Page;
  return Object.hash(runtimeType,_this.pageId,_this.bookId,_this.name,_this.kind,_this.chapter,_this.priority);
}

@override
String toString() {
  final _this = this as Page;
  return 'Page(pageId: ${_this.pageId}, bookId: ${_this.bookId}, name: ${_this.name}, kind: ${_this.kind}, chapter: ${_this.chapter}, priority: ${_this.priority})';
}


}

/// @nodoc
abstract mixin class $PageCopyWith<$Res>  {
  factory $PageCopyWith(Page value, $Res Function(Page) _then) = _$PageCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId pageId, skir.ResourceId bookId, String name, PageKindRef kind, String chapter, int priority
});


$PageKindRefCopyWith<$Res> get kind;

}
/// @nodoc
class _$PageCopyWithImpl<$Res>
    implements $PageCopyWith<$Res> {
  _$PageCopyWithImpl(this._self, this._then);

  final Page _self;
  final $Res Function(Page) _then;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageId = null,Object? bookId = null,Object? name = null,Object? kind = null,Object? chapter = null,Object? priority = null,}) {
  return _then(Page(
pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageKindRefCopyWith<$Res> get kind {
  
  return $PageKindRefCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId pageId,  skir.ResourceId bookId,  String name,  PageKindRef kind,  String chapter,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Page() when $default != null:
return $default(_that.pageId,_that.bookId,_that.name,_that.kind,_that.chapter,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId pageId,  skir.ResourceId bookId,  String name,  PageKindRef kind,  String chapter,  int priority)  $default,) {final _that = this;
switch (_that) {
case _Page():
return $default(_that.pageId,_that.bookId,_that.name,_that.kind,_that.chapter,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId pageId,  skir.ResourceId bookId,  String name,  PageKindRef kind,  String chapter,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _Page() when $default != null:
return $default(_that.pageId,_that.bookId,_that.name,_that.kind,_that.chapter,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _Page extends Page {
  const _Page({required this.pageId, required this.bookId, required this.name, required this.kind, required this.chapter, required this.priority}): assert(name != "", 'Name must not be empty.'),super._();
  

@override final  skir.ResourceId pageId;
@override final  skir.ResourceId bookId;
@override final  String name;
@override final  PageKindRef kind;
@override final  String chapter;
@override final  int priority;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageCopyWith<_Page> get copyWith => __$PageCopyWithImpl<_Page>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Page&&(identical(other.pageId, pageId) || other.pageId == pageId)&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode {
    return Object.hash(runtimeType,pageId,bookId,name,kind,chapter,priority);
}

@override
String toString() {
    return 'Page(pageId: $pageId, bookId: $bookId, name: $name, kind: $kind, chapter: $chapter, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$PageCopyWith<$Res> implements $PageCopyWith<$Res> {
  factory _$PageCopyWith(_Page value, $Res Function(_Page) _then) = __$PageCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId pageId, skir.ResourceId bookId, String name, PageKindRef kind, String chapter, int priority
});


@override $PageKindRefCopyWith<$Res> get kind;

}
/// @nodoc
class __$PageCopyWithImpl<$Res>
    implements _$PageCopyWith<$Res> {
  __$PageCopyWithImpl(this._self, this._then);

  final _Page _self;
  final $Res Function(_Page) _then;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageId = null,Object? bookId = null,Object? name = null,Object? kind = null,Object? chapter = null,Object? priority = null,}) {
  return _then(_Page(
pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PageKindRef,chapter: null == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Page
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
