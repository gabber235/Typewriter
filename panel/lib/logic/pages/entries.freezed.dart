// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entries.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PageEntry _$PageEntryFromJson(
  Map<String, dynamic> json
) {
        switch (json['_kind']) {
                  case 'definition':
          return DefinitionPageEntry.fromJson(
            json
          );
                case 'reference':
          return ReferencePageEntry.fromJson(
            json
          );
                case 'nonexistent':
          return NonexistentPageEntry.fromJson(
            json
          );
                case 'noBlueprint':
          return NoBlueprintPageEntry.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  '_kind',
  'PageEntry',
  'Invalid union type "${json['_kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$PageEntry implements DiagnosticableTreeMixin {



  /// Serializes this PageEntry to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PageEntry'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageEntry);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PageEntry()';
}


}

/// @nodoc
class $PageEntryCopyWith<$Res>  {
$PageEntryCopyWith(PageEntry _, $Res Function(PageEntry) __);
}


/// Adds pattern-matching-related methods to [PageEntry].
extension PageEntryPatterns on PageEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DefinitionPageEntry value)?  definition,TResult Function( ReferencePageEntry value)?  reference,TResult Function( NonexistentPageEntry value)?  nonexistent,TResult Function( NoBlueprintPageEntry value)?  noBlueprint,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DefinitionPageEntry() when definition != null:
return definition(_that);case ReferencePageEntry() when reference != null:
return reference(_that);case NonexistentPageEntry() when nonexistent != null:
return nonexistent(_that);case NoBlueprintPageEntry() when noBlueprint != null:
return noBlueprint(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DefinitionPageEntry value)  definition,required TResult Function( ReferencePageEntry value)  reference,required TResult Function( NonexistentPageEntry value)  nonexistent,required TResult Function( NoBlueprintPageEntry value)  noBlueprint,}){
final _that = this;
switch (_that) {
case DefinitionPageEntry():
return definition(_that);case ReferencePageEntry():
return reference(_that);case NonexistentPageEntry():
return nonexistent(_that);case NoBlueprintPageEntry():
return noBlueprint(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DefinitionPageEntry value)?  definition,TResult? Function( ReferencePageEntry value)?  reference,TResult? Function( NonexistentPageEntry value)?  nonexistent,TResult? Function( NoBlueprintPageEntry value)?  noBlueprint,}){
final _that = this;
switch (_that) {
case DefinitionPageEntry() when definition != null:
return definition(_that);case ReferencePageEntry() when reference != null:
return reference(_that);case NonexistentPageEntry() when nonexistent != null:
return nonexistent(_that);case NoBlueprintPageEntry() when noBlueprint != null:
return noBlueprint(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( EntryDefinition definition)?  definition,TResult Function( String id,  String name,  EntryBlueprint blueprint,  String pageId,  List<EntryMetadata> metadata)?  reference,TResult Function( String id)?  nonexistent,TResult Function( String id,  String name,  EntryPlacement placement,  List<ElementLink> inwardLinks,  List<ElementLink> outwardLinks,  List<EntryMetadata> metadata)?  noBlueprint,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DefinitionPageEntry() when definition != null:
return definition(_that.definition);case ReferencePageEntry() when reference != null:
return reference(_that.id,_that.name,_that.blueprint,_that.pageId,_that.metadata);case NonexistentPageEntry() when nonexistent != null:
return nonexistent(_that.id);case NoBlueprintPageEntry() when noBlueprint != null:
return noBlueprint(_that.id,_that.name,_that.placement,_that.inwardLinks,_that.outwardLinks,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( EntryDefinition definition)  definition,required TResult Function( String id,  String name,  EntryBlueprint blueprint,  String pageId,  List<EntryMetadata> metadata)  reference,required TResult Function( String id)  nonexistent,required TResult Function( String id,  String name,  EntryPlacement placement,  List<ElementLink> inwardLinks,  List<ElementLink> outwardLinks,  List<EntryMetadata> metadata)  noBlueprint,}) {final _that = this;
switch (_that) {
case DefinitionPageEntry():
return definition(_that.definition);case ReferencePageEntry():
return reference(_that.id,_that.name,_that.blueprint,_that.pageId,_that.metadata);case NonexistentPageEntry():
return nonexistent(_that.id);case NoBlueprintPageEntry():
return noBlueprint(_that.id,_that.name,_that.placement,_that.inwardLinks,_that.outwardLinks,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( EntryDefinition definition)?  definition,TResult? Function( String id,  String name,  EntryBlueprint blueprint,  String pageId,  List<EntryMetadata> metadata)?  reference,TResult? Function( String id)?  nonexistent,TResult? Function( String id,  String name,  EntryPlacement placement,  List<ElementLink> inwardLinks,  List<ElementLink> outwardLinks,  List<EntryMetadata> metadata)?  noBlueprint,}) {final _that = this;
switch (_that) {
case DefinitionPageEntry() when definition != null:
return definition(_that.definition);case ReferencePageEntry() when reference != null:
return reference(_that.id,_that.name,_that.blueprint,_that.pageId,_that.metadata);case NonexistentPageEntry() when nonexistent != null:
return nonexistent(_that.id);case NoBlueprintPageEntry() when noBlueprint != null:
return noBlueprint(_that.id,_that.name,_that.placement,_that.inwardLinks,_that.outwardLinks,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class DefinitionPageEntry with DiagnosticableTreeMixin implements PageEntry {
  const DefinitionPageEntry({required this.definition, final  String? $type}): $type = $type ?? 'definition';
  factory DefinitionPageEntry.fromJson(Map<String, dynamic> json) => _$DefinitionPageEntryFromJson(json);

 final  EntryDefinition definition;

@JsonKey(name: '_kind')
final String $type;


/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DefinitionPageEntryCopyWith<DefinitionPageEntry> get copyWith => _$DefinitionPageEntryCopyWithImpl<DefinitionPageEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DefinitionPageEntryToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PageEntry.definition'))
    ..add(DiagnosticsProperty('definition', definition));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DefinitionPageEntry&&(identical(other.definition, definition) || other.definition == definition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definition);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PageEntry.definition(definition: $definition)';
}


}

/// @nodoc
abstract mixin class $DefinitionPageEntryCopyWith<$Res> implements $PageEntryCopyWith<$Res> {
  factory $DefinitionPageEntryCopyWith(DefinitionPageEntry value, $Res Function(DefinitionPageEntry) _then) = _$DefinitionPageEntryCopyWithImpl;
@useResult
$Res call({
 EntryDefinition definition
});


$EntryDefinitionCopyWith<$Res> get definition;

}
/// @nodoc
class _$DefinitionPageEntryCopyWithImpl<$Res>
    implements $DefinitionPageEntryCopyWith<$Res> {
  _$DefinitionPageEntryCopyWithImpl(this._self, this._then);

  final DefinitionPageEntry _self;
  final $Res Function(DefinitionPageEntry) _then;

/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? definition = null,}) {
  return _then(DefinitionPageEntry(
definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as EntryDefinition,
  ));
}

/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryDefinitionCopyWith<$Res> get definition {
  
  return $EntryDefinitionCopyWith<$Res>(_self.definition, (value) {
    return _then(_self.copyWith(definition: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ReferencePageEntry with DiagnosticableTreeMixin implements PageEntry {
  const ReferencePageEntry({required this.id, required this.name, required this.blueprint, required this.pageId, final  List<EntryMetadata> metadata = const [], final  String? $type}): _metadata = metadata,$type = $type ?? 'reference';
  factory ReferencePageEntry.fromJson(Map<String, dynamic> json) => _$ReferencePageEntryFromJson(json);

 final  String id;
 final  String name;
 final  EntryBlueprint blueprint;
 final  String pageId;
 final  List<EntryMetadata> _metadata;
@JsonKey() List<EntryMetadata> get metadata {
  if (_metadata is EqualUnmodifiableListView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metadata);
}


@JsonKey(name: '_kind')
final String $type;


/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferencePageEntryCopyWith<ReferencePageEntry> get copyWith => _$ReferencePageEntryCopyWithImpl<ReferencePageEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferencePageEntryToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PageEntry.reference'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('blueprint', blueprint))..add(DiagnosticsProperty('pageId', pageId))..add(DiagnosticsProperty('metadata', metadata));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferencePageEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint)&&(identical(other.pageId, pageId) || other.pageId == pageId)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,blueprint,pageId,const DeepCollectionEquality().hash(_metadata));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PageEntry.reference(id: $id, name: $name, blueprint: $blueprint, pageId: $pageId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ReferencePageEntryCopyWith<$Res> implements $PageEntryCopyWith<$Res> {
  factory $ReferencePageEntryCopyWith(ReferencePageEntry value, $Res Function(ReferencePageEntry) _then) = _$ReferencePageEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, EntryBlueprint blueprint, String pageId, List<EntryMetadata> metadata
});


$EntryBlueprintCopyWith<$Res> get blueprint;

}
/// @nodoc
class _$ReferencePageEntryCopyWithImpl<$Res>
    implements $ReferencePageEntryCopyWith<$Res> {
  _$ReferencePageEntryCopyWithImpl(this._self, this._then);

  final ReferencePageEntry _self;
  final $Res Function(ReferencePageEntry) _then;

/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? blueprint = null,Object? pageId = null,Object? metadata = null,}) {
  return _then(ReferencePageEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as EntryBlueprint,pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<EntryMetadata>,
  ));
}

/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryBlueprintCopyWith<$Res> get blueprint {
  
  return $EntryBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class NonexistentPageEntry with DiagnosticableTreeMixin implements PageEntry {
  const NonexistentPageEntry({required this.id, final  String? $type}): $type = $type ?? 'nonexistent';
  factory NonexistentPageEntry.fromJson(Map<String, dynamic> json) => _$NonexistentPageEntryFromJson(json);

 final  String id;

@JsonKey(name: '_kind')
final String $type;


/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NonexistentPageEntryCopyWith<NonexistentPageEntry> get copyWith => _$NonexistentPageEntryCopyWithImpl<NonexistentPageEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NonexistentPageEntryToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PageEntry.nonexistent'))
    ..add(DiagnosticsProperty('id', id));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NonexistentPageEntry&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PageEntry.nonexistent(id: $id)';
}


}

/// @nodoc
abstract mixin class $NonexistentPageEntryCopyWith<$Res> implements $PageEntryCopyWith<$Res> {
  factory $NonexistentPageEntryCopyWith(NonexistentPageEntry value, $Res Function(NonexistentPageEntry) _then) = _$NonexistentPageEntryCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$NonexistentPageEntryCopyWithImpl<$Res>
    implements $NonexistentPageEntryCopyWith<$Res> {
  _$NonexistentPageEntryCopyWithImpl(this._self, this._then);

  final NonexistentPageEntry _self;
  final $Res Function(NonexistentPageEntry) _then;

/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(NonexistentPageEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class NoBlueprintPageEntry with DiagnosticableTreeMixin implements PageEntry {
  const NoBlueprintPageEntry({required this.id, required this.name, required this.placement, required final  List<ElementLink> inwardLinks, required final  List<ElementLink> outwardLinks, final  List<EntryMetadata> metadata = const [], final  String? $type}): _inwardLinks = inwardLinks,_outwardLinks = outwardLinks,_metadata = metadata,$type = $type ?? 'noBlueprint';
  factory NoBlueprintPageEntry.fromJson(Map<String, dynamic> json) => _$NoBlueprintPageEntryFromJson(json);

 final  String id;
 final  String name;
 final  EntryPlacement placement;
 final  List<ElementLink> _inwardLinks;
 List<ElementLink> get inwardLinks {
  if (_inwardLinks is EqualUnmodifiableListView) return _inwardLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inwardLinks);
}

 final  List<ElementLink> _outwardLinks;
 List<ElementLink> get outwardLinks {
  if (_outwardLinks is EqualUnmodifiableListView) return _outwardLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outwardLinks);
}

 final  List<EntryMetadata> _metadata;
@JsonKey() List<EntryMetadata> get metadata {
  if (_metadata is EqualUnmodifiableListView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metadata);
}


@JsonKey(name: '_kind')
final String $type;


/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoBlueprintPageEntryCopyWith<NoBlueprintPageEntry> get copyWith => _$NoBlueprintPageEntryCopyWithImpl<NoBlueprintPageEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoBlueprintPageEntryToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PageEntry.noBlueprint'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('placement', placement))..add(DiagnosticsProperty('inwardLinks', inwardLinks))..add(DiagnosticsProperty('outwardLinks', outwardLinks))..add(DiagnosticsProperty('metadata', metadata));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoBlueprintPageEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.placement, placement) || other.placement == placement)&&const DeepCollectionEquality().equals(other._inwardLinks, _inwardLinks)&&const DeepCollectionEquality().equals(other._outwardLinks, _outwardLinks)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,placement,const DeepCollectionEquality().hash(_inwardLinks),const DeepCollectionEquality().hash(_outwardLinks),const DeepCollectionEquality().hash(_metadata));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PageEntry.noBlueprint(id: $id, name: $name, placement: $placement, inwardLinks: $inwardLinks, outwardLinks: $outwardLinks, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $NoBlueprintPageEntryCopyWith<$Res> implements $PageEntryCopyWith<$Res> {
  factory $NoBlueprintPageEntryCopyWith(NoBlueprintPageEntry value, $Res Function(NoBlueprintPageEntry) _then) = _$NoBlueprintPageEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, EntryPlacement placement, List<ElementLink> inwardLinks, List<ElementLink> outwardLinks, List<EntryMetadata> metadata
});


$EntryPlacementCopyWith<$Res> get placement;

}
/// @nodoc
class _$NoBlueprintPageEntryCopyWithImpl<$Res>
    implements $NoBlueprintPageEntryCopyWith<$Res> {
  _$NoBlueprintPageEntryCopyWithImpl(this._self, this._then);

  final NoBlueprintPageEntry _self;
  final $Res Function(NoBlueprintPageEntry) _then;

/// Create a copy of PageEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? placement = null,Object? inwardLinks = null,Object? outwardLinks = null,Object? metadata = null,}) {
  return _then(NoBlueprintPageEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as EntryPlacement,inwardLinks: null == inwardLinks ? _self._inwardLinks : inwardLinks // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,outwardLinks: null == outwardLinks ? _self._outwardLinks : outwardLinks // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<EntryMetadata>,
  ));
}

/// Create a copy of PageEntry
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
mixin _$EntryDefinition implements DiagnosticableTreeMixin {

 String get id; String get name; EntryBlueprint get blueprint; EntryPlacement get placement; DynamicData get data; List<ElementLink> get inwardEdges; List<ElementLink> get outwardEdges; List<EntryMetadata> get metadata;
/// Create a copy of EntryDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryDefinitionCopyWith<EntryDefinition> get copyWith => _$EntryDefinitionCopyWithImpl<EntryDefinition>(this as EntryDefinition, _$identity);

  /// Serializes this EntryDefinition to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryDefinition'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('blueprint', blueprint))..add(DiagnosticsProperty('placement', placement))..add(DiagnosticsProperty('data', data))..add(DiagnosticsProperty('inwardEdges', inwardEdges))..add(DiagnosticsProperty('outwardEdges', outwardEdges))..add(DiagnosticsProperty('metadata', metadata));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.data, data) || other.data == data)&&const DeepCollectionEquality().equals(other.inwardEdges, inwardEdges)&&const DeepCollectionEquality().equals(other.outwardEdges, outwardEdges)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,blueprint,placement,data,const DeepCollectionEquality().hash(inwardEdges),const DeepCollectionEquality().hash(outwardEdges),const DeepCollectionEquality().hash(metadata));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryDefinition(id: $id, name: $name, blueprint: $blueprint, placement: $placement, data: $data, inwardEdges: $inwardEdges, outwardEdges: $outwardEdges, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $EntryDefinitionCopyWith<$Res>  {
  factory $EntryDefinitionCopyWith(EntryDefinition value, $Res Function(EntryDefinition) _then) = _$EntryDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String name, EntryBlueprint blueprint, EntryPlacement placement, DynamicData data, List<ElementLink> inwardEdges, List<ElementLink> outwardEdges, List<EntryMetadata> metadata
});


$EntryBlueprintCopyWith<$Res> get blueprint;$EntryPlacementCopyWith<$Res> get placement;

}
/// @nodoc
class _$EntryDefinitionCopyWithImpl<$Res>
    implements $EntryDefinitionCopyWith<$Res> {
  _$EntryDefinitionCopyWithImpl(this._self, this._then);

  final EntryDefinition _self;
  final $Res Function(EntryDefinition) _then;

/// Create a copy of EntryDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? blueprint = null,Object? placement = null,Object? data = null,Object? inwardEdges = null,Object? outwardEdges = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as EntryBlueprint,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as EntryPlacement,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as DynamicData,inwardEdges: null == inwardEdges ? _self.inwardEdges : inwardEdges // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,outwardEdges: null == outwardEdges ? _self.outwardEdges : outwardEdges // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<EntryMetadata>,
  ));
}
/// Create a copy of EntryDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryBlueprintCopyWith<$Res> get blueprint {
  
  return $EntryBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}/// Create a copy of EntryDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryPlacementCopyWith<$Res> get placement {
  
  return $EntryPlacementCopyWith<$Res>(_self.placement, (value) {
    return _then(_self.copyWith(placement: value));
  });
}
}


