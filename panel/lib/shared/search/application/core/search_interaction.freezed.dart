// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_interaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchCommandId implements DiagnosticableTreeMixin {

 String get value;
/// Create a copy of SearchCommandId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandIdCopyWith<SearchCommandId> get copyWith => _$SearchCommandIdCopyWithImpl<SearchCommandId>(this as SearchCommandId, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchCommandId;
  properties
    ..add(DiagnosticsProperty('type', 'SearchCommandId'))
    ..add(DiagnosticsProperty('value', _this.value));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchCommandId;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandId&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as SearchCommandId;
  return Object.hash(runtimeType,_this.value);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchCommandId;
  return 'SearchCommandId(value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $SearchCommandIdCopyWith<$Res>  {
  factory $SearchCommandIdCopyWith(SearchCommandId value, $Res Function(SearchCommandId) _then) = _$SearchCommandIdCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$SearchCommandIdCopyWithImpl<$Res>
    implements $SearchCommandIdCopyWith<$Res> {
  _$SearchCommandIdCopyWithImpl(this._self, this._then);

  final SearchCommandId _self;
  final $Res Function(SearchCommandId) _then;

/// Create a copy of SearchCommandId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(SearchCommandId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchCommandId].
extension SearchCommandIdPatterns on SearchCommandId {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchCommandId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchCommandId() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchCommandId value)  $default,){
final _that = this;
switch (_that) {
case _SearchCommandId():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchCommandId value)?  $default,){
final _that = this;
switch (_that) {
case _SearchCommandId() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchCommandId() when $default != null:
return $default(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value)  $default,) {final _that = this;
switch (_that) {
case _SearchCommandId():
return $default(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value)?  $default,) {final _that = this;
switch (_that) {
case _SearchCommandId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _SearchCommandId with DiagnosticableTreeMixin implements SearchCommandId {
  const _SearchCommandId(this.value): assert(value != "", 'Command ID must not be empty.');
  

@override final  String value;

/// Create a copy of SearchCommandId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchCommandIdCopyWith<_SearchCommandId> get copyWith => __$SearchCommandIdCopyWithImpl<_SearchCommandId>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandId'))
    ..add(DiagnosticsProperty('value', value));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchCommandId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandId(value: $value)';
}


}

/// @nodoc
abstract mixin class _$SearchCommandIdCopyWith<$Res> implements $SearchCommandIdCopyWith<$Res> {
  factory _$SearchCommandIdCopyWith(_SearchCommandId value, $Res Function(_SearchCommandId) _then) = __$SearchCommandIdCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$SearchCommandIdCopyWithImpl<$Res>
    implements _$SearchCommandIdCopyWith<$Res> {
  __$SearchCommandIdCopyWithImpl(this._self, this._then);

  final _SearchCommandId _self;
  final $Res Function(_SearchCommandId) _then;

/// Create a copy of SearchCommandId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_SearchCommandId(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SearchCommandPresentation implements DiagnosticableTreeMixin {

 String get label; int get priority; String? get icon; Color? get color; ShortcutActivator? get shortcut;
/// Create a copy of SearchCommandPresentation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandPresentationCopyWith<SearchCommandPresentation> get copyWith => _$SearchCommandPresentationCopyWithImpl<SearchCommandPresentation>(this as SearchCommandPresentation, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchCommandPresentation;
  properties
    ..add(DiagnosticsProperty('type', 'SearchCommandPresentation'))
    ..add(DiagnosticsProperty('label', _this.label))..add(DiagnosticsProperty('priority', _this.priority))..add(DiagnosticsProperty('icon', _this.icon))..add(DiagnosticsProperty('color', _this.color))..add(DiagnosticsProperty('shortcut', _this.shortcut));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchCommandPresentation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandPresentation&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.shortcut, _this.shortcut) || other.shortcut == _this.shortcut));
}


@override
int get hashCode {
  final _this = this as SearchCommandPresentation;
  return Object.hash(runtimeType,_this.label,_this.priority,_this.icon,_this.color,_this.shortcut);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchCommandPresentation;
  return 'SearchCommandPresentation(label: ${_this.label}, priority: ${_this.priority}, icon: ${_this.icon}, color: ${_this.color}, shortcut: ${_this.shortcut})';
}


}

/// @nodoc
abstract mixin class $SearchCommandPresentationCopyWith<$Res>  {
  factory $SearchCommandPresentationCopyWith(SearchCommandPresentation value, $Res Function(SearchCommandPresentation) _then) = _$SearchCommandPresentationCopyWithImpl;
@useResult
$Res call({
 String label, int priority, String? icon, Color? color, ShortcutActivator? shortcut
});




}
/// @nodoc
class _$SearchCommandPresentationCopyWithImpl<$Res>
    implements $SearchCommandPresentationCopyWith<$Res> {
  _$SearchCommandPresentationCopyWithImpl(this._self, this._then);

  final SearchCommandPresentation _self;
  final $Res Function(SearchCommandPresentation) _then;

/// Create a copy of SearchCommandPresentation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? priority = null,Object? icon = freezed,Object? color = freezed,Object? shortcut = freezed,}) {
  return _then(SearchCommandPresentation(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,shortcut: freezed == shortcut ? _self.shortcut : shortcut // ignore: cast_nullable_to_non_nullable
as ShortcutActivator?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchCommandPresentation].
extension SearchCommandPresentationPatterns on SearchCommandPresentation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchCommandPresentation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchCommandPresentation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchCommandPresentation value)  $default,){
final _that = this;
switch (_that) {
case _SearchCommandPresentation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchCommandPresentation value)?  $default,){
final _that = this;
switch (_that) {
case _SearchCommandPresentation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  int priority,  String? icon,  Color? color,  ShortcutActivator? shortcut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchCommandPresentation() when $default != null:
return $default(_that.label,_that.priority,_that.icon,_that.color,_that.shortcut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  int priority,  String? icon,  Color? color,  ShortcutActivator? shortcut)  $default,) {final _that = this;
switch (_that) {
case _SearchCommandPresentation():
return $default(_that.label,_that.priority,_that.icon,_that.color,_that.shortcut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  int priority,  String? icon,  Color? color,  ShortcutActivator? shortcut)?  $default,) {final _that = this;
switch (_that) {
case _SearchCommandPresentation() when $default != null:
return $default(_that.label,_that.priority,_that.icon,_that.color,_that.shortcut);case _:
  return null;

}
}

}

/// @nodoc


class _SearchCommandPresentation with DiagnosticableTreeMixin implements SearchCommandPresentation {
  const _SearchCommandPresentation({required this.label, this.priority = 0, this.icon, this.color, this.shortcut}): assert(label != "", 'Command label must not be empty.');
  

@override final  String label;
@override@JsonKey() final  int priority;
@override final  String? icon;
@override final  Color? color;
@override final  ShortcutActivator? shortcut;

/// Create a copy of SearchCommandPresentation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchCommandPresentationCopyWith<_SearchCommandPresentation> get copyWith => __$SearchCommandPresentationCopyWithImpl<_SearchCommandPresentation>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandPresentation'))
    ..add(DiagnosticsProperty('label', label))..add(DiagnosticsProperty('priority', priority))..add(DiagnosticsProperty('icon', icon))..add(DiagnosticsProperty('color', color))..add(DiagnosticsProperty('shortcut', shortcut));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchCommandPresentation&&(identical(other.label, label) || other.label == label)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.shortcut, shortcut) || other.shortcut == shortcut));
}


@override
int get hashCode {
    return Object.hash(runtimeType,label,priority,icon,color,shortcut);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandPresentation(label: $label, priority: $priority, icon: $icon, color: $color, shortcut: $shortcut)';
}


}

/// @nodoc
abstract mixin class _$SearchCommandPresentationCopyWith<$Res> implements $SearchCommandPresentationCopyWith<$Res> {
  factory _$SearchCommandPresentationCopyWith(_SearchCommandPresentation value, $Res Function(_SearchCommandPresentation) _then) = __$SearchCommandPresentationCopyWithImpl;
@override @useResult
$Res call({
 String label, int priority, String? icon, Color? color, ShortcutActivator? shortcut
});




}
/// @nodoc
class __$SearchCommandPresentationCopyWithImpl<$Res>
    implements _$SearchCommandPresentationCopyWith<$Res> {
  __$SearchCommandPresentationCopyWithImpl(this._self, this._then);

  final _SearchCommandPresentation _self;
  final $Res Function(_SearchCommandPresentation) _then;

/// Create a copy of SearchCommandPresentation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? priority = null,Object? icon = freezed,Object? color = freezed,Object? shortcut = freezed,}) {
  return _then(_SearchCommandPresentation(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,shortcut: freezed == shortcut ? _self.shortcut : shortcut // ignore: cast_nullable_to_non_nullable
as ShortcutActivator?,
  ));
}


}

/// @nodoc
mixin _$SearchCommandState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandState'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandState()';
}


}

/// @nodoc
class $SearchCommandStateCopyWith<$Res>  {
$SearchCommandStateCopyWith(SearchCommandState _, $Res Function(SearchCommandState) __);
}


/// Adds pattern-matching-related methods to [SearchCommandState].
extension SearchCommandStatePatterns on SearchCommandState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchCommandHidden value)?  hidden,TResult Function( SearchCommandDisabled value)?  disabled,TResult Function( SearchCommandEnabled value)?  enabled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchCommandHidden() when hidden != null:
return hidden(_that);case SearchCommandDisabled() when disabled != null:
return disabled(_that);case SearchCommandEnabled() when enabled != null:
return enabled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchCommandHidden value)  hidden,required TResult Function( SearchCommandDisabled value)  disabled,required TResult Function( SearchCommandEnabled value)  enabled,}){
final _that = this;
switch (_that) {
case SearchCommandHidden():
return hidden(_that);case SearchCommandDisabled():
return disabled(_that);case SearchCommandEnabled():
return enabled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchCommandHidden value)?  hidden,TResult? Function( SearchCommandDisabled value)?  disabled,TResult? Function( SearchCommandEnabled value)?  enabled,}){
final _that = this;
switch (_that) {
case SearchCommandHidden() when hidden != null:
return hidden(_that);case SearchCommandDisabled() when disabled != null:
return disabled(_that);case SearchCommandEnabled() when enabled != null:
return enabled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  hidden,TResult Function( String reason)?  disabled,TResult Function()?  enabled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchCommandHidden() when hidden != null:
return hidden();case SearchCommandDisabled() when disabled != null:
return disabled(_that.reason);case SearchCommandEnabled() when enabled != null:
return enabled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  hidden,required TResult Function( String reason)  disabled,required TResult Function()  enabled,}) {final _that = this;
switch (_that) {
case SearchCommandHidden():
return hidden();case SearchCommandDisabled():
return disabled(_that.reason);case SearchCommandEnabled():
return enabled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  hidden,TResult? Function( String reason)?  disabled,TResult? Function()?  enabled,}) {final _that = this;
switch (_that) {
case SearchCommandHidden() when hidden != null:
return hidden();case SearchCommandDisabled() when disabled != null:
return disabled(_that.reason);case SearchCommandEnabled() when enabled != null:
return enabled();case _:
  return null;

}
}

}

/// @nodoc


class SearchCommandHidden with DiagnosticableTreeMixin implements SearchCommandState {
  const SearchCommandHidden();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandState.hidden'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandHidden);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandState.hidden()';
}


}




/// @nodoc


class SearchCommandDisabled with DiagnosticableTreeMixin implements SearchCommandState {
  const SearchCommandDisabled(this.reason): assert(reason != "", 'Disabled reason must not be empty.');
  

