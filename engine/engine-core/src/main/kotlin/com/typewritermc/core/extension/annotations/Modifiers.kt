package com.typewritermc.core.extension.annotations

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.books.pages.PageType
import kotlin.reflect.KClass

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * Allows you to specify a way to capture the content of the field in game.
 * TODO: Make the capturer a KClass<ContentMode>
 */
annotation class ContentEditor(val capturer: KClass<*>)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This field allows [Adventure MiniMessages](https://docs.advntr.dev/minimessage/format.html) to be used in the field.
 */
annotation class Colored

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This will generate a random UUID as default value for the field.
 */
annotation class Generated

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to add a tooltip to the field.
 * You can specify either [text] as a fallback string or [key] as a localization key.
 */
annotation class Help(val text: String = "", val key: String = "")

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify an icon from [Iconify](https://iconify.design/) for the field.
 */
annotation class Icon(val icon: String)


enum class MaterialProperty {
    ITEM,
    BLOCK,
    SOLID,
    TRANSPARENT,
    FLAMMABLE,
    BURNABLE,
    EDIBLE,
    FUEL,
    INTRACTABLE,
    OCCLUDING,
    RECORD,
    TOOL,
    WEAPON,
    ARMOR,
    ORE,
}

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify the properties of the material.
 */
annotation class MaterialProperties(vararg val properties: MaterialProperty)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify that the field allows multiple lines.
 */
annotation class MultiLine

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows for negative numbers to be used in the field.
 */
annotation class Negative

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify which tags the entries must have to be accepted.
 */
annotation class OnlyTags(vararg val tags: String)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify the type of the page for the field.
 */
annotation class Page(val type: PageType)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to use [PlaceholderAPI](https://www.spigotmc.org/reRUNTIMEs/placeholderapi.6245/) placeholders in the field.
 */
annotation class Placeholder

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify a [Regex](https://www.autoregex.xyz/) for the field.
 */
annotation class Regex

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you mark this field as a Segment for a cinematic.
 */
annotation class Segments(val color: String = Colors.CYAN, val icon: String = "fa6-solid:star")

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify a minimum value for the field.
 */
annotation class Min(val value: Int)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify a minimum value on the inner field.
 * This is useful for lists and maps.
 */
annotation class InnerMin(val annotation: Min)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify a maximum value for the field.
 */
annotation class Max(val value: Int)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to specify a maximum value on the inner field.
 * This is useful for lists and maps.
 */
annotation class InnerMax(val annotation: Max)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This requires the field to only accept snake_case.
 */
annotation class SnakeCase

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows the yaw, pitch of the location to be specified.
 */
annotation class WithRotation

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * Show the alpha slider in the web panel.
 */
annotation class WithAlpha

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * This allows you to have a `InteractionContextKey` field which ignores the generic bound.
 * In other words, it allows any interaction context key to be used.
 */
annotation class IgnoreContextKeyBlueprint

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * Specifies a localization key for the field label.
 * Example: "entity.random_patrol_activity.fields.radius.label"
 */
annotation class LabelKey(val value: String)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * Specifies a localization key for the field placeholder text.
 * Example: "entity.random_patrol_activity.fields.radius.placeholder"
 */
annotation class PlaceholderKey(val value: String)

@Target(AnnotationTarget.FIELD, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.RUNTIME)
/**
 * Specifies localization keys for enum/option labels.
 * Keys should be in the format: "namespace.field.options.{option_value}"
 * Example: "entity.random_patrol_activity.fields.type.options.aggressive"
 */
annotation class OptionLabelsKey(val keyPrefix: String)