package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.typewritermc.authoring.AuthoringNavigationHandler
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.namedArguments
import com.typewritermc.codegen.TypewriterApi as Api

/** The registration object of one `@TypewriterResourceDefinition` property, naming its root's definition. */
internal fun resourceRegistrationFile(
    name: ClassName,
    id: String,
    root: ClassName,
    navigation: AuthoringNavigationHandler,
): FileSpec {
    val registration =
        TypeSpec
            .objectBuilder(name)
            .addSuperinterface(Api.GeneratedResourceProvider)
            .addProperty(
                PropertySpec
                    .builder("definition", AuthoringResourceDefinition::class, KModifier.OVERRIDE)
                    .initializer(
                        "%T%L",
                        AuthoringResourceDefinition::class,
                        namedArguments(
                            "id" to CodeBlock.of("%T(%S)", ResourceDefinitionId::class, id),
                            "root" to CodeBlock.of("%T.id", root),
                            "navigationHandler" to CodeBlock.of("%T.%L", AuthoringNavigationHandler::class, navigation.name),
                        ),
                    ).build(),
            ).build()
    return GeneratedFile.builder(name.packageName, name.simpleName).addType(registration).build()
}
