package com.typewritermc.processors.entry

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.typewritermc.processors.entry.modifiers.*
import kotlin.reflect.KClass
import kotlin.reflect.cast

interface DataModifierComputer<A : Annotation> {
    val annotationClass: KClass<A>

    context(KSPLogger, Resolver)
    @OptIn(KspExperimental::class)
    fun applyModifier(blueprint: DataBlueprint, property: KSPropertyDeclaration) {
        val annotation = property.getAnnotationsByType(annotationClass).firstOrNull() ?: return
        val modifier = compute(blueprint, annotationClass.cast(annotation)).getOrNull() ?: return
        modifier.appendModifier(blueprint)
    }

    context(KSPLogger, Resolver)
    fun compute(blueprint: DataBlueprint, annotation: A): Result<DataModifier>

    context(KSPLogger, Resolver)
    fun innerListCompute(blueprint: DataBlueprint, annotation: A): DataModifier? {
        if (blueprint !is DataBlueprint.ListBlueprint) return null
        val modifier = compute(blueprint.type, annotation).getOrNull() ?: return null
        return DataModifier.InnerModifier(modifier)
    }

    context(KSPLogger, Resolver)
    fun innerMapCompute(blueprint: DataBlueprint, annotation: A): DataModifier? {
        if (blueprint !is DataBlueprint.MapBlueprint) return null
        val keyModifier = compute(blueprint.key, annotation).onFailure { return null }.getOrNull()
        val valueModifier = compute(blueprint.value, annotation).onFailure { return null }.getOrNull()

        if (keyModifier == null && valueModifier == null) return null
        return DataModifier.InnerMapModifier(keyModifier, valueModifier)
    }

    context(KSPLogger, Resolver)
    fun innerObjectCompute(blueprint: DataBlueprint, annotation: A): DataModifier? {
        if (blueprint !is DataBlueprint.ObjectBlueprint) return null
        val modifiers = blueprint.fields.mapNotNull {
            val modifier = compute(it.value, annotation).getOrNull() ?: return@mapNotNull null
            it.key to modifier
        }.toMap()
        if (modifiers.isEmpty()) return null
        return DataModifier.InnerObjectModifier(modifiers)
    }

    context(KSPLogger, Resolver)
    fun innerCustomCompute(blueprint: DataBlueprint, annotation: A): DataModifier? {
        if (blueprint !is DataBlueprint.CustomBlueprint) return null
        val modifier = superInnerCompute(blueprint.shape, annotation) ?: return null
        return DataModifier.InnerModifier(modifier)
    }

    context(KSPLogger, Resolver)
    fun innerCompute(blueprint: DataBlueprint, annotation: A): DataModifier? {
        return when (blueprint) {
            is DataBlueprint.ListBlueprint -> innerListCompute(blueprint, annotation)
            is DataBlueprint.MapBlueprint -> innerMapCompute(blueprint, annotation)
            is DataBlueprint.CustomBlueprint -> innerCustomCompute(blueprint, annotation)
            else -> null
        }
    }

    context(KSPLogger, Resolver)
    fun superInnerCompute(blueprint: DataBlueprint, annotation: A): DataModifier? {
        return innerCompute(blueprint, annotation) ?: innerObjectCompute(blueprint, annotation) ?: compute(blueprint, annotation).getOrNull()
    }
}

private val computers: List<DataModifierComputer<*>> = listOf(
    ColoredModifierComputer,
    ContentEditorModifierComputer,
    GeneratedModifierComputer,
    HelpModifierComputer,
    IconModifierComputer,
    IgnoreContextKeyBlueprintModifierComputer,
    MaterialPropertiesModifierComputer,
    MultiLineModifierComputer,
    NegativeModifierComputer,
    OnlyTagsModifierComputer,
    PageModifierComputer,
    PlaceholderModifierComputer,
    RegexModifierComputer,
    SegmentModifierComputer,
    SnakeCaseModifierComputer,
    WithRotationModifierComputer,
    WithAlphaModifierComputer,
    MinModifierComputer,
    MaxModifierComputer,
    InnerMinModifierComputer,
    InnerMaxModifierComputer,
)

context(KSPLogger, Resolver)
fun applyModifiers(blueprint: DataBlueprint, property: KSPropertyDeclaration) {
    for (computer in computers) {
        computer.applyModifier(blueprint, property)
    }

    property.findOverridee()?.let {
        applyModifiers(blueprint, it)
    }
}