 final  String reason;

/// Create a copy of SearchCommandState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandDisabledCopyWith<SearchCommandDisabled> get copyWith => _$SearchCommandDisabledCopyWithImpl<SearchCommandDisabled>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandState.disabled'))
    ..add(DiagnosticsProperty('reason', reason));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandDisabled&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandState.disabled(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $SearchCommandDisabledCopyWith<$Res> implements $SearchCommandStateCopyWith<$Res> {
  factory $SearchCommandDisabledCopyWith(SearchCommandDisabled value, $Res Function(SearchCommandDisabled) _then) = _$SearchCommandDisabledCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$SearchCommandDisabledCopyWithImpl<$Res>
    implements $SearchCommandDisabledCopyWith<$Res> {
  _$SearchCommandDisabledCopyWithImpl(this._self, this._then);

  final SearchCommandDisabled _self;
  final $Res Function(SearchCommandDisabled) _then;

/// Create a copy of SearchCommandState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(SearchCommandDisabled(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SearchCommandEnabled with DiagnosticableTreeMixin implements SearchCommandState {
  const SearchCommandEnabled();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandState.enabled'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandEnabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandState.enabled()';
}


}




/// @nodoc
mixin _$SearchCommandTarget implements DiagnosticableTreeMixin {

 SearchResult get primary; List<SearchResult> get selection; SearchQueryContext get query;
/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandTargetCopyWith<SearchCommandTarget> get copyWith => _$SearchCommandTargetCopyWithImpl<SearchCommandTarget>(this as SearchCommandTarget, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchCommandTarget;
  properties
    ..add(DiagnosticsProperty('type', 'SearchCommandTarget'))
    ..add(DiagnosticsProperty('primary', _this.primary))..add(DiagnosticsProperty('selection', _this.selection))..add(DiagnosticsProperty('query', _this.query));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchCommandTarget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandTarget&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&const DeepCollectionEquality().equals(other.selection, _this.selection)&&(identical(other.query, _this.query) || other.query == _this.query));
}


@override
int get hashCode {
  final _this = this as SearchCommandTarget;
  return Object.hash(runtimeType,_this.primary,const DeepCollectionEquality().hash(_this.selection),_this.query);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchCommandTarget;
  return 'SearchCommandTarget(primary: ${_this.primary}, selection: ${_this.selection}, query: ${_this.query})';
}


}

/// @nodoc
abstract mixin class $SearchCommandTargetCopyWith<$Res>  {
  factory $SearchCommandTargetCopyWith(SearchCommandTarget value, $Res Function(SearchCommandTarget) _then) = _$SearchCommandTargetCopyWithImpl;
@useResult
$Res call({
 SearchResult primary, List<SearchResult> selection, SearchQueryContext query
});


$SearchResultCopyWith<$Res> get primary;$SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$SearchCommandTargetCopyWithImpl<$Res>
    implements $SearchCommandTargetCopyWith<$Res> {
  _$SearchCommandTargetCopyWithImpl(this._self, this._then);

  final SearchCommandTarget _self;
  final $Res Function(SearchCommandTarget) _then;

/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = null,Object? selection = null,Object? query = null,}) {
  return _then(SearchCommandTarget(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as SearchResult,selection: null == selection ? _self.selection : selection // ignore: cast_nullable_to_non_nullable
as List<SearchResult>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}
/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get primary {
  
  return $SearchResultCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchCommandTarget].
extension SearchCommandTargetPatterns on SearchCommandTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchCommandTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchCommandTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchCommandTarget value)  $default,){
final _that = this;
switch (_that) {
case _SearchCommandTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchCommandTarget value)?  $default,){
final _that = this;
switch (_that) {
case _SearchCommandTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchResult primary,  List<SearchResult> selection,  SearchQueryContext query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchCommandTarget() when $default != null:
return $default(_that.primary,_that.selection,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchResult primary,  List<SearchResult> selection,  SearchQueryContext query)  $default,) {final _that = this;
switch (_that) {
case _SearchCommandTarget():
return $default(_that.primary,_that.selection,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchResult primary,  List<SearchResult> selection,  SearchQueryContext query)?  $default,) {final _that = this;
switch (_that) {
case _SearchCommandTarget() when $default != null:
return $default(_that.primary,_that.selection,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class _SearchCommandTarget with DiagnosticableTreeMixin implements SearchCommandTarget {
  const _SearchCommandTarget({required this.primary, required  List<SearchResult> selection, required this.query}): assert(selection.length > 0, 'Selection must not be empty.'),_selection = selection;
  

@override final  SearchResult primary;
 final  List<SearchResult> _selection;
@override List<SearchResult> get selection {
  if (_selection is EqualUnmodifiableListView) return _selection;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selection);
}

@override final  SearchQueryContext query;

/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchCommandTargetCopyWith<_SearchCommandTarget> get copyWith => __$SearchCommandTargetCopyWithImpl<_SearchCommandTarget>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandTarget'))
    ..add(DiagnosticsProperty('primary', primary))..add(DiagnosticsProperty('selection', selection))..add(DiagnosticsProperty('query', query));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchCommandTarget&&(identical(other.primary, primary) || other.primary == primary)&&const DeepCollectionEquality().equals(other.selection, _selection)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode {
    return Object.hash(runtimeType,primary,const DeepCollectionEquality().hash(_selection),query);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandTarget(primary: $primary, selection: $selection, query: $query)';
}


}

/// @nodoc
abstract mixin class _$SearchCommandTargetCopyWith<$Res> implements $SearchCommandTargetCopyWith<$Res> {
  factory _$SearchCommandTargetCopyWith(_SearchCommandTarget value, $Res Function(_SearchCommandTarget) _then) = __$SearchCommandTargetCopyWithImpl;
@override @useResult
$Res call({
 SearchResult primary, List<SearchResult> selection, SearchQueryContext query
});


@override $SearchResultCopyWith<$Res> get primary;@override $SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class __$SearchCommandTargetCopyWithImpl<$Res>
    implements _$SearchCommandTargetCopyWith<$Res> {
  __$SearchCommandTargetCopyWithImpl(this._self, this._then);

  final _SearchCommandTarget _self;
  final $Res Function(_SearchCommandTarget) _then;

/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primary = null,Object? selection = null,Object? query = null,}) {
  return _then(_SearchCommandTarget(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as SearchResult,selection: null == selection ? _self._selection : selection // ignore: cast_nullable_to_non_nullable
as List<SearchResult>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}

/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultCopyWith<$Res> get primary {
  
  return $SearchResultCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}/// Create a copy of SearchCommandTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

/// @nodoc
mixin _$SearchResultMatcher<P extends Object> implements DiagnosticableTreeMixin {

 SearchResultType get type;
/// Create a copy of SearchResultMatcher
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultMatcherCopyWith<P, SearchResultMatcher<P>> get copyWith => _$SearchResultMatcherCopyWithImpl<P, SearchResultMatcher<P>>(this as SearchResultMatcher<P>, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchResultMatcher<P>;
  properties
    ..add(DiagnosticsProperty('type', 'SearchResultMatcher<$P>'))
    ..add(DiagnosticsProperty('type', _this.type));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchResultMatcher<P>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultMatcher<P>&&(identical(other.type, _this.type) || other.type == _this.type));
}


@override
int get hashCode {
  final _this = this as SearchResultMatcher<P>;
  return Object.hash(runtimeType,_this.type);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchResultMatcher<P>;
  return 'SearchResultMatcher<$P>(type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $SearchResultMatcherCopyWith<P extends Object,$Res>  {
  factory $SearchResultMatcherCopyWith(SearchResultMatcher<P> value, $Res Function(SearchResultMatcher<P>) _then) = _$SearchResultMatcherCopyWithImpl;
@useResult
$Res call({
 SearchResultType type
});


$SearchResultTypeCopyWith<$Res> get type;

}
/// @nodoc
class _$SearchResultMatcherCopyWithImpl<P extends Object,$Res>
    implements $SearchResultMatcherCopyWith<P, $Res> {
  _$SearchResultMatcherCopyWithImpl(this._self, this._then);

  final SearchResultMatcher<P> _self;
  final $Res Function(SearchResultMatcher<P>) _then;

/// Create a copy of SearchResultMatcher
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,}) {
  return _then(SearchResultMatcher(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,
  ));
}
/// Create a copy of SearchResultMatcher
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultTypeCopyWith<$Res> get type {
  
  return $SearchResultTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResultMatcher].
extension SearchResultMatcherPatterns<P extends Object> on SearchResultMatcher<P> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultMatcher<P> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultMatcher() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultMatcher<P> value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultMatcher():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultMatcher<P> value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultMatcher() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchResultType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultMatcher() when $default != null:
return $default(_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchResultType type)  $default,) {final _that = this;
switch (_that) {
case _SearchResultMatcher():
return $default(_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchResultType type)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultMatcher() when $default != null:
return $default(_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResultMatcher<P extends Object> extends SearchResultMatcher<P> with DiagnosticableTreeMixin {
  const _SearchResultMatcher(this.type): super._();
  

@override final  SearchResultType type;

/// Create a copy of SearchResultMatcher
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultMatcherCopyWith<P, _SearchResultMatcher<P>> get copyWith => __$SearchResultMatcherCopyWithImpl<P, _SearchResultMatcher<P>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchResultMatcher<$P>'))
    ..add(DiagnosticsProperty('type', type));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultMatcher<P>&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchResultMatcher<$P>(type: $type)';
}


}

/// @nodoc
abstract mixin class _$SearchResultMatcherCopyWith<P extends Object,$Res> implements $SearchResultMatcherCopyWith<P, $Res> {
  factory _$SearchResultMatcherCopyWith(_SearchResultMatcher<P> value, $Res Function(_SearchResultMatcher<P>) _then) = __$SearchResultMatcherCopyWithImpl;
@override @useResult
$Res call({
 SearchResultType type
});


@override $SearchResultTypeCopyWith<$Res> get type;

}
/// @nodoc
class __$SearchResultMatcherCopyWithImpl<P extends Object,$Res>
    implements _$SearchResultMatcherCopyWith<P, $Res> {
  __$SearchResultMatcherCopyWithImpl(this._self, this._then);

  final _SearchResultMatcher<P> _self;
  final $Res Function(_SearchResultMatcher<P>) _then;

/// Create a copy of SearchResultMatcher
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(_SearchResultMatcher<P>(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchResultType,
  ));
}

/// Create a copy of SearchResultMatcher
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchResultTypeCopyWith<$Res> get type {
  
  return $SearchResultTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

/// @nodoc
mixin _$ResolvedSearchCommand implements DiagnosticableTreeMixin {

 SearchCommand get command; SearchCommandState get state;
/// Create a copy of ResolvedSearchCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResolvedSearchCommandCopyWith<ResolvedSearchCommand> get copyWith => _$ResolvedSearchCommandCopyWithImpl<ResolvedSearchCommand>(this as ResolvedSearchCommand, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as ResolvedSearchCommand;
  properties
    ..add(DiagnosticsProperty('type', 'ResolvedSearchCommand'))
    ..add(DiagnosticsProperty('command', _this.command))..add(DiagnosticsProperty('state', _this.state));
}

@override
bool operator ==(Object other) {
  final _this = this as ResolvedSearchCommand;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResolvedSearchCommand&&(identical(other.command, _this.command) || other.command == _this.command)&&(identical(other.state, _this.state) || other.state == _this.state));
}


@override
int get hashCode {
  final _this = this as ResolvedSearchCommand;
  return Object.hash(runtimeType,_this.command,_this.state);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as ResolvedSearchCommand;
  return 'ResolvedSearchCommand(command: ${_this.command}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $ResolvedSearchCommandCopyWith<$Res>  {
  factory $ResolvedSearchCommandCopyWith(ResolvedSearchCommand value, $Res Function(ResolvedSearchCommand) _then) = _$ResolvedSearchCommandCopyWithImpl;
@useResult
$Res call({
 SearchCommand command, SearchCommandState state
});


$SearchCommandStateCopyWith<$Res> get state;

}
/// @nodoc
class _$ResolvedSearchCommandCopyWithImpl<$Res>
    implements $ResolvedSearchCommandCopyWith<$Res> {
  _$ResolvedSearchCommandCopyWithImpl(this._self, this._then);

  final ResolvedSearchCommand _self;
  final $Res Function(ResolvedSearchCommand) _then;

/// Create a copy of ResolvedSearchCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? command = null,Object? state = null,}) {
  return _then(ResolvedSearchCommand(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as SearchCommand,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SearchCommandState,
  ));
}
/// Create a copy of ResolvedSearchCommand
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchCommandStateCopyWith<$Res> get state {
  
  return $SearchCommandStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}


/// Adds pattern-matching-related methods to [ResolvedSearchCommand].
extension ResolvedSearchCommandPatterns on ResolvedSearchCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResolvedSearchCommand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResolvedSearchCommand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResolvedSearchCommand value)  $default,){
final _that = this;
switch (_that) {
case _ResolvedSearchCommand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResolvedSearchCommand value)?  $default,){
final _that = this;
switch (_that) {
case _ResolvedSearchCommand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchCommand command,  SearchCommandState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResolvedSearchCommand() when $default != null:
return $default(_that.command,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchCommand command,  SearchCommandState state)  $default,) {final _that = this;
switch (_that) {
case _ResolvedSearchCommand():
return $default(_that.command,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchCommand command,  SearchCommandState state)?  $default,) {final _that = this;
switch (_that) {
case _ResolvedSearchCommand() when $default != null:
return $default(_that.command,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _ResolvedSearchCommand with DiagnosticableTreeMixin implements ResolvedSearchCommand {
  const _ResolvedSearchCommand({required this.command, required this.state});
  

@override final  SearchCommand command;
@override final  SearchCommandState state;

/// Create a copy of ResolvedSearchCommand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResolvedSearchCommandCopyWith<_ResolvedSearchCommand> get copyWith => __$ResolvedSearchCommandCopyWithImpl<_ResolvedSearchCommand>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'ResolvedSearchCommand'))
    ..add(DiagnosticsProperty('command', command))..add(DiagnosticsProperty('state', state));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResolvedSearchCommand&&(identical(other.command, command) || other.command == command)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode {
    return Object.hash(runtimeType,command,state);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'ResolvedSearchCommand(command: $command, state: $state)';
}


}

/// @nodoc
abstract mixin class _$ResolvedSearchCommandCopyWith<$Res> implements $ResolvedSearchCommandCopyWith<$Res> {
  factory _$ResolvedSearchCommandCopyWith(_ResolvedSearchCommand value, $Res Function(_ResolvedSearchCommand) _then) = __$ResolvedSearchCommandCopyWithImpl;
@override @useResult
$Res call({
 SearchCommand command, SearchCommandState state
});


@override $SearchCommandStateCopyWith<$Res> get state;

}
/// @nodoc
class __$ResolvedSearchCommandCopyWithImpl<$Res>
    implements _$ResolvedSearchCommandCopyWith<$Res> {
  __$ResolvedSearchCommandCopyWithImpl(this._self, this._then);

  final _ResolvedSearchCommand _self;
  final $Res Function(_ResolvedSearchCommand) _then;

/// Create a copy of ResolvedSearchCommand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? command = null,Object? state = null,}) {
  return _then(_ResolvedSearchCommand(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as SearchCommand,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SearchCommandState,
  ));
}

/// Create a copy of ResolvedSearchCommand
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchCommandStateCopyWith<$Res> get state {
  
  return $SearchCommandStateCopyWith<$Res>(_self.state, (value) {
    return _then(_self.copyWith(state: value));
  });
}
}

/// @nodoc
mixin _$SearchResultVisibility implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchResultVisibility'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultVisibility);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchResultVisibility()';
}


}

/// @nodoc
class $SearchResultVisibilityCopyWith<$Res>  {
$SearchResultVisibilityCopyWith(SearchResultVisibility _, $Res Function(SearchResultVisibility) __);
}


/// Adds pattern-matching-related methods to [SearchResultVisibility].
extension SearchResultVisibilityPatterns on SearchResultVisibility {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchResultVisible value)?  visible,TResult Function( SearchResultHidden value)?  hidden,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchResultVisible() when visible != null:
return visible(_that);case SearchResultHidden() when hidden != null:
return hidden(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchResultVisible value)  visible,required TResult Function( SearchResultHidden value)  hidden,}){
final _that = this;
switch (_that) {
case SearchResultVisible():
return visible(_that);case SearchResultHidden():
return hidden(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchResultVisible value)?  visible,TResult? Function( SearchResultHidden value)?  hidden,}){
final _that = this;
switch (_that) {
case SearchResultVisible() when visible != null:
return visible(_that);case SearchResultHidden() when hidden != null:
return hidden(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  visible,TResult Function()?  hidden,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchResultVisible() when visible != null:
return visible();case SearchResultHidden() when hidden != null:
return hidden();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  visible,required TResult Function()  hidden,}) {final _that = this;
switch (_that) {
case SearchResultVisible():
return visible();case SearchResultHidden():
return hidden();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  visible,TResult? Function()?  hidden,}) {final _that = this;
switch (_that) {
case SearchResultVisible() when visible != null:
return visible();case SearchResultHidden() when hidden != null:
return hidden();case _:
  return null;

}
}

}

/// @nodoc


class SearchResultVisible with DiagnosticableTreeMixin implements SearchResultVisibility {
  const SearchResultVisible();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchResultVisibility.visible'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultVisible);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchResultVisibility.visible()';
}


}




/// @nodoc


class SearchResultHidden with DiagnosticableTreeMixin implements SearchResultVisibility {
  const SearchResultHidden();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchResultVisibility.hidden'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultHidden);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchResultVisibility.hidden()';
}


}




/// @nodoc
mixin _$SearchActivationState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationState'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationState()';
}


}

/// @nodoc
class $SearchActivationStateCopyWith<$Res>  {
$SearchActivationStateCopyWith(SearchActivationState _, $Res Function(SearchActivationState) __);
}


/// Adds pattern-matching-related methods to [SearchActivationState].
extension SearchActivationStatePatterns on SearchActivationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchActivationHidden value)?  hidden,TResult Function( SearchActivationDisabled value)?  disabled,TResult Function( SearchActivationEnabled value)?  enabled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchActivationHidden() when hidden != null:
return hidden(_that);case SearchActivationDisabled() when disabled != null:
return disabled(_that);case SearchActivationEnabled() when enabled != null:
return enabled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchActivationHidden value)  hidden,required TResult Function( SearchActivationDisabled value)  disabled,required TResult Function( SearchActivationEnabled value)  enabled,}){
final _that = this;
switch (_that) {
case SearchActivationHidden():
return hidden(_that);case SearchActivationDisabled():
return disabled(_that);case SearchActivationEnabled():
return enabled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchActivationHidden value)?  hidden,TResult? Function( SearchActivationDisabled value)?  disabled,TResult? Function( SearchActivationEnabled value)?  enabled,}){
final _that = this;
switch (_that) {
case SearchActivationHidden() when hidden != null:
return hidden(_that);case SearchActivationDisabled() when disabled != null:
return disabled(_that);case SearchActivationEnabled() when enabled != null:
return enabled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  hidden,TResult Function( String reason)?  disabled,TResult Function()?  enabled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchActivationHidden() when hidden != null:
return hidden();case SearchActivationDisabled() when disabled != null:
return disabled(_that.reason);case SearchActivationEnabled() when enabled != null:
return enabled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  hidden,required TResult Function( String reason)  disabled,required TResult Function()  enabled,}) {final _that = this;
switch (_that) {
case SearchActivationHidden():
return hidden();case SearchActivationDisabled():
return disabled(_that.reason);case SearchActivationEnabled():
return enabled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  hidden,TResult? Function( String reason)?  disabled,TResult? Function()?  enabled,}) {final _that = this;
switch (_that) {
case SearchActivationHidden() when hidden != null:
return hidden();case SearchActivationDisabled() when disabled != null:
return disabled(_that.reason);case SearchActivationEnabled() when enabled != null:
return enabled();case _:
  return null;

}
}

}

