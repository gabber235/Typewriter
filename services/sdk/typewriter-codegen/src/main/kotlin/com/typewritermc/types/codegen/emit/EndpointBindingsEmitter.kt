package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LIST
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.listCode
import com.typewritermc.codegen.namedArguments
import com.typewritermc.types.codegen.SdkNames
import com.typewritermc.types.codegen.kotlinCode
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.type_catalog.EndpointId
import com.typewritermc.codegen.TypewriterApi as Api

/** `XEndpointBindings`: every relation endpoint a resource root reaches through its fields. */
context(_: DefinitionReferences)
internal fun endpointBindingsFile(
    names: SdkNames,
    bindings: List<EndpointBindingTemplate>,
): FileSpec {
    val provider =
        TypeSpec
            .objectBuilder(names.endpointBindings)
            .addSuperinterface(Api.GeneratedEndpointBindingsProvider)
            .addProperty(
                PropertySpec
                    .builder("bindings", LIST.parameterizedBy(EndpointBindingTemplate::class.asClassName()), KModifier.OVERRIDE)
                    .initializer(bindings.map { it.kotlinCode() }.listCode())
                    .build(),
            ).build()
    return GeneratedFile.builder(names.endpointBindings.packageName, names.endpointBindings.simpleName).addType(provider).build()
}

context(_: DefinitionReferences)
private fun EndpointBindingTemplate.kotlinCode(): CodeBlock =
    CodeBlock.of(
        "%T%L",
        EndpointBindingTemplate::class,
        namedArguments(
            "endpoint" to CodeBlock.of("%T(value·=·%S)", EndpointId::class, endpoint.value),
            "containingResource" to containingResource.kotlinCode(),
            "valueOwner" to valueOwner.kotlinCode(),
            "relativePath" to relativePath.kotlinCode(),
            "target" to target.kotlinCode(),
            "containsCollection" to CodeBlock.of("%L", containsCollection),
        ),
    )
