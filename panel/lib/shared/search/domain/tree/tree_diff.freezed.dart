// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tree_diff.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchTreeDiff {

 List<SearchTreeRemoval> get removals; List<SearchTreeInsertion> get insertions;
/// Create a copy of SearchTreeDiff
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeDiffCopyWith<SearchTreeDiff> get copyWith => _$SearchTreeDiffCopyWithImpl<SearchTreeDiff>(this as SearchTreeDiff, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchTreeDiff;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeDiff&&const DeepCollectionEquality().equals(other.removals, _this.removals)&&const DeepCollectionEquality().equals(other.insertions, _this.insertions));
}


@override
int get hashCode {
  final _this = this as SearchTreeDiff;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.removals),const DeepCollectionEquality().hash(_this.insertions));
}

@override
String toString() {
  final _this = this as SearchTreeDiff;
  return 'SearchTreeDiff(removals: ${_this.removals}, insertions: ${_this.insertions})';
}


}

/// @nodoc
abstract mixin class $SearchTreeDiffCopyWith<$Res>  {
  factory $SearchTreeDiffCopyWith(SearchTreeDiff value, $Res Function(SearchTreeDiff) _then) = _$SearchTreeDiffCopyWithImpl;
@useResult
$Res call({
 List<SearchTreeRemoval> removals, List<SearchTreeInsertion> insertions
});




}
/// @nodoc
class _$SearchTreeDiffCopyWithImpl<$Res>
    implements $SearchTreeDiffCopyWith<$Res> {
  _$SearchTreeDiffCopyWithImpl(this._self, this._then);

  final SearchTreeDiff _self;
  final $Res Function(SearchTreeDiff) _then;

/// Create a copy of SearchTreeDiff
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? removals = null,Object? insertions = null,}) {
  return _then(SearchTreeDiff(
removals: null == removals ? _self.removals : removals // ignore: cast_nullable_to_non_nullable
as List<SearchTreeRemoval>,insertions: null == insertions ? _self.insertions : insertions // ignore: cast_nullable_to_non_nullable
as List<SearchTreeInsertion>,
  ));
}

}


/// Adds pattern matching related methods to [SearchTreeDiff].
extension SearchTreeDiffPatterns on SearchTreeDiff {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchTreeDiff value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchTreeDiff() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchTreeDiff value)  $default,){
final _that = this;
switch (_that) {
case _SearchTreeDiff():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchTreeDiff value)?  $default,){
final _that = this;
switch (_that) {
case _SearchTreeDiff() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchTreeRemoval> removals,  List<SearchTreeInsertion> insertions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchTreeDiff() when $default != null:
return $default(_that.removals,_that.insertions);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchTreeRemoval> removals,  List<SearchTreeInsertion> insertions)  $default,) {final _that = this;
switch (_that) {
case _SearchTreeDiff():
return $default(_that.removals,_that.insertions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchTreeRemoval> removals,  List<SearchTreeInsertion> insertions)?  $default,) {final _that = this;
switch (_that) {
case _SearchTreeDiff() when $default != null:
return $default(_that.removals,_that.insertions);case _:
  return null;

}
}

}

/// @nodoc


class _SearchTreeDiff implements SearchTreeDiff {
  const _SearchTreeDiff({required  List<SearchTreeRemoval> removals, required  List<SearchTreeInsertion> insertions}): _removals = removals,_insertions = insertions;


 final  List<SearchTreeRemoval> _removals;
@override List<SearchTreeRemoval> get removals {
  if (_removals is EqualUnmodifiableListView) return _removals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_removals);
}

 final  List<SearchTreeInsertion> _insertions;
@override List<SearchTreeInsertion> get insertions {
  if (_insertions is EqualUnmodifiableListView) return _insertions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_insertions);
}


/// Create a copy of SearchTreeDiff
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTreeDiffCopyWith<_SearchTreeDiff> get copyWith => __$SearchTreeDiffCopyWithImpl<_SearchTreeDiff>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTreeDiff&&const DeepCollectionEquality().equals(other.removals, _removals)&&const DeepCollectionEquality().equals(other.insertions, _insertions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_removals),const DeepCollectionEquality().hash(_insertions));
}

@override
String toString() {
    return 'SearchTreeDiff(removals: $removals, insertions: $insertions)';
}


}