/// Adds pattern-matching-related methods to [EntryDefinition].
extension EntryDefinitionPatterns on EntryDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntryDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntryDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntryDefinition value)  $default,){
final _that = this;
switch (_that) {
case _EntryDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntryDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _EntryDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  EntryBlueprint blueprint,  EntryPlacement placement,  DynamicData data,  List<ElementLink> inwardEdges,  List<ElementLink> outwardEdges,  List<EntryMetadata> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntryDefinition() when $default != null:
return $default(_that.id,_that.name,_that.blueprint,_that.placement,_that.data,_that.inwardEdges,_that.outwardEdges,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  EntryBlueprint blueprint,  EntryPlacement placement,  DynamicData data,  List<ElementLink> inwardEdges,  List<ElementLink> outwardEdges,  List<EntryMetadata> metadata)  $default,) {final _that = this;
switch (_that) {
case _EntryDefinition():
return $default(_that.id,_that.name,_that.blueprint,_that.placement,_that.data,_that.inwardEdges,_that.outwardEdges,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  EntryBlueprint blueprint,  EntryPlacement placement,  DynamicData data,  List<ElementLink> inwardEdges,  List<ElementLink> outwardEdges,  List<EntryMetadata> metadata)?  $default,) {final _that = this;
switch (_that) {
case _EntryDefinition() when $default != null:
return $default(_that.id,_that.name,_that.blueprint,_that.placement,_that.data,_that.inwardEdges,_that.outwardEdges,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EntryDefinition with DiagnosticableTreeMixin implements EntryDefinition {
  const _EntryDefinition({required this.id, required this.name, required this.blueprint, required this.placement, required this.data, required final  List<ElementLink> inwardEdges, required final  List<ElementLink> outwardEdges, final  List<EntryMetadata> metadata = const []}): _inwardEdges = inwardEdges,_outwardEdges = outwardEdges,_metadata = metadata;
  factory _EntryDefinition.fromJson(Map<String, dynamic> json) => _$EntryDefinitionFromJson(json);

@override final  String id;
@override final  String name;
@override final  EntryBlueprint blueprint;
@override final  EntryPlacement placement;
@override final  DynamicData data;
 final  List<ElementLink> _inwardEdges;
@override List<ElementLink> get inwardEdges {
  if (_inwardEdges is EqualUnmodifiableListView) return _inwardEdges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inwardEdges);
}

 final  List<ElementLink> _outwardEdges;
@override List<ElementLink> get outwardEdges {
  if (_outwardEdges is EqualUnmodifiableListView) return _outwardEdges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outwardEdges);
}

 final  List<EntryMetadata> _metadata;
@override@JsonKey() List<EntryMetadata> get metadata {
  if (_metadata is EqualUnmodifiableListView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metadata);
}


/// Create a copy of EntryDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntryDefinitionCopyWith<_EntryDefinition> get copyWith => __$EntryDefinitionCopyWithImpl<_EntryDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntryDefinitionToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryDefinition'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('blueprint', blueprint))..add(DiagnosticsProperty('placement', placement))..add(DiagnosticsProperty('data', data))..add(DiagnosticsProperty('inwardEdges', inwardEdges))..add(DiagnosticsProperty('outwardEdges', outwardEdges))..add(DiagnosticsProperty('metadata', metadata));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntryDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint)&&(identical(other.placement, placement) || other.placement == placement)&&(identical(other.data, data) || other.data == data)&&const DeepCollectionEquality().equals(other._inwardEdges, _inwardEdges)&&const DeepCollectionEquality().equals(other._outwardEdges, _outwardEdges)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,blueprint,placement,data,const DeepCollectionEquality().hash(_inwardEdges),const DeepCollectionEquality().hash(_outwardEdges),const DeepCollectionEquality().hash(_metadata));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryDefinition(id: $id, name: $name, blueprint: $blueprint, placement: $placement, data: $data, inwardEdges: $inwardEdges, outwardEdges: $outwardEdges, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$EntryDefinitionCopyWith<$Res> implements $EntryDefinitionCopyWith<$Res> {
  factory _$EntryDefinitionCopyWith(_EntryDefinition value, $Res Function(_EntryDefinition) _then) = __$EntryDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, EntryBlueprint blueprint, EntryPlacement placement, DynamicData data, List<ElementLink> inwardEdges, List<ElementLink> outwardEdges, List<EntryMetadata> metadata
});


@override $EntryBlueprintCopyWith<$Res> get blueprint;@override $EntryPlacementCopyWith<$Res> get placement;

}
/// @nodoc
class __$EntryDefinitionCopyWithImpl<$Res>
    implements _$EntryDefinitionCopyWith<$Res> {
  __$EntryDefinitionCopyWithImpl(this._self, this._then);

  final _EntryDefinition _self;
  final $Res Function(_EntryDefinition) _then;

/// Create a copy of EntryDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? blueprint = null,Object? placement = null,Object? data = null,Object? inwardEdges = null,Object? outwardEdges = null,Object? metadata = null,}) {
  return _then(_EntryDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as EntryBlueprint,placement: null == placement ? _self.placement : placement // ignore: cast_nullable_to_non_nullable
as EntryPlacement,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as DynamicData,inwardEdges: null == inwardEdges ? _self._inwardEdges : inwardEdges // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,outwardEdges: null == outwardEdges ? _self._outwardEdges : outwardEdges // ignore: cast_nullable_to_non_nullable
as List<ElementLink>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<EntryMetadata>,
  ));
}

