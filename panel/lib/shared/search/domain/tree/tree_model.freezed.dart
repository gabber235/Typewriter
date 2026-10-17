// GENERATED CODE. DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tree_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchTreeRow {

 String get key; int get depth;
/// Create a copy of SearchTreeRow
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeRowCopyWith<SearchTreeRow> get copyWith => _$SearchTreeRowCopyWithImpl<SearchTreeRow>(this as SearchTreeRow, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchTreeRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeRow&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.depth, _this.depth) || other.depth == _this.depth));
}


@override
int get hashCode {
  final _this = this as SearchTreeRow;
  return Object.hash(runtimeType,_this.key,_this.depth);
}

@override
String toString() {
  final _this = this as SearchTreeRow;
  return 'SearchTreeRow(key: ${_this.key}, depth: ${_this.depth})';
}


}

/// @nodoc
abstract mixin class $SearchTreeRowCopyWith<$Res>  {
  factory $SearchTreeRowCopyWith(SearchTreeRow value, $Res Function(SearchTreeRow) _then) = _$SearchTreeRowCopyWithImpl;
@useResult
$Res call({
 String key, int depth
});




}
/// @nodoc
class _$SearchTreeRowCopyWithImpl<$Res>
    implements $SearchTreeRowCopyWith<$Res> {
  _$SearchTreeRowCopyWithImpl(this._self, this._then);

  final SearchTreeRow _self;
  final $Res Function(SearchTreeRow) _then;

/// Create a copy of SearchTreeRow
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? depth = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern matching related methods to [SearchTreeRow].
extension SearchTreeRowPatterns on SearchTreeRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchTreeSectionRow value)?  section,TResult Function( SearchTreeResultRow value)?  result,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchTreeSectionRow() when section != null:
return section(_that);case SearchTreeResultRow() when result != null:
return result(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchTreeSectionRow value)  section,required TResult Function( SearchTreeResultRow value)  result,}){
final _that = this;
switch (_that) {
case SearchTreeSectionRow():
return section(_that);case SearchTreeResultRow():
return result(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchTreeSectionRow value)?  section,TResult? Function( SearchTreeResultRow value)?  result,}){
final _that = this;
switch (_that) {
case SearchTreeSectionRow() when section != null:
return section(_that);case SearchTreeResultRow() when result != null:
return result(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String key,  int depth,  String id,  String title,  String? subtitle,  bool expanded,  int resultCount,  bool topLevel)?  section,TResult Function( String key,  int depth,  SearchResult result,  int? shortcutNumber)?  result,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchTreeSectionRow() when section != null:
return section(_that.key,_that.depth,_that.id,_that.title,_that.subtitle,_that.expanded,_that.resultCount,_that.topLevel);case SearchTreeResultRow() when result != null:
return result(_that.key,_that.depth,_that.result,_that.shortcutNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String key,  int depth,  String id,  String title,  String? subtitle,  bool expanded,  int resultCount,  bool topLevel)  section,required TResult Function( String key,  int depth,  SearchResult result,  int? shortcutNumber)  result,}) {final _that = this;
switch (_that) {
case SearchTreeSectionRow():
return section(_that.key,_that.depth,_that.id,_that.title,_that.subtitle,_that.expanded,_that.resultCount,_that.topLevel);case SearchTreeResultRow():
return result(_that.key,_that.depth,_that.result,_that.shortcutNumber);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String key,  int depth,  String id,  String title,  String? subtitle,  bool expanded,  int resultCount,  bool topLevel)?  section,TResult? Function( String key,  int depth,  SearchResult result,  int? shortcutNumber)?  result,}) {final _that = this;
switch (_that) {
case SearchTreeSectionRow() when section != null:
return section(_that.key,_that.depth,_that.id,_that.title,_that.subtitle,_that.expanded,_that.resultCount,_that.topLevel);case SearchTreeResultRow() when result != null:
return result(_that.key,_that.depth,_that.result,_that.shortcutNumber);case _:
  return null;

}
}

}

/// @nodoc


class SearchTreeSectionRow implements SearchTreeRow {
  const SearchTreeSectionRow({required this.key, required this.depth, required this.id, required this.title, required this.subtitle, required this.expanded, required this.resultCount, required this.topLevel});


@override final  String key;
@override final  int depth;
 final  String id;
 final  String title;
 final  String? subtitle;
 final  bool expanded;
 final  int resultCount;
 final  bool topLevel;

/// Create a copy of SearchTreeRow
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeSectionRowCopyWith<SearchTreeSectionRow> get copyWith => _$SearchTreeSectionRowCopyWithImpl<SearchTreeSectionRow>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeSectionRow&&(identical(other.key, key) || other.key == key)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.expanded, expanded) || other.expanded == expanded)&&(identical(other.resultCount, resultCount) || other.resultCount == resultCount)&&(identical(other.topLevel, topLevel) || other.topLevel == topLevel));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,depth,id,title,subtitle,expanded,resultCount,topLevel);
}