/// @nodoc
abstract mixin class _$SearchTreeDiffCopyWith<$Res> implements $SearchTreeDiffCopyWith<$Res> {
  factory _$SearchTreeDiffCopyWith(_SearchTreeDiff value, $Res Function(_SearchTreeDiff) _then) = __$SearchTreeDiffCopyWithImpl;
@override @useResult
$Res call({
 List<SearchTreeRemoval> removals, List<SearchTreeInsertion> insertions
});




}
/// @nodoc
class __$SearchTreeDiffCopyWithImpl<$Res>
    implements _$SearchTreeDiffCopyWith<$Res> {
  __$SearchTreeDiffCopyWithImpl(this._self, this._then);

  final _SearchTreeDiff _self;
  final $Res Function(_SearchTreeDiff) _then;

/// Create a copy of SearchTreeDiff
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? removals = null,Object? insertions = null,}) {
  return _then(_SearchTreeDiff(
removals: null == removals ? _self._removals : removals // ignore: cast_nullable_to_non_nullable
as List<SearchTreeRemoval>,insertions: null == insertions ? _self._insertions : insertions // ignore: cast_nullable_to_non_nullable
as List<SearchTreeInsertion>,
  ));
}


}

/// @nodoc
mixin _$SearchTreeRemoval {

 int get index; SearchTreeRow get row;
/// Create a copy of SearchTreeRemoval
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeRemovalCopyWith<SearchTreeRemoval> get copyWith => _$SearchTreeRemovalCopyWithImpl<SearchTreeRemoval>(this as SearchTreeRemoval, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchTreeRemoval;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeRemoval&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.row, _this.row) || other.row == _this.row));
}


@override
int get hashCode {
  final _this = this as SearchTreeRemoval;
  return Object.hash(runtimeType,_this.index,_this.row);
}

@override
String toString() {
  final _this = this as SearchTreeRemoval;
  return 'SearchTreeRemoval(index: ${_this.index}, row: ${_this.row})';
}


}

/// @nodoc
abstract mixin class $SearchTreeRemovalCopyWith<$Res>  {
  factory $SearchTreeRemovalCopyWith(SearchTreeRemoval value, $Res Function(SearchTreeRemoval) _then) = _$SearchTreeRemovalCopyWithImpl;
@useResult
$Res call({
 int index, SearchTreeRow row
});


$SearchTreeRowCopyWith<$Res> get row;

}
/// @nodoc
class _$SearchTreeRemovalCopyWithImpl<$Res>
    implements $SearchTreeRemovalCopyWith<$Res> {
  _$SearchTreeRemovalCopyWithImpl(this._self, this._then);

  final SearchTreeRemoval _self;
  final $Res Function(SearchTreeRemoval) _then;

/// Create a copy of SearchTreeRemoval
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? row = null,}) {
  return _then(SearchTreeRemoval(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as SearchTreeRow,
  ));
}
/// Create a copy of SearchTreeRemoval
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchTreeRowCopyWith<$Res> get row {

  return $SearchTreeRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}
}


/// Adds pattern matching related methods to [SearchTreeRemoval].
extension SearchTreeRemovalPatterns on SearchTreeRemoval {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchTreeRemoval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchTreeRemoval() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchTreeRemoval value)  $default,){
final _that = this;
switch (_that) {
case _SearchTreeRemoval():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchTreeRemoval value)?  $default,){
final _that = this;
switch (_that) {
case _SearchTreeRemoval() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  SearchTreeRow row)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchTreeRemoval() when $default != null:
return $default(_that.index,_that.row);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  SearchTreeRow row)  $default,) {final _that = this;
switch (_that) {
case _SearchTreeRemoval():
return $default(_that.index,_that.row);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  SearchTreeRow row)?  $default,) {final _that = this;
switch (_that) {
case _SearchTreeRemoval() when $default != null:
return $default(_that.index,_that.row);case _:
  return null;

}
}

}

/// @nodoc


class _SearchTreeRemoval implements SearchTreeRemoval {
  const _SearchTreeRemoval({required this.index, required this.row});


@override final  int index;
@override final  SearchTreeRow row;

/// Create a copy of SearchTreeRemoval
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTreeRemovalCopyWith<_SearchTreeRemoval> get copyWith => __$SearchTreeRemovalCopyWithImpl<_SearchTreeRemoval>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTreeRemoval&&(identical(other.index, index) || other.index == index)&&(identical(other.row, row) || other.row == row));
}


@override
int get hashCode {
    return Object.hash(runtimeType,index,row);
}

@override
String toString() {
    return 'SearchTreeRemoval(index: $index, row: $row)';
}


}

/// @nodoc
abstract mixin class _$SearchTreeRemovalCopyWith<$Res> implements $SearchTreeRemovalCopyWith<$Res> {
  factory _$SearchTreeRemovalCopyWith(_SearchTreeRemoval value, $Res Function(_SearchTreeRemoval) _then) = __$SearchTreeRemovalCopyWithImpl;
@override @useResult
$Res call({
 int index, SearchTreeRow row
});


@override $SearchTreeRowCopyWith<$Res> get row;

}
/// @nodoc
class __$SearchTreeRemovalCopyWithImpl<$Res>
    implements _$SearchTreeRemovalCopyWith<$Res> {
  __$SearchTreeRemovalCopyWithImpl(this._self, this._then);

  final _SearchTreeRemoval _self;
  final $Res Function(_SearchTreeRemoval) _then;

/// Create a copy of SearchTreeRemoval
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? row = null,}) {
  return _then(_SearchTreeRemoval(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as SearchTreeRow,
  ));
}