/// @nodoc


class SearchActivationHidden with DiagnosticableTreeMixin implements SearchActivationState {
  const SearchActivationHidden();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationState.hidden'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationHidden);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationState.hidden()';
}


}




/// @nodoc


class SearchActivationDisabled with DiagnosticableTreeMixin implements SearchActivationState {
  const SearchActivationDisabled(this.reason): assert(reason != "", 'Disabled reason must not be empty.');
  

 final  String reason;

/// Create a copy of SearchActivationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActivationDisabledCopyWith<SearchActivationDisabled> get copyWith => _$SearchActivationDisabledCopyWithImpl<SearchActivationDisabled>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationState.disabled'))
    ..add(DiagnosticsProperty('reason', reason));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationDisabled&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationState.disabled(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $SearchActivationDisabledCopyWith<$Res> implements $SearchActivationStateCopyWith<$Res> {
  factory $SearchActivationDisabledCopyWith(SearchActivationDisabled value, $Res Function(SearchActivationDisabled) _then) = _$SearchActivationDisabledCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$SearchActivationDisabledCopyWithImpl<$Res>
    implements $SearchActivationDisabledCopyWith<$Res> {
  _$SearchActivationDisabledCopyWithImpl(this._self, this._then);

  final SearchActivationDisabled _self;
  final $Res Function(SearchActivationDisabled) _then;

/// Create a copy of SearchActivationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(SearchActivationDisabled(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SearchActivationEnabled with DiagnosticableTreeMixin implements SearchActivationState {
  const SearchActivationEnabled();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationState.enabled'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationEnabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationState.enabled()';
}


}




/// @nodoc
mixin _$SearchActivationResult<T> implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationResult<$T>'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationResult<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationResult<$T>()';
}


}

/// @nodoc
class $SearchActivationResultCopyWith<T,$Res>  {
$SearchActivationResultCopyWith(SearchActivationResult<T> _, $Res Function(SearchActivationResult<T>) __);
}


