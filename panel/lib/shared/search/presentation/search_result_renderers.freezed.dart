// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result_renderers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchResultRowContext {

 SearchResult get result; bool get selected; bool get focused; bool get loading; VoidCallback get onTap; ShortcutActivator? get shortcutActivator;
/// Create a copy of SearchResultRowContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultRowContextCopyWith<SearchResultRowContext> get copyWith => _$SearchResultRowContextCopyWithImpl<SearchResultRowContext>(this as SearchResultRowContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultRowContext&&(identical(other.result, result) || other.result == result)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.focused, focused) || other.focused == focused)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.onTap, onTap) || other.onTap == onTap)&&(identical(other.shortcutActivator, shortcutActivator) || other.shortcutActivator == shortcutActivator));
}


@override
int get hashCode => Object.hash(runtimeType,result,selected,focused,loading,onTap,shortcutActivator);

@override
String toString() {
  return 'SearchResultRowContext(result: $result, selected: $selected, focused: $focused, loading: $loading, onTap: $onTap, shortcutActivator: $shortcutActivator)';
}


}

/// @nodoc
abstract mixin class $SearchResultRowContextCopyWith<$Res>  {
  factory $SearchResultRowContextCopyWith(SearchResultRowContext value, $Res Function(SearchResultRowContext) _then) = _$SearchResultRowContextCopyWithImpl;
@useResult
$Res call({
 SearchResult result, bool selected, bool focused, bool loading, VoidCallback onTap, ShortcutActivator? shortcutActivator
});


$SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$SearchResultRowContextCopyWithImpl<$Res>
    implements $SearchResultRowContextCopyWith<$Res> {
  _$SearchResultRowContextCopyWithImpl(this._self, this._then);

  final SearchResultRowContext _self;
  final $Res Function(SearchResultRowContext) _then;

/// Create a copy of SearchResultRowContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? result = null,Object? selected = null,Object? focused = null,Object? loading = null,Object? onTap = null,Object? shortcutActivator = freezed,}) {
  return _then(_self.copyWith(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as bool,focused: null == focused ? _self.focused : focused // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,onTap: null == onTap ? _self.onTap : onTap // ignore: cast_nullable_to_non_nullable
as VoidCallback,shortcutActivator: freezed == shortcutActivator ? _self.shortcutActivator : shortcutActivator // ignore: cast_nullable_to_non_nullable
as ShortcutActivator?,
  ));
}
/// Create a copy of SearchResultRowContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResultRowContext].
extension SearchResultRowContextPatterns on SearchResultRowContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultRowContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultRowContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultRowContext value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultRowContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultRowContext value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultRowContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchResult result,  bool selected,  bool focused,  bool loading,  VoidCallback onTap,  ShortcutActivator? shortcutActivator)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultRowContext() when $default != null:
return $default(_that.result,_that.selected,_that.focused,_that.loading,_that.onTap,_that.shortcutActivator);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchResult result,  bool selected,  bool focused,  bool loading,  VoidCallback onTap,  ShortcutActivator? shortcutActivator)  $default,) {final _that = this;
switch (_that) {
case _SearchResultRowContext():
return $default(_that.result,_that.selected,_that.focused,_that.loading,_that.onTap,_that.shortcutActivator);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchResult result,  bool selected,  bool focused,  bool loading,  VoidCallback onTap,  ShortcutActivator? shortcutActivator)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultRowContext() when $default != null:
return $default(_that.result,_that.selected,_that.focused,_that.loading,_that.onTap,_that.shortcutActivator);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResultRowContext implements SearchResultRowContext {
  const _SearchResultRowContext({required this.result, required this.selected, required this.focused, required this.loading, required this.onTap, this.shortcutActivator});
  

@override final  SearchResult result;
@override final  bool selected;
@override final  bool focused;
@override final  bool loading;
@override final  VoidCallback onTap;
@override final  ShortcutActivator? shortcutActivator;

/// Create a copy of SearchResultRowContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultRowContextCopyWith<_SearchResultRowContext> get copyWith => __$SearchResultRowContextCopyWithImpl<_SearchResultRowContext>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultRowContext&&(identical(other.result, result) || other.result == result)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.focused, focused) || other.focused == focused)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.onTap, onTap) || other.onTap == onTap)&&(identical(other.shortcutActivator, shortcutActivator) || other.shortcutActivator == shortcutActivator));
}


@override
int get hashCode => Object.hash(runtimeType,result,selected,focused,loading,onTap,shortcutActivator);

@override
String toString() {
  return 'SearchResultRowContext(result: $result, selected: $selected, focused: $focused, loading: $loading, onTap: $onTap, shortcutActivator: $shortcutActivator)';
}


}

