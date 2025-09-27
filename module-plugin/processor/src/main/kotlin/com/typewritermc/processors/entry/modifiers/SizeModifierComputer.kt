package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.InnerMax
import com.typewritermc.core.extension.annotations.InnerMin
import com.typewritermc.core.extension.annotations.Max
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import kotlin.reflect.KClass

object MinModifierComputer : DataModifierComputer<Min> {
    override val annotationClass: KClass<Min> = Min::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: Min): Result<DataModifier> {
        return ok(DataModifier.Modifier("min", annotation.value))
    }
}

object InnerMinModifierComputer : DataModifierComputer<InnerMin> {
    override val annotationClass: KClass<InnerMin> = InnerMin::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: InnerMin): Result<DataModifier> {
        when (blueprint) {
            is DataBlueprint.ListBlueprint, is DataBlueprint.ObjectBlueprint, is DataBlueprint.CustomBlueprint -> return ok(
                DataModifier.InnerModifier(
                    DataModifier.Modifier(
                        "min",
                        annotation.annotation.value
                    )
                )
            )

            is DataBlueprint.MapBlueprint -> return ok(
                DataModifier.InnerMapModifier(
                    key = null,
                    value = DataModifier.Modifier("min", annotation.annotation.value)
                )
            )

            else -> return failure("InnerMin annotation can only be used on lists, maps or objects")
        }
    }
}

object MaxModifierComputer : DataModifierComputer<Max> {
    override val annotationClass: KClass<Max> = Max::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: Max): Result<DataModifier> {
        return ok(DataModifier.Modifier("max", annotation.value))
    }
}

object InnerMaxModifierComputer : DataModifierComputer<InnerMax> {
    override val annotationClass: KClass<InnerMax> = InnerMax::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: InnerMax): Result<DataModifier> {
        when (blueprint) {
            is DataBlueprint.ListBlueprint, is DataBlueprint.ObjectBlueprint, is DataBlueprint.CustomBlueprint -> return ok(
                DataModifier.InnerModifier(
                    DataModifier.Modifier(
                        "max",
                        annotation.annotation.value
                    )
                )
            )

            is DataBlueprint.MapBlueprint -> return ok(
                DataModifier.InnerMapModifier(
                    key = null,
                    value = DataModifier.Modifier("max", annotation.annotation.value)
                )
            )

            else -> return failure("InnerMax annotation can only be used on lists, maps or objects")
        }
    }
}