/// Create a copy of EntryDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntryBlueprintCopyWith<$Res> get blueprint {
  
  return $EntryBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}/// Create a copy of EntryDefinition
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
mixin _$EntryPlacement implements DiagnosticableTreeMixin {

 int get x; int get y; int get width; int get height;
/// Create a copy of EntryPlacement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryPlacementCopyWith<EntryPlacement> get copyWith => _$EntryPlacementCopyWithImpl<EntryPlacement>(this as EntryPlacement, _$identity);

  /// Serializes this EntryPlacement to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryPlacement'))
    ..add(DiagnosticsProperty('x', x))..add(DiagnosticsProperty('y', y))..add(DiagnosticsProperty('width', width))..add(DiagnosticsProperty('height', height));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryPlacement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryPlacement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $EntryPlacementCopyWith<$Res>  {
  factory $EntryPlacementCopyWith(EntryPlacement value, $Res Function(EntryPlacement) _then) = _$EntryPlacementCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$EntryPlacementCopyWithImpl<$Res>
    implements $EntryPlacementCopyWith<$Res> {
  _$EntryPlacementCopyWithImpl(this._self, this._then);

  final EntryPlacement _self;
  final $Res Function(EntryPlacement) _then;

/// Create a copy of EntryPlacement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EntryPlacement].
extension EntryPlacementPatterns on EntryPlacement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntryPlacement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntryPlacement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntryPlacement value)  $default,){
final _that = this;
switch (_that) {
case _EntryPlacement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntryPlacement value)?  $default,){
final _that = this;
switch (_that) {
case _EntryPlacement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntryPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _EntryPlacement():
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _EntryPlacement() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EntryPlacement with DiagnosticableTreeMixin implements EntryPlacement {
  const _EntryPlacement({required this.x, required this.y, required this.width, required this.height});
  factory _EntryPlacement.fromJson(Map<String, dynamic> json) => _$EntryPlacementFromJson(json);

@override final  int x;
@override final  int y;
@override final  int width;
@override final  int height;

/// Create a copy of EntryPlacement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntryPlacementCopyWith<_EntryPlacement> get copyWith => __$EntryPlacementCopyWithImpl<_EntryPlacement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntryPlacementToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryPlacement'))
    ..add(DiagnosticsProperty('x', x))..add(DiagnosticsProperty('y', y))..add(DiagnosticsProperty('width', width))..add(DiagnosticsProperty('height', height));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntryPlacement&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryPlacement(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$EntryPlacementCopyWith<$Res> implements $EntryPlacementCopyWith<$Res> {
  factory _$EntryPlacementCopyWith(_EntryPlacement value, $Res Function(_EntryPlacement) _then) = __$EntryPlacementCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$EntryPlacementCopyWithImpl<$Res>
    implements _$EntryPlacementCopyWith<$Res> {
  __$EntryPlacementCopyWithImpl(this._self, this._then);

  final _EntryPlacement _self;
  final $Res Function(_EntryPlacement) _then;

/// Create a copy of EntryPlacement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_EntryPlacement(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$EntryBlueprint implements DiagnosticableTreeMixin {

 String get id; String get name; String get description; String get extension; ObjectBlueprint get dataBlueprint;@ColorConverter() Color get color; String get icon; List<String> get tags; List<DataBlueprint>? get genericConstraints; DataBlueprint? get variableDataBlueprint; List<ContextKey> get contextKeys; List<EntryModifier> get modifiers;
/// Create a copy of EntryBlueprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryBlueprintCopyWith<EntryBlueprint> get copyWith => _$EntryBlueprintCopyWithImpl<EntryBlueprint>(this as EntryBlueprint, _$identity);

  /// Serializes this EntryBlueprint to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryBlueprint'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('extension', extension))..add(DiagnosticsProperty('dataBlueprint', dataBlueprint))..add(DiagnosticsProperty('color', color))..add(DiagnosticsProperty('icon', icon))..add(DiagnosticsProperty('tags', tags))..add(DiagnosticsProperty('genericConstraints', genericConstraints))..add(DiagnosticsProperty('variableDataBlueprint', variableDataBlueprint))..add(DiagnosticsProperty('contextKeys', contextKeys))..add(DiagnosticsProperty('modifiers', modifiers));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryBlueprint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.extension, extension) || other.extension == extension)&&const DeepCollectionEquality().equals(other.dataBlueprint, dataBlueprint)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.genericConstraints, genericConstraints)&&(identical(other.variableDataBlueprint, variableDataBlueprint) || other.variableDataBlueprint == variableDataBlueprint)&&const DeepCollectionEquality().equals(other.contextKeys, contextKeys)&&const DeepCollectionEquality().equals(other.modifiers, modifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,extension,const DeepCollectionEquality().hash(dataBlueprint),color,icon,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(genericConstraints),variableDataBlueprint,const DeepCollectionEquality().hash(contextKeys),const DeepCollectionEquality().hash(modifiers));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryBlueprint(id: $id, name: $name, description: $description, extension: $extension, dataBlueprint: $dataBlueprint, color: $color, icon: $icon, tags: $tags, genericConstraints: $genericConstraints, variableDataBlueprint: $variableDataBlueprint, contextKeys: $contextKeys, modifiers: $modifiers)';
}


}

/// @nodoc
abstract mixin class $EntryBlueprintCopyWith<$Res>  {
  factory $EntryBlueprintCopyWith(EntryBlueprint value, $Res Function(EntryBlueprint) _then) = _$EntryBlueprintCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String extension, ObjectBlueprint dataBlueprint,@ColorConverter() Color color, String icon, List<String> tags, List<DataBlueprint>? genericConstraints, DataBlueprint? variableDataBlueprint, List<ContextKey> contextKeys, List<EntryModifier> modifiers
});


$DataBlueprintCopyWith<$Res>? get variableDataBlueprint;

}
/// @nodoc
class _$EntryBlueprintCopyWithImpl<$Res>
    implements $EntryBlueprintCopyWith<$Res> {
  _$EntryBlueprintCopyWithImpl(this._self, this._then);

  final EntryBlueprint _self;
  final $Res Function(EntryBlueprint) _then;

/// Create a copy of EntryBlueprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? extension = null,Object? dataBlueprint = freezed,Object? color = null,Object? icon = null,Object? tags = null,Object? genericConstraints = freezed,Object? variableDataBlueprint = freezed,Object? contextKeys = null,Object? modifiers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String,dataBlueprint: freezed == dataBlueprint ? _self.dataBlueprint : dataBlueprint // ignore: cast_nullable_to_non_nullable
as ObjectBlueprint,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,genericConstraints: freezed == genericConstraints ? _self.genericConstraints : genericConstraints // ignore: cast_nullable_to_non_nullable
as List<DataBlueprint>?,variableDataBlueprint: freezed == variableDataBlueprint ? _self.variableDataBlueprint : variableDataBlueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint?,contextKeys: null == contextKeys ? _self.contextKeys : contextKeys // ignore: cast_nullable_to_non_nullable
as List<ContextKey>,modifiers: null == modifiers ? _self.modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<EntryModifier>,
  ));
}
/// Create a copy of EntryBlueprint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res>? get variableDataBlueprint {
    if (_self.variableDataBlueprint == null) {
    return null;
  }

  return $DataBlueprintCopyWith<$Res>(_self.variableDataBlueprint!, (value) {
    return _then(_self.copyWith(variableDataBlueprint: value));
  });
}
}


