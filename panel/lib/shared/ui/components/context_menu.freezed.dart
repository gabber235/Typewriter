// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'context_menu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MenuItem implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MenuItem'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MenuItem()';
}


}

/// @nodoc
class $MenuItemCopyWith<$Res>  {
$MenuItemCopyWith(MenuItem _, $Res Function(MenuItem) __);
}


/// Adds pattern-matching-related methods to [MenuItem].
extension MenuItemPatterns on MenuItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuItem value)?  $default,{TResult Function( MenuItemSubmenu value)?  submenu,TResult Function( MenuItemSection value)?  section,TResult Function( MenuItemDivider value)?  divider,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that);case MenuItemSubmenu() when submenu != null:
return submenu(_that);case MenuItemSection() when section != null:
return section(_that);case MenuItemDivider() when divider != null:
return divider(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuItem value)  $default,{required TResult Function( MenuItemSubmenu value)  submenu,required TResult Function( MenuItemSection value)  section,required TResult Function( MenuItemDivider value)  divider,}){
final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that);case MenuItemSubmenu():
return submenu(_that);case MenuItemSection():
return section(_that);case MenuItemDivider():
return divider(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuItem value)?  $default,{TResult? Function( MenuItemSubmenu value)?  submenu,TResult? Function( MenuItemSection value)?  section,TResult? Function( MenuItemDivider value)?  divider,}){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that);case MenuItemSubmenu() when submenu != null:
return submenu(_that);case MenuItemSection() when section != null:
return section(_that);case MenuItemDivider() when divider != null:
return divider(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  Widget? icon,  Color? color,  VoidCallback? onPressed,  List<ShortcutActivator> shortcuts)?  $default,{TResult Function( String label,  List<MenuItem> items,  Widget? icon,  Color? color)?  submenu,TResult Function( List<MenuItem> items,  String? label,  Widget? icon,  Color? color)?  section,TResult Function()?  divider,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.label,_that.icon,_that.color,_that.onPressed,_that.shortcuts);case MenuItemSubmenu() when submenu != null:
return submenu(_that.label,_that.items,_that.icon,_that.color);case MenuItemSection() when section != null:
return section(_that.items,_that.label,_that.icon,_that.color);case MenuItemDivider() when divider != null:
return divider();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  Widget? icon,  Color? color,  VoidCallback? onPressed,  List<ShortcutActivator> shortcuts)  $default,{required TResult Function( String label,  List<MenuItem> items,  Widget? icon,  Color? color)  submenu,required TResult Function( List<MenuItem> items,  String? label,  Widget? icon,  Color? color)  section,required TResult Function()  divider,}) {final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that.label,_that.icon,_that.color,_that.onPressed,_that.shortcuts);case MenuItemSubmenu():
return submenu(_that.label,_that.items,_that.icon,_that.color);case MenuItemSection():
return section(_that.items,_that.label,_that.icon,_that.color);case MenuItemDivider():
return divider();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  Widget? icon,  Color? color,  VoidCallback? onPressed,  List<ShortcutActivator> shortcuts)?  $default,{TResult? Function( String label,  List<MenuItem> items,  Widget? icon,  Color? color)?  submenu,TResult? Function( List<MenuItem> items,  String? label,  Widget? icon,  Color? color)?  section,TResult? Function()?  divider,}) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.label,_that.icon,_that.color,_that.onPressed,_that.shortcuts);case MenuItemSubmenu() when submenu != null:
return submenu(_that.label,_that.items,_that.icon,_that.color);case MenuItemSection() when section != null:
return section(_that.items,_that.label,_that.icon,_that.color);case MenuItemDivider() when divider != null:
return divider();case _:
  return null;

}
}

}

/// @nodoc


class _MenuItem with DiagnosticableTreeMixin implements MenuItem {
  const _MenuItem({required this.label, this.icon, this.color, this.onPressed, final  List<ShortcutActivator> shortcuts = const []}): assert(label != "", 'Label must not be empty.'),_shortcuts = shortcuts;
  

 final  String label;
 final  Widget? icon;
 final  Color? color;
 final  VoidCallback? onPressed;
 final  List<ShortcutActivator> _shortcuts;
@JsonKey() List<ShortcutActivator> get shortcuts {
  if (_shortcuts is EqualUnmodifiableListView) return _shortcuts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shortcuts);
}


/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuItemCopyWith<_MenuItem> get copyWith => __$MenuItemCopyWithImpl<_MenuItem>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MenuItem'))
    ..add(DiagnosticsProperty('label', label))..add(DiagnosticsProperty('icon', icon))..add(DiagnosticsProperty('color', color))..add(DiagnosticsProperty('onPressed', onPressed))..add(DiagnosticsProperty('shortcuts', shortcuts));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuItem&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.onPressed, onPressed) || other.onPressed == onPressed)&&const DeepCollectionEquality().equals(other._shortcuts, _shortcuts));
}


@override
int get hashCode => Object.hash(runtimeType,label,icon,color,onPressed,const DeepCollectionEquality().hash(_shortcuts));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MenuItem(label: $label, icon: $icon, color: $color, onPressed: $onPressed, shortcuts: $shortcuts)';
}


}