/// Create a copy of SearchTreeRemoval
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchTreeRowCopyWith<$Res> get row {

  return $SearchTreeRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}
}

/// @nodoc
mixin _$SearchTreeInsertion {

 int get index; SearchTreeRow get row;
/// Create a copy of SearchTreeInsertion
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeInsertionCopyWith<SearchTreeInsertion> get copyWith => _$SearchTreeInsertionCopyWithImpl<SearchTreeInsertion>(this as SearchTreeInsertion, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchTreeInsertion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeInsertion&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.row, _this.row) || other.row == _this.row));
}


@override
int get hashCode {
  final _this = this as SearchTreeInsertion;
  return Object.hash(runtimeType,_this.index,_this.row);
}

@override
String toString() {
  final _this = this as SearchTreeInsertion;
  return 'SearchTreeInsertion(index: ${_this.index}, row: ${_this.row})';
}


}

/// @nodoc
abstract mixin class $SearchTreeInsertionCopyWith<$Res>  {
  factory $SearchTreeInsertionCopyWith(SearchTreeInsertion value, $Res Function(SearchTreeInsertion) _then) = _$SearchTreeInsertionCopyWithImpl;
@useResult
$Res call({
 int index, SearchTreeRow row
});


$SearchTreeRowCopyWith<$Res> get row;

}
/// @nodoc
class _$SearchTreeInsertionCopyWithImpl<$Res>
    implements $SearchTreeInsertionCopyWith<$Res> {
  _$SearchTreeInsertionCopyWithImpl(this._self, this._then);

  final SearchTreeInsertion _self;
  final $Res Function(SearchTreeInsertion) _then;

/// Create a copy of SearchTreeInsertion
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? row = null,}) {
  return _then(SearchTreeInsertion(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as SearchTreeRow,
  ));
}
/// Create a copy of SearchTreeInsertion
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchTreeRowCopyWith<$Res> get row {

  return $SearchTreeRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}
}


/// Adds pattern matching related methods to [SearchTreeInsertion].
extension SearchTreeInsertionPatterns on SearchTreeInsertion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchTreeInsertion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchTreeInsertion() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchTreeInsertion value)  $default,){
final _that = this;
switch (_that) {
case _SearchTreeInsertion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchTreeInsertion value)?  $default,){
final _that = this;
switch (_that) {
case _SearchTreeInsertion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  SearchTreeRow row)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchTreeInsertion() when $default != null:
return $default(_that.index,_that.row);case _:
  return orElse();

}
}
/// A method similar to a `switch`, using callbacks.
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  SearchTreeRow row)  $default,) {final _that = this;
switch (_that) {
case _SearchTreeInsertion():
return $default(_that.index,_that.row);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  SearchTreeRow row)?  $default,) {final _that = this;
switch (_that) {
case _SearchTreeInsertion() when $default != null:
return $default(_that.index,_that.row);case _:
  return null;

}
}

}

/// @nodoc


class _SearchTreeInsertion implements SearchTreeInsertion {
  const _SearchTreeInsertion({required this.index, required this.row});


@override final  int index;
@override final  SearchTreeRow row;

/// Create a copy of SearchTreeInsertion
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTreeInsertionCopyWith<_SearchTreeInsertion> get copyWith => __$SearchTreeInsertionCopyWithImpl<_SearchTreeInsertion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTreeInsertion&&(identical(other.index, index) || other.index == index)&&(identical(other.row, row) || other.row == row));
}


@override
int get hashCode {
    return Object.hash(runtimeType,index,row);
}

@override
String toString() {
    return 'SearchTreeInsertion(index: $index, row: $row)';
}


}

/// @nodoc
abstract mixin class _$SearchTreeInsertionCopyWith<$Res> implements $SearchTreeInsertionCopyWith<$Res> {
  factory _$SearchTreeInsertionCopyWith(_SearchTreeInsertion value, $Res Function(_SearchTreeInsertion) _then) = __$SearchTreeInsertionCopyWithImpl;
@override @useResult
$Res call({
 int index, SearchTreeRow row
});


@override $SearchTreeRowCopyWith<$Res> get row;

}
/// @nodoc
class __$SearchTreeInsertionCopyWithImpl<$Res>
    implements _$SearchTreeInsertionCopyWith<$Res> {
  __$SearchTreeInsertionCopyWithImpl(this._self, this._then);

  final _SearchTreeInsertion _self;
  final $Res Function(_SearchTreeInsertion) _then;

/// Create a copy of SearchTreeInsertion
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? row = null,}) {
  return _then(_SearchTreeInsertion(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as SearchTreeRow,
  ));
}

/// Create a copy of SearchTreeInsertion
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchTreeRowCopyWith<$Res> get row {

  return $SearchTreeRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}
}

// dart format on