/// @nodoc
abstract mixin class _$SearchResultRowContextCopyWith<$Res> implements $SearchResultRowContextCopyWith<$Res> {
  factory _$SearchResultRowContextCopyWith(_SearchResultRowContext value, $Res Function(_SearchResultRowContext) _then) = __$SearchResultRowContextCopyWithImpl;
@override @useResult
$Res call({
 SearchResult result, bool selected, bool focused, bool loading, VoidCallback onTap, ShortcutActivator? shortcutActivator
});


@override $SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class __$SearchResultRowContextCopyWithImpl<$Res>
    implements _$SearchResultRowContextCopyWith<$Res> {
  __$SearchResultRowContextCopyWithImpl(this._self, this._then);

  final _SearchResultRowContext _self;
  final $Res Function(_SearchResultRowContext) _then;

/// Create a copy of SearchResultRowContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? result = null,Object? selected = null,Object? focused = null,Object? loading = null,Object? onTap = null,Object? shortcutActivator = freezed,}) {
  return _then(_SearchResultRowContext(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as bool,focused: null == focused ? _self.focused : focused // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,onTap: null == onTap ? _self.onTap : onTap // ignore: cast_nullable_to_non_nullable
as VoidCallback,shortcutActivator: freezed == shortcutActivator ? _self.shortcutActivator : shortcutActivator // ignore: cast_nullable_to_non_nullable
as ShortcutActivator?,
  ));
}

/// Create a copy of SearchResultRowContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc
mixin _$SearchResultPreviewContext {

 SearchResult get result;
/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultPreviewContextCopyWith<SearchResultPreviewContext> get copyWith => _$SearchResultPreviewContextCopyWithImpl<SearchResultPreviewContext>(this as SearchResultPreviewContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultPreviewContext&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'SearchResultPreviewContext(result: $result)';
}


}

/// @nodoc
abstract mixin class $SearchResultPreviewContextCopyWith<$Res>  {
  factory $SearchResultPreviewContextCopyWith(SearchResultPreviewContext value, $Res Function(SearchResultPreviewContext) _then) = _$SearchResultPreviewContextCopyWithImpl;
@useResult
$Res call({
 SearchResult result
});


$SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$SearchResultPreviewContextCopyWithImpl<$Res>
    implements $SearchResultPreviewContextCopyWith<$Res> {
  _$SearchResultPreviewContextCopyWithImpl(this._self, this._then);

  final SearchResultPreviewContext _self;
  final $Res Function(SearchResultPreviewContext) _then;

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? result = null,}) {
  return _then(_self.copyWith(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,
  ));
}
/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResultPreviewContext].
extension SearchResultPreviewContextPatterns on SearchResultPreviewContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchResultPreviewContextLoading value)?  loading,TResult Function( SearchResultPreviewContextData value)?  data,TResult Function( SearchResultPreviewContextError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchResultPreviewContextLoading() when loading != null:
return loading(_that);case SearchResultPreviewContextData() when data != null:
return data(_that);case SearchResultPreviewContextError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchResultPreviewContextLoading value)  loading,required TResult Function( SearchResultPreviewContextData value)  data,required TResult Function( SearchResultPreviewContextError value)  error,}){
final _that = this;
switch (_that) {
case SearchResultPreviewContextLoading():
return loading(_that);case SearchResultPreviewContextData():
return data(_that);case SearchResultPreviewContextError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchResultPreviewContextLoading value)?  loading,TResult? Function( SearchResultPreviewContextData value)?  data,TResult? Function( SearchResultPreviewContextError value)?  error,}){
final _that = this;
switch (_that) {
case SearchResultPreviewContextLoading() when loading != null:
return loading(_that);case SearchResultPreviewContextData() when data != null:
return data(_that);case SearchResultPreviewContextError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SearchResult result)?  loading,TResult Function( SearchResult result,  Object data)?  data,TResult Function( SearchResult result,  String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchResultPreviewContextLoading() when loading != null:
return loading(_that.result);case SearchResultPreviewContextData() when data != null:
return data(_that.result,_that.data);case SearchResultPreviewContextError() when error != null:
return error(_that.result,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SearchResult result)  loading,required TResult Function( SearchResult result,  Object data)  data,required TResult Function( SearchResult result,  String message)  error,}) {final _that = this;
switch (_that) {
case SearchResultPreviewContextLoading():
return loading(_that.result);case SearchResultPreviewContextData():
return data(_that.result,_that.data);case SearchResultPreviewContextError():
return error(_that.result,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SearchResult result)?  loading,TResult? Function( SearchResult result,  Object data)?  data,TResult? Function( SearchResult result,  String message)?  error,}) {final _that = this;
switch (_that) {
case SearchResultPreviewContextLoading() when loading != null:
return loading(_that.result);case SearchResultPreviewContextData() when data != null:
return data(_that.result,_that.data);case SearchResultPreviewContextError() when error != null:
return error(_that.result,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SearchResultPreviewContextLoading implements SearchResultPreviewContext {
  const SearchResultPreviewContextLoading({required this.result});
  

@override final  SearchResult result;

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultPreviewContextLoadingCopyWith<SearchResultPreviewContextLoading> get copyWith => _$SearchResultPreviewContextLoadingCopyWithImpl<SearchResultPreviewContextLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultPreviewContextLoading&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'SearchResultPreviewContext.loading(result: $result)';
}


}

/// @nodoc
abstract mixin class $SearchResultPreviewContextLoadingCopyWith<$Res> implements $SearchResultPreviewContextCopyWith<$Res> {
  factory $SearchResultPreviewContextLoadingCopyWith(SearchResultPreviewContextLoading value, $Res Function(SearchResultPreviewContextLoading) _then) = _$SearchResultPreviewContextLoadingCopyWithImpl;
@override @useResult
$Res call({
 SearchResult result
});


@override $SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$SearchResultPreviewContextLoadingCopyWithImpl<$Res>
    implements $SearchResultPreviewContextLoadingCopyWith<$Res> {
  _$SearchResultPreviewContextLoadingCopyWithImpl(this._self, this._then);

  final SearchResultPreviewContextLoading _self;
  final $Res Function(SearchResultPreviewContextLoading) _then;

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(SearchResultPreviewContextLoading(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,
  ));
}

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class SearchResultPreviewContextData implements SearchResultPreviewContext {
  const SearchResultPreviewContextData({required this.result, required this.data});
  

@override final  SearchResult result;
 final  Object data;

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultPreviewContextDataCopyWith<SearchResultPreviewContextData> get copyWith => _$SearchResultPreviewContextDataCopyWithImpl<SearchResultPreviewContextData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultPreviewContextData&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,result,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'SearchResultPreviewContext.data(result: $result, data: $data)';
}


}

/// @nodoc
abstract mixin class $SearchResultPreviewContextDataCopyWith<$Res> implements $SearchResultPreviewContextCopyWith<$Res> {
  factory $SearchResultPreviewContextDataCopyWith(SearchResultPreviewContextData value, $Res Function(SearchResultPreviewContextData) _then) = _$SearchResultPreviewContextDataCopyWithImpl;
@override @useResult
$Res call({
 SearchResult result, Object data
});


@override $SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$SearchResultPreviewContextDataCopyWithImpl<$Res>
    implements $SearchResultPreviewContextDataCopyWith<$Res> {
  _$SearchResultPreviewContextDataCopyWithImpl(this._self, this._then);

  final SearchResultPreviewContextData _self;
  final $Res Function(SearchResultPreviewContextData) _then;

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? result = null,Object? data = null,}) {
  return _then(SearchResultPreviewContextData(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,data: null == data ? _self.data : data ,
  ));
}

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class SearchResultPreviewContextError implements SearchResultPreviewContext {
  const SearchResultPreviewContextError({required this.result, required this.message});
  

@override final  SearchResult result;
 final  String message;

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultPreviewContextErrorCopyWith<SearchResultPreviewContextError> get copyWith => _$SearchResultPreviewContextErrorCopyWithImpl<SearchResultPreviewContextError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultPreviewContextError&&(identical(other.result, result) || other.result == result)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,result,message);

@override
String toString() {
  return 'SearchResultPreviewContext.error(result: $result, message: $message)';
}


}

/// @nodoc
abstract mixin class $SearchResultPreviewContextErrorCopyWith<$Res> implements $SearchResultPreviewContextCopyWith<$Res> {
  factory $SearchResultPreviewContextErrorCopyWith(SearchResultPreviewContextError value, $Res Function(SearchResultPreviewContextError) _then) = _$SearchResultPreviewContextErrorCopyWithImpl;
@override @useResult
$Res call({
 SearchResult result, String message
});


@override $SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$SearchResultPreviewContextErrorCopyWithImpl<$Res>
    implements $SearchResultPreviewContextErrorCopyWith<$Res> {
  _$SearchResultPreviewContextErrorCopyWithImpl(this._self, this._then);

  final SearchResultPreviewContextError _self;
  final $Res Function(SearchResultPreviewContextError) _then;

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? result = null,Object? message = null,}) {
  return _then(SearchResultPreviewContextError(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SearchResultPreviewContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {
  
  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
