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
                case 'cue':
          return PageElementCue.fromJson(
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PageElementEntry value)?  entry,TResult Function( PageElementGroup value)?  group,TResult Function( PageElementCue value)?  cue,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that);case PageElementGroup() when group != null:
return group(_that);case PageElementCue() when cue != null:
return cue(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PageElementEntry value)  entry,required TResult Function( PageElementGroup value)  group,required TResult Function( PageElementCue value)  cue,}){
final _that = this;
switch (_that) {
case PageElementEntry():
return entry(_that);case PageElementGroup():
return group(_that);case PageElementCue():
return cue(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PageElementEntry value)?  entry,TResult? Function( PageElementGroup value)?  group,TResult? Function( PageElementCue value)?  cue,}){
final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that);case PageElementGroup() when group != null:
return group(_that);case PageElementCue() when cue != null:
return cue(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PageEntry entry)?  entry,TResult Function( String id,  String name,  EntryPlacement placement)?  group,TResult Function( Cue cue)?  cue,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that.entry);case PageElementGroup() when group != null:
return group(_that.id,_that.name,_that.placement);case PageElementCue() when cue != null:
return cue(_that.cue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PageEntry entry)  entry,required TResult Function( String id,  String name,  EntryPlacement placement)  group,required TResult Function( Cue cue)  cue,}) {final _that = this;
switch (_that) {
case PageElementEntry():
return entry(_that.entry);case PageElementGroup():
return group(_that.id,_that.name,_that.placement);case PageElementCue():
return cue(_that.cue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PageEntry entry)?  entry,TResult? Function( String id,  String name,  EntryPlacement placement)?  group,TResult? Function( Cue cue)?  cue,}) {final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that.entry);case PageElementGroup() when group != null:
return group(_that.id,_that.name,_that.placement);case PageElementCue() when cue != null:
return cue(_that.cue);case _:
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
  const PageElementGroup({required this.id, required this.name, required this.placement, final  String? $type}): assert(id != "", 'ID must not be empty.'),$type = $type ?? 'group';
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

/// @nodoc
@JsonSerializable()

class PageElementCue implements PageElement {
  const PageElementCue({required this.cue, final  String? $type}): $type = $type ?? 'cue';
  factory PageElementCue.fromJson(Map<String, dynamic> json) => _$PageElementCueFromJson(json);

 final  Cue cue;

@JsonKey(name: '_kind')
final String $type;


/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageElementCueCopyWith<PageElementCue> get copyWith => _$PageElementCueCopyWithImpl<PageElementCue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageElementCueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementCue&&(identical(other.cue, cue) || other.cue == cue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cue);

@override
String toString() {
  return 'PageElement.cue(cue: $cue)';
}


}

/// @nodoc
abstract mixin class $PageElementCueCopyWith<$Res> implements $PageElementCopyWith<$Res> {
  factory $PageElementCueCopyWith(PageElementCue value, $Res Function(PageElementCue) _then) = _$PageElementCueCopyWithImpl;
@useResult
$Res call({
 Cue cue
});


$CueCopyWith<$Res> get cue;

}
/// @nodoc
class _$PageElementCueCopyWithImpl<$Res>
    implements $PageElementCueCopyWith<$Res> {
  _$PageElementCueCopyWithImpl(this._self, this._then);

  final PageElementCue _self;
  final $Res Function(PageElementCue) _then;

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cue = null,}) {
  return _then(PageElementCue(
cue: null == cue ? _self.cue : cue // ignore: cast_nullable_to_non_nullable
as Cue,
  ));
}

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CueCopyWith<$Res> get cue {
  
  return $CueCopyWith<$Res>(_self.cue, (value) {
    return _then(_self.copyWith(cue: value));
  });
}
}


/// @nodoc
mixin _$ElementLink {

 String get linkId; String get otherId; String get path;
/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementLinkCopyWith<ElementLink> get copyWith => _$ElementLinkCopyWithImpl<ElementLink>(this as ElementLink, _$identity);

  /// Serializes this ElementLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementLink&&(identical(other.linkId, linkId) || other.linkId == linkId)&&(identical(other.otherId, otherId) || other.otherId == otherId)&&(identical(other.path, path) || other.path == path));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,linkId,otherId,path);

@override
String toString() {
  return 'ElementLink(linkId: $linkId, otherId: $otherId, path: $path)';
}


}

/// @nodoc
abstract mixin class $ElementLinkCopyWith<$Res>  {
  factory $ElementLinkCopyWith(ElementLink value, $Res Function(ElementLink) _then) = _$ElementLinkCopyWithImpl;
@useResult
$Res call({
 String linkId, String otherId, String path
});




}
/// @nodoc
class _$ElementLinkCopyWithImpl<$Res>
    implements $ElementLinkCopyWith<$Res> {
  _$ElementLinkCopyWithImpl(this._self, this._then);

  final ElementLink _self;
  final $Res Function(ElementLink) _then;

/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? linkId = null,Object? otherId = null,Object? path = null,}) {
  return _then(_self.copyWith(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,otherId: null == otherId ? _self.otherId : otherId // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ElementLink].
extension ElementLinkPatterns on ElementLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ElementLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ElementLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ElementLink value)  $default,){
final _that = this;
switch (_that) {
case _ElementLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ElementLink value)?  $default,){
final _that = this;
switch (_that) {
case _ElementLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String linkId,  String otherId,  String path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElementLink() when $default != null:
return $default(_that.linkId,_that.otherId,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String linkId,  String otherId,  String path)  $default,) {final _that = this;
switch (_that) {
case _ElementLink():
return $default(_that.linkId,_that.otherId,_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String linkId,  String otherId,  String path)?  $default,) {final _that = this;
switch (_that) {
case _ElementLink() when $default != null:
return $default(_that.linkId,_that.otherId,_that.path);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ElementLink implements ElementLink {
  const _ElementLink({required this.linkId, required this.otherId, required this.path}): assert(linkId != "", 'Link ID must not be empty.'),assert(otherId != "", 'Other ID must not be empty.');
  factory _ElementLink.fromJson(Map<String, dynamic> json) => _$ElementLinkFromJson(json);

@override final  String linkId;
@override final  String otherId;
@override final  String path;

/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ElementLinkCopyWith<_ElementLink> get copyWith => __$ElementLinkCopyWithImpl<_ElementLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ElementLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElementLink&&(identical(other.linkId, linkId) || other.linkId == linkId)&&(identical(other.otherId, otherId) || other.otherId == otherId)&&(identical(other.path, path) || other.path == path));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,linkId,otherId,path);

@override
String toString() {
  return 'ElementLink(linkId: $linkId, otherId: $otherId, path: $path)';
}


}

/// @nodoc
abstract mixin class _$ElementLinkCopyWith<$Res> implements $ElementLinkCopyWith<$Res> {
  factory _$ElementLinkCopyWith(_ElementLink value, $Res Function(_ElementLink) _then) = __$ElementLinkCopyWithImpl;
@override @useResult
$Res call({
 String linkId, String otherId, String path
});




}
/// @nodoc
class __$ElementLinkCopyWithImpl<$Res>
    implements _$ElementLinkCopyWith<$Res> {
  __$ElementLinkCopyWithImpl(this._self, this._then);

  final _ElementLink _self;
  final $Res Function(_ElementLink) _then;

/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? linkId = null,Object? otherId = null,Object? path = null,}) {
  return _then(_ElementLink(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,otherId: null == otherId ? _self.otherId : otherId // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