/// Adds pattern-matching-related methods to [SearchActivationResult].
extension SearchActivationResultPatterns<T> on SearchActivationResult<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchActivationComplete<T> value)?  complete,TResult Function( SearchActivationCommand<T> value)?  command,TResult Function( SearchActivationKeepOpen<T> value)?  keepOpen,TResult Function( SearchActivationCancelled<T> value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchActivationComplete() when complete != null:
return complete(_that);case SearchActivationCommand() when command != null:
return command(_that);case SearchActivationKeepOpen() when keepOpen != null:
return keepOpen(_that);case SearchActivationCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchActivationComplete<T> value)  complete,required TResult Function( SearchActivationCommand<T> value)  command,required TResult Function( SearchActivationKeepOpen<T> value)  keepOpen,required TResult Function( SearchActivationCancelled<T> value)  cancelled,}){
final _that = this;
switch (_that) {
case SearchActivationComplete():
return complete(_that);case SearchActivationCommand():
return command(_that);case SearchActivationKeepOpen():
return keepOpen(_that);case SearchActivationCancelled():
return cancelled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchActivationComplete<T> value)?  complete,TResult? Function( SearchActivationCommand<T> value)?  command,TResult? Function( SearchActivationKeepOpen<T> value)?  keepOpen,TResult? Function( SearchActivationCancelled<T> value)?  cancelled,}){
final _that = this;
switch (_that) {
case SearchActivationComplete() when complete != null:
return complete(_that);case SearchActivationCommand() when command != null:
return command(_that);case SearchActivationKeepOpen() when keepOpen != null:
return keepOpen(_that);case SearchActivationCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T value)?  complete,TResult Function( SearchCommandId id)?  command,TResult Function()?  keepOpen,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchActivationComplete() when complete != null:
return complete(_that.value);case SearchActivationCommand() when command != null:
return command(_that.id);case SearchActivationKeepOpen() when keepOpen != null:
return keepOpen();case SearchActivationCancelled() when cancelled != null:
return cancelled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T value)  complete,required TResult Function( SearchCommandId id)  command,required TResult Function()  keepOpen,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case SearchActivationComplete():
return complete(_that.value);case SearchActivationCommand():
return command(_that.id);case SearchActivationKeepOpen():
return keepOpen();case SearchActivationCancelled():
return cancelled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T value)?  complete,TResult? Function( SearchCommandId id)?  command,TResult? Function()?  keepOpen,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case SearchActivationComplete() when complete != null:
return complete(_that.value);case SearchActivationCommand() when command != null:
return command(_that.id);case SearchActivationKeepOpen() when keepOpen != null:
return keepOpen();case SearchActivationCancelled() when cancelled != null:
return cancelled();case _:
  return null;

}
}

}

/// @nodoc


class SearchActivationComplete<T> with DiagnosticableTreeMixin implements SearchActivationResult<T> {
  const SearchActivationComplete(this.value);
  

 final  T value;

/// Create a copy of SearchActivationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActivationCompleteCopyWith<T, SearchActivationComplete<T>> get copyWith => _$SearchActivationCompleteCopyWithImpl<T, SearchActivationComplete<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationResult<$T>.complete'))
    ..add(DiagnosticsProperty('value', value));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationComplete<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationResult<$T>.complete(value: $value)';
}


}

/// @nodoc
abstract mixin class $SearchActivationCompleteCopyWith<T,$Res> implements $SearchActivationResultCopyWith<T, $Res> {
  factory $SearchActivationCompleteCopyWith(SearchActivationComplete<T> value, $Res Function(SearchActivationComplete<T>) _then) = _$SearchActivationCompleteCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$SearchActivationCompleteCopyWithImpl<T,$Res>
    implements $SearchActivationCompleteCopyWith<T, $Res> {
  _$SearchActivationCompleteCopyWithImpl(this._self, this._then);

  final SearchActivationComplete<T> _self;
  final $Res Function(SearchActivationComplete<T>) _then;

/// Create a copy of SearchActivationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(SearchActivationComplete<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class SearchActivationCommand<T> with DiagnosticableTreeMixin implements SearchActivationResult<T> {
  const SearchActivationCommand(this.id);
  

 final  SearchCommandId id;

/// Create a copy of SearchActivationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActivationCommandCopyWith<T, SearchActivationCommand<T>> get copyWith => _$SearchActivationCommandCopyWithImpl<T, SearchActivationCommand<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationResult<$T>.command'))
    ..add(DiagnosticsProperty('id', id));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationCommand<T>&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationResult<$T>.command(id: $id)';
}


}

/// @nodoc
abstract mixin class $SearchActivationCommandCopyWith<T,$Res> implements $SearchActivationResultCopyWith<T, $Res> {
  factory $SearchActivationCommandCopyWith(SearchActivationCommand<T> value, $Res Function(SearchActivationCommand<T>) _then) = _$SearchActivationCommandCopyWithImpl;
@useResult
$Res call({
 SearchCommandId id
});


$SearchCommandIdCopyWith<$Res> get id;

}
/// @nodoc
class _$SearchActivationCommandCopyWithImpl<T,$Res>
    implements $SearchActivationCommandCopyWith<T, $Res> {
  _$SearchActivationCommandCopyWithImpl(this._self, this._then);

  final SearchActivationCommand<T> _self;
  final $Res Function(SearchActivationCommand<T>) _then;

/// Create a copy of SearchActivationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(SearchActivationCommand<T>(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as SearchCommandId,
  ));
}

/// Create a copy of SearchActivationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchCommandIdCopyWith<$Res> get id {
  
  return $SearchCommandIdCopyWith<$Res>(_self.id, (value) {
    return _then(_self.copyWith(id: value));
  });
}
}

/// @nodoc


class SearchActivationKeepOpen<T> with DiagnosticableTreeMixin implements SearchActivationResult<T> {
  const SearchActivationKeepOpen();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationResult<$T>.keepOpen'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationKeepOpen<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationResult<$T>.keepOpen()';
}


}




/// @nodoc


class SearchActivationCancelled<T> with DiagnosticableTreeMixin implements SearchActivationResult<T> {
  const SearchActivationCancelled();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationResult<$T>.cancelled'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationCancelled<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationResult<$T>.cancelled()';
}


}




/// @nodoc
mixin _$SearchCommandExecutionContext implements DiagnosticableTreeMixin {

 SearchPromptHost get prompts;
/// Create a copy of SearchCommandExecutionContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandExecutionContextCopyWith<SearchCommandExecutionContext> get copyWith => _$SearchCommandExecutionContextCopyWithImpl<SearchCommandExecutionContext>(this as SearchCommandExecutionContext, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchCommandExecutionContext;
  properties
    ..add(DiagnosticsProperty('type', 'SearchCommandExecutionContext'))
    ..add(DiagnosticsProperty('prompts', _this.prompts));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchCommandExecutionContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandExecutionContext&&(identical(other.prompts, _this.prompts) || other.prompts == _this.prompts));
}


@override
int get hashCode {
  final _this = this as SearchCommandExecutionContext;
  return Object.hash(runtimeType,_this.prompts);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchCommandExecutionContext;
  return 'SearchCommandExecutionContext(prompts: ${_this.prompts})';
}


}

/// @nodoc
abstract mixin class $SearchCommandExecutionContextCopyWith<$Res>  {
  factory $SearchCommandExecutionContextCopyWith(SearchCommandExecutionContext value, $Res Function(SearchCommandExecutionContext) _then) = _$SearchCommandExecutionContextCopyWithImpl;
@useResult
$Res call({
 SearchPromptHost prompts
});




}
/// @nodoc
class _$SearchCommandExecutionContextCopyWithImpl<$Res>
    implements $SearchCommandExecutionContextCopyWith<$Res> {
  _$SearchCommandExecutionContextCopyWithImpl(this._self, this._then);

  final SearchCommandExecutionContext _self;
  final $Res Function(SearchCommandExecutionContext) _then;

/// Create a copy of SearchCommandExecutionContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? prompts = null,}) {
  return _then(SearchCommandExecutionContext(
prompts: null == prompts ? _self.prompts : prompts // ignore: cast_nullable_to_non_nullable
as SearchPromptHost,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchCommandExecutionContext].
extension SearchCommandExecutionContextPatterns on SearchCommandExecutionContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchCommandExecutionContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchCommandExecutionContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchCommandExecutionContext value)  $default,){
final _that = this;
switch (_that) {
case _SearchCommandExecutionContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchCommandExecutionContext value)?  $default,){
final _that = this;
switch (_that) {
case _SearchCommandExecutionContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchPromptHost prompts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchCommandExecutionContext() when $default != null:
return $default(_that.prompts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchPromptHost prompts)  $default,) {final _that = this;
switch (_that) {
case _SearchCommandExecutionContext():
return $default(_that.prompts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchPromptHost prompts)?  $default,) {final _that = this;
switch (_that) {
case _SearchCommandExecutionContext() when $default != null:
return $default(_that.prompts);case _:
  return null;

}
}

}

/// @nodoc


class _SearchCommandExecutionContext with DiagnosticableTreeMixin implements SearchCommandExecutionContext {
  const _SearchCommandExecutionContext({required this.prompts});
  

@override final  SearchPromptHost prompts;

/// Create a copy of SearchCommandExecutionContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchCommandExecutionContextCopyWith<_SearchCommandExecutionContext> get copyWith => __$SearchCommandExecutionContextCopyWithImpl<_SearchCommandExecutionContext>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandExecutionContext'))
    ..add(DiagnosticsProperty('prompts', prompts));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchCommandExecutionContext&&(identical(other.prompts, prompts) || other.prompts == prompts));
}


@override
int get hashCode {
    return Object.hash(runtimeType,prompts);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandExecutionContext(prompts: $prompts)';
}


}

/// @nodoc
abstract mixin class _$SearchCommandExecutionContextCopyWith<$Res> implements $SearchCommandExecutionContextCopyWith<$Res> {
  factory _$SearchCommandExecutionContextCopyWith(_SearchCommandExecutionContext value, $Res Function(_SearchCommandExecutionContext) _then) = __$SearchCommandExecutionContextCopyWithImpl;
@override @useResult
$Res call({
 SearchPromptHost prompts
});




}
/// @nodoc
class __$SearchCommandExecutionContextCopyWithImpl<$Res>
    implements _$SearchCommandExecutionContextCopyWith<$Res> {
  __$SearchCommandExecutionContextCopyWithImpl(this._self, this._then);

  final _SearchCommandExecutionContext _self;
  final $Res Function(_SearchCommandExecutionContext) _then;

/// Create a copy of SearchCommandExecutionContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? prompts = null,}) {
  return _then(_SearchCommandExecutionContext(
prompts: null == prompts ? _self.prompts : prompts // ignore: cast_nullable_to_non_nullable
as SearchPromptHost,
  ));
}


}

/// @nodoc
mixin _$SearchActivationContext implements DiagnosticableTreeMixin {

 SearchPromptHost get prompts; SearchCommandDispatcher get commands; SearchQueryContext get query;
/// Create a copy of SearchActivationContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActivationContextCopyWith<SearchActivationContext> get copyWith => _$SearchActivationContextCopyWithImpl<SearchActivationContext>(this as SearchActivationContext, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchActivationContext;
  properties
    ..add(DiagnosticsProperty('type', 'SearchActivationContext'))
    ..add(DiagnosticsProperty('prompts', _this.prompts))..add(DiagnosticsProperty('commands', _this.commands))..add(DiagnosticsProperty('query', _this.query));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchActivationContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationContext&&(identical(other.prompts, _this.prompts) || other.prompts == _this.prompts)&&(identical(other.commands, _this.commands) || other.commands == _this.commands)&&(identical(other.query, _this.query) || other.query == _this.query));
}


@override
int get hashCode {
  final _this = this as SearchActivationContext;
  return Object.hash(runtimeType,_this.prompts,_this.commands,_this.query);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchActivationContext;
  return 'SearchActivationContext(prompts: ${_this.prompts}, commands: ${_this.commands}, query: ${_this.query})';
}


}