/// Adds pattern-matching-related methods to [EntryBlueprint].
extension EntryBlueprintPatterns on EntryBlueprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntryBlueprint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntryBlueprint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntryBlueprint value)  $default,){
final _that = this;
switch (_that) {
case _EntryBlueprint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntryBlueprint value)?  $default,){
final _that = this;
switch (_that) {
case _EntryBlueprint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String extension,  ObjectBlueprint dataBlueprint, @ColorConverter()  Color color,  String icon,  List<String> tags,  List<DataBlueprint>? genericConstraints,  DataBlueprint? variableDataBlueprint,  List<ContextKey> contextKeys,  List<EntryModifier> modifiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntryBlueprint() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.extension,_that.dataBlueprint,_that.color,_that.icon,_that.tags,_that.genericConstraints,_that.variableDataBlueprint,_that.contextKeys,_that.modifiers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String extension,  ObjectBlueprint dataBlueprint, @ColorConverter()  Color color,  String icon,  List<String> tags,  List<DataBlueprint>? genericConstraints,  DataBlueprint? variableDataBlueprint,  List<ContextKey> contextKeys,  List<EntryModifier> modifiers)  $default,) {final _that = this;
switch (_that) {
case _EntryBlueprint():
return $default(_that.id,_that.name,_that.description,_that.extension,_that.dataBlueprint,_that.color,_that.icon,_that.tags,_that.genericConstraints,_that.variableDataBlueprint,_that.contextKeys,_that.modifiers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String extension,  ObjectBlueprint dataBlueprint, @ColorConverter()  Color color,  String icon,  List<String> tags,  List<DataBlueprint>? genericConstraints,  DataBlueprint? variableDataBlueprint,  List<ContextKey> contextKeys,  List<EntryModifier> modifiers)?  $default,) {final _that = this;
switch (_that) {
case _EntryBlueprint() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.extension,_that.dataBlueprint,_that.color,_that.icon,_that.tags,_that.genericConstraints,_that.variableDataBlueprint,_that.contextKeys,_that.modifiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EntryBlueprint with DiagnosticableTreeMixin implements EntryBlueprint {
  const _EntryBlueprint({required this.id, required this.name, required this.description, required this.extension, required this.dataBlueprint, @ColorConverter() this.color = Colors.grey, this.icon = "fa-solid:question-circle", final  List<String> tags = const <String>[], final  List<DataBlueprint>? genericConstraints = null, this.variableDataBlueprint = null, final  List<ContextKey> contextKeys = const [], final  List<EntryModifier> modifiers = const []}): _tags = tags,_genericConstraints = genericConstraints,_contextKeys = contextKeys,_modifiers = modifiers;
  factory _EntryBlueprint.fromJson(Map<String, dynamic> json) => _$EntryBlueprintFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  String extension;
@override final  ObjectBlueprint dataBlueprint;
@override@JsonKey()@ColorConverter() final  Color color;
@override@JsonKey() final  String icon;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<DataBlueprint>? _genericConstraints;
@override@JsonKey() List<DataBlueprint>? get genericConstraints {
  final value = _genericConstraints;
  if (value == null) return null;
  if (_genericConstraints is EqualUnmodifiableListView) return _genericConstraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  DataBlueprint? variableDataBlueprint;
 final  List<ContextKey> _contextKeys;
@override@JsonKey() List<ContextKey> get contextKeys {
  if (_contextKeys is EqualUnmodifiableListView) return _contextKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contextKeys);
}

 final  List<EntryModifier> _modifiers;
@override@JsonKey() List<EntryModifier> get modifiers {
  if (_modifiers is EqualUnmodifiableListView) return _modifiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modifiers);
}


/// Create a copy of EntryBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntryBlueprintCopyWith<_EntryBlueprint> get copyWith => __$EntryBlueprintCopyWithImpl<_EntryBlueprint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntryBlueprintToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryBlueprint'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('extension', extension))..add(DiagnosticsProperty('dataBlueprint', dataBlueprint))..add(DiagnosticsProperty('color', color))..add(DiagnosticsProperty('icon', icon))..add(DiagnosticsProperty('tags', tags))..add(DiagnosticsProperty('genericConstraints', genericConstraints))..add(DiagnosticsProperty('variableDataBlueprint', variableDataBlueprint))..add(DiagnosticsProperty('contextKeys', contextKeys))..add(DiagnosticsProperty('modifiers', modifiers));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntryBlueprint&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.extension, extension) || other.extension == extension)&&const DeepCollectionEquality().equals(other.dataBlueprint, dataBlueprint)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._genericConstraints, _genericConstraints)&&(identical(other.variableDataBlueprint, variableDataBlueprint) || other.variableDataBlueprint == variableDataBlueprint)&&const DeepCollectionEquality().equals(other._contextKeys, _contextKeys)&&const DeepCollectionEquality().equals(other._modifiers, _modifiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,extension,const DeepCollectionEquality().hash(dataBlueprint),color,icon,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_genericConstraints),variableDataBlueprint,const DeepCollectionEquality().hash(_contextKeys),const DeepCollectionEquality().hash(_modifiers));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryBlueprint(id: $id, name: $name, description: $description, extension: $extension, dataBlueprint: $dataBlueprint, color: $color, icon: $icon, tags: $tags, genericConstraints: $genericConstraints, variableDataBlueprint: $variableDataBlueprint, contextKeys: $contextKeys, modifiers: $modifiers)';
}


}

/// @nodoc
abstract mixin class _$EntryBlueprintCopyWith<$Res> implements $EntryBlueprintCopyWith<$Res> {
  factory _$EntryBlueprintCopyWith(_EntryBlueprint value, $Res Function(_EntryBlueprint) _then) = __$EntryBlueprintCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String extension, ObjectBlueprint dataBlueprint,@ColorConverter() Color color, String icon, List<String> tags, List<DataBlueprint>? genericConstraints, DataBlueprint? variableDataBlueprint, List<ContextKey> contextKeys, List<EntryModifier> modifiers
});


