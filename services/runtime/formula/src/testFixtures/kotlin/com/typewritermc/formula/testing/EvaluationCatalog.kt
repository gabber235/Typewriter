package com.typewritermc.formula.testing

import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.Deferred
import com.typewritermc.formula.FormulaDefinition
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.FormulaFailureException
import com.typewritermc.formula.FormulaNativeBindingFactory
import com.typewritermc.formula.FormulaReferenceDefinition
import com.typewritermc.formula.FormulaReferenceNativeBindingFactory
import com.typewritermc.formula.TextSpanDefinition
import com.typewritermc.formula.TextSpanNativeBindingFactory
import com.typewritermc.formula.VarComputedDefinition
import com.typewritermc.formula.VarComputedNativeBindingFactory
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.VarValueDefinition
import com.typewritermc.formula.VarValueNativeBindingFactory
import com.typewritermc.types.EvaluationValues
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ResourceDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.ContentSource
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.content
import com.typewritermc.types.catalog.contentField
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

// The catalog and bindings the interpreter runs over: the standard types, Var and Formula, the Kotlin records of
// EvaluationTypes.kt with their generated bindings, and a few content declarations, so code and content records meet
// in one world.

/** The resource that declares the content types of this world. */
val contentOwner: ResourceId = ResourceId(value = "prizes")

private val prizeId: TypeDefinitionId = TypeDefinitionId.content(contentOwner, "prize")

/** A content record `Prize(gold: Int)`, which has no Kotlin class. */
val prizeUse: TypeUse = prizeId.use()

/** An alias of Prize: the type the field `alias` of the declaring resource holds. */
val prizeAliasUse: TypeUse = TypeDefinitionId.contentField(contentOwner, "alias").use()

private val prizeDeclaration: TypeDefinition =
    TypeDefinition.partial(
        id = prizeId,
        representation =
            RepresentationTemplate.createRecord(
                fields = listOf(FieldDeclaration.partial(owner = FieldOwner(definition = prizeId, name = "gold"), type = int.toTemplate())),
                form = RecordForm.CONCRETE,
            ),
    )

private val codeCatalog: DefaultCheckedCatalog =
    DefaultCheckedCatalog(
        CatalogGeneration(value = "formula evaluation test"),
        formulaCoreDefinitions +
            listOf(
                GoldDefinition.definition,
                BoxDefinition.definition,
                RewardDefinition.definition,
                SettingsDefinition.definition,
                SeasonDefinition.definition,
                CoinsDefinition.definition,
                DoorDefinition.definition,
                DoorOpenDefinition.definition,
                DoorClosedDefinition.definition,
                PaymentDefinition.definition,
                PaymentMoneyDefinition.definition,
                PaymentFreeDefinition.definition,
                MoodDefinition.definition,
                CrewDefinition.definition,
                MeasureDefinition.definition,
                SmithDefinition.definition,
                SignalDefinition.definition,
                SignalQuietDefinition.definition,
                SignalTunedDefinition.definition,
            ) + SeasonDefinition.cases,
    )

/** The code catalog plus Prize and its alias. */
val evaluationCatalog: CheckedCatalog =
    codeCatalog.withContent(
        object : ContentSource {
            override fun declarations(owner: ResourceId): List<TypeDefinition> =
                if (owner ==
                    contentOwner
                ) {
                    listOf(prizeDeclaration)
                } else {
                    emptyList()
                }

            override fun heldType(
                owner: ResourceId,
                field: String,
            ): TypeUse? = if (owner == contentOwner && field == "alias") prizeUse else null
        },
    )

/** The native bindings of this world over [evaluationCatalog]. */
val evaluationBindings: NativeBindingRegistry =
    FactoryNativeBindingRegistry(
        codeCatalog,
        listOf(
            FormulaNativeBindingFactory,
            FormulaReferenceNativeBindingFactory,
            TextSpanNativeBindingFactory,
            VarValueNativeBindingFactory,
            VarComputedNativeBindingFactory,
            GoldNativeBindingFactory,
            BoxNativeBindingFactory,
            RewardNativeBindingFactory,
            SettingsNativeBindingFactory,
            SeasonNativeBindingFactory,
            CoinsNativeBindingFactory,
            DoorOpenNativeBindingFactory,
            DoorClosedNativeBindingFactory,
            PaymentMoneyNativeBindingFactory,
            PaymentFreeNativeBindingFactory,
            MoodNativeBindingFactory,
            CrewNativeBindingFactory,
            MeasureNativeBindingFactory,
            SmithNativeBindingFactory,
            SignalQuietNativeBindingFactory,
            SignalTunedNativeBindingFactory,
        ),
    ).over(evaluationCatalog)

/** [use] resolved in this world; fails when it does not resolve. */
fun checkedUse(use: TypeUse): CheckedType =
    when (val resolved = evaluationCatalog.resolve(use)) {
        is Resolution.Ready -> resolved.value
        is Resolution.Invalid -> error("$use does not resolve: ${resolved.diagnostics}")
    }

/** The native binding of [use] in this world. */
fun binding(use: TypeUse): NativeBinding<*> = evaluationBindings.bind(checkedUse(use))

/** A record of [use] built from [fields] through its Kotlin constructor, as a formula constructor builds it. */
fun construct(
    use: TypeUse,
    fields: Map<String, Any?>,
): Any? = evaluationBindings.construct(checkedUse(use), fields, valuesResolving())

/**
 * Evaluation values whose only unevaluated values are [deferred], each standing for its value. A failure is the
 * provider failure an interpreter would give.
 */
fun valuesResolving(vararg deferred: Pair<Deferred, Any?>): EvaluationValues =
    object : EvaluationValues {
        private val answers = deferred.toMap()

        override fun resolve(value: Any?): Any? = if (value is Deferred) answers.getValue(value) else value

        override fun force(value: Any?): Any? = resolve(value)

        override fun fail(message: String): Nothing = throw FormulaFailureException(FormulaFailure.ProviderThrew(message))
    }