@override
String toString() {
    return 'SearchTreeRow.section(key: $key, depth: $depth, id: $id, title: $title, subtitle: $subtitle, expanded: $expanded, resultCount: $resultCount, topLevel: $topLevel)';
}


}

/// @nodoc
abstract mixin class $SearchTreeSectionRowCopyWith<$Res> implements $SearchTreeRowCopyWith<$Res> {
  factory $SearchTreeSectionRowCopyWith(SearchTreeSectionRow value, $Res Function(SearchTreeSectionRow) _then) = _$SearchTreeSectionRowCopyWithImpl;
@override @useResult
$Res call({
 String key, int depth, String id, String title, String? subtitle, bool expanded, int resultCount, bool topLevel
});




}
/// @nodoc
class _$SearchTreeSectionRowCopyWithImpl<$Res>
    implements $SearchTreeSectionRowCopyWith<$Res> {
  _$SearchTreeSectionRowCopyWithImpl(this._self, this._then);

  final SearchTreeSectionRow _self;
  final $Res Function(SearchTreeSectionRow) _then;

/// Create a copy of SearchTreeRow
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? depth = null,Object? id = null,Object? title = null,Object? subtitle = freezed,Object? expanded = null,Object? resultCount = null,Object? topLevel = null,}) {
  return _then(SearchTreeSectionRow(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,expanded: null == expanded ? _self.expanded : expanded // ignore: cast_nullable_to_non_nullable
as bool,resultCount: null == resultCount ? _self.resultCount : resultCount // ignore: cast_nullable_to_non_nullable
as int,topLevel: null == topLevel ? _self.topLevel : topLevel // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class SearchTreeResultRow implements SearchTreeRow {
  const SearchTreeResultRow({required this.key, required this.depth, required this.result, required this.shortcutNumber});


@override final  String key;
@override final  int depth;
 final  SearchResult result;
 final  int? shortcutNumber;

/// Create a copy of SearchTreeRow
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeResultRowCopyWith<SearchTreeResultRow> get copyWith => _$SearchTreeResultRowCopyWithImpl<SearchTreeResultRow>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeResultRow&&(identical(other.key, key) || other.key == key)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.result, result) || other.result == result)&&(identical(other.shortcutNumber, shortcutNumber) || other.shortcutNumber == shortcutNumber));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,depth,result,shortcutNumber);
}

@override
String toString() {
    return 'SearchTreeRow.result(key: $key, depth: $depth, result: $result, shortcutNumber: $shortcutNumber)';
}


}

/// @nodoc
abstract mixin class $SearchTreeResultRowCopyWith<$Res> implements $SearchTreeRowCopyWith<$Res> {
  factory $SearchTreeResultRowCopyWith(SearchTreeResultRow value, $Res Function(SearchTreeResultRow) _then) = _$SearchTreeResultRowCopyWithImpl;
@override @useResult
$Res call({
 String key, int depth, SearchResult result, int? shortcutNumber
});


$SearchResultCopyWith<$Res> get result;

}
/// @nodoc
class _$SearchTreeResultRowCopyWithImpl<$Res>
    implements $SearchTreeResultRowCopyWith<$Res> {
  _$SearchTreeResultRowCopyWithImpl(this._self, this._then);

  final SearchTreeResultRow _self;
  final $Res Function(SearchTreeResultRow) _then;

/// Create a copy of SearchTreeRow
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? depth = null,Object? result = null,Object? shortcutNumber = freezed,}) {
  return _then(SearchTreeResultRow(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as int,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as SearchResult,shortcutNumber: freezed == shortcutNumber ? _self.shortcutNumber : shortcutNumber // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of SearchTreeRow
/// with the given fields replaced by the non null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get result {

  return $SearchResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc
mixin _$SearchTreeTopLevelGroup {

 SearchTreeSectionRow? get section; List<SearchTreeRow> get rows;
/// Create a copy of SearchTreeTopLevelGroup
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeTopLevelGroupCopyWith<SearchTreeTopLevelGroup> get copyWith => _$SearchTreeTopLevelGroupCopyWithImpl<SearchTreeTopLevelGroup>(this as SearchTreeTopLevelGroup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchTreeTopLevelGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeTopLevelGroup&&const DeepCollectionEquality().equals(other.section, _this.section)&&const DeepCollectionEquality().equals(other.rows, _this.rows));
}


@override
int get hashCode {
  final _this = this as SearchTreeTopLevelGroup;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.section),const DeepCollectionEquality().hash(_this.rows));
}

@override
String toString() {
  final _this = this as SearchTreeTopLevelGroup;
  return 'SearchTreeTopLevelGroup(section: ${_this.section}, rows: ${_this.rows})';
}


}

