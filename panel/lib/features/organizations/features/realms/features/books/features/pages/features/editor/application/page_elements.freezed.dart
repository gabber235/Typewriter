// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page_elements.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PageElement {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElement);
}


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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PageElementEntry value)?  entry,TResult Function( PageElementCue value)?  cue,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that);case PageElementCue() when cue != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PageElementEntry value)  entry,required TResult Function( PageElementCue value)  cue,}){
final _that = this;
switch (_that) {
case PageElementEntry():
return entry(_that);case PageElementCue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PageElementEntry value)?  entry,TResult? Function( PageElementCue value)?  cue,}){
final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that);case PageElementCue() when cue != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PageEntry entry)?  entry,TResult Function( Cue cue)?  cue,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that.entry);case PageElementCue() when cue != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PageEntry entry)  entry,required TResult Function( Cue cue)  cue,}) {final _that = this;
switch (_that) {
case PageElementEntry():
return entry(_that.entry);case PageElementCue():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PageEntry entry)?  entry,TResult? Function( Cue cue)?  cue,}) {final _that = this;
switch (_that) {
case PageElementEntry() when entry != null:
return entry(_that.entry);case PageElementCue() when cue != null:
return cue(_that.cue);case _:
  return null;

}
}

}

/// @nodoc


class PageElementEntry implements PageElement {
  const PageElementEntry({required this.entry});


 final  PageEntry entry;

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageElementEntryCopyWith<PageElementEntry> get copyWith => _$PageElementEntryCopyWithImpl<PageElementEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementEntry&&(identical(other.entry, entry) || other.entry == entry));
}


@override
int get hashCode {
    return Object.hash(runtimeType,entry);
}

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


class PageElementCue implements PageElement {
  const PageElementCue({required this.cue});


 final  Cue cue;

/// Create a copy of PageElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageElementCueCopyWith<PageElementCue> get copyWith => _$PageElementCueCopyWithImpl<PageElementCue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PageElementCue&&(identical(other.cue, cue) || other.cue == cue));
}


@override
int get hashCode {
    return Object.hash(runtimeType,cue);
}

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

 String get linkId; String get otherId; String get path;@JsonKey(includeFromJson: false, includeToJson: false) DataPath? get sourcePath;
/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElementLinkCopyWith<ElementLink> get copyWith => _$ElementLinkCopyWithImpl<ElementLink>(this as ElementLink, _$identity);

  /// Serializes this ElementLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ElementLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElementLink&&(identical(other.linkId, _this.linkId) || other.linkId == _this.linkId)&&(identical(other.otherId, _this.otherId) || other.otherId == _this.otherId)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.sourcePath, _this.sourcePath) || other.sourcePath == _this.sourcePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ElementLink;
  return Object.hash(runtimeType,_this.linkId,_this.otherId,_this.path,_this.sourcePath);
}

@override
String toString() {
  final _this = this as ElementLink;
  return 'ElementLink(linkId: ${_this.linkId}, otherId: ${_this.otherId}, path: ${_this.path}, sourcePath: ${_this.sourcePath})';
}


}

