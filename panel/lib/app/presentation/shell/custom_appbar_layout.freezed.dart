// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_appbar_layout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppBarItemMeasurement {

 AppBarItemPolicy get policy; double get width;
/// Create a copy of AppBarItemMeasurement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppBarItemMeasurementCopyWith<AppBarItemMeasurement> get copyWith => _$AppBarItemMeasurementCopyWithImpl<AppBarItemMeasurement>(this as AppBarItemMeasurement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppBarItemMeasurement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppBarItemMeasurement&&(identical(other.policy, _this.policy) || other.policy == _this.policy)&&(identical(other.width, _this.width) || other.width == _this.width));
}


@override
int get hashCode {
  final _this = this as AppBarItemMeasurement;
  return Object.hash(runtimeType,_this.policy,_this.width);
}

@override
String toString() {
  final _this = this as AppBarItemMeasurement;
  return 'AppBarItemMeasurement(policy: ${_this.policy}, width: ${_this.width})';
}


}

/// @nodoc
abstract mixin class $AppBarItemMeasurementCopyWith<$Res>  {
  factory $AppBarItemMeasurementCopyWith(AppBarItemMeasurement value, $Res Function(AppBarItemMeasurement) _then) = _$AppBarItemMeasurementCopyWithImpl;
@useResult
$Res call({
 AppBarItemPolicy policy, double width
});


$AppBarItemPolicyCopyWith<$Res> get policy;

}
/// @nodoc
class _$AppBarItemMeasurementCopyWithImpl<$Res>
    implements $AppBarItemMeasurementCopyWith<$Res> {
  _$AppBarItemMeasurementCopyWithImpl(this._self, this._then);

  final AppBarItemMeasurement _self;
  final $Res Function(AppBarItemMeasurement) _then;

/// Create a copy of AppBarItemMeasurement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? policy = null,Object? width = null,}) {
  return _then(AppBarItemMeasurement(
policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as AppBarItemPolicy,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of AppBarItemMeasurement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBarItemPolicyCopyWith<$Res> get policy {
  
  return $AppBarItemPolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppBarItemMeasurement].
extension AppBarItemMeasurementPatterns on AppBarItemMeasurement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppBarItemMeasurement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppBarItemMeasurement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppBarItemMeasurement value)  $default,){
final _that = this;
switch (_that) {
case _AppBarItemMeasurement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppBarItemMeasurement value)?  $default,){
final _that = this;
switch (_that) {
case _AppBarItemMeasurement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppBarItemPolicy policy,  double width)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppBarItemMeasurement() when $default != null:
return $default(_that.policy,_that.width);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppBarItemPolicy policy,  double width)  $default,) {final _that = this;
switch (_that) {
case _AppBarItemMeasurement():
return $default(_that.policy,_that.width);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppBarItemPolicy policy,  double width)?  $default,) {final _that = this;
switch (_that) {
case _AppBarItemMeasurement() when $default != null:
return $default(_that.policy,_that.width);case _:
  return null;

}
}

}

/// @nodoc


class _AppBarItemMeasurement extends AppBarItemMeasurement {
  const _AppBarItemMeasurement({required this.policy, required this.width}): super._();
  

@override final  AppBarItemPolicy policy;
@override final  double width;

/// Create a copy of AppBarItemMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppBarItemMeasurementCopyWith<_AppBarItemMeasurement> get copyWith => __$AppBarItemMeasurementCopyWithImpl<_AppBarItemMeasurement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppBarItemMeasurement&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.width, width) || other.width == width));
}


@override
int get hashCode {
    return Object.hash(runtimeType,policy,width);
}

@override
String toString() {
    return 'AppBarItemMeasurement(policy: $policy, width: $width)';
}


}