/// @nodoc
abstract mixin class $SearchActivationContextCopyWith<$Res>  {
  factory $SearchActivationContextCopyWith(SearchActivationContext value, $Res Function(SearchActivationContext) _then) = _$SearchActivationContextCopyWithImpl;
@useResult
$Res call({
 SearchPromptHost prompts, SearchCommandDispatcher commands, SearchQueryContext query
});


$SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$SearchActivationContextCopyWithImpl<$Res>
    implements $SearchActivationContextCopyWith<$Res> {
  _$SearchActivationContextCopyWithImpl(this._self, this._then);

  final SearchActivationContext _self;
  final $Res Function(SearchActivationContext) _then;

/// Create a copy of SearchActivationContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? prompts = null,Object? commands = null,Object? query = null,}) {
  return _then(SearchActivationContext(
prompts: null == prompts ? _self.prompts : prompts // ignore: cast_nullable_to_non_nullable
as SearchPromptHost,commands: null == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as SearchCommandDispatcher,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}
/// Create a copy of SearchActivationContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchActivationContext].
extension SearchActivationContextPatterns on SearchActivationContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchActivationContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchActivationContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchActivationContext value)  $default,){
final _that = this;
switch (_that) {
case _SearchActivationContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchActivationContext value)?  $default,){
final _that = this;
switch (_that) {
case _SearchActivationContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchPromptHost prompts,  SearchCommandDispatcher commands,  SearchQueryContext query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchActivationContext() when $default != null:
return $default(_that.prompts,_that.commands,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchPromptHost prompts,  SearchCommandDispatcher commands,  SearchQueryContext query)  $default,) {final _that = this;
switch (_that) {
case _SearchActivationContext():
return $default(_that.prompts,_that.commands,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchPromptHost prompts,  SearchCommandDispatcher commands,  SearchQueryContext query)?  $default,) {final _that = this;
switch (_that) {
case _SearchActivationContext() when $default != null:
return $default(_that.prompts,_that.commands,_that.query);case _:
  return null;

}
}

}

/// @nodoc


class _SearchActivationContext with DiagnosticableTreeMixin implements SearchActivationContext {
  const _SearchActivationContext({required this.prompts, required this.commands, required this.query});
  

@override final  SearchPromptHost prompts;
@override final  SearchCommandDispatcher commands;
@override final  SearchQueryContext query;

/// Create a copy of SearchActivationContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchActivationContextCopyWith<_SearchActivationContext> get copyWith => __$SearchActivationContextCopyWithImpl<_SearchActivationContext>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationContext'))
    ..add(DiagnosticsProperty('prompts', prompts))..add(DiagnosticsProperty('commands', commands))..add(DiagnosticsProperty('query', query));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchActivationContext&&(identical(other.prompts, prompts) || other.prompts == prompts)&&(identical(other.commands, commands) || other.commands == commands)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode {
    return Object.hash(runtimeType,prompts,commands,query);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationContext(prompts: $prompts, commands: $commands, query: $query)';
}


}

/// @nodoc
abstract mixin class _$SearchActivationContextCopyWith<$Res> implements $SearchActivationContextCopyWith<$Res> {
  factory _$SearchActivationContextCopyWith(_SearchActivationContext value, $Res Function(_SearchActivationContext) _then) = __$SearchActivationContextCopyWithImpl;
@override @useResult
$Res call({
 SearchPromptHost prompts, SearchCommandDispatcher commands, SearchQueryContext query
});


@override $SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class __$SearchActivationContextCopyWithImpl<$Res>
    implements _$SearchActivationContextCopyWith<$Res> {
  __$SearchActivationContextCopyWithImpl(this._self, this._then);

  final _SearchActivationContext _self;
  final $Res Function(_SearchActivationContext) _then;

/// Create a copy of SearchActivationContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? prompts = null,Object? commands = null,Object? query = null,}) {
  return _then(_SearchActivationContext(
prompts: null == prompts ? _self.prompts : prompts // ignore: cast_nullable_to_non_nullable
as SearchPromptHost,commands: null == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as SearchCommandDispatcher,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,
  ));
}

/// Create a copy of SearchActivationContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

/// @nodoc
mixin _$SearchActivationEvaluationContext implements DiagnosticableTreeMixin {

 SearchQueryContext get query; SearchCommandDispatcher get commands;
/// Create a copy of SearchActivationEvaluationContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchActivationEvaluationContextCopyWith<SearchActivationEvaluationContext> get copyWith => _$SearchActivationEvaluationContextCopyWithImpl<SearchActivationEvaluationContext>(this as SearchActivationEvaluationContext, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchActivationEvaluationContext;
  properties
    ..add(DiagnosticsProperty('type', 'SearchActivationEvaluationContext'))
    ..add(DiagnosticsProperty('query', _this.query))..add(DiagnosticsProperty('commands', _this.commands));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchActivationEvaluationContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchActivationEvaluationContext&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.commands, _this.commands) || other.commands == _this.commands));
}


@override
int get hashCode {
  final _this = this as SearchActivationEvaluationContext;
  return Object.hash(runtimeType,_this.query,_this.commands);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchActivationEvaluationContext;
  return 'SearchActivationEvaluationContext(query: ${_this.query}, commands: ${_this.commands})';
}


}

/// @nodoc
abstract mixin class $SearchActivationEvaluationContextCopyWith<$Res>  {
  factory $SearchActivationEvaluationContextCopyWith(SearchActivationEvaluationContext value, $Res Function(SearchActivationEvaluationContext) _then) = _$SearchActivationEvaluationContextCopyWithImpl;
@useResult
$Res call({
 SearchQueryContext query, SearchCommandDispatcher commands
});


$SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class _$SearchActivationEvaluationContextCopyWithImpl<$Res>
    implements $SearchActivationEvaluationContextCopyWith<$Res> {
  _$SearchActivationEvaluationContextCopyWithImpl(this._self, this._then);

  final SearchActivationEvaluationContext _self;
  final $Res Function(SearchActivationEvaluationContext) _then;

/// Create a copy of SearchActivationEvaluationContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? commands = null,}) {
  return _then(SearchActivationEvaluationContext(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,commands: null == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as SearchCommandDispatcher,
  ));
}
/// Create a copy of SearchActivationEvaluationContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchActivationEvaluationContext].
extension SearchActivationEvaluationContextPatterns on SearchActivationEvaluationContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchActivationEvaluationContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchActivationEvaluationContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchActivationEvaluationContext value)  $default,){
final _that = this;
switch (_that) {
case _SearchActivationEvaluationContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchActivationEvaluationContext value)?  $default,){
final _that = this;
switch (_that) {
case _SearchActivationEvaluationContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchQueryContext query,  SearchCommandDispatcher commands)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchActivationEvaluationContext() when $default != null:
return $default(_that.query,_that.commands);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchQueryContext query,  SearchCommandDispatcher commands)  $default,) {final _that = this;
switch (_that) {
case _SearchActivationEvaluationContext():
return $default(_that.query,_that.commands);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchQueryContext query,  SearchCommandDispatcher commands)?  $default,) {final _that = this;
switch (_that) {
case _SearchActivationEvaluationContext() when $default != null:
return $default(_that.query,_that.commands);case _:
  return null;

}
}

}

/// @nodoc


class _SearchActivationEvaluationContext with DiagnosticableTreeMixin implements SearchActivationEvaluationContext {
  const _SearchActivationEvaluationContext({required this.query, required this.commands});
  

@override final  SearchQueryContext query;
@override final  SearchCommandDispatcher commands;

/// Create a copy of SearchActivationEvaluationContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchActivationEvaluationContextCopyWith<_SearchActivationEvaluationContext> get copyWith => __$SearchActivationEvaluationContextCopyWithImpl<_SearchActivationEvaluationContext>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchActivationEvaluationContext'))
    ..add(DiagnosticsProperty('query', query))..add(DiagnosticsProperty('commands', commands));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchActivationEvaluationContext&&(identical(other.query, query) || other.query == query)&&(identical(other.commands, commands) || other.commands == commands));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,commands);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchActivationEvaluationContext(query: $query, commands: $commands)';
}


}

/// @nodoc
abstract mixin class _$SearchActivationEvaluationContextCopyWith<$Res> implements $SearchActivationEvaluationContextCopyWith<$Res> {
  factory _$SearchActivationEvaluationContextCopyWith(_SearchActivationEvaluationContext value, $Res Function(_SearchActivationEvaluationContext) _then) = __$SearchActivationEvaluationContextCopyWithImpl;
@override @useResult
$Res call({
 SearchQueryContext query, SearchCommandDispatcher commands
});


@override $SearchQueryContextCopyWith<$Res> get query;

}
/// @nodoc
class __$SearchActivationEvaluationContextCopyWithImpl<$Res>
    implements _$SearchActivationEvaluationContextCopyWith<$Res> {
  __$SearchActivationEvaluationContextCopyWithImpl(this._self, this._then);

  final _SearchActivationEvaluationContext _self;
  final $Res Function(_SearchActivationEvaluationContext) _then;

/// Create a copy of SearchActivationEvaluationContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? commands = null,}) {
  return _then(_SearchActivationEvaluationContext(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as SearchQueryContext,commands: null == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as SearchCommandDispatcher,
  ));
}

/// Create a copy of SearchActivationEvaluationContext
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchQueryContextCopyWith<$Res> get query {
  
  return $SearchQueryContextCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

/// @nodoc
mixin _$SearchInteraction<T> implements DiagnosticableTreeMixin {

 SearchActivation<T> get activation; SearchSelectionMode get selectionMode; List<SearchCommand> get commands;
/// Create a copy of SearchInteraction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchInteractionCopyWith<T, SearchInteraction<T>> get copyWith => _$SearchInteractionCopyWithImpl<T, SearchInteraction<T>>(this as SearchInteraction<T>, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchInteraction<T>;
  properties
    ..add(DiagnosticsProperty('type', 'SearchInteraction<$T>'))
    ..add(DiagnosticsProperty('activation', _this.activation))..add(DiagnosticsProperty('selectionMode', _this.selectionMode))..add(DiagnosticsProperty('commands', _this.commands));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchInteraction<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchInteraction<T>&&(identical(other.activation, _this.activation) || other.activation == _this.activation)&&(identical(other.selectionMode, _this.selectionMode) || other.selectionMode == _this.selectionMode)&&const DeepCollectionEquality().equals(other.commands, _this.commands));
}


@override
int get hashCode {
  final _this = this as SearchInteraction<T>;
  return Object.hash(runtimeType,_this.activation,_this.selectionMode,const DeepCollectionEquality().hash(_this.commands));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchInteraction<T>;
  return 'SearchInteraction<$T>(activation: ${_this.activation}, selectionMode: ${_this.selectionMode}, commands: ${_this.commands})';
}


}

/// @nodoc
abstract mixin class $SearchInteractionCopyWith<T,$Res>  {
  factory $SearchInteractionCopyWith(SearchInteraction<T> value, $Res Function(SearchInteraction<T>) _then) = _$SearchInteractionCopyWithImpl;
@useResult
$Res call({
 SearchActivation<T> activation, SearchSelectionMode selectionMode, List<SearchCommand> commands
});




}
/// @nodoc
class _$SearchInteractionCopyWithImpl<T,$Res>
    implements $SearchInteractionCopyWith<T, $Res> {
  _$SearchInteractionCopyWithImpl(this._self, this._then);

  final SearchInteraction<T> _self;
  final $Res Function(SearchInteraction<T>) _then;

/// Create a copy of SearchInteraction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activation = null,Object? selectionMode = null,Object? commands = null,}) {
  return _then(SearchInteraction(
activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as SearchActivation<T>,selectionMode: null == selectionMode ? _self.selectionMode : selectionMode // ignore: cast_nullable_to_non_nullable
as SearchSelectionMode,commands: null == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as List<SearchCommand>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchInteraction].
extension SearchInteractionPatterns<T> on SearchInteraction<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchInteraction<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchInteraction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchInteraction<T> value)  $default,){
final _that = this;
switch (_that) {
case _SearchInteraction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchInteraction<T> value)?  $default,){
final _that = this;
switch (_that) {
case _SearchInteraction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchActivation<T> activation,  SearchSelectionMode selectionMode,  List<SearchCommand> commands)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchInteraction() when $default != null:
return $default(_that.activation,_that.selectionMode,_that.commands);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchActivation<T> activation,  SearchSelectionMode selectionMode,  List<SearchCommand> commands)  $default,) {final _that = this;
switch (_that) {
case _SearchInteraction():
return $default(_that.activation,_that.selectionMode,_that.commands);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchActivation<T> activation,  SearchSelectionMode selectionMode,  List<SearchCommand> commands)?  $default,) {final _that = this;
switch (_that) {
case _SearchInteraction() when $default != null:
return $default(_that.activation,_that.selectionMode,_that.commands);case _:
  return null;

}
}

}