/// @nodoc
abstract mixin class _$MenuItemCopyWith<$Res> implements $MenuItemCopyWith<$Res> {
  factory _$MenuItemCopyWith(_MenuItem value, $Res Function(_MenuItem) _then) = __$MenuItemCopyWithImpl;
@useResult
$Res call({
 String label, Widget? icon, Color? color, VoidCallback? onPressed, List<ShortcutActivator> shortcuts
});




}
/// @nodoc
class __$MenuItemCopyWithImpl<$Res>
    implements _$MenuItemCopyWith<$Res> {
  __$MenuItemCopyWithImpl(this._self, this._then);

  final _MenuItem _self;
  final $Res Function(_MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,Object? icon = freezed,Object? color = freezed,Object? onPressed = freezed,Object? shortcuts = null,}) {
  return _then(_MenuItem(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as Widget?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,onPressed: freezed == onPressed ? _self.onPressed : onPressed // ignore: cast_nullable_to_non_nullable
as VoidCallback?,shortcuts: null == shortcuts ? _self._shortcuts : shortcuts // ignore: cast_nullable_to_non_nullable
as List<ShortcutActivator>,
  ));
}


}

/// @nodoc


class MenuItemSubmenu with DiagnosticableTreeMixin implements MenuItem {
  const MenuItemSubmenu({required this.label, required final  List<MenuItem> items, this.icon, this.color}): assert(label != "", 'Label must not be empty.'),assert(items.length > 0, 'Items must not be empty.'),_items = items;
  

 final  String label;
 final  List<MenuItem> _items;
 List<MenuItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  Widget? icon;
 final  Color? color;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemSubmenuCopyWith<MenuItemSubmenu> get copyWith => _$MenuItemSubmenuCopyWithImpl<MenuItemSubmenu>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MenuItem.submenu'))
    ..add(DiagnosticsProperty('label', label))..add(DiagnosticsProperty('items', items))..add(DiagnosticsProperty('icon', icon))..add(DiagnosticsProperty('color', color));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItemSubmenu&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,label,const DeepCollectionEquality().hash(_items),icon,color);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MenuItem.submenu(label: $label, items: $items, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class $MenuItemSubmenuCopyWith<$Res> implements $MenuItemCopyWith<$Res> {
  factory $MenuItemSubmenuCopyWith(MenuItemSubmenu value, $Res Function(MenuItemSubmenu) _then) = _$MenuItemSubmenuCopyWithImpl;
@useResult
$Res call({
 String label, List<MenuItem> items, Widget? icon, Color? color
});




}
/// @nodoc
class _$MenuItemSubmenuCopyWithImpl<$Res>
    implements $MenuItemSubmenuCopyWith<$Res> {
  _$MenuItemSubmenuCopyWithImpl(this._self, this._then);

  final MenuItemSubmenu _self;
  final $Res Function(MenuItemSubmenu) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,Object? items = null,Object? icon = freezed,Object? color = freezed,}) {
  return _then(MenuItemSubmenu(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItem>,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as Widget?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}


}

/// @nodoc


class MenuItemSection with DiagnosticableTreeMixin implements MenuItem {
  const MenuItemSection({required final  List<MenuItem> items, this.label, this.icon, this.color}): assert(items.length > 0, 'Items must not be empty.'),assert(label == null || label != "", 'Label must be null or nonempty.'),_items = items;
  

 final  List<MenuItem> _items;
 List<MenuItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  String? label;
 final  Widget? icon;
 final  Color? color;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemSectionCopyWith<MenuItemSection> get copyWith => _$MenuItemSectionCopyWithImpl<MenuItemSection>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MenuItem.section'))
    ..add(DiagnosticsProperty('items', items))..add(DiagnosticsProperty('label', label))..add(DiagnosticsProperty('icon', icon))..add(DiagnosticsProperty('color', color));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItemSection&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.label, label) || other.label == label)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),label,icon,color);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MenuItem.section(items: $items, label: $label, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class $MenuItemSectionCopyWith<$Res> implements $MenuItemCopyWith<$Res> {
  factory $MenuItemSectionCopyWith(MenuItemSection value, $Res Function(MenuItemSection) _then) = _$MenuItemSectionCopyWithImpl;
@useResult
$Res call({
 List<MenuItem> items, String? label, Widget? icon, Color? color
});




}
/// @nodoc
class _$MenuItemSectionCopyWithImpl<$Res>
    implements $MenuItemSectionCopyWith<$Res> {
  _$MenuItemSectionCopyWithImpl(this._self, this._then);

  final MenuItemSection _self;
  final $Res Function(MenuItemSection) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? label = freezed,Object? icon = freezed,Object? color = freezed,}) {
  return _then(MenuItemSection(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItem>,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as Widget?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}


}

/// @nodoc


class MenuItemDivider with DiagnosticableTreeMixin implements MenuItem {
  const MenuItemDivider();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MenuItem.divider'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItemDivider);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MenuItem.divider()';
}


}




// dart format on