/// @nodoc
abstract mixin class $ElementLinkCopyWith<$Res>  {
  factory $ElementLinkCopyWith(ElementLink value, $Res Function(ElementLink) _then) = _$ElementLinkCopyWithImpl;
@useResult
$Res call({
 String linkId, String otherId, String path,@JsonKey(includeFromJson: false, includeToJson: false) DataPath? sourcePath
});


$DataPathCopyWith<$Res>? get sourcePath;

}
/// @nodoc
class _$ElementLinkCopyWithImpl<$Res>
    implements $ElementLinkCopyWith<$Res> {
  _$ElementLinkCopyWithImpl(this._self, this._then);

  final ElementLink _self;
  final $Res Function(ElementLink) _then;

/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? linkId = null,Object? otherId = null,Object? path = null,Object? sourcePath = freezed,}) {
  return _then(ElementLink(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,otherId: null == otherId ? _self.otherId : otherId // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sourcePath: freezed == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as DataPath?,
  ));
}
/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res>? get sourcePath {
    if (_self.sourcePath == null) {
    return null;
  }

  return $DataPathCopyWith<$Res>(_self.sourcePath!, (value) {
    return _then(_self.copyWith(sourcePath: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String linkId,  String otherId,  String path, @JsonKey(includeFromJson: false, includeToJson: false)  DataPath? sourcePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElementLink() when $default != null:
return $default(_that.linkId,_that.otherId,_that.path,_that.sourcePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String linkId,  String otherId,  String path, @JsonKey(includeFromJson: false, includeToJson: false)  DataPath? sourcePath)  $default,) {final _that = this;
switch (_that) {
case _ElementLink():
return $default(_that.linkId,_that.otherId,_that.path,_that.sourcePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String linkId,  String otherId,  String path, @JsonKey(includeFromJson: false, includeToJson: false)  DataPath? sourcePath)?  $default,) {final _that = this;
switch (_that) {
case _ElementLink() when $default != null:
return $default(_that.linkId,_that.otherId,_that.path,_that.sourcePath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ElementLink implements ElementLink {
  const _ElementLink({required this.linkId, required this.otherId, required this.path, @JsonKey(includeFromJson: false, includeToJson: false) this.sourcePath}): assert(linkId != "", 'Link ID must not be empty.'),assert(otherId != "", 'Other ID must not be empty.');
  factory _ElementLink.fromJson(Map<String, dynamic> json) => _$ElementLinkFromJson(json);

@override final  String linkId;
@override final  String otherId;
@override final  String path;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  DataPath? sourcePath;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElementLink&&(identical(other.linkId, linkId) || other.linkId == linkId)&&(identical(other.otherId, otherId) || other.otherId == otherId)&&(identical(other.path, path) || other.path == path)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,linkId,otherId,path,sourcePath);
}

@override
String toString() {
    return 'ElementLink(linkId: $linkId, otherId: $otherId, path: $path, sourcePath: $sourcePath)';
}


}

/// @nodoc
abstract mixin class _$ElementLinkCopyWith<$Res> implements $ElementLinkCopyWith<$Res> {
  factory _$ElementLinkCopyWith(_ElementLink value, $Res Function(_ElementLink) _then) = __$ElementLinkCopyWithImpl;
@override @useResult
$Res call({
 String linkId, String otherId, String path,@JsonKey(includeFromJson: false, includeToJson: false) DataPath? sourcePath
});


@override $DataPathCopyWith<$Res>? get sourcePath;

}
/// @nodoc
class __$ElementLinkCopyWithImpl<$Res>
    implements _$ElementLinkCopyWith<$Res> {
  __$ElementLinkCopyWithImpl(this._self, this._then);

  final _ElementLink _self;
  final $Res Function(_ElementLink) _then;

/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? linkId = null,Object? otherId = null,Object? path = null,Object? sourcePath = freezed,}) {
  return _then(_ElementLink(
linkId: null == linkId ? _self.linkId : linkId // ignore: cast_nullable_to_non_nullable
as String,otherId: null == otherId ? _self.otherId : otherId // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sourcePath: freezed == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as DataPath?,
  ));
}

/// Create a copy of ElementLink
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res>? get sourcePath {
    if (_self.sourcePath == null) {
    return null;
  }

  return $DataPathCopyWith<$Res>(_self.sourcePath!, (value) {
    return _then(_self.copyWith(sourcePath: value));
  });
}
}

/// @nodoc
mixin _$RelationshipUsage {

 String get sourceId; String get targetId; String get slot; DataPath? get sourcePath;
/// Create a copy of RelationshipUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationshipUsageCopyWith<RelationshipUsage> get copyWith => _$RelationshipUsageCopyWithImpl<RelationshipUsage>(this as RelationshipUsage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RelationshipUsage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationshipUsage&&(identical(other.sourceId, _this.sourceId) || other.sourceId == _this.sourceId)&&(identical(other.targetId, _this.targetId) || other.targetId == _this.targetId)&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.sourcePath, _this.sourcePath) || other.sourcePath == _this.sourcePath));
}


@override
int get hashCode {
  final _this = this as RelationshipUsage;
  return Object.hash(runtimeType,_this.sourceId,_this.targetId,_this.slot,_this.sourcePath);
}

@override
String toString() {
  final _this = this as RelationshipUsage;
  return 'RelationshipUsage(sourceId: ${_this.sourceId}, targetId: ${_this.targetId}, slot: ${_this.slot}, sourcePath: ${_this.sourcePath})';
}


}

/// @nodoc
abstract mixin class $RelationshipUsageCopyWith<$Res>  {
  factory $RelationshipUsageCopyWith(RelationshipUsage value, $Res Function(RelationshipUsage) _then) = _$RelationshipUsageCopyWithImpl;
@useResult
$Res call({
 String sourceId, String targetId, String slot, DataPath? sourcePath
});


$DataPathCopyWith<$Res>? get sourcePath;

}
/// @nodoc
class _$RelationshipUsageCopyWithImpl<$Res>
    implements $RelationshipUsageCopyWith<$Res> {
  _$RelationshipUsageCopyWithImpl(this._self, this._then);

  final RelationshipUsage _self;
  final $Res Function(RelationshipUsage) _then;

/// Create a copy of RelationshipUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceId = null,Object? targetId = null,Object? slot = null,Object? sourcePath = freezed,}) {
  return _then(RelationshipUsage(
sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,sourcePath: freezed == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as DataPath?,
  ));
}
/// Create a copy of RelationshipUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res>? get sourcePath {
    if (_self.sourcePath == null) {
    return null;
  }

  return $DataPathCopyWith<$Res>(_self.sourcePath!, (value) {
    return _then(_self.copyWith(sourcePath: value));
  });
}
}


/// Adds pattern-matching-related methods to [RelationshipUsage].
extension RelationshipUsagePatterns on RelationshipUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelationshipUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelationshipUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelationshipUsage value)  $default,){
final _that = this;
switch (_that) {
case _RelationshipUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelationshipUsage value)?  $default,){
final _that = this;
switch (_that) {
case _RelationshipUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sourceId,  String targetId,  String slot,  DataPath? sourcePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelationshipUsage() when $default != null:
return $default(_that.sourceId,_that.targetId,_that.slot,_that.sourcePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sourceId,  String targetId,  String slot,  DataPath? sourcePath)  $default,) {final _that = this;
switch (_that) {
case _RelationshipUsage():
return $default(_that.sourceId,_that.targetId,_that.slot,_that.sourcePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sourceId,  String targetId,  String slot,  DataPath? sourcePath)?  $default,) {final _that = this;
switch (_that) {
case _RelationshipUsage() when $default != null:
return $default(_that.sourceId,_that.targetId,_that.slot,_that.sourcePath);case _:
  return null;

}
}

}

/// @nodoc


class _RelationshipUsage extends RelationshipUsage {
  const _RelationshipUsage({required this.sourceId, required this.targetId, required this.slot, required this.sourcePath}): super._();


@override final  String sourceId;
@override final  String targetId;
@override final  String slot;
@override final  DataPath? sourcePath;

/// Create a copy of RelationshipUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelationshipUsageCopyWith<_RelationshipUsage> get copyWith => __$RelationshipUsageCopyWithImpl<_RelationshipUsage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelationshipUsage&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,sourceId,targetId,slot,sourcePath);
}

@override
String toString() {
    return 'RelationshipUsage(sourceId: $sourceId, targetId: $targetId, slot: $slot, sourcePath: $sourcePath)';
}


}