/// @nodoc


class _SearchInteraction<T> with DiagnosticableTreeMixin implements SearchInteraction<T> {
  const _SearchInteraction({required this.activation, required this.selectionMode,  List<SearchCommand> commands = const []}): _commands = commands;
  

@override final  SearchActivation<T> activation;
@override final  SearchSelectionMode selectionMode;
 final  List<SearchCommand> _commands;
@override@JsonKey() List<SearchCommand> get commands {
  if (_commands is EqualUnmodifiableListView) return _commands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_commands);
}


/// Create a copy of SearchInteraction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchInteractionCopyWith<T, _SearchInteraction<T>> get copyWith => __$SearchInteractionCopyWithImpl<T, _SearchInteraction<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchInteraction<$T>'))
    ..add(DiagnosticsProperty('activation', activation))..add(DiagnosticsProperty('selectionMode', selectionMode))..add(DiagnosticsProperty('commands', commands));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchInteraction<T>&&(identical(other.activation, activation) || other.activation == activation)&&(identical(other.selectionMode, selectionMode) || other.selectionMode == selectionMode)&&const DeepCollectionEquality().equals(other.commands, _commands));
}


@override
int get hashCode {
    return Object.hash(runtimeType,activation,selectionMode,const DeepCollectionEquality().hash(_commands));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchInteraction<$T>(activation: $activation, selectionMode: $selectionMode, commands: $commands)';
}


}

/// @nodoc
abstract mixin class _$SearchInteractionCopyWith<T,$Res> implements $SearchInteractionCopyWith<T, $Res> {
  factory _$SearchInteractionCopyWith(_SearchInteraction<T> value, $Res Function(_SearchInteraction<T>) _then) = __$SearchInteractionCopyWithImpl;
@override @useResult
$Res call({
 SearchActivation<T> activation, SearchSelectionMode selectionMode, List<SearchCommand> commands
});




}
/// @nodoc
class __$SearchInteractionCopyWithImpl<T,$Res>
    implements _$SearchInteractionCopyWith<T, $Res> {
  __$SearchInteractionCopyWithImpl(this._self, this._then);

  final _SearchInteraction<T> _self;
  final $Res Function(_SearchInteraction<T>) _then;

/// Create a copy of SearchInteraction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activation = null,Object? selectionMode = null,Object? commands = null,}) {
  return _then(_SearchInteraction<T>(
activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as SearchActivation<T>,selectionMode: null == selectionMode ? _self.selectionMode : selectionMode // ignore: cast_nullable_to_non_nullable
as SearchSelectionMode,commands: null == commands ? _self._commands : commands // ignore: cast_nullable_to_non_nullable
as List<SearchCommand>,
  ));
}


}

/// @nodoc
mixin _$SearchSession<T> implements DiagnosticableTreeMixin {

 SearchSource get source; SearchInteraction<T> get interaction; SearchScope get scope; String get initialQuery;
/// Create a copy of SearchSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSessionCopyWith<T, SearchSession<T>> get copyWith => _$SearchSessionCopyWithImpl<T, SearchSession<T>>(this as SearchSession<T>, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchSession<T>;
  properties
    ..add(DiagnosticsProperty('type', 'SearchSession<$T>'))
    ..add(DiagnosticsProperty('source', _this.source))..add(DiagnosticsProperty('interaction', _this.interaction))..add(DiagnosticsProperty('scope', _this.scope))..add(DiagnosticsProperty('initialQuery', _this.initialQuery));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchSession<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSession<T>&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.interaction, _this.interaction) || other.interaction == _this.interaction)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.initialQuery, _this.initialQuery) || other.initialQuery == _this.initialQuery));
}


@override
int get hashCode {
  final _this = this as SearchSession<T>;
  return Object.hash(runtimeType,_this.source,_this.interaction,_this.scope,_this.initialQuery);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchSession<T>;
  return 'SearchSession<$T>(source: ${_this.source}, interaction: ${_this.interaction}, scope: ${_this.scope}, initialQuery: ${_this.initialQuery})';
}


}

/// @nodoc
abstract mixin class $SearchSessionCopyWith<T,$Res>  {
  factory $SearchSessionCopyWith(SearchSession<T> value, $Res Function(SearchSession<T>) _then) = _$SearchSessionCopyWithImpl;
@useResult
$Res call({
 SearchSource source, SearchInteraction<T> interaction, SearchScope scope, String initialQuery
});


$SearchInteractionCopyWith<T, $Res> get interaction;

}
/// @nodoc
class _$SearchSessionCopyWithImpl<T,$Res>
    implements $SearchSessionCopyWith<T, $Res> {
  _$SearchSessionCopyWithImpl(this._self, this._then);

  final SearchSession<T> _self;
  final $Res Function(SearchSession<T>) _then;

/// Create a copy of SearchSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? interaction = null,Object? scope = null,Object? initialQuery = null,}) {
  return _then(SearchSession(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SearchSource,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as SearchInteraction<T>,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as SearchScope,initialQuery: null == initialQuery ? _self.initialQuery : initialQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SearchSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchInteractionCopyWith<T, $Res> get interaction {
  
  return $SearchInteractionCopyWith<T, $Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchSession].
extension SearchSessionPatterns<T> on SearchSession<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchSession<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchSession<T> value)  $default,){
final _that = this;
switch (_that) {
case _SearchSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchSession<T> value)?  $default,){
final _that = this;
switch (_that) {
case _SearchSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchSource source,  SearchInteraction<T> interaction,  SearchScope scope,  String initialQuery)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchSession() when $default != null:
return $default(_that.source,_that.interaction,_that.scope,_that.initialQuery);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchSource source,  SearchInteraction<T> interaction,  SearchScope scope,  String initialQuery)  $default,) {final _that = this;
switch (_that) {
case _SearchSession():
return $default(_that.source,_that.interaction,_that.scope,_that.initialQuery);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchSource source,  SearchInteraction<T> interaction,  SearchScope scope,  String initialQuery)?  $default,) {final _that = this;
switch (_that) {
case _SearchSession() when $default != null:
return $default(_that.source,_that.interaction,_that.scope,_that.initialQuery);case _:
  return null;

}
}

}

/// @nodoc


class _SearchSession<T> with DiagnosticableTreeMixin implements SearchSession<T> {
  const _SearchSession({required this.source, required this.interaction, this.scope = const AllSearchScope(), this.initialQuery = ""});
  

@override final  SearchSource source;
@override final  SearchInteraction<T> interaction;
@override@JsonKey() final  SearchScope scope;
@override@JsonKey() final  String initialQuery;

/// Create a copy of SearchSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchSessionCopyWith<T, _SearchSession<T>> get copyWith => __$SearchSessionCopyWithImpl<T, _SearchSession<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchSession<$T>'))
    ..add(DiagnosticsProperty('source', source))..add(DiagnosticsProperty('interaction', interaction))..add(DiagnosticsProperty('scope', scope))..add(DiagnosticsProperty('initialQuery', initialQuery));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchSession<T>&&(identical(other.source, source) || other.source == source)&&(identical(other.interaction, interaction) || other.interaction == interaction)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.initialQuery, initialQuery) || other.initialQuery == initialQuery));
}


@override
int get hashCode {
    return Object.hash(runtimeType,source,interaction,scope,initialQuery);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchSession<$T>(source: $source, interaction: $interaction, scope: $scope, initialQuery: $initialQuery)';
}


}

/// @nodoc
abstract mixin class _$SearchSessionCopyWith<T,$Res> implements $SearchSessionCopyWith<T, $Res> {
  factory _$SearchSessionCopyWith(_SearchSession<T> value, $Res Function(_SearchSession<T>) _then) = __$SearchSessionCopyWithImpl;
@override @useResult
$Res call({
 SearchSource source, SearchInteraction<T> interaction, SearchScope scope, String initialQuery
});


@override $SearchInteractionCopyWith<T, $Res> get interaction;

}
/// @nodoc
class __$SearchSessionCopyWithImpl<T,$Res>
    implements _$SearchSessionCopyWith<T, $Res> {
  __$SearchSessionCopyWithImpl(this._self, this._then);

  final _SearchSession<T> _self;
  final $Res Function(_SearchSession<T>) _then;

/// Create a copy of SearchSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? interaction = null,Object? scope = null,Object? initialQuery = null,}) {
  return _then(_SearchSession<T>(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SearchSource,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as SearchInteraction<T>,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as SearchScope,initialQuery: null == initialQuery ? _self.initialQuery : initialQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SearchSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchInteractionCopyWith<T, $Res> get interaction {
  
  return $SearchInteractionCopyWith<T, $Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}
}

/// @nodoc
mixin _$SearchCommandResult implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandResult'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandResult()';
}


}

/// @nodoc
class $SearchCommandResultCopyWith<$Res>  {
$SearchCommandResultCopyWith(SearchCommandResult _, $Res Function(SearchCommandResult) __);
}


/// Adds pattern-matching-related methods to [SearchCommandResult].
extension SearchCommandResultPatterns on SearchCommandResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchCommandResultCompleted value)?  completed,TResult Function( SearchCommandResultFailed value)?  failed,TResult Function( SearchCommandResultCancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchCommandResultCompleted() when completed != null:
return completed(_that);case SearchCommandResultFailed() when failed != null:
return failed(_that);case SearchCommandResultCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchCommandResultCompleted value)  completed,required TResult Function( SearchCommandResultFailed value)  failed,required TResult Function( SearchCommandResultCancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case SearchCommandResultCompleted():
return completed(_that);case SearchCommandResultFailed():
return failed(_that);case SearchCommandResultCancelled():
return cancelled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchCommandResultCompleted value)?  completed,TResult? Function( SearchCommandResultFailed value)?  failed,TResult? Function( SearchCommandResultCancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case SearchCommandResultCompleted() when completed != null:
return completed(_that);case SearchCommandResultFailed() when failed != null:
return failed(_that);case SearchCommandResultCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SearchSurfaceEffect surfaceEffect,  List<SearchHostEffect> hostEffects)?  completed,TResult Function( String message,  SearchSurfaceEffect surfaceEffect)?  failed,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchCommandResultCompleted() when completed != null:
return completed(_that.surfaceEffect,_that.hostEffects);case SearchCommandResultFailed() when failed != null:
return failed(_that.message,_that.surfaceEffect);case SearchCommandResultCancelled() when cancelled != null:
return cancelled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SearchSurfaceEffect surfaceEffect,  List<SearchHostEffect> hostEffects)  completed,required TResult Function( String message,  SearchSurfaceEffect surfaceEffect)  failed,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case SearchCommandResultCompleted():
return completed(_that.surfaceEffect,_that.hostEffects);case SearchCommandResultFailed():
return failed(_that.message,_that.surfaceEffect);case SearchCommandResultCancelled():
return cancelled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SearchSurfaceEffect surfaceEffect,  List<SearchHostEffect> hostEffects)?  completed,TResult? Function( String message,  SearchSurfaceEffect surfaceEffect)?  failed,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case SearchCommandResultCompleted() when completed != null:
return completed(_that.surfaceEffect,_that.hostEffects);case SearchCommandResultFailed() when failed != null:
return failed(_that.message,_that.surfaceEffect);case SearchCommandResultCancelled() when cancelled != null:
return cancelled();case _:
  return null;

}
}

}

/// @nodoc


