// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringSessionState {

 int? get sequence; Map<skir.RecordId, wire.Book> get books; Map<skir.RecordId, wire.Tag> get tags; Map<skir.RecordId, wire.Page> get pages; Map<skir.RecordId, wire.PageDocument> get documents; bool get refreshing;
/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<AuthoringSessionState> get copyWith => _$AuthoringSessionStateCopyWithImpl<AuthoringSessionState>(this as AuthoringSessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSessionState&&(identical(other.sequence, sequence) || other.sequence == sequence)&&const DeepCollectionEquality().equals(other.books, books)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.pages, pages)&&const DeepCollectionEquality().equals(other.documents, documents)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing));
}


@override
int get hashCode => Object.hash(runtimeType,sequence,const DeepCollectionEquality().hash(books),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(pages),const DeepCollectionEquality().hash(documents),refreshing);

@override
String toString() {
  return 'AuthoringSessionState(sequence: $sequence, books: $books, tags: $tags, pages: $pages, documents: $documents, refreshing: $refreshing)';
}


}

/// @nodoc
abstract mixin class $AuthoringSessionStateCopyWith<$Res>  {
  factory $AuthoringSessionStateCopyWith(AuthoringSessionState value, $Res Function(AuthoringSessionState) _then) = _$AuthoringSessionStateCopyWithImpl;
@useResult
$Res call({
 int? sequence, Map<skir.RecordId, wire.Book> books, Map<skir.RecordId, wire.Tag> tags, Map<skir.RecordId, wire.Page> pages, Map<skir.RecordId, wire.PageDocument> documents, bool refreshing
});




}
/// @nodoc
class _$AuthoringSessionStateCopyWithImpl<$Res>
    implements $AuthoringSessionStateCopyWith<$Res> {
  _$AuthoringSessionStateCopyWithImpl(this._self, this._then);

  final AuthoringSessionState _self;
  final $Res Function(AuthoringSessionState) _then;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sequence = freezed,Object? books = null,Object? tags = null,Object? pages = null,Object? documents = null,Object? refreshing = null,}) {
  return _then(_self.copyWith(
sequence: freezed == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int?,books: null == books ? _self.books : books // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.Book>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.Tag>,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.Page>,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.PageDocument>,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringSessionState].
extension AuthoringSessionStatePatterns on AuthoringSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSessionState value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? sequence,  Map<skir.RecordId, wire.Book> books,  Map<skir.RecordId, wire.Tag> tags,  Map<skir.RecordId, wire.Page> pages,  Map<skir.RecordId, wire.PageDocument> documents,  bool refreshing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
return $default(_that.sequence,_that.books,_that.tags,_that.pages,_that.documents,_that.refreshing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? sequence,  Map<skir.RecordId, wire.Book> books,  Map<skir.RecordId, wire.Tag> tags,  Map<skir.RecordId, wire.Page> pages,  Map<skir.RecordId, wire.PageDocument> documents,  bool refreshing)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionState():
return $default(_that.sequence,_that.books,_that.tags,_that.pages,_that.documents,_that.refreshing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? sequence,  Map<skir.RecordId, wire.Book> books,  Map<skir.RecordId, wire.Tag> tags,  Map<skir.RecordId, wire.Page> pages,  Map<skir.RecordId, wire.PageDocument> documents,  bool refreshing)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
return $default(_that.sequence,_that.books,_that.tags,_that.pages,_that.documents,_that.refreshing);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSessionState implements AuthoringSessionState {
  const _AuthoringSessionState({this.sequence, final  Map<skir.RecordId, wire.Book> books = const {}, final  Map<skir.RecordId, wire.Tag> tags = const {}, final  Map<skir.RecordId, wire.Page> pages = const {}, final  Map<skir.RecordId, wire.PageDocument> documents = const {}, this.refreshing = false}): _books = books,_tags = tags,_pages = pages,_documents = documents;
  

@override final  int? sequence;
 final  Map<skir.RecordId, wire.Book> _books;
@override@JsonKey() Map<skir.RecordId, wire.Book> get books {
  if (_books is EqualUnmodifiableMapView) return _books;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_books);
}

 final  Map<skir.RecordId, wire.Tag> _tags;
@override@JsonKey() Map<skir.RecordId, wire.Tag> get tags {
  if (_tags is EqualUnmodifiableMapView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tags);
}

 final  Map<skir.RecordId, wire.Page> _pages;
@override@JsonKey() Map<skir.RecordId, wire.Page> get pages {
  if (_pages is EqualUnmodifiableMapView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pages);
}

 final  Map<skir.RecordId, wire.PageDocument> _documents;
@override@JsonKey() Map<skir.RecordId, wire.PageDocument> get documents {
  if (_documents is EqualUnmodifiableMapView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_documents);
}

@override@JsonKey() final  bool refreshing;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSessionStateCopyWith<_AuthoringSessionState> get copyWith => __$AuthoringSessionStateCopyWithImpl<_AuthoringSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSessionState&&(identical(other.sequence, sequence) || other.sequence == sequence)&&const DeepCollectionEquality().equals(other._books, _books)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._pages, _pages)&&const DeepCollectionEquality().equals(other._documents, _documents)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing));
}


@override
int get hashCode => Object.hash(runtimeType,sequence,const DeepCollectionEquality().hash(_books),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_pages),const DeepCollectionEquality().hash(_documents),refreshing);