/// @nodoc
abstract mixin class _$RelationshipUsageCopyWith<$Res> implements $RelationshipUsageCopyWith<$Res> {
  factory _$RelationshipUsageCopyWith(_RelationshipUsage value, $Res Function(_RelationshipUsage) _then) = __$RelationshipUsageCopyWithImpl;
@override @useResult
$Res call({
 String sourceId, String targetId, String slot, DataPath? sourcePath
});


@override $DataPathCopyWith<$Res>? get sourcePath;

}
/// @nodoc
class __$RelationshipUsageCopyWithImpl<$Res>
    implements _$RelationshipUsageCopyWith<$Res> {
  __$RelationshipUsageCopyWithImpl(this._self, this._then);

  final _RelationshipUsage _self;
  final $Res Function(_RelationshipUsage) _then;

/// Create a copy of RelationshipUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceId = null,Object? targetId = null,Object? slot = null,Object? sourcePath = freezed,}) {
  return _then(_RelationshipUsage(
sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,sourcePath: freezed == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as DataPath?,
  ));
}

/// Create a copy of RelationshipUsage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataPathCopyWith<$Res>? get sourcePath {
    if (_self.sourcePath == null) {
    return null;
  }

  return $DataPathCopyWith<$Res>(_self.sourcePath!, (value) {
    return _then(_self.copyWith(sourcePath: value));
  });
}
}

