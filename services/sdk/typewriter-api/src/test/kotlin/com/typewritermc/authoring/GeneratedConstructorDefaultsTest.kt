@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.authoring

import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.NativeBindingResolver
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.qualified
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

val GeneratedConstructorDefaultsTest by testSuite {
    val owner = TypeDefinitionId.qualified("test", "Sampled")
    val name = FieldOwner(definition = owner, name = "name")
    val count = FieldOwner(definition = owner, name = "count")

    val nameField = GeneratedConstructorField<Sampled>(name, name.name, false, { ScalarKind.TEXT.use }, { null })
    val countField = GeneratedConstructorField<Sampled>(count, count.name, true, { ScalarKind.TEXT.use }, { null })

    test("metadata that matches the primary constructor in order is accepted and names its defaulted fields") {
        Sampled::class.constructorDefaults(listOf(nameField, countField)).defaultedFields shouldBe setOf(count)
    }

    mapOf(
        "a type without a primary constructor" to
            (
                { SampledShape::class.constructorDefaults(emptyList()) } to
                    "${SampledShape::class.qualifiedName}: No primary constructor is available."
            ),
        "a field no constructor parameter matches" to
            (
                {
                    Sampled::class.constructorDefaults(
                        listOf(
                            nameField,
                            GeneratedConstructorField<Sampled>(count, "total", true, {
                                ScalarKind.TEXT.use
                            }, { null }),
                        ),
                    )
                } to
                    "${Sampled::class.qualifiedName}: No primary constructor parameter matches $count (total)."
            ),
        "the same field twice" to
            (
                { Sampled::class.constructorDefaults(listOf(nameField, nameField)) } to
                    "${Sampled::class.qualifiedName}: Generated constructor fields must have unique identities in primary constructor order."
            ),
        "fields out of constructor order" to
            (
                { Sampled::class.constructorDefaults(listOf(countField, nameField)) } to
                    "${Sampled::class.qualifiedName}: Generated constructor fields must have unique identities in primary constructor order."
            ),
        "an unstored parameter without a default" to
            (
                { Sampled::class.constructorDefaults(listOf(countField)) } to
                    "${Sampled::class.qualifiedName}: Unstored constructor parameter name must have a Kotlin default."
            ),
        "a default flag that disagrees with the constructor" to
            (
                {
                    Sampled::class.constructorDefaults(
                        listOf(
                            GeneratedConstructorField<Sampled>(name, name.name, true, {
                                ScalarKind.TEXT.use
                            }, { null }),
                            countField,
                        ),
                    )
                } to
                    "${Sampled::class.qualifiedName}: Generated constructor metadata disagrees for $name (name)."
            ),
    ).forEach { (case, rejection) ->
        test("constructor metadata with $case is refused") {
            val failure = shouldThrow<NativeBindingException> { rejection.first() }

            failure.code shouldBe "invalid_constructor_metadata"
            failure.message shouldBe rejection.second
        }
    }

    test("sampling a default refuses an opaque portable argument the compiled Kotlin bound does not allow") {
        val plan = Sampled::class.constructorDefaults(listOf(nameField, countField))
        val arguments =
            AppliedNativeArguments(
                listOf(ScalarKind.TEXT.use),
                listOf(OpaqueBinding),
                NativeBindingResolver { error("No binding is resolved.") },
            )

        val suppliedName =
            (
                DefaultCheckedCatalog(
                    CatalogGeneration(value = "opaque bound"),
                    StandardTypes.definitions,
                ).resolve(ScalarKind.TEXT.use) as Resolution.Ready
            ).value
                .complete(DataValue.StringValueWrapper("Ada"))

        plan.sample(arguments, mapOf(name to (suppliedName as CompletenessResult.Complete).value)) shouldBe
            CaptureResult.Unavailable(
                listOf(
                    InitializationDiagnostic(
                        field = null,
                        code = "opaque_native_argument_violates_bound",
                        message = "Portable argument 0 cannot satisfy the compiled Kotlin bound.",
                        relativePath = null,
                    ),
                ),
            )
    }
}