@override $DataBlueprintCopyWith<$Res>? get variableDataBlueprint;

}
/// @nodoc
class __$EntryBlueprintCopyWithImpl<$Res>
    implements _$EntryBlueprintCopyWith<$Res> {
  __$EntryBlueprintCopyWithImpl(this._self, this._then);

  final _EntryBlueprint _self;
  final $Res Function(_EntryBlueprint) _then;

/// Create a copy of EntryBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? extension = null,Object? dataBlueprint = freezed,Object? color = null,Object? icon = null,Object? tags = null,Object? genericConstraints = freezed,Object? variableDataBlueprint = freezed,Object? contextKeys = null,Object? modifiers = null,}) {
  return _then(_EntryBlueprint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String,dataBlueprint: freezed == dataBlueprint ? _self.dataBlueprint : dataBlueprint // ignore: cast_nullable_to_non_nullable
as ObjectBlueprint,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,genericConstraints: freezed == genericConstraints ? _self._genericConstraints : genericConstraints // ignore: cast_nullable_to_non_nullable
as List<DataBlueprint>?,variableDataBlueprint: freezed == variableDataBlueprint ? _self.variableDataBlueprint : variableDataBlueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint?,contextKeys: null == contextKeys ? _self._contextKeys : contextKeys // ignore: cast_nullable_to_non_nullable
as List<ContextKey>,modifiers: null == modifiers ? _self._modifiers : modifiers // ignore: cast_nullable_to_non_nullable
as List<EntryModifier>,
  ));
}

