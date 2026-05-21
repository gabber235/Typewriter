package com.typewritermc.core.extension.annotations

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class Entry(
    val name: String,
    val description: String,
    val color: String, // Hex color
    val icon: String, // Any https://icon-sets.iconify.design/ icon
    val titleKey: String = "", // Localization key for node title (e.g., "entity.random_patrol_activity.title")
    val descriptionKey: String = "", // Localization key for node description
)