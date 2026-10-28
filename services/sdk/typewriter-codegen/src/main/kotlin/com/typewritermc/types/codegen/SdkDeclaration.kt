package com.typewritermc.types.codegen

import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeVariableName
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.TypeParameterBindings
import com.typewritermc.codegen.implements
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.Resource
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.ksp.OwnedFieldDeclaration
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeTemplate

/** One source declaration resolved for SDK emission. Built once by the processor; emitters only read it. */
internal class SdkDeclaration(
    val source: KSClassDeclaration,
    val definition: TypeDefinition,
    val names: SdkNames,
    /** The declaration's own type variables with their non Any bounds, reused by every emitted type. */
    val typeVariables: List<TypeVariableName>,
    /** Effective authoring fields, including inherited ones, in declaration order. */
    val fields: List<SdkField>,
    /** Fields this declaration states itself; native bindings construct and read only these. */
    val ownedFields: List<OwnedFieldDeclaration>,
    /** The declaration classified like a field of its own type, applied to its own type variables. */
    val shape: FieldShape,
    /** Resolves every type definition id this declaration's SDK mentions to the object that owns it. */
    val references: DefinitionReferences,
    /** The complete display: the validated `@TypewriterDisplay` with every omitted part filled. */
    val display: TypeDisplay,
    /** The search scope keyword of a resource type, or null for a type that is not a resource. */
    val searchKey: String?,
) {
    val resource: Boolean = source.implements(Resource::class)
    val record: Boolean = definition.representation is RepresentationTemplate.RecordWrapper
    val abstract: Boolean = source.isAbstractDeclaration
    val generic: Boolean = typeVariables.isNotEmpty()

    /** The declaration applied to its own type variables, for example `Box<T>`. */
    val selfType: TypeName = names.source.parameterizedOrSelf(typeVariables)

    /** The declaration with every type argument projected, for example `Box<*>`. */
    val starType: TypeName = names.source.parameterizedOrSelf(typeVariables.map { STAR })

    /** The expressions scope applied to the declaration's own type variables. */
    val expressionsType: TypeName = names.expressions.parameterizedOrSelf(typeVariables)

    /** Draft type variables `D0`, `D1`, ... that stand for the read side of each type parameter. */
    val draftVariables: List<TypeVariableName> = typeVariables.indices.map { TypeVariableName("D$it") }

    /** Exact drafts know both the native type variables and their draft projections. */
    val exactVariables: List<TypeVariableName> = typeVariables + draftVariables

    /** The template of this declaration applied to its own parameters. */
    val template: NamedTypeTemplate =
        definition.id.namedTemplate(definition.parameters.map { it.key.template })

    /** Binds each type parameter to the expected type of the draft projection argument of the same index. */
    val draftBindings: TypeParameterBindings =
        TypeParameterBindings.from(
            typeVariables.indices.associate { index ->
                ParameterKey(owner = definition.id, index = index) to
                    CodeBlock.of("argument%L.expected", index)
            },
        )
}

/** One authoring field: serialized [name], Kotlin [property], its portable [template] and its classified [shape]. */
internal class SdkField(
    val name: String,
    val property: String,
    val template: TypeTemplate,
    val shape: FieldShape,
    /** For a link field, or a list or set of links: its reference contract and side; null for every other field. */
    val link: SdkLink? = null,
    /** Whether the field holds the resource's placement in its owner's editor surface. */
    val placement: Boolean = false,
)

/** One side of a reference contract, resolved from the generated endpoint interface of a `Ref<Endpoint, Target>`. */
internal class SdkLink(
    /** Whether the contract is in the owning family. */
    val owning: Boolean,
    val slot: EndpointSlot,
    /** Whether the field holds a list or set of links rather than one link. */
    val collection: Boolean,
    /** The type a link in this field points at; for an owning list, the type its children must implement. */
    val elementType: TypeName,
) {
    /** The owner's list of its children on an owning contract, for example `Book.pages`. */
    val isOwningListOfChildren: Boolean get() = owning && slot == EndpointSlot.First && collection

    /** The child's link back to its owner on an owning contract, for example `Book.library`. */
    val isOwnerLinkOfChild: Boolean get() = owning && slot == EndpointSlot.Second && !collection
}

/** Contributes the declarations of one generated artifact to the declaration's SDK file. */
internal fun interface SdkEmitter {
    fun FileSpec.Builder.emit(declaration: SdkDeclaration)
}
