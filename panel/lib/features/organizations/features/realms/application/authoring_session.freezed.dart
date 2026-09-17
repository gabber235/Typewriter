// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authoring_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringSessionAccess {

 AuthoringSession get notifier; AuthoringSessionState get state;
/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSessionAccessCopyWith<AuthoringSessionAccess> get copyWith => _$AuthoringSessionAccessCopyWithImpl<AuthoringSessionAccess>(this as AuthoringSessionAccess, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSessionAccess;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSessionAccess&&(identical(other.notifier, _this.notifier) || other.notifier == _this.notifier)&&(identical(other.state, _this.state) || other.state == _this.state));
}


@override
int get hashCode {
  final _this = this as AuthoringSessionAccess;
  return Object.hash(runtimeType,_this.notifier,_this.state);
}

@override
String toString() {
  final _this = this as AuthoringSessionAccess;
  return 'AuthoringSessionAccess(notifier: ${_this.notifier}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $AuthoringSessionAccessCopyWith<$Res>  {
  factory $AuthoringSessionAccessCopyWith(AuthoringSessionAccess value, $Res Function(AuthoringSessionAccess) _then) = _$AuthoringSessionAccessCopyWithImpl;
@useResult
$Res call({
 AuthoringSession notifier, AuthoringSessionState state
});


$AuthoringSessionStateCopyWith<$Res> get state;

}
/// @nodoc
class _$AuthoringSessionAccessCopyWithImpl<$Res>
    implements $AuthoringSessionAccessCopyWith<$Res> {
  _$AuthoringSessionAccessCopyWithImpl(this._self, this._then);

  final AuthoringSessionAccess _self;
  final $Res Function(AuthoringSessionAccess) _then;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notifier = null,Object? state = null,}) {
  return _then(AuthoringSessionAccess(
notifier: null == notifier ? _self.notifier : notifier // ignore: cast_nullable_to_non_nullable
as AuthoringSession,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AuthoringSessionState,
  ));
}
/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<$Res> get state {
  
  return $AuthoringSessionStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthoringSessionAccess].
extension AuthoringSessionAccessPatterns on AuthoringSessionAccess {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringSessionAccess value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringSessionAccess value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringSessionAccess value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthoringSession notifier,  AuthoringSessionState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
return $default(_that.notifier,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthoringSession notifier,  AuthoringSessionState state)  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess():
return $default(_that.notifier,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthoringSession notifier,  AuthoringSessionState state)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionAccess() when $default != null:
return $default(_that.notifier,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSessionAccess implements AuthoringSessionAccess {
  const _AuthoringSessionAccess({required this.notifier, required this.state});
  

@override final  AuthoringSession notifier;
@override final  AuthoringSessionState state;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSessionAccessCopyWith<_AuthoringSessionAccess> get copyWith => __$AuthoringSessionAccessCopyWithImpl<_AuthoringSessionAccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSessionAccess&&(identical(other.notifier, notifier) || other.notifier == notifier)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode {
    return Object.hash(runtimeType,notifier,state);
}

@override
String toString() {
    return 'AuthoringSessionAccess(notifier: $notifier, state: $state)';
}


}

/// @nodoc
abstract mixin class _$AuthoringSessionAccessCopyWith<$Res> implements $AuthoringSessionAccessCopyWith<$Res> {
  factory _$AuthoringSessionAccessCopyWith(_AuthoringSessionAccess value, $Res Function(_AuthoringSessionAccess) _then) = __$AuthoringSessionAccessCopyWithImpl;
@override @useResult
$Res call({
 AuthoringSession notifier, AuthoringSessionState state
});


@override $AuthoringSessionStateCopyWith<$Res> get state;

}
/// @nodoc
class __$AuthoringSessionAccessCopyWithImpl<$Res>
    implements _$AuthoringSessionAccessCopyWith<$Res> {
  __$AuthoringSessionAccessCopyWithImpl(this._self, this._then);

  final _AuthoringSessionAccess _self;
  final $Res Function(_AuthoringSessionAccess) _then;

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notifier = null,Object? state = null,}) {
  return _then(_AuthoringSessionAccess(
notifier: null == notifier ? _self.notifier : notifier // ignore: cast_nullable_to_non_nullable
as AuthoringSession,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AuthoringSessionState,
  ));
}

/// Create a copy of AuthoringSessionAccess
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<$Res> get state {
  
  return $AuthoringSessionStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$AuthoringValue<T> {

 T get value; int get revision;
/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringValueCopyWith<T, AuthoringValue<T>> get copyWith => _$AuthoringValueCopyWithImpl<T, AuthoringValue<T>>(this as AuthoringValue<T>, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringValue<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringValue<T>&&const DeepCollectionEquality().equals(other.value, _this.value)&&(identical(other.revision, _this.revision) || other.revision == _this.revision));
}


@override
int get hashCode {
  final _this = this as AuthoringValue<T>;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.value),_this.revision);
}

