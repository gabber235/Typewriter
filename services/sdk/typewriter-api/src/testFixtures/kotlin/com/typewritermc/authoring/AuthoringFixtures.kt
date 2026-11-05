@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.authoring

import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.field
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.expression.shortcuts.gte
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.testkit.singleFixed
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.NativeBindingResolver
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.integer
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath

internal class Sampled(
    val name: String,
    val count: String = "three",
)

internal interface SampledShape

/** A binding standing for a portable type argument the Kotlin type cannot see into. */
internal object OpaqueBinding : NativeBinding<Any?> {
    override val provider = NativeBindingId(value = "test.opaque")
    override val signature = "opaque"
    override val actualType: TypeUse = ScalarKind.TEXT.use
    override val opaque = true

    override fun encode(value: Any?): DataValue = error("Opaque arguments are not encoded here.")

    override fun decode(value: CompleteValue): Any? = error("Opaque arguments are not decoded here.")
}

/** Whether a condition over the configured segment holds for a segment from [start] to [end]. */
internal fun skirout.editor.v1.expression.ExpressionNode.shownFor(
    start: Long,
    end: Long,
): DataValue? {
    val segment = DataValue.record(mapOf("startFrame" to DataValue.integer(start), "endFrame" to DataValue.integer(end)))
    return (
        com.typewritermc.expression.evaluate(
            this,
            "configured_value" to segment,
        ) as? com.typewritermc.authoring.Availability.Available
    )?.value
}

internal interface ValueFieldExpressions {
    val value: Expr<String, MayBeMissing>
}

internal object ValueFieldExpressionsFactory : ExpressionFactory<ValueFieldExpressions> {
    override val scope = ValueFieldExpressions::class

    override fun create(value: Expr<*, out MissingPolicy>): ValueFieldExpressions =
        object : ValueFieldExpressions {
            override val value: Expr<String, MayBeMissing> = value.field("value")
        }
}

internal object ConditionalPlacementPresentation : TimelineSegmentPlacementPresentation {
    override fun TimelineSegmentPlacementPresentationScope.present() {
        showIf(
            condition = { (endFrame gte startFrame).orElse(literal(false)) },
        ) {
            endFrame {
                label("End frame")
                numericInput()
            }
        }
    }
}