/// @nodoc
abstract mixin class _$AppBarItemMeasurementCopyWith<$Res> implements $AppBarItemMeasurementCopyWith<$Res> {
  factory _$AppBarItemMeasurementCopyWith(_AppBarItemMeasurement value, $Res Function(_AppBarItemMeasurement) _then) = __$AppBarItemMeasurementCopyWithImpl;
@override @useResult
$Res call({
 AppBarItemPolicy policy, double width
});


@override $AppBarItemPolicyCopyWith<$Res> get policy;

}
/// @nodoc
class __$AppBarItemMeasurementCopyWithImpl<$Res>
    implements _$AppBarItemMeasurementCopyWith<$Res> {
  __$AppBarItemMeasurementCopyWithImpl(this._self, this._then);

  final _AppBarItemMeasurement _self;
  final $Res Function(_AppBarItemMeasurement) _then;

/// Create a copy of AppBarItemMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? policy = null,Object? width = null,}) {
  return _then(_AppBarItemMeasurement(
policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as AppBarItemPolicy,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of AppBarItemMeasurement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBarItemPolicyCopyWith<$Res> get policy {
  
  return $AppBarItemPolicyCopyWith<$Res>(_self.policy, (value) {
    return _then(_self.copyWith(policy: value));
  });
}
}

/// @nodoc
mixin _$AppBarItemAllocation {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppBarItemAllocation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppBarItemAllocation()';
}


}

/// @nodoc
class $AppBarItemAllocationCopyWith<$Res>  {
$AppBarItemAllocationCopyWith(AppBarItemAllocation _, $Res Function(AppBarItemAllocation) __);
}


/// Adds pattern-matching-related methods to [AppBarItemAllocation].
extension AppBarItemAllocationPatterns on AppBarItemAllocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HiddenAppBarAllocation value)?  hidden,TResult Function( VisibleAppBarAllocation value)?  visible,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HiddenAppBarAllocation() when hidden != null:
return hidden(_that);case VisibleAppBarAllocation() when visible != null:
return visible(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HiddenAppBarAllocation value)  hidden,required TResult Function( VisibleAppBarAllocation value)  visible,}){
final _that = this;
switch (_that) {
case HiddenAppBarAllocation():
return hidden(_that);case VisibleAppBarAllocation():
return visible(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HiddenAppBarAllocation value)?  hidden,TResult? Function( VisibleAppBarAllocation value)?  visible,}){
final _that = this;
switch (_that) {
case HiddenAppBarAllocation() when hidden != null:
return hidden(_that);case VisibleAppBarAllocation() when visible != null:
return visible(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  hidden,TResult Function( double extent)?  visible,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HiddenAppBarAllocation() when hidden != null:
return hidden();case VisibleAppBarAllocation() when visible != null:
return visible(_that.extent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  hidden,required TResult Function( double extent)  visible,}) {final _that = this;
switch (_that) {
case HiddenAppBarAllocation():
return hidden();case VisibleAppBarAllocation():
return visible(_that.extent);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  hidden,TResult? Function( double extent)?  visible,}) {final _that = this;
switch (_that) {
case HiddenAppBarAllocation() when hidden != null:
return hidden();case VisibleAppBarAllocation() when visible != null:
return visible(_that.extent);case _:
  return null;

}
}

}

/// @nodoc


class HiddenAppBarAllocation extends AppBarItemAllocation {
  const HiddenAppBarAllocation(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is HiddenAppBarAllocation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppBarItemAllocation.hidden()';
}


}




/// @nodoc


class VisibleAppBarAllocation extends AppBarItemAllocation {
  const VisibleAppBarAllocation(this.extent): super._();
  

 final  double extent;

/// Create a copy of AppBarItemAllocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisibleAppBarAllocationCopyWith<VisibleAppBarAllocation> get copyWith => _$VisibleAppBarAllocationCopyWithImpl<VisibleAppBarAllocation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is VisibleAppBarAllocation&&(identical(other.extent, extent) || other.extent == extent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,extent);
}

@override
String toString() {
    return 'AppBarItemAllocation.visible(extent: $extent)';
}


}