/// Create a copy of EntryBlueprint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res>? get variableDataBlueprint {
    if (_self.variableDataBlueprint == null) {
    return null;
  }

  return $DataBlueprintCopyWith<$Res>(_self.variableDataBlueprint!, (value) {
    return _then(_self.copyWith(variableDataBlueprint: value));
  });
}
}


/// @nodoc
mixin _$ContextKey implements DiagnosticableTreeMixin {

 String get name; String get klassName; DataBlueprint get blueprint;
/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextKeyCopyWith<ContextKey> get copyWith => _$ContextKeyCopyWithImpl<ContextKey>(this as ContextKey, _$identity);

  /// Serializes this ContextKey to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ContextKey'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('klassName', klassName))..add(DiagnosticsProperty('blueprint', blueprint));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextKey&&(identical(other.name, name) || other.name == name)&&(identical(other.klassName, klassName) || other.klassName == klassName)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,klassName,blueprint);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ContextKey(name: $name, klassName: $klassName, blueprint: $blueprint)';
}


}

/// @nodoc
abstract mixin class $ContextKeyCopyWith<$Res>  {
  factory $ContextKeyCopyWith(ContextKey value, $Res Function(ContextKey) _then) = _$ContextKeyCopyWithImpl;
@useResult
$Res call({
 String name, String klassName, DataBlueprint blueprint
});


$DataBlueprintCopyWith<$Res> get blueprint;

}
/// @nodoc
class _$ContextKeyCopyWithImpl<$Res>
    implements $ContextKeyCopyWith<$Res> {
  _$ContextKeyCopyWithImpl(this._self, this._then);

  final ContextKey _self;
  final $Res Function(ContextKey) _then;

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? klassName = null,Object? blueprint = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,klassName: null == klassName ? _self.klassName : klassName // ignore: cast_nullable_to_non_nullable
as String,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint,
  ));
}
/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res> get blueprint {
  
  return $DataBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}
}