/// @nodoc
abstract mixin class $SearchTreeTopLevelGroupCopyWith<$Res>  {
  factory $SearchTreeTopLevelGroupCopyWith(SearchTreeTopLevelGroup value, $Res Function(SearchTreeTopLevelGroup) _then) = _$SearchTreeTopLevelGroupCopyWithImpl;
@useResult
$Res call({
 SearchTreeSectionRow? section, List<SearchTreeRow> rows
});




}
/// @nodoc
class _$SearchTreeTopLevelGroupCopyWithImpl<$Res>
    implements $SearchTreeTopLevelGroupCopyWith<$Res> {
  _$SearchTreeTopLevelGroupCopyWithImpl(this._self, this._then);

  final SearchTreeTopLevelGroup _self;
  final $Res Function(SearchTreeTopLevelGroup) _then;

/// Create a copy of SearchTreeTopLevelGroup
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? section = freezed,Object? rows = null,}) {
  return _then(SearchTreeTopLevelGroup(
section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as SearchTreeSectionRow?,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<SearchTreeRow>,
  ));
}

}


/// Adds pattern matching related methods to [SearchTreeTopLevelGroup].
extension SearchTreeTopLevelGroupPatterns on SearchTreeTopLevelGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchTreeTopLevelGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchTreeTopLevelGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchTreeTopLevelGroup value)  $default,){
final _that = this;
switch (_that) {
case _SearchTreeTopLevelGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchTreeTopLevelGroup value)?  $default,){
final _that = this;
switch (_that) {
case _SearchTreeTopLevelGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchTreeSectionRow? section,  List<SearchTreeRow> rows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchTreeTopLevelGroup() when $default != null:
return $default(_that.section,_that.rows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchTreeSectionRow? section,  List<SearchTreeRow> rows)  $default,) {final _that = this;
switch (_that) {
case _SearchTreeTopLevelGroup():
return $default(_that.section,_that.rows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchTreeSectionRow? section,  List<SearchTreeRow> rows)?  $default,) {final _that = this;
switch (_that) {
case _SearchTreeTopLevelGroup() when $default != null:
return $default(_that.section,_that.rows);case _:
  return null;

}
}

}

/// @nodoc


class _SearchTreeTopLevelGroup implements SearchTreeTopLevelGroup {
  const _SearchTreeTopLevelGroup({required this.section, required  List<SearchTreeRow> rows}): _rows = rows;


@override final  SearchTreeSectionRow? section;
 final  List<SearchTreeRow> _rows;
@override List<SearchTreeRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}


/// Create a copy of SearchTreeTopLevelGroup
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTreeTopLevelGroupCopyWith<_SearchTreeTopLevelGroup> get copyWith => __$SearchTreeTopLevelGroupCopyWithImpl<_SearchTreeTopLevelGroup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTreeTopLevelGroup&&const DeepCollectionEquality().equals(other.section, section)&&const DeepCollectionEquality().equals(other.rows, _rows));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(section),const DeepCollectionEquality().hash(_rows));
}

@override
String toString() {
    return 'SearchTreeTopLevelGroup(section: $section, rows: $rows)';
}


}

/// @nodoc
abstract mixin class _$SearchTreeTopLevelGroupCopyWith<$Res> implements $SearchTreeTopLevelGroupCopyWith<$Res> {
  factory _$SearchTreeTopLevelGroupCopyWith(_SearchTreeTopLevelGroup value, $Res Function(_SearchTreeTopLevelGroup) _then) = __$SearchTreeTopLevelGroupCopyWithImpl;
@override @useResult
$Res call({
 SearchTreeSectionRow? section, List<SearchTreeRow> rows
});




}
/// @nodoc
class __$SearchTreeTopLevelGroupCopyWithImpl<$Res>
    implements _$SearchTreeTopLevelGroupCopyWith<$Res> {
  __$SearchTreeTopLevelGroupCopyWithImpl(this._self, this._then);

  final _SearchTreeTopLevelGroup _self;
  final $Res Function(_SearchTreeTopLevelGroup) _then;

/// Create a copy of SearchTreeTopLevelGroup
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? section = freezed,Object? rows = null,}) {
  return _then(_SearchTreeTopLevelGroup(
section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as SearchTreeSectionRow?,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<SearchTreeRow>,
  ));
}


}

