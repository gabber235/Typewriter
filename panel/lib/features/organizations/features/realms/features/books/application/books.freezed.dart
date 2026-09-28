// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'books.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Book {

 skir.ResourceId get bookId; String get title; String get icon; Color get color; List<skir.ResourceId> get tagIds;
/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookCopyWith<Book> get copyWith => _$BookCopyWithImpl<Book>(this as Book, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Book;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Book&&(identical(other.bookId, _this.bookId) || other.bookId == _this.bookId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.color, _this.color) || other.color == _this.color)&&const DeepCollectionEquality().equals(other.tagIds, _this.tagIds));
}


@override
int get hashCode {
  final _this = this as Book;
  return Object.hash(runtimeType,_this.bookId,_this.title,_this.icon,_this.color,const DeepCollectionEquality().hash(_this.tagIds));
}

@override
String toString() {
  final _this = this as Book;
  return 'Book(bookId: ${_this.bookId}, title: ${_this.title}, icon: ${_this.icon}, color: ${_this.color}, tagIds: ${_this.tagIds})';
}


}

/// @nodoc
abstract mixin class $BookCopyWith<$Res>  {
  factory $BookCopyWith(Book value, $Res Function(Book) _then) = _$BookCopyWithImpl;
@useResult
$Res call({
 skir.ResourceId bookId, String title, String icon, Color color, List<skir.ResourceId> tagIds
});




}
/// @nodoc
class _$BookCopyWithImpl<$Res>
    implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._self, this._then);

  final Book _self;
  final $Res Function(Book) _then;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookId = null,Object? title = null,Object? icon = null,Object? color = null,Object? tagIds = null,}) {
  return _then(Book(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,tagIds: null == tagIds ? _self.tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}

}


/// Adds pattern-matching-related methods to [Book].
extension BookPatterns on Book {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Book value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Book() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Book value)  $default,){
final _that = this;
switch (_that) {
case _Book():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Book value)?  $default,){
final _that = this;
switch (_that) {
case _Book() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( skir.ResourceId bookId,  String title,  String icon,  Color color,  List<skir.ResourceId> tagIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Book() when $default != null:
return $default(_that.bookId,_that.title,_that.icon,_that.color,_that.tagIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( skir.ResourceId bookId,  String title,  String icon,  Color color,  List<skir.ResourceId> tagIds)  $default,) {final _that = this;
switch (_that) {
case _Book():
return $default(_that.bookId,_that.title,_that.icon,_that.color,_that.tagIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( skir.ResourceId bookId,  String title,  String icon,  Color color,  List<skir.ResourceId> tagIds)?  $default,) {final _that = this;
switch (_that) {
case _Book() when $default != null:
return $default(_that.bookId,_that.title,_that.icon,_that.color,_that.tagIds);case _:
  return null;

}
}

}

/// @nodoc


class _Book extends Book {
  const _Book({required this.bookId, required this.title, required this.icon, required this.color, required  List<skir.ResourceId> tagIds}): assert(title != "", 'Title must not be empty.'),assert(icon != "", 'Icon must not be empty.'),_tagIds = tagIds,super._();
  

@override final  skir.ResourceId bookId;
@override final  String title;
@override final  String icon;
@override final  Color color;
 final  List<skir.ResourceId> _tagIds;
@override List<skir.ResourceId> get tagIds {
  if (_tagIds is EqualUnmodifiableListView) return _tagIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tagIds);
}


/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookCopyWith<_Book> get copyWith => __$BookCopyWithImpl<_Book>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Book&&(identical(other.bookId, bookId) || other.bookId == bookId)&&(identical(other.title, title) || other.title == title)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.tagIds, _tagIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bookId,title,icon,color,const DeepCollectionEquality().hash(_tagIds));
}

@override
String toString() {
    return 'Book(bookId: $bookId, title: $title, icon: $icon, color: $color, tagIds: $tagIds)';
}


}

/// @nodoc
abstract mixin class _$BookCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$BookCopyWith(_Book value, $Res Function(_Book) _then) = __$BookCopyWithImpl;
@override @useResult
$Res call({
 skir.ResourceId bookId, String title, String icon, Color color, List<skir.ResourceId> tagIds
});




}
/// @nodoc
class __$BookCopyWithImpl<$Res>
    implements _$BookCopyWith<$Res> {
  __$BookCopyWithImpl(this._self, this._then);

  final _Book _self;
  final $Res Function(_Book) _then;

/// Create a copy of Book
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookId = null,Object? title = null,Object? icon = null,Object? color = null,Object? tagIds = null,}) {
  return _then(_Book(
bookId: null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.ResourceId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,tagIds: null == tagIds ? _self._tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<skir.ResourceId>,
  ));
}


}

// dart format on