class SearchCommandResultCompleted with DiagnosticableTreeMixin implements SearchCommandResult {
  const SearchCommandResultCompleted({this.surfaceEffect = const SearchSurfaceEffect.close(),  List<SearchHostEffect> hostEffects = const []}): _hostEffects = hostEffects;
  

@JsonKey() final  SearchSurfaceEffect surfaceEffect;
 final  List<SearchHostEffect> _hostEffects;
@JsonKey() List<SearchHostEffect> get hostEffects {
  if (_hostEffects is EqualUnmodifiableListView) return _hostEffects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hostEffects);
}


/// Create a copy of SearchCommandResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandResultCompletedCopyWith<SearchCommandResultCompleted> get copyWith => _$SearchCommandResultCompletedCopyWithImpl<SearchCommandResultCompleted>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandResult.completed'))
    ..add(DiagnosticsProperty('surfaceEffect', surfaceEffect))..add(DiagnosticsProperty('hostEffects', hostEffects));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandResultCompleted&&(identical(other.surfaceEffect, surfaceEffect) || other.surfaceEffect == surfaceEffect)&&const DeepCollectionEquality().equals(other.hostEffects, _hostEffects));
}


@override
int get hashCode {
    return Object.hash(runtimeType,surfaceEffect,const DeepCollectionEquality().hash(_hostEffects));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandResult.completed(surfaceEffect: $surfaceEffect, hostEffects: $hostEffects)';
}


}

/// @nodoc
abstract mixin class $SearchCommandResultCompletedCopyWith<$Res> implements $SearchCommandResultCopyWith<$Res> {
  factory $SearchCommandResultCompletedCopyWith(SearchCommandResultCompleted value, $Res Function(SearchCommandResultCompleted) _then) = _$SearchCommandResultCompletedCopyWithImpl;
@useResult
$Res call({
 SearchSurfaceEffect surfaceEffect, List<SearchHostEffect> hostEffects
});


$SearchSurfaceEffectCopyWith<$Res> get surfaceEffect;

}
/// @nodoc
class _$SearchCommandResultCompletedCopyWithImpl<$Res>
    implements $SearchCommandResultCompletedCopyWith<$Res> {
  _$SearchCommandResultCompletedCopyWithImpl(this._self, this._then);

  final SearchCommandResultCompleted _self;
  final $Res Function(SearchCommandResultCompleted) _then;

/// Create a copy of SearchCommandResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surfaceEffect = null,Object? hostEffects = null,}) {
  return _then(SearchCommandResultCompleted(
surfaceEffect: null == surfaceEffect ? _self.surfaceEffect : surfaceEffect // ignore: cast_nullable_to_non_nullable
as SearchSurfaceEffect,hostEffects: null == hostEffects ? _self._hostEffects : hostEffects // ignore: cast_nullable_to_non_nullable
as List<SearchHostEffect>,
  ));
}

/// Create a copy of SearchCommandResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSurfaceEffectCopyWith<$Res> get surfaceEffect {
  
  return $SearchSurfaceEffectCopyWith<$Res>(_self.surfaceEffect, (value) {
    return _then(_self.copyWith(surfaceEffect: value));
  });
}
}

/// @nodoc


class SearchCommandResultFailed with DiagnosticableTreeMixin implements SearchCommandResult {
  const SearchCommandResultFailed({required this.message, this.surfaceEffect = const SearchSurfaceEffect.refresh()}): assert(message != "", 'Message must not be empty.');
  

 final  String message;
@JsonKey() final  SearchSurfaceEffect surfaceEffect;

/// Create a copy of SearchCommandResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandResultFailedCopyWith<SearchCommandResultFailed> get copyWith => _$SearchCommandResultFailedCopyWithImpl<SearchCommandResultFailed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandResult.failed'))
    ..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('surfaceEffect', surfaceEffect));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandResultFailed&&(identical(other.message, message) || other.message == message)&&(identical(other.surfaceEffect, surfaceEffect) || other.surfaceEffect == surfaceEffect));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,surfaceEffect);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandResult.failed(message: $message, surfaceEffect: $surfaceEffect)';
}


}

/// @nodoc
abstract mixin class $SearchCommandResultFailedCopyWith<$Res> implements $SearchCommandResultCopyWith<$Res> {
  factory $SearchCommandResultFailedCopyWith(SearchCommandResultFailed value, $Res Function(SearchCommandResultFailed) _then) = _$SearchCommandResultFailedCopyWithImpl;
@useResult
$Res call({
 String message, SearchSurfaceEffect surfaceEffect
});


$SearchSurfaceEffectCopyWith<$Res> get surfaceEffect;

}
/// @nodoc
class _$SearchCommandResultFailedCopyWithImpl<$Res>
    implements $SearchCommandResultFailedCopyWith<$Res> {
  _$SearchCommandResultFailedCopyWithImpl(this._self, this._then);

  final SearchCommandResultFailed _self;
  final $Res Function(SearchCommandResultFailed) _then;

/// Create a copy of SearchCommandResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? surfaceEffect = null,}) {
  return _then(SearchCommandResultFailed(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,surfaceEffect: null == surfaceEffect ? _self.surfaceEffect : surfaceEffect // ignore: cast_nullable_to_non_nullable
as SearchSurfaceEffect,
  ));
}

/// Create a copy of SearchCommandResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSurfaceEffectCopyWith<$Res> get surfaceEffect {
  
  return $SearchSurfaceEffectCopyWith<$Res>(_self.surfaceEffect, (value) {
    return _then(_self.copyWith(surfaceEffect: value));
  });
}
}

/// @nodoc


class SearchCommandResultCancelled with DiagnosticableTreeMixin implements SearchCommandResult {
  const SearchCommandResultCancelled();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandResult.cancelled'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandResultCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandResult.cancelled()';
}


}




/// @nodoc
mixin _$SearchCommandExecutionState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandExecutionState'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandExecutionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandExecutionState()';
}


}

/// @nodoc
class $SearchCommandExecutionStateCopyWith<$Res>  {
$SearchCommandExecutionStateCopyWith(SearchCommandExecutionState _, $Res Function(SearchCommandExecutionState) __);
}


/// Adds pattern-matching-related methods to [SearchCommandExecutionState].
extension SearchCommandExecutionStatePatterns on SearchCommandExecutionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchCommandIdle value)?  idle,TResult Function( SearchCommandRunning value)?  running,TResult Function( SearchCommandCompleted value)?  completed,TResult Function( SearchCommandFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchCommandIdle() when idle != null:
return idle(_that);case SearchCommandRunning() when running != null:
return running(_that);case SearchCommandCompleted() when completed != null:
return completed(_that);case SearchCommandFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchCommandIdle value)  idle,required TResult Function( SearchCommandRunning value)  running,required TResult Function( SearchCommandCompleted value)  completed,required TResult Function( SearchCommandFailed value)  failed,}){
final _that = this;
switch (_that) {
case SearchCommandIdle():
return idle(_that);case SearchCommandRunning():
return running(_that);case SearchCommandCompleted():
return completed(_that);case SearchCommandFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchCommandIdle value)?  idle,TResult? Function( SearchCommandRunning value)?  running,TResult? Function( SearchCommandCompleted value)?  completed,TResult? Function( SearchCommandFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SearchCommandIdle() when idle != null:
return idle(_that);case SearchCommandRunning() when running != null:
return running(_that);case SearchCommandCompleted() when completed != null:
return completed(_that);case SearchCommandFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( SearchCommandId command,  Set<String> resultIds)?  running,TResult Function( SearchCommandId command,  Set<String> resultIds)?  completed,TResult Function( SearchCommandId command,  Set<String> resultIds,  String message)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchCommandIdle() when idle != null:
return idle();case SearchCommandRunning() when running != null:
return running(_that.command,_that.resultIds);case SearchCommandCompleted() when completed != null:
return completed(_that.command,_that.resultIds);case SearchCommandFailed() when failed != null:
return failed(_that.command,_that.resultIds,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( SearchCommandId command,  Set<String> resultIds)  running,required TResult Function( SearchCommandId command,  Set<String> resultIds)  completed,required TResult Function( SearchCommandId command,  Set<String> resultIds,  String message)  failed,}) {final _that = this;
switch (_that) {
case SearchCommandIdle():
return idle();case SearchCommandRunning():
return running(_that.command,_that.resultIds);case SearchCommandCompleted():
return completed(_that.command,_that.resultIds);case SearchCommandFailed():
return failed(_that.command,_that.resultIds,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( SearchCommandId command,  Set<String> resultIds)?  running,TResult? Function( SearchCommandId command,  Set<String> resultIds)?  completed,TResult? Function( SearchCommandId command,  Set<String> resultIds,  String message)?  failed,}) {final _that = this;
switch (_that) {
case SearchCommandIdle() when idle != null:
return idle();case SearchCommandRunning() when running != null:
return running(_that.command,_that.resultIds);case SearchCommandCompleted() when completed != null:
return completed(_that.command,_that.resultIds);case SearchCommandFailed() when failed != null:
return failed(_that.command,_that.resultIds,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SearchCommandIdle with DiagnosticableTreeMixin implements SearchCommandExecutionState {
  const SearchCommandIdle();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandExecutionState.idle'))
    ;
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandExecutionState.idle()';
}


}




/// @nodoc


class SearchCommandRunning with DiagnosticableTreeMixin implements SearchCommandExecutionState {
  const SearchCommandRunning({required this.command, required  Set<String> resultIds}): assert(resultIds.length > 0, 'Result IDs must not be empty.'),_resultIds = resultIds;
  

 final  SearchCommandId command;
 final  Set<String> _resultIds;
 Set<String> get resultIds {
  if (_resultIds is EqualUnmodifiableSetView) return _resultIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resultIds);
}


/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandRunningCopyWith<SearchCommandRunning> get copyWith => _$SearchCommandRunningCopyWithImpl<SearchCommandRunning>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandExecutionState.running'))
    ..add(DiagnosticsProperty('command', command))..add(DiagnosticsProperty('resultIds', resultIds));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandRunning&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other.resultIds, _resultIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,command,const DeepCollectionEquality().hash(_resultIds));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandExecutionState.running(command: $command, resultIds: $resultIds)';
}


}

/// @nodoc
abstract mixin class $SearchCommandRunningCopyWith<$Res> implements $SearchCommandExecutionStateCopyWith<$Res> {
  factory $SearchCommandRunningCopyWith(SearchCommandRunning value, $Res Function(SearchCommandRunning) _then) = _$SearchCommandRunningCopyWithImpl;
@useResult
$Res call({
 SearchCommandId command, Set<String> resultIds
});


$SearchCommandIdCopyWith<$Res> get command;

}
/// @nodoc
class _$SearchCommandRunningCopyWithImpl<$Res>
    implements $SearchCommandRunningCopyWith<$Res> {
  _$SearchCommandRunningCopyWithImpl(this._self, this._then);

  final SearchCommandRunning _self;
  final $Res Function(SearchCommandRunning) _then;

/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? command = null,Object? resultIds = null,}) {
  return _then(SearchCommandRunning(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as SearchCommandId,resultIds: null == resultIds ? _self._resultIds : resultIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchCommandIdCopyWith<$Res> get command {
  
  return $SearchCommandIdCopyWith<$Res>(_self.command, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}

/// @nodoc


class SearchCommandCompleted with DiagnosticableTreeMixin implements SearchCommandExecutionState {
  const SearchCommandCompleted({required this.command, required  Set<String> resultIds}): assert(resultIds.length > 0, 'Result IDs must not be empty.'),_resultIds = resultIds;
  

 final  SearchCommandId command;
 final  Set<String> _resultIds;
 Set<String> get resultIds {
  if (_resultIds is EqualUnmodifiableSetView) return _resultIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resultIds);
}


/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandCompletedCopyWith<SearchCommandCompleted> get copyWith => _$SearchCommandCompletedCopyWithImpl<SearchCommandCompleted>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandExecutionState.completed'))
    ..add(DiagnosticsProperty('command', command))..add(DiagnosticsProperty('resultIds', resultIds));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandCompleted&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other.resultIds, _resultIds));
}


@override
int get hashCode {
    return Object.hash(runtimeType,command,const DeepCollectionEquality().hash(_resultIds));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandExecutionState.completed(command: $command, resultIds: $resultIds)';
}


}