@override
String toString() {
  return 'AuthoringSessionState(sequence: $sequence, books: $books, tags: $tags, pages: $pages, documents: $documents, refreshing: $refreshing)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSessionStateCopyWith<$Res> implements $AuthoringSessionStateCopyWith<$Res> {
  factory _$AuthoringSessionStateCopyWith(_AuthoringSessionState value, $Res Function(_AuthoringSessionState) _then) = __$AuthoringSessionStateCopyWithImpl;
@override @useResult
$Res call({
 int? sequence, Map<skir.RecordId, wire.Book> books, Map<skir.RecordId, wire.Tag> tags, Map<skir.RecordId, wire.Page> pages, Map<skir.RecordId, wire.PageDocument> documents, bool refreshing
});




}
/// @nodoc
class __$AuthoringSessionStateCopyWithImpl<$Res>
    implements _$AuthoringSessionStateCopyWith<$Res> {
  __$AuthoringSessionStateCopyWithImpl(this._self, this._then);

  final _AuthoringSessionState _self;
  final $Res Function(_AuthoringSessionState) _then;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sequence = freezed,Object? books = null,Object? tags = null,Object? pages = null,Object? documents = null,Object? refreshing = null,}) {
  return _then(_AuthoringSessionState(
sequence: freezed == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int?,books: null == books ? _self._books : books // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.Book>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.Tag>,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.Page>,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, wire.PageDocument>,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AuthoringScope {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringScope);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return '_AuthoringScope()';
}


}

/// @nodoc
class _$AuthoringScopeCopyWith<$Res>  {
_$AuthoringScopeCopyWith(_AuthoringScope _, $Res Function(_AuthoringScope) __);
}


/// Adds pattern-matching-related methods to [_AuthoringScope].
extension _AuthoringScopePatterns on _AuthoringScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LibraryScope value)?  library,TResult Function( _BookScope value)?  book,TResult Function( _PageScope value)?  page,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryScope() when library != null:
return library(_that);case _BookScope() when book != null:
return book(_that);case _PageScope() when page != null:
return page(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LibraryScope value)  library,required TResult Function( _BookScope value)  book,required TResult Function( _PageScope value)  page,}){
final _that = this;
switch (_that) {
case _LibraryScope():
return library(_that);case _BookScope():
return book(_that);case _PageScope():
return page(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LibraryScope value)?  library,TResult? Function( _BookScope value)?  book,TResult? Function( _PageScope value)?  page,}){
final _that = this;
switch (_that) {
case _LibraryScope() when library != null:
return library(_that);case _BookScope() when book != null:
return book(_that);case _PageScope() when page != null:
return page(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  library,TResult Function( skir.RecordId bookId)?  book,TResult Function( skir.RecordId pageId)?  page,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryScope() when library != null:
return library();case _BookScope() when book != null:
return book(_that.bookId);case _PageScope() when page != null:
return page(_that.pageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  library,required TResult Function( skir.RecordId bookId)  book,required TResult Function( skir.RecordId pageId)  page,}) {final _that = this;
switch (_that) {
case _LibraryScope():
return library();case _BookScope():
return book(_that.bookId);case _PageScope():
return page(_that.pageId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  library,TResult? Function( skir.RecordId bookId)?  book,TResult? Function( skir.RecordId pageId)?  page,}) {final _that = this;
switch (_that) {
case _LibraryScope() when library != null:
return library();case _BookScope() when book != null:
return book(_that.bookId);case _PageScope() when page != null:
return page(_that.pageId);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryScope extends _AuthoringScope {
  const _LibraryScope(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryScope);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return '_AuthoringScope.library()';
}


}




/// @nodoc


class _BookScope extends _AuthoringScope {
  const _BookScope(this.bookId): super._();
  

 final  skir.RecordId bookId;

/// Create a copy of _AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookScopeCopyWith<_BookScope> get copyWith => __$BookScopeCopyWithImpl<_BookScope>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookScope&&(identical(other.bookId, bookId) || other.bookId == bookId));
}


@override
int get hashCode => Object.hash(runtimeType,bookId);

@override
String toString() {
  return '_AuthoringScope.book(bookId: $bookId)';
}


}

/// @nodoc
abstract mixin class _$BookScopeCopyWith<$Res> implements _$AuthoringScopeCopyWith<$Res> {
  factory _$BookScopeCopyWith(_BookScope value, $Res Function(_BookScope) _then) = __$BookScopeCopyWithImpl;
@useResult
$Res call({
 skir.RecordId bookId
});




}
/// @nodoc
class __$BookScopeCopyWithImpl<$Res>
    implements _$BookScopeCopyWith<$Res> {
  __$BookScopeCopyWithImpl(this._self, this._then);

  final _BookScope _self;
  final $Res Function(_BookScope) _then;

/// Create a copy of _AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bookId = null,}) {
  return _then(_BookScope(
null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

/// @nodoc


class _PageScope extends _AuthoringScope {
  const _PageScope(this.pageId): super._();
  

 final  skir.RecordId pageId;

/// Create a copy of _AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageScopeCopyWith<_PageScope> get copyWith => __$PageScopeCopyWithImpl<_PageScope>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageScope&&(identical(other.pageId, pageId) || other.pageId == pageId));
}


@override
int get hashCode => Object.hash(runtimeType,pageId);

@override
String toString() {
  return '_AuthoringScope.page(pageId: $pageId)';
}


}

/// @nodoc
abstract mixin class _$PageScopeCopyWith<$Res> implements _$AuthoringScopeCopyWith<$Res> {
  factory _$PageScopeCopyWith(_PageScope value, $Res Function(_PageScope) _then) = __$PageScopeCopyWithImpl;
@useResult
$Res call({
 skir.RecordId pageId
});




}
/// @nodoc
class __$PageScopeCopyWithImpl<$Res>
    implements _$PageScopeCopyWith<$Res> {
  __$PageScopeCopyWithImpl(this._self, this._then);

  final _PageScope _self;
  final $Res Function(_PageScope) _then;

/// Create a copy of _AuthoringScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pageId = null,}) {
  return _then(_PageScope(
null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as skir.RecordId,
  ));
}


}

// dart format on