/// @nodoc
mixin _$RelationshipGroup {

 String get resourceId; String get name; String? get pageId; List<RelationshipUsage> get usages;
/// Create a copy of RelationshipGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelationshipGroupCopyWith<RelationshipGroup> get copyWith => _$RelationshipGroupCopyWithImpl<RelationshipGroup>(this as RelationshipGroup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RelationshipGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelationshipGroup&&(identical(other.resourceId, _this.resourceId) || other.resourceId == _this.resourceId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.pageId, _this.pageId) || other.pageId == _this.pageId)&&const DeepCollectionEquality().equals(other.usages, _this.usages));
}


@override
int get hashCode {
  final _this = this as RelationshipGroup;
  return Object.hash(runtimeType,_this.resourceId,_this.name,_this.pageId,const DeepCollectionEquality().hash(_this.usages));
}

@override
String toString() {
  final _this = this as RelationshipGroup;
  return 'RelationshipGroup(resourceId: ${_this.resourceId}, name: ${_this.name}, pageId: ${_this.pageId}, usages: ${_this.usages})';
}


}

/// @nodoc
abstract mixin class $RelationshipGroupCopyWith<$Res>  {
  factory $RelationshipGroupCopyWith(RelationshipGroup value, $Res Function(RelationshipGroup) _then) = _$RelationshipGroupCopyWithImpl;
@useResult
$Res call({
 String resourceId, String name, String? pageId, List<RelationshipUsage> usages
});




}
/// @nodoc
class _$RelationshipGroupCopyWithImpl<$Res>
    implements $RelationshipGroupCopyWith<$Res> {
  _$RelationshipGroupCopyWithImpl(this._self, this._then);

  final RelationshipGroup _self;
  final $Res Function(RelationshipGroup) _then;

/// Create a copy of RelationshipGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resourceId = null,Object? name = null,Object? pageId = freezed,Object? usages = null,}) {
  return _then(RelationshipGroup(
resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,pageId: freezed == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as String?,usages: null == usages ? _self.usages : usages // ignore: cast_nullable_to_non_nullable
as List<RelationshipUsage>,
  ));
}

}