/// @nodoc
abstract mixin class $VisibleAppBarAllocationCopyWith<$Res> implements $AppBarItemAllocationCopyWith<$Res> {
  factory $VisibleAppBarAllocationCopyWith(VisibleAppBarAllocation value, $Res Function(VisibleAppBarAllocation) _then) = _$VisibleAppBarAllocationCopyWithImpl;
@useResult
$Res call({
 double extent
});




}
/// @nodoc
class _$VisibleAppBarAllocationCopyWithImpl<$Res>
    implements $VisibleAppBarAllocationCopyWith<$Res> {
  _$VisibleAppBarAllocationCopyWithImpl(this._self, this._then);

  final VisibleAppBarAllocation _self;
  final $Res Function(VisibleAppBarAllocation) _then;

/// Create a copy of AppBarItemAllocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? extent = null,}) {
  return _then(VisibleAppBarAllocation(
null == extent ? _self.extent : extent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$AppBarFit {

 double get contentWidth; double get navigationWidth; AppBarItemAllocation get primary; List<AppBarItemAllocation> get actions;
/// Create a copy of AppBarFit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppBarFitCopyWith<AppBarFit> get copyWith => _$AppBarFitCopyWithImpl<AppBarFit>(this as AppBarFit, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppBarFit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppBarFit&&(identical(other.contentWidth, _this.contentWidth) || other.contentWidth == _this.contentWidth)&&(identical(other.navigationWidth, _this.navigationWidth) || other.navigationWidth == _this.navigationWidth)&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&const DeepCollectionEquality().equals(other.actions, _this.actions));
}


@override
int get hashCode {
  final _this = this as AppBarFit;
  return Object.hash(runtimeType,_this.contentWidth,_this.navigationWidth,_this.primary,const DeepCollectionEquality().hash(_this.actions));
}

@override
String toString() {
  final _this = this as AppBarFit;
  return 'AppBarFit(contentWidth: ${_this.contentWidth}, navigationWidth: ${_this.navigationWidth}, primary: ${_this.primary}, actions: ${_this.actions})';
}


}

/// @nodoc
abstract mixin class $AppBarFitCopyWith<$Res>  {
  factory $AppBarFitCopyWith(AppBarFit value, $Res Function(AppBarFit) _then) = _$AppBarFitCopyWithImpl;
@useResult
$Res call({
 double contentWidth, double navigationWidth, AppBarItemAllocation primary, List<AppBarItemAllocation> actions
});


$AppBarItemAllocationCopyWith<$Res> get primary;

}
/// @nodoc
class _$AppBarFitCopyWithImpl<$Res>
    implements $AppBarFitCopyWith<$Res> {
  _$AppBarFitCopyWithImpl(this._self, this._then);

  final AppBarFit _self;
  final $Res Function(AppBarFit) _then;

/// Create a copy of AppBarFit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contentWidth = null,Object? navigationWidth = null,Object? primary = null,Object? actions = null,}) {
  return _then(AppBarFit(
contentWidth: null == contentWidth ? _self.contentWidth : contentWidth // ignore: cast_nullable_to_non_nullable
as double,navigationWidth: null == navigationWidth ? _self.navigationWidth : navigationWidth // ignore: cast_nullable_to_non_nullable
as double,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AppBarItemAllocation,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<AppBarItemAllocation>,
  ));
}
/// Create a copy of AppBarFit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBarItemAllocationCopyWith<$Res> get primary {
  
  return $AppBarItemAllocationCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppBarFit].
extension AppBarFitPatterns on AppBarFit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppBarFit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppBarFit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppBarFit value)  $default,){
final _that = this;
switch (_that) {
case _AppBarFit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppBarFit value)?  $default,){
final _that = this;
switch (_that) {
case _AppBarFit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double contentWidth,  double navigationWidth,  AppBarItemAllocation primary,  List<AppBarItemAllocation> actions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppBarFit() when $default != null:
return $default(_that.contentWidth,_that.navigationWidth,_that.primary,_that.actions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double contentWidth,  double navigationWidth,  AppBarItemAllocation primary,  List<AppBarItemAllocation> actions)  $default,) {final _that = this;
switch (_that) {
case _AppBarFit():
return $default(_that.contentWidth,_that.navigationWidth,_that.primary,_that.actions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double contentWidth,  double navigationWidth,  AppBarItemAllocation primary,  List<AppBarItemAllocation> actions)?  $default,) {final _that = this;
switch (_that) {
case _AppBarFit() when $default != null:
return $default(_that.contentWidth,_that.navigationWidth,_that.primary,_that.actions);case _:
  return null;

}
}

}

/// @nodoc


class _AppBarFit extends AppBarFit {
  const _AppBarFit({required this.contentWidth, required this.navigationWidth, required this.primary, required  List<AppBarItemAllocation> actions}): _actions = actions,super._();
  

@override final  double contentWidth;
@override final  double navigationWidth;
@override final  AppBarItemAllocation primary;
 final  List<AppBarItemAllocation> _actions;
@override List<AppBarItemAllocation> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}


/// Create a copy of AppBarFit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppBarFitCopyWith<_AppBarFit> get copyWith => __$AppBarFitCopyWithImpl<_AppBarFit>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppBarFit&&(identical(other.contentWidth, contentWidth) || other.contentWidth == contentWidth)&&(identical(other.navigationWidth, navigationWidth) || other.navigationWidth == navigationWidth)&&(identical(other.primary, primary) || other.primary == primary)&&const DeepCollectionEquality().equals(other.actions, _actions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,contentWidth,navigationWidth,primary,const DeepCollectionEquality().hash(_actions));
}

