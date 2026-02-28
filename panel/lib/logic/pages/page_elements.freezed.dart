// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_elements.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PageElement _$PageElementFromJson(
  Map<String, dynamic> json
) {
        switch (json['_kind']) {
                  case 'entry':
          return PageElementEntry.fromJson(
            json
          );
                case 'group':
          return PageElementGroup.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  '_kind',
  'PageElement',
  'Invalid union type "${json['_kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$PageElement {



  /// Serializes this PageElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElement);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PageElement()';
}


}

/// @nodoc
class $PageElementCopyWith<$Res>  {
$PageElementCopyWith(PageElement _, $Res Function(PageElement) __);
}


/// Adds pattern-matching-related methods to [PageElement].
extension PageElementPatterns on PageElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PageElementEntry value)?  entry,TResult Function( PageElementGroup value)?  group,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that);case PageElementGroup() when group != null:
return group(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PageElementEntry value)  entry,required TResult Function( PageElementGroup value)  group,}){
final _that = this;
switch (_that) {
case PageElementEntry():
return entry(_that);case PageElementGroup():
return group(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PageElementEntry value)?  entry,TResult? Function( PageElementGroup value)?  group,}){
final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that);case PageElementGroup() when group != null:
return group(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PageEntry entry)?  entry,TResult Function( String id,  String name,  EntryPlacement placement)?  group,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that.entry);case PageElementGroup() when group != null:
return group(_that.id,_that.name,_that.placement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PageEntry entry)  entry,required TResult Function( String id,  String name,  EntryPlacement placement)  group,}) {final _that = this;
switch (_that) {
case PageElementEntry():
return entry(_that.entry);case PageElementGroup():
return group(_that.id,_that.name,_that.placement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PageEntry entry)?  entry,TResult? Function( String id,  String name,  EntryPlacement placement)?  group,}) {final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that.entry);case PageElementGroup() when group != null:
return group(_that.id,_that.name,_that.placement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class PageElementEntry implements PageElement {
  const PageElementEntry({required this.entry, final  String? $type}): $type = $type ?? 'entry';
  factory PageElementEntry.fromJson(Map<String, dynamic> json) => _$PageElementEntryFromJson(json);

 final  PageEntry entry;

@JsonKey(name: '_kind')
final String $type;


/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageElementEntryCopyWith<PageElementEntry> get copyWith => _$PageElementEntryCopyWithImpl<PageElementEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageElementEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementEntry&&(identical(other.entry, entry) || other.entry == entry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entry);

@override
String toString() {
  return 'PageElement.entry(entry: $entry)';
}


}

/// @nodoc
abstract mixin class $PageElementEntryCopyWith<$Res> implements $PageElementCopyWith<$Res> {
  factory $PageElementEntryCopyWith(PageElementEntry value, $Res Function(PageElementEntry) _then) = _$PageElementEntryCopyWithImpl;
@useResult
$Res call({
 PageEntry entry
});


$PageEntryCopyWith<$Res> get entry;

}
/// @nodoc
class _$PageElementEntryCopyWithImpl<$Res>
    implements $PageElementEntryCopyWith<$Res> {
  _$PageElementEntryCopyWithImpl(this._self, this._then);

  final PageElementEntry _self;
  final $Res Function(PageElementEntry) _then;

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entry = null,}) {
  return _then(PageElementEntry(
entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as PageEntry,
  ));
}

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageEntryCopyWith<$Res> get entry {
  
  return $PageEntryCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class PageElementGroup implements PageElement {
  const PageElementGroup({required this.id, required this.name, required this.placement, final  String? $type}): $type = $type ?? 'group';
  factory PageElementGroup.fromJson(Map<String, dynamic> json) => _$PageElementGroupFromJson(json);

 final  String id;
 final  String name;
 final  EntryPlacement placement;

@JsonKey(name: '_kind')
final String $type;


/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageElementGroupCopyWith<PageElementGroup> get copyWith => _$PageElementGroupCopyWithImpl<PageElementGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageElementGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.placement, placement) || other.placement == placement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,placement);

@override
String toString() {
  return 'PageElement.group(id: $id, name: $name, placement: $placement)';
}


}

/// @nodoc
abstract mixin class $PageElementGroupCopyWith<$Res> implements $PageElementCopyWith<$Res> {
  factory $PageElementGroupCopyWith(PageElementGroup value, $Res Function(PageElementGroup) _then) = _$PageElementGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, EntryPlacement placement
});


$EntryPlacementCopyWith<$Res> get placement;

}
/// @nodoc
class _$PageElementGroupCopyWithImpl<$Res>
    implements $PageElementGroupCopyWith<$Res> {
  _$PageElementGroupCopyWithImpl(this._self, this._then);

  final PageElementGroup _self;
  final $Res Function(PageElementGroup) _then;

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? placement = null,}) {
  return _then(PageElementGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as EntryPlacement,
  ));
}

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryPlacementCopyWith<$Res> get placement {
  
  return $EntryPlacementCopyWith<$Res>(_self.placement, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}

// dart format on