/// Adds pattern-matching-related methods to [RelationshipGroup].
extension RelationshipGroupPatterns on RelationshipGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelationshipGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelationshipGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelationshipGroup value)  $default,){
final _that = this;
switch (_that) {
case _RelationshipGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelationshipGroup value)?  $default,){
final _that = this;
switch (_that) {
case _RelationshipGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resourceId,  String name,  String? pageId,  List<RelationshipUsage> usages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelationshipGroup() when $default != null:
return $default(_that.resourceId,_that.name,_that.pageId,_that.usages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resourceId,  String name,  String? pageId,  List<RelationshipUsage> usages)  $default,) {final _that = this;
switch (_that) {
case _RelationshipGroup():
return $default(_that.resourceId,_that.name,_that.pageId,_that.usages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resourceId,  String name,  String? pageId,  List<RelationshipUsage> usages)?  $default,) {final _that = this;
switch (_that) {
case _RelationshipGroup() when $default != null:
return $default(_that.resourceId,_that.name,_that.pageId,_that.usages);case _:
  return null;

}
}

}

/// @nodoc


class _RelationshipGroup implements RelationshipGroup {
  const _RelationshipGroup({required this.resourceId, required this.name, required this.pageId, required  List<RelationshipUsage> usages}): _usages = usages;


@override final  String resourceId;
@override final  String name;
@override final  String? pageId;
 final  List<RelationshipUsage> _usages;
@override List<RelationshipUsage> get usages {
  if (_usages is EqualUnmodifiableListView) return _usages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_usages);
}


/// Create a copy of RelationshipGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelationshipGroupCopyWith<_RelationshipGroup> get copyWith => __$RelationshipGroupCopyWithImpl<_RelationshipGroup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelationshipGroup&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.pageId, pageId) || other.pageId == pageId)&&const DeepCollectionEquality().equals(other.usages, _usages));
}


@override
int get hashCode {
    return Object.hash(runtimeType,resourceId,name,pageId,const DeepCollectionEquality().hash(_usages));
}

@override
String toString() {
    return 'RelationshipGroup(resourceId: $resourceId, name: $name, pageId: $pageId, usages: $usages)';
}


}

/// @nodoc
abstract mixin class _$RelationshipGroupCopyWith<$Res> implements $RelationshipGroupCopyWith<$Res> {
  factory _$RelationshipGroupCopyWith(_RelationshipGroup value, $Res Function(_RelationshipGroup) _then) = __$RelationshipGroupCopyWithImpl;
@override @useResult
$Res call({
 String resourceId, String name, String? pageId, List<RelationshipUsage> usages
});




}
/// @nodoc
class __$RelationshipGroupCopyWithImpl<$Res>
    implements _$RelationshipGroupCopyWith<$Res> {
  __$RelationshipGroupCopyWithImpl(this._self, this._then);

  final _RelationshipGroup _self;
  final $Res Function(_RelationshipGroup) _then;

/// Create a copy of RelationshipGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resourceId = null,Object? name = null,Object? pageId = freezed,Object? usages = null,}) {
  return _then(_RelationshipGroup(
resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,pageId: freezed == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as String?,usages: null == usages ? _self._usages : usages // ignore: cast_nullable_to_non_nullable
as List<RelationshipUsage>,
  ));
}


}

/// @nodoc
mixin _$EntryRelationships {

 List<RelationshipGroup> get incoming; List<RelationshipGroup> get outgoing;
/// Create a copy of EntryRelationships
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryRelationshipsCopyWith<EntryRelationships> get copyWith => _$EntryRelationshipsCopyWithImpl<EntryRelationships>(this as EntryRelationships, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EntryRelationships;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryRelationships&&const DeepCollectionEquality().equals(other.incoming, _this.incoming)&&const DeepCollectionEquality().equals(other.outgoing, _this.outgoing));
}


@override
int get hashCode {
  final _this = this as EntryRelationships;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.incoming),const DeepCollectionEquality().hash(_this.outgoing));
}

@override
String toString() {
  final _this = this as EntryRelationships;
  return 'EntryRelationships(incoming: ${_this.incoming}, outgoing: ${_this.outgoing})';
}


}