@override
String toString() {
    return 'AppBarFit(contentWidth: $contentWidth, navigationWidth: $navigationWidth, primary: $primary, actions: $actions)';
}


}

/// @nodoc
abstract mixin class _$AppBarFitCopyWith<$Res> implements $AppBarFitCopyWith<$Res> {
  factory _$AppBarFitCopyWith(_AppBarFit value, $Res Function(_AppBarFit) _then) = __$AppBarFitCopyWithImpl;
@override @useResult
$Res call({
 double contentWidth, double navigationWidth, AppBarItemAllocation primary, List<AppBarItemAllocation> actions
});


@override $AppBarItemAllocationCopyWith<$Res> get primary;

}
/// @nodoc
class __$AppBarFitCopyWithImpl<$Res>
    implements _$AppBarFitCopyWith<$Res> {
  __$AppBarFitCopyWithImpl(this._self, this._then);

  final _AppBarFit _self;
  final $Res Function(_AppBarFit) _then;

/// Create a copy of AppBarFit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contentWidth = null,Object? navigationWidth = null,Object? primary = null,Object? actions = null,}) {
  return _then(_AppBarFit(
contentWidth: null == contentWidth ? _self.contentWidth : contentWidth // ignore: cast_nullable_to_non_nullable
as double,navigationWidth: null == navigationWidth ? _self.navigationWidth : navigationWidth // ignore: cast_nullable_to_non_nullable
as double,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AppBarItemAllocation,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<AppBarItemAllocation>,
  ));
}

/// Create a copy of AppBarFit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBarItemAllocationCopyWith<$Res> get primary {
  
  return $AppBarItemAllocationCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}
}

/// @nodoc
mixin _$AppBarMeasurements {

 double get navigationWidth; AppBarItemMeasurement get primary; List<AppBarItemMeasurement> get actions;
/// Create a copy of AppBarMeasurements
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppBarMeasurementsCopyWith<AppBarMeasurements> get copyWith => _$AppBarMeasurementsCopyWithImpl<AppBarMeasurements>(this as AppBarMeasurements, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppBarMeasurements;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppBarMeasurements&&(identical(other.navigationWidth, _this.navigationWidth) || other.navigationWidth == _this.navigationWidth)&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&const DeepCollectionEquality().equals(other.actions, _this.actions));
}


@override
int get hashCode {
  final _this = this as AppBarMeasurements;
  return Object.hash(runtimeType,_this.navigationWidth,_this.primary,const DeepCollectionEquality().hash(_this.actions));
}

@override
String toString() {
  final _this = this as AppBarMeasurements;
  return 'AppBarMeasurements(navigationWidth: ${_this.navigationWidth}, primary: ${_this.primary}, actions: ${_this.actions})';
}


}

/// @nodoc
abstract mixin class $AppBarMeasurementsCopyWith<$Res>  {
  factory $AppBarMeasurementsCopyWith(AppBarMeasurements value, $Res Function(AppBarMeasurements) _then) = _$AppBarMeasurementsCopyWithImpl;
@useResult
$Res call({
 double navigationWidth, AppBarItemMeasurement primary, List<AppBarItemMeasurement> actions
});


$AppBarItemMeasurementCopyWith<$Res> get primary;

}
/// @nodoc
class _$AppBarMeasurementsCopyWithImpl<$Res>
    implements $AppBarMeasurementsCopyWith<$Res> {
  _$AppBarMeasurementsCopyWithImpl(this._self, this._then);

  final AppBarMeasurements _self;
  final $Res Function(AppBarMeasurements) _then;

/// Create a copy of AppBarMeasurements
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? navigationWidth = null,Object? primary = null,Object? actions = null,}) {
  return _then(AppBarMeasurements(
navigationWidth: null == navigationWidth ? _self.navigationWidth : navigationWidth // ignore: cast_nullable_to_non_nullable
as double,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AppBarItemMeasurement,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<AppBarItemMeasurement>,
  ));
}
/// Create a copy of AppBarMeasurements
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBarItemMeasurementCopyWith<$Res> get primary {
  
  return $AppBarItemMeasurementCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppBarMeasurements].
