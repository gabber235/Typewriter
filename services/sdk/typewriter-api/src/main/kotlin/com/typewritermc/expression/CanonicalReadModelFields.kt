package com.typewritermc.expression

import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.catalog.ResourceAppearance
import skirout.editor.v1.catalog.TypeDisplay

// Typed field reads on read model expressions, keyed by their Skir field names. A read model value is projected from
// a complete Skir value, so reading a field of a present value keeps the receiver's missing policy.

/** The display metadata of a published type. */
@get:JvmName("publishedTypeDisplay")
val <M : MissingPolicy> Expr<out PublishedType, M>.display: Expr<TypeDisplay, M> get() = readField("display")

@get:JvmName("typeDisplayName")
val <M : MissingPolicy> Expr<out TypeDisplay, M>.name: Expr<String, M> get() = readField("name")

@get:JvmName("typeDisplayDescription")
val <M : MissingPolicy> Expr<out TypeDisplay, M>.description: Expr<String, M> get() = readField("description")

@get:JvmName("typeDisplayIcon")
val <M : MissingPolicy> Expr<out TypeDisplay, M>.icon: Expr<Icon, M> get() = readField("icon")

@get:JvmName("typeDisplayColor")
val <M : MissingPolicy> Expr<out TypeDisplay, M>.color: Expr<Color, M> get() = readField("color")

/** The evaluated label of a resource. */
@get:JvmName("resourceAppearanceLabel")
val <M : MissingPolicy> Expr<out ResourceAppearance, M>.label: Expr<String, M> get() = readField("label")

@get:JvmName("resourceAppearanceAccent")
val <M : MissingPolicy> Expr<out ResourceAppearance, M>.accent: Expr<Color, M> get() = readField("accent")

@get:JvmName("resourceAppearanceIcon")
val <M : MissingPolicy> Expr<out ResourceAppearance, M>.icon: Expr<Icon, M> get() = readField("icon")

@Suppress("UNCHECKED_CAST")
private fun <V, M : MissingPolicy> Expr<*, M>.readField(key: String): Expr<V, M> = field<V>(key) as Expr<V, M>