/// @nodoc
mixin _$SearchTreeViewModel {

 List<SearchTreeTopLevelGroup> get groups; int get rowCount;
/// Create a copy of SearchTreeViewModel
/// with the given fields replaced by the non null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchTreeViewModelCopyWith<SearchTreeViewModel> get copyWith => _$SearchTreeViewModelCopyWithImpl<SearchTreeViewModel>(this as SearchTreeViewModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchTreeViewModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchTreeViewModel&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&(identical(other.rowCount, _this.rowCount) || other.rowCount == _this.rowCount));
}


@override
int get hashCode {
  final _this = this as SearchTreeViewModel;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.groups),_this.rowCount);
}

@override
String toString() {
  final _this = this as SearchTreeViewModel;
  return 'SearchTreeViewModel(groups: ${_this.groups}, rowCount: ${_this.rowCount})';
}


}

/// @nodoc
abstract mixin class $SearchTreeViewModelCopyWith<$Res>  {
  factory $SearchTreeViewModelCopyWith(SearchTreeViewModel value, $Res Function(SearchTreeViewModel) _then) = _$SearchTreeViewModelCopyWithImpl;
@useResult
$Res call({
 List<SearchTreeTopLevelGroup> groups, int rowCount
});




}
/// @nodoc
class _$SearchTreeViewModelCopyWithImpl<$Res>
    implements $SearchTreeViewModelCopyWith<$Res> {
  _$SearchTreeViewModelCopyWithImpl(this._self, this._then);

  final SearchTreeViewModel _self;
  final $Res Function(SearchTreeViewModel) _then;

/// Create a copy of SearchTreeViewModel
/// with the given fields replaced by the non null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groups = null,Object? rowCount = null,}) {
  return _then(SearchTreeViewModel(
groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<SearchTreeTopLevelGroup>,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern matching related methods to [SearchTreeViewModel].
extension SearchTreeViewModelPatterns on SearchTreeViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchTreeViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchTreeViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchTreeViewModel value)  $default,){
final _that = this;
switch (_that) {
case _SearchTreeViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchTreeViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _SearchTreeViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchTreeTopLevelGroup> groups,  int rowCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchTreeViewModel() when $default != null:
return $default(_that.groups,_that.rowCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchTreeTopLevelGroup> groups,  int rowCount)  $default,) {final _that = this;
switch (_that) {
case _SearchTreeViewModel():
return $default(_that.groups,_that.rowCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchTreeTopLevelGroup> groups,  int rowCount)?  $default,) {final _that = this;
switch (_that) {
case _SearchTreeViewModel() when $default != null:
return $default(_that.groups,_that.rowCount);case _:
  return null;

}
}

}

/// @nodoc


class _SearchTreeViewModel implements SearchTreeViewModel {
  const _SearchTreeViewModel({required  List<SearchTreeTopLevelGroup> groups, required this.rowCount}): _groups = groups;


 final  List<SearchTreeTopLevelGroup> _groups;
@override List<SearchTreeTopLevelGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

@override final  int rowCount;

/// Create a copy of SearchTreeViewModel
/// with the given fields replaced by the non null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTreeViewModelCopyWith<_SearchTreeViewModel> get copyWith => __$SearchTreeViewModelCopyWithImpl<_SearchTreeViewModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTreeViewModel&&const DeepCollectionEquality().equals(other.groups, _groups)&&(identical(other.rowCount, rowCount) || other.rowCount == rowCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups),rowCount);
}

@override
String toString() {
    return 'SearchTreeViewModel(groups: $groups, rowCount: $rowCount)';
}


}

/// @nodoc
abstract mixin class _$SearchTreeViewModelCopyWith<$Res> implements $SearchTreeViewModelCopyWith<$Res> {
  factory _$SearchTreeViewModelCopyWith(_SearchTreeViewModel value, $Res Function(_SearchTreeViewModel) _then) = __$SearchTreeViewModelCopyWithImpl;
@override @useResult
$Res call({
 List<SearchTreeTopLevelGroup> groups, int rowCount
});




}
/// @nodoc
class __$SearchTreeViewModelCopyWithImpl<$Res>
    implements _$SearchTreeViewModelCopyWith<$Res> {
  __$SearchTreeViewModelCopyWithImpl(this._self, this._then);

  final _SearchTreeViewModel _self;
  final $Res Function(_SearchTreeViewModel) _then;

/// Create a copy of SearchTreeViewModel
/// with the given fields replaced by the non null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groups = null,Object? rowCount = null,}) {
  return _then(_SearchTreeViewModel(
groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<SearchTreeTopLevelGroup>,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