@override
String toString() {
  final _this = this as AuthoringValue<T>;
  return 'AuthoringValue<$T>(value: ${_this.value}, revision: ${_this.revision})';
}


}

/// @nodoc
abstract mixin class $AuthoringValueCopyWith<T,$Res>  {
  factory $AuthoringValueCopyWith(AuthoringValue<T> value, $Res Function(AuthoringValue<T>) _then) = _$AuthoringValueCopyWithImpl;
@useResult
$Res call({
 T value, int revision
});




}
/// @nodoc
class _$AuthoringValueCopyWithImpl<T,$Res>
    implements $AuthoringValueCopyWith<T, $Res> {
  _$AuthoringValueCopyWithImpl(this._self, this._then);

  final AuthoringValue<T> _self;
  final $Res Function(AuthoringValue<T>) _then;

/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = freezed,Object? revision = null,}) {
  return _then(AuthoringValue(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthoringValue].
extension AuthoringValuePatterns<T> on AuthoringValue<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthoringValue<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthoringValue<T> value)  $default,){
final _that = this;
switch (_that) {
case _AuthoringValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthoringValue<T> value)?  $default,){
final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( T value,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
return $default(_that.value,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( T value,  int revision)  $default,) {final _that = this;
switch (_that) {
case _AuthoringValue():
return $default(_that.value,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( T value,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringValue() when $default != null:
return $default(_that.value,_that.revision);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringValue<T> implements AuthoringValue<T> {
  const _AuthoringValue({required this.value, required this.revision});
  

@override final  T value;
@override final  int revision;

/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringValueCopyWith<T, _AuthoringValue<T>> get copyWith => __$AuthoringValueCopyWithImpl<T, _AuthoringValue<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringValue<T>&&const DeepCollectionEquality().equals(other.value, value)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value),revision);
}

@override
String toString() {
    return 'AuthoringValue<$T>(value: $value, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$AuthoringValueCopyWith<T,$Res> implements $AuthoringValueCopyWith<T, $Res> {
  factory _$AuthoringValueCopyWith(_AuthoringValue<T> value, $Res Function(_AuthoringValue<T>) _then) = __$AuthoringValueCopyWithImpl;
@override @useResult
$Res call({
 T value, int revision
});




}
/// @nodoc
class __$AuthoringValueCopyWithImpl<T,$Res>
    implements _$AuthoringValueCopyWith<T, $Res> {
  __$AuthoringValueCopyWithImpl(this._self, this._then);

  final _AuthoringValue<T> _self;
  final $Res Function(_AuthoringValue<T>) _then;

/// Create a copy of AuthoringValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,Object? revision = null,}) {
  return _then(_AuthoringValue<T>(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AuthoringSessionState {

/// The server sequence represented by all canonical collections.
 int? get sequence;/// Canonical books retained by active scopes.
 Map<skir.RecordId, skir.Book> get books;/// Canonical tags retained by the library scope.
 Map<skir.RecordId, skir.Tag> get tags;/// Canonical page metadata retained by active book or page scopes.
 Map<skir.RecordId, skir.Page> get pages;/// Canonical page documents retained by active page scopes.
 Map<skir.RecordId, skir.PageDocument> get documents;/// Whether an authoritative refresh is currently reconciling the model.
 bool get refreshing;
/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoringSessionStateCopyWith<AuthoringSessionState> get copyWith => _$AuthoringSessionStateCopyWithImpl<AuthoringSessionState>(this as AuthoringSessionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSessionState&&(identical(other.sequence, _this.sequence) || other.sequence == _this.sequence)&&const DeepCollectionEquality().equals(other.books, _this.books)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&const DeepCollectionEquality().equals(other.pages, _this.pages)&&const DeepCollectionEquality().equals(other.documents, _this.documents)&&(identical(other.refreshing, _this.refreshing) || other.refreshing == _this.refreshing));
}


@override
int get hashCode {
  final _this = this as AuthoringSessionState;
  return Object.hash(runtimeType,_this.sequence,const DeepCollectionEquality().hash(_this.books),const DeepCollectionEquality().hash(_this.tags),const DeepCollectionEquality().hash(_this.pages),const DeepCollectionEquality().hash(_this.documents),_this.refreshing);
}

@override
String toString() {
  final _this = this as AuthoringSessionState;
  return 'AuthoringSessionState(sequence: ${_this.sequence}, books: ${_this.books}, tags: ${_this.tags}, pages: ${_this.pages}, documents: ${_this.documents}, refreshing: ${_this.refreshing})';
}


}

/// @nodoc
abstract mixin class $AuthoringSessionStateCopyWith<$Res>  {
  factory $AuthoringSessionStateCopyWith(AuthoringSessionState value, $Res Function(AuthoringSessionState) _then) = _$AuthoringSessionStateCopyWithImpl;
@useResult
$Res call({
 int? sequence, Map<skir.RecordId, skir.Book> books, Map<skir.RecordId, skir.Tag> tags, Map<skir.RecordId, skir.Page> pages, Map<skir.RecordId, skir.PageDocument> documents, bool refreshing
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
  return _then(AuthoringSessionState(
sequence: freezed == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int?,books: null == books ? _self.books : books // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, skir.Book>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, skir.Tag>,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, skir.Page>,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, skir.PageDocument>,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? sequence,  Map<skir.RecordId, skir.Book> books,  Map<skir.RecordId, skir.Tag> tags,  Map<skir.RecordId, skir.Page> pages,  Map<skir.RecordId, skir.PageDocument> documents,  bool refreshing)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? sequence,  Map<skir.RecordId, skir.Book> books,  Map<skir.RecordId, skir.Tag> tags,  Map<skir.RecordId, skir.Page> pages,  Map<skir.RecordId, skir.PageDocument> documents,  bool refreshing)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? sequence,  Map<skir.RecordId, skir.Book> books,  Map<skir.RecordId, skir.Tag> tags,  Map<skir.RecordId, skir.Page> pages,  Map<skir.RecordId, skir.PageDocument> documents,  bool refreshing)?  $default,) {final _that = this;
switch (_that) {
case _AuthoringSessionState() when $default != null:
return $default(_that.sequence,_that.books,_that.tags,_that.pages,_that.documents,_that.refreshing);case _:
  return null;

}
}

}

/// @nodoc


class _AuthoringSessionState implements AuthoringSessionState {
  const _AuthoringSessionState({this.sequence,  Map<skir.RecordId, skir.Book> books = const {},  Map<skir.RecordId, skir.Tag> tags = const {},  Map<skir.RecordId, skir.Page> pages = const {},  Map<skir.RecordId, skir.PageDocument> documents = const {}, this.refreshing = false}): _books = books,_tags = tags,_pages = pages,_documents = documents;
  

/// The server sequence represented by all canonical collections.
@override final  int? sequence;
/// Canonical books retained by active scopes.
 final  Map<skir.RecordId, skir.Book> _books;
/// Canonical books retained by active scopes.
@override@JsonKey() Map<skir.RecordId, skir.Book> get books {
  if (_books is EqualUnmodifiableMapView) return _books;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_books);
}

/// Canonical tags retained by the library scope.
 final  Map<skir.RecordId, skir.Tag> _tags;
/// Canonical tags retained by the library scope.
@override@JsonKey() Map<skir.RecordId, skir.Tag> get tags {
  if (_tags is EqualUnmodifiableMapView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tags);
}

/// Canonical page metadata retained by active book or page scopes.
 final  Map<skir.RecordId, skir.Page> _pages;
/// Canonical page metadata retained by active book or page scopes.
@override@JsonKey() Map<skir.RecordId, skir.Page> get pages {
  if (_pages is EqualUnmodifiableMapView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pages);
}

/// Canonical page documents retained by active page scopes.
 final  Map<skir.RecordId, skir.PageDocument> _documents;
/// Canonical page documents retained by active page scopes.
@override@JsonKey() Map<skir.RecordId, skir.PageDocument> get documents {
  if (_documents is EqualUnmodifiableMapView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_documents);
}

/// Whether an authoritative refresh is currently reconciling the model.
@override@JsonKey() final  bool refreshing;

/// Create a copy of AuthoringSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthoringSessionStateCopyWith<_AuthoringSessionState> get copyWith => __$AuthoringSessionStateCopyWithImpl<_AuthoringSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSessionState&&(identical(other.sequence, sequence) || other.sequence == sequence)&&const DeepCollectionEquality().equals(other.books, _books)&&const DeepCollectionEquality().equals(other.tags, _tags)&&const DeepCollectionEquality().equals(other.pages, _pages)&&const DeepCollectionEquality().equals(other.documents, _documents)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sequence,const DeepCollectionEquality().hash(_books),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_pages),const DeepCollectionEquality().hash(_documents),refreshing);
}

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
 int? sequence, Map<skir.RecordId, skir.Book> books, Map<skir.RecordId, skir.Tag> tags, Map<skir.RecordId, skir.Page> pages, Map<skir.RecordId, skir.PageDocument> documents, bool refreshing
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
as Map<skir.RecordId, skir.Book>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, skir.Tag>,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, skir.Page>,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as Map<skir.RecordId, skir.PageDocument>,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
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
int get hashCode {
    return Object.hash(runtimeType,bookId);
}

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
int get hashCode {
    return Object.hash(runtimeType,pageId);
}

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