extension AppBarMeasurementsPatterns on AppBarMeasurements {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppBarMeasurements value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppBarMeasurements() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppBarMeasurements value)  $default,){
final _that = this;
switch (_that) {
case _AppBarMeasurements():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppBarMeasurements value)?  $default,){
final _that = this;
switch (_that) {
case _AppBarMeasurements() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double navigationWidth,  AppBarItemMeasurement primary,  List<AppBarItemMeasurement> actions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppBarMeasurements() when $default != null:
return $default(_that.navigationWidth,_that.primary,_that.actions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double navigationWidth,  AppBarItemMeasurement primary,  List<AppBarItemMeasurement> actions)  $default,) {final _that = this;
switch (_that) {
case _AppBarMeasurements():
return $default(_that.navigationWidth,_that.primary,_that.actions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double navigationWidth,  AppBarItemMeasurement primary,  List<AppBarItemMeasurement> actions)?  $default,) {final _that = this;
switch (_that) {
case _AppBarMeasurements() when $default != null:
return $default(_that.navigationWidth,_that.primary,_that.actions);case _:
  return null;

}
}

}

/// @nodoc


class _AppBarMeasurements extends AppBarMeasurements {
  const _AppBarMeasurements({required this.navigationWidth, required this.primary, required  List<AppBarItemMeasurement> actions}): _actions = actions,super._();
  

@override final  double navigationWidth;
@override final  AppBarItemMeasurement primary;
 final  List<AppBarItemMeasurement> _actions;
@override List<AppBarItemMeasurement> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}


/// Create a copy of AppBarMeasurements
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppBarMeasurementsCopyWith<_AppBarMeasurements> get copyWith => __$AppBarMeasurementsCopyWithImpl<_AppBarMeasurements>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppBarMeasurements&&(identical(other.navigationWidth, navigationWidth) || other.navigationWidth == navigationWidth)&&(identical(other.primary, primary) || other.primary == primary)&&const DeepCollectionEquality().equals(other.actions, _actions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,navigationWidth,primary,const DeepCollectionEquality().hash(_actions));
}

@override
String toString() {
    return 'AppBarMeasurements(navigationWidth: $navigationWidth, primary: $primary, actions: $actions)';
}


}

/// @nodoc
abstract mixin class _$AppBarMeasurementsCopyWith<$Res> implements $AppBarMeasurementsCopyWith<$Res> {
  factory _$AppBarMeasurementsCopyWith(_AppBarMeasurements value, $Res Function(_AppBarMeasurements) _then) = __$AppBarMeasurementsCopyWithImpl;
@override @useResult
$Res call({
 double navigationWidth, AppBarItemMeasurement primary, List<AppBarItemMeasurement> actions
});


@override $AppBarItemMeasurementCopyWith<$Res> get primary;

}
/// @nodoc
class __$AppBarMeasurementsCopyWithImpl<$Res>
    implements _$AppBarMeasurementsCopyWith<$Res> {
  __$AppBarMeasurementsCopyWithImpl(this._self, this._then);

  final _AppBarMeasurements _self;
  final $Res Function(_AppBarMeasurements) _then;

/// Create a copy of AppBarMeasurements
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? navigationWidth = null,Object? primary = null,Object? actions = null,}) {
  return _then(_AppBarMeasurements(
navigationWidth: null == navigationWidth ? _self.navigationWidth : navigationWidth // ignore: cast_nullable_to_non_nullable
as double,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as AppBarItemMeasurement,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<AppBarItemMeasurement>,
  ));
}

/// Create a copy of AppBarMeasurements
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppBarItemMeasurementCopyWith<$Res> get primary {
  
  return $AppBarItemMeasurementCopyWith<$Res>(_self.primary, (value) {
    return _then(_self.copyWith(primary: value));
  });
}
}

// dart format on