/// @nodoc
abstract mixin class $EntryRelationshipsCopyWith<$Res>  {
  factory $EntryRelationshipsCopyWith(EntryRelationships value, $Res Function(EntryRelationships) _then) = _$EntryRelationshipsCopyWithImpl;
@useResult
$Res call({
 List<RelationshipGroup> incoming, List<RelationshipGroup> outgoing
});




}
/// @nodoc
class _$EntryRelationshipsCopyWithImpl<$Res>
    implements $EntryRelationshipsCopyWith<$Res> {
  _$EntryRelationshipsCopyWithImpl(this._self, this._then);

  final EntryRelationships _self;
  final $Res Function(EntryRelationships) _then;

/// Create a copy of EntryRelationships
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? incoming = null,Object? outgoing = null,}) {
  return _then(EntryRelationships(
incoming: null == incoming ? _self.incoming : incoming // ignore: cast_nullable_to_non_nullable
as List<RelationshipGroup>,outgoing: null == outgoing ? _self.outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<RelationshipGroup>,
  ));
}

}


/// Adds pattern-matching-related methods to [EntryRelationships].
extension EntryRelationshipsPatterns on EntryRelationships {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntryRelationships value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntryRelationships() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntryRelationships value)  $default,){
final _that = this;
switch (_that) {
case _EntryRelationships():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntryRelationships value)?  $default,){
final _that = this;
switch (_that) {
case _EntryRelationships() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RelationshipGroup> incoming,  List<RelationshipGroup> outgoing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntryRelationships() when $default != null:
return $default(_that.incoming,_that.outgoing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RelationshipGroup> incoming,  List<RelationshipGroup> outgoing)  $default,) {final _that = this;
switch (_that) {
case _EntryRelationships():
return $default(_that.incoming,_that.outgoing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RelationshipGroup> incoming,  List<RelationshipGroup> outgoing)?  $default,) {final _that = this;
switch (_that) {
case _EntryRelationships() when $default != null:
return $default(_that.incoming,_that.outgoing);case _:
  return null;

}
}

}

/// @nodoc


class _EntryRelationships implements EntryRelationships {
  const _EntryRelationships({required  List<RelationshipGroup> incoming, required  List<RelationshipGroup> outgoing}): _incoming = incoming,_outgoing = outgoing;


 final  List<RelationshipGroup> _incoming;
@override List<RelationshipGroup> get incoming {
  if (_incoming is EqualUnmodifiableListView) return _incoming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_incoming);
}

 final  List<RelationshipGroup> _outgoing;
@override List<RelationshipGroup> get outgoing {
  if (_outgoing is EqualUnmodifiableListView) return _outgoing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outgoing);
}


/// Create a copy of EntryRelationships
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntryRelationshipsCopyWith<_EntryRelationships> get copyWith => __$EntryRelationshipsCopyWithImpl<_EntryRelationships>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntryRelationships&&const DeepCollectionEquality().equals(other.incoming, _incoming)&&const DeepCollectionEquality().equals(other.outgoing, _outgoing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_incoming),const DeepCollectionEquality().hash(_outgoing));
}

@override
String toString() {
    return 'EntryRelationships(incoming: $incoming, outgoing: $outgoing)';
}


}

/// @nodoc
abstract mixin class _$EntryRelationshipsCopyWith<$Res> implements $EntryRelationshipsCopyWith<$Res> {
  factory _$EntryRelationshipsCopyWith(_EntryRelationships value, $Res Function(_EntryRelationships) _then) = __$EntryRelationshipsCopyWithImpl;
@override @useResult
$Res call({
 List<RelationshipGroup> incoming, List<RelationshipGroup> outgoing
});




}
/// @nodoc
class __$EntryRelationshipsCopyWithImpl<$Res>
    implements _$EntryRelationshipsCopyWith<$Res> {
  __$EntryRelationshipsCopyWithImpl(this._self, this._then);

  final _EntryRelationships _self;
  final $Res Function(_EntryRelationships) _then;

/// Create a copy of EntryRelationships
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? incoming = null,Object? outgoing = null,}) {
  return _then(_EntryRelationships(
incoming: null == incoming ? _self._incoming : incoming // ignore: cast_nullable_to_non_nullable
as List<RelationshipGroup>,outgoing: null == outgoing ? _self._outgoing : outgoing // ignore: cast_nullable_to_non_nullable
as List<RelationshipGroup>,
  ));
}


}

// dart format on