/// @nodoc
abstract mixin class $SearchCommandCompletedCopyWith<$Res> implements $SearchCommandExecutionStateCopyWith<$Res> {
  factory $SearchCommandCompletedCopyWith(SearchCommandCompleted value, $Res Function(SearchCommandCompleted) _then) = _$SearchCommandCompletedCopyWithImpl;
@useResult
$Res call({
 SearchCommandId command, Set<String> resultIds
});


$SearchCommandIdCopyWith<$Res> get command;

}
/// @nodoc
class _$SearchCommandCompletedCopyWithImpl<$Res>
    implements $SearchCommandCompletedCopyWith<$Res> {
  _$SearchCommandCompletedCopyWithImpl(this._self, this._then);

  final SearchCommandCompleted _self;
  final $Res Function(SearchCommandCompleted) _then;

/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? command = null,Object? resultIds = null,}) {
  return _then(SearchCommandCompleted(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as SearchCommandId,resultIds: null == resultIds ? _self._resultIds : resultIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchCommandIdCopyWith<$Res> get command {
  
  return $SearchCommandIdCopyWith<$Res>(_self.command, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}

/// @nodoc


class SearchCommandFailed with DiagnosticableTreeMixin implements SearchCommandExecutionState {
  const SearchCommandFailed({required this.command, required  Set<String> resultIds, required this.message}): assert(resultIds.length > 0, 'Result IDs must not be empty.'),assert(message != "", 'Message must not be empty.'),_resultIds = resultIds;
  

 final  SearchCommandId command;
 final  Set<String> _resultIds;
 Set<String> get resultIds {
  if (_resultIds is EqualUnmodifiableSetView) return _resultIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_resultIds);
}

 final  String message;

/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchCommandFailedCopyWith<SearchCommandFailed> get copyWith => _$SearchCommandFailedCopyWithImpl<SearchCommandFailed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchCommandExecutionState.failed'))
    ..add(DiagnosticsProperty('command', command))..add(DiagnosticsProperty('resultIds', resultIds))..add(DiagnosticsProperty('message', message));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchCommandFailed&&(identical(other.command, command) || other.command == command)&&const DeepCollectionEquality().equals(other.resultIds, _resultIds)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,command,const DeepCollectionEquality().hash(_resultIds),message);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchCommandExecutionState.failed(command: $command, resultIds: $resultIds, message: $message)';
}


}

/// @nodoc
abstract mixin class $SearchCommandFailedCopyWith<$Res> implements $SearchCommandExecutionStateCopyWith<$Res> {
  factory $SearchCommandFailedCopyWith(SearchCommandFailed value, $Res Function(SearchCommandFailed) _then) = _$SearchCommandFailedCopyWithImpl;
@useResult
$Res call({
 SearchCommandId command, Set<String> resultIds, String message
});


$SearchCommandIdCopyWith<$Res> get command;

}
/// @nodoc
class _$SearchCommandFailedCopyWithImpl<$Res>
    implements $SearchCommandFailedCopyWith<$Res> {
  _$SearchCommandFailedCopyWithImpl(this._self, this._then);

  final SearchCommandFailed _self;
  final $Res Function(SearchCommandFailed) _then;

/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? command = null,Object? resultIds = null,Object? message = null,}) {
  return _then(SearchCommandFailed(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as SearchCommandId,resultIds: null == resultIds ? _self._resultIds : resultIds // ignore: cast_nullable_to_non_nullable
as Set<String>,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SearchCommandExecutionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchCommandIdCopyWith<$Res> get command {
  
  return $SearchCommandIdCopyWith<$Res>(_self.command, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}

/// @nodoc
mixin _$SearchContribution<T> implements DiagnosticableTreeMixin {

 SearchSession<T> get session; List<QuerySelectorDefinition> get baseSelectors; List<SearchHostEffectExecutor<SearchHostEffect>> get hostEffectExecutors;
/// Create a copy of SearchContribution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchContributionCopyWith<T, SearchContribution<T>> get copyWith => _$SearchContributionCopyWithImpl<T, SearchContribution<T>>(this as SearchContribution<T>, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as SearchContribution<T>;
  properties
    ..add(DiagnosticsProperty('type', 'SearchContribution<$T>'))
    ..add(DiagnosticsProperty('session', _this.session))..add(DiagnosticsProperty('baseSelectors', _this.baseSelectors))..add(DiagnosticsProperty('hostEffectExecutors', _this.hostEffectExecutors));
}

@override
bool operator ==(Object other) {
  final _this = this as SearchContribution<T>;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchContribution<T>&&(identical(other.session, _this.session) || other.session == _this.session)&&const DeepCollectionEquality().equals(other.baseSelectors, _this.baseSelectors)&&const DeepCollectionEquality().equals(other.hostEffectExecutors, _this.hostEffectExecutors));
}


@override
int get hashCode {
  final _this = this as SearchContribution<T>;
  return Object.hash(runtimeType,_this.session,const DeepCollectionEquality().hash(_this.baseSelectors),const DeepCollectionEquality().hash(_this.hostEffectExecutors));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as SearchContribution<T>;
  return 'SearchContribution<$T>(session: ${_this.session}, baseSelectors: ${_this.baseSelectors}, hostEffectExecutors: ${_this.hostEffectExecutors})';
}


}

/// @nodoc
abstract mixin class $SearchContributionCopyWith<T,$Res>  {
  factory $SearchContributionCopyWith(SearchContribution<T> value, $Res Function(SearchContribution<T>) _then) = _$SearchContributionCopyWithImpl;
@useResult
$Res call({
 SearchSession<T> session, List<QuerySelectorDefinition> baseSelectors, List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors
});


$SearchSessionCopyWith<T, $Res> get session;

}
/// @nodoc
class _$SearchContributionCopyWithImpl<T,$Res>
    implements $SearchContributionCopyWith<T, $Res> {
  _$SearchContributionCopyWithImpl(this._self, this._then);

  final SearchContribution<T> _self;
  final $Res Function(SearchContribution<T>) _then;

/// Create a copy of SearchContribution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? baseSelectors = null,Object? hostEffectExecutors = null,}) {
  return _then(SearchContribution(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SearchSession<T>,baseSelectors: null == baseSelectors ? _self.baseSelectors : baseSelectors // ignore: cast_nullable_to_non_nullable
as List<QuerySelectorDefinition>,hostEffectExecutors: null == hostEffectExecutors ? _self.hostEffectExecutors : hostEffectExecutors // ignore: cast_nullable_to_non_nullable
as List<SearchHostEffectExecutor<SearchHostEffect>>,
  ));
}
/// Create a copy of SearchContribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSessionCopyWith<T, $Res> get session {
  
  return $SearchSessionCopyWith<T, $Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchContribution].
extension SearchContributionPatterns<T> on SearchContribution<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchContribution<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchContribution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchContribution<T> value)  $default,){
final _that = this;
switch (_that) {
case _SearchContribution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchContribution<T> value)?  $default,){
final _that = this;
switch (_that) {
case _SearchContribution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchSession<T> session,  List<QuerySelectorDefinition> baseSelectors,  List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchContribution() when $default != null:
return $default(_that.session,_that.baseSelectors,_that.hostEffectExecutors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchSession<T> session,  List<QuerySelectorDefinition> baseSelectors,  List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors)  $default,) {final _that = this;
switch (_that) {
case _SearchContribution():
return $default(_that.session,_that.baseSelectors,_that.hostEffectExecutors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchSession<T> session,  List<QuerySelectorDefinition> baseSelectors,  List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors)?  $default,) {final _that = this;
switch (_that) {
case _SearchContribution() when $default != null:
return $default(_that.session,_that.baseSelectors,_that.hostEffectExecutors);case _:
  return null;

}
}

}

/// @nodoc


class _SearchContribution<T> with DiagnosticableTreeMixin implements SearchContribution<T> {
  const _SearchContribution({required this.session,  List<QuerySelectorDefinition> baseSelectors = const [],  List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors = const []}): _baseSelectors = baseSelectors,_hostEffectExecutors = hostEffectExecutors;
  

@override final  SearchSession<T> session;
 final  List<QuerySelectorDefinition> _baseSelectors;
@override@JsonKey() List<QuerySelectorDefinition> get baseSelectors {
  if (_baseSelectors is EqualUnmodifiableListView) return _baseSelectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_baseSelectors);
}

 final  List<SearchHostEffectExecutor<SearchHostEffect>> _hostEffectExecutors;
@override@JsonKey() List<SearchHostEffectExecutor<SearchHostEffect>> get hostEffectExecutors {
  if (_hostEffectExecutors is EqualUnmodifiableListView) return _hostEffectExecutors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hostEffectExecutors);
}


/// Create a copy of SearchContribution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchContributionCopyWith<T, _SearchContribution<T>> get copyWith => __$SearchContributionCopyWithImpl<T, _SearchContribution<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'SearchContribution<$T>'))
    ..add(DiagnosticsProperty('session', session))..add(DiagnosticsProperty('baseSelectors', baseSelectors))..add(DiagnosticsProperty('hostEffectExecutors', hostEffectExecutors));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchContribution<T>&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other.baseSelectors, _baseSelectors)&&const DeepCollectionEquality().equals(other.hostEffectExecutors, _hostEffectExecutors));
}


@override
int get hashCode {
    return Object.hash(runtimeType,session,const DeepCollectionEquality().hash(_baseSelectors),const DeepCollectionEquality().hash(_hostEffectExecutors));
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'SearchContribution<$T>(session: $session, baseSelectors: $baseSelectors, hostEffectExecutors: $hostEffectExecutors)';
}


}

/// @nodoc
abstract mixin class _$SearchContributionCopyWith<T,$Res> implements $SearchContributionCopyWith<T, $Res> {
  factory _$SearchContributionCopyWith(_SearchContribution<T> value, $Res Function(_SearchContribution<T>) _then) = __$SearchContributionCopyWithImpl;
@override @useResult
$Res call({
 SearchSession<T> session, List<QuerySelectorDefinition> baseSelectors, List<SearchHostEffectExecutor<SearchHostEffect>> hostEffectExecutors
});


@override $SearchSessionCopyWith<T, $Res> get session;

}
/// @nodoc
class __$SearchContributionCopyWithImpl<T,$Res>
    implements _$SearchContributionCopyWith<T, $Res> {
  __$SearchContributionCopyWithImpl(this._self, this._then);

  final _SearchContribution<T> _self;
  final $Res Function(_SearchContribution<T>) _then;

/// Create a copy of SearchContribution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? baseSelectors = null,Object? hostEffectExecutors = null,}) {
  return _then(_SearchContribution<T>(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SearchSession<T>,baseSelectors: null == baseSelectors ? _self._baseSelectors : baseSelectors // ignore: cast_nullable_to_non_nullable
as List<QuerySelectorDefinition>,hostEffectExecutors: null == hostEffectExecutors ? _self._hostEffectExecutors : hostEffectExecutors // ignore: cast_nullable_to_non_nullable
as List<SearchHostEffectExecutor<SearchHostEffect>>,
  ));
}

/// Create a copy of SearchContribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSessionCopyWith<T, $Res> get session {
  
  return $SearchSessionCopyWith<T, $Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