/// Adds pattern-matching-related methods to [ContextKey].
extension ContextKeyPatterns on ContextKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContextKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContextKey value)  $default,){
final _that = this;
switch (_that) {
case _ContextKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContextKey value)?  $default,){
final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String klassName,  DataBlueprint blueprint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
return $default(_that.name,_that.klassName,_that.blueprint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String klassName,  DataBlueprint blueprint)  $default,) {final _that = this;
switch (_that) {
case _ContextKey():
return $default(_that.name,_that.klassName,_that.blueprint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String klassName,  DataBlueprint blueprint)?  $default,) {final _that = this;
switch (_that) {
case _ContextKey() when $default != null:
return $default(_that.name,_that.klassName,_that.blueprint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContextKey with DiagnosticableTreeMixin implements ContextKey {
  const _ContextKey({required this.name, required this.klassName, required this.blueprint});
  factory _ContextKey.fromJson(Map<String, dynamic> json) => _$ContextKeyFromJson(json);

@override final  String name;
@override final  String klassName;
@override final  DataBlueprint blueprint;

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContextKeyCopyWith<_ContextKey> get copyWith => __$ContextKeyCopyWithImpl<_ContextKey>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContextKeyToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ContextKey'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('klassName', klassName))..add(DiagnosticsProperty('blueprint', blueprint));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContextKey&&(identical(other.name, name) || other.name == name)&&(identical(other.klassName, klassName) || other.klassName == klassName)&&(identical(other.blueprint, blueprint) || other.blueprint == blueprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,klassName,blueprint);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ContextKey(name: $name, klassName: $klassName, blueprint: $blueprint)';
}


}

/// @nodoc
abstract mixin class _$ContextKeyCopyWith<$Res> implements $ContextKeyCopyWith<$Res> {
  factory _$ContextKeyCopyWith(_ContextKey value, $Res Function(_ContextKey) _then) = __$ContextKeyCopyWithImpl;
@override @useResult
$Res call({
 String name, String klassName, DataBlueprint blueprint
});


@override $DataBlueprintCopyWith<$Res> get blueprint;

}
/// @nodoc
class __$ContextKeyCopyWithImpl<$Res>
    implements _$ContextKeyCopyWith<$Res> {
  __$ContextKeyCopyWithImpl(this._self, this._then);

  final _ContextKey _self;
  final $Res Function(_ContextKey) _then;

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? klassName = null,Object? blueprint = null,}) {
  return _then(_ContextKey(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,klassName: null == klassName ? _self.klassName : klassName // ignore: cast_nullable_to_non_nullable
as String,blueprint: null == blueprint ? _self.blueprint : blueprint // ignore: cast_nullable_to_non_nullable
as DataBlueprint,
  ));
}

/// Create a copy of ContextKey
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataBlueprintCopyWith<$Res> get blueprint {
  
  return $DataBlueprintCopyWith<$Res>(_self.blueprint, (value) {
    return _then(_self.copyWith(blueprint: value));
  });
}
}

EntryModifier _$EntryModifierFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'default':
          return _EmptyModifier.fromJson(
            json
          );
                case 'deprecated':
          return DeprecatedModifier.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'EntryModifier',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$EntryModifier implements DiagnosticableTreeMixin {



  /// Serializes this EntryModifier to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryModifier'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryModifier);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryModifier()';
}


}

/// @nodoc
class $EntryModifierCopyWith<$Res>  {
$EntryModifierCopyWith(EntryModifier _, $Res Function(EntryModifier) __);
}


/// Adds pattern-matching-related methods to [EntryModifier].
extension EntryModifierPatterns on EntryModifier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmptyModifier value)?  $default,{TResult Function( DeprecatedModifier value)?  deprecated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default(_that);case DeprecatedModifier() when deprecated != null:
return deprecated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmptyModifier value)  $default,{required TResult Function( DeprecatedModifier value)  deprecated,}){
final _that = this;
switch (_that) {
case _EmptyModifier():
return $default(_that);case DeprecatedModifier():
return deprecated(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmptyModifier value)?  $default,{TResult? Function( DeprecatedModifier value)?  deprecated,}){
final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default(_that);case DeprecatedModifier() when deprecated != null:
return deprecated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function()?  $default,{TResult Function( String reason)?  deprecated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default();case DeprecatedModifier() when deprecated != null:
return deprecated(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function()  $default,{required TResult Function( String reason)  deprecated,}) {final _that = this;
switch (_that) {
case _EmptyModifier():
return $default();case DeprecatedModifier():
return deprecated(_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function()?  $default,{TResult? Function( String reason)?  deprecated,}) {final _that = this;
switch (_that) {
case _EmptyModifier() when $default != null:
return $default();case DeprecatedModifier() when deprecated != null:
return deprecated(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmptyModifier with DiagnosticableTreeMixin implements EntryModifier {
  const _EmptyModifier({final  String? $type}): $type = $type ?? 'default';
  factory _EmptyModifier.fromJson(Map<String, dynamic> json) => _$EmptyModifierFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$EmptyModifierToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryModifier'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmptyModifier);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryModifier()';
}


}




/// @nodoc
@JsonSerializable()

class DeprecatedModifier with DiagnosticableTreeMixin implements EntryModifier {
  const DeprecatedModifier({this.reason = "", final  String? $type}): $type = $type ?? 'deprecated';
  factory DeprecatedModifier.fromJson(Map<String, dynamic> json) => _$DeprecatedModifierFromJson(json);

@JsonKey() final  String reason;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of EntryModifier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeprecatedModifierCopyWith<DeprecatedModifier> get copyWith => _$DeprecatedModifierCopyWithImpl<DeprecatedModifier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeprecatedModifierToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryModifier.deprecated'))
    ..add(DiagnosticsProperty('reason', reason));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeprecatedModifier&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryModifier.deprecated(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $DeprecatedModifierCopyWith<$Res> implements $EntryModifierCopyWith<$Res> {
  factory $DeprecatedModifierCopyWith(DeprecatedModifier value, $Res Function(DeprecatedModifier) _then) = _$DeprecatedModifierCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$DeprecatedModifierCopyWithImpl<$Res>
    implements $DeprecatedModifierCopyWith<$Res> {
  _$DeprecatedModifierCopyWithImpl(this._self, this._then);

  final DeprecatedModifier _self;
  final $Res Function(DeprecatedModifier) _then;

/// Create a copy of EntryModifier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(DeprecatedModifier(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

EntryMetadata _$EntryMetadataFromJson(
  Map<String, dynamic> json
) {
    return CustomEntryMetadata.fromJson(
      json
    );
}

/// @nodoc
mixin _$EntryMetadata implements DiagnosticableTreeMixin {

 String get name; dynamic get data;
/// Create a copy of EntryMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryMetadataCopyWith<EntryMetadata> get copyWith => _$EntryMetadataCopyWithImpl<EntryMetadata>(this as EntryMetadata, _$identity);

  /// Serializes this EntryMetadata to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryMetadata'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryMetadata&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(data));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryMetadata(name: $name, data: $data)';
}


}

/// @nodoc
abstract mixin class $EntryMetadataCopyWith<$Res>  {
  factory $EntryMetadataCopyWith(EntryMetadata value, $Res Function(EntryMetadata) _then) = _$EntryMetadataCopyWithImpl;
@useResult
$Res call({
 String name, dynamic data
});




}
/// @nodoc
class _$EntryMetadataCopyWithImpl<$Res>
    implements $EntryMetadataCopyWith<$Res> {
  _$EntryMetadataCopyWithImpl(this._self, this._then);

  final EntryMetadata _self;
  final $Res Function(EntryMetadata) _then;

/// Create a copy of EntryMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? data = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [EntryMetadata].
extension EntryMetadataPatterns on EntryMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CustomEntryMetadata value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CustomEntryMetadata() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CustomEntryMetadata value)  custom,}){
final _that = this;
switch (_that) {
case CustomEntryMetadata():
return custom(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CustomEntryMetadata value)?  custom,}){
final _that = this;
switch (_that) {
case CustomEntryMetadata() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name,  dynamic data)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CustomEntryMetadata() when custom != null:
return custom(_that.name,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name,  dynamic data)  custom,}) {final _that = this;
switch (_that) {
case CustomEntryMetadata():
return custom(_that.name,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name,  dynamic data)?  custom,}) {final _that = this;
switch (_that) {
case CustomEntryMetadata() when custom != null:
return custom(_that.name,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class CustomEntryMetadata with DiagnosticableTreeMixin implements EntryMetadata {
  const CustomEntryMetadata({required this.name, required this.data});
  factory CustomEntryMetadata.fromJson(Map<String, dynamic> json) => _$CustomEntryMetadataFromJson(json);

@override final  String name;
@override final  dynamic data;

/// Create a copy of EntryMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomEntryMetadataCopyWith<CustomEntryMetadata> get copyWith => _$CustomEntryMetadataCopyWithImpl<CustomEntryMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomEntryMetadataToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'EntryMetadata.custom'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('data', data));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomEntryMetadata&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(data));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'EntryMetadata.custom(name: $name, data: $data)';
}


}

/// @nodoc
abstract mixin class $CustomEntryMetadataCopyWith<$Res> implements $EntryMetadataCopyWith<$Res> {
  factory $CustomEntryMetadataCopyWith(CustomEntryMetadata value, $Res Function(CustomEntryMetadata) _then) = _$CustomEntryMetadataCopyWithImpl;
@override @useResult
$Res call({
 String name, dynamic data
});




}
/// @nodoc
class _$CustomEntryMetadataCopyWithImpl<$Res>
    implements $CustomEntryMetadataCopyWith<$Res> {
  _$CustomEntryMetadataCopyWithImpl(this._self, this._then);

  final CustomEntryMetadata _self;
  final $Res Function(CustomEntryMetadata) _then;

/// Create a copy of EntryMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? data = freezed,}) {
  return _then(CustomEntryMetadata(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
