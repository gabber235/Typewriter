package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.LIST
import com.squareup.kotlinpoet.ParameterSpec
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.STRING
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.codegen.declarationCode
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeUse
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * `XDefinition`: the one object that states this type's identity and portable declaration.
 *
 * `id` is the first property and the only literal statement of the id; every other generated reference reads it
 * from here. Because it is initialized first, definitions that reference each other read an initialized id.
 */
internal object DefinitionEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        val names = declaration.names
        val parameterCount = declaration.typeVariables.size
        val named = TypeUse.Named::class.asClassName()
        addType(
            TypeSpec
                .objectBuilder(names.definition)
                .addSuperinterface(Api.GeneratedTypeProvider)
                .addProperty(
                    PropertySpec
                        .builder("id", TypeDefinitionId::class)
                        .initializer(declaration.definition.id.declarationCode())
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("declaration", TypeDefinition::class)
                        .initializer(
                            context(declaration.references.inside(declaration.definition.id)) { declaration.definition.kotlinCode() },
                        ).build(),
                ).addProperty(
                    PropertySpec
                        .builder("definition", TypeDefinition::class, KModifier.OVERRIDE)
                        .getter(FunSpec.getterBuilder().addStatement("return declaration").build())
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("nativeClass", KClass::class.asClassName().parameterizedBy(STAR), KModifier.OVERRIDE)
                        .getter(FunSpec.getterBuilder().addStatement("return %T::class", names.source).build())
                        .build(),
                ).addProperty(declaration.displayProperty)
                .apply { declaration.searchKeyProperty?.let(::addProperty) }
                .addFunction(
                    FunSpec
                        .builder("applied")
                        .addParameter(
                            ParameterSpec
                                .builder("arguments", LIST.parameterizedBy(TypeUse::class.asClassName()))
                                .defaultValue("emptyList()")
                                .build(),
                        ).returns(named)
                        .addStatement(
                            "require(arguments.size == %L) { %S }",
                            parameterCount,
                            "${names.source.simpleNames.joinToString(".")} requires $parameterCount type arguments.",
                        ).addStatement("return %T(id,♢arguments)", named)
                        .build(),
                ).apply {
                    if (!declaration.generic) {
                        addProperty(PropertySpec.builder("use", named).initializer("applied()").build())
                    }
                }.build(),
        )
    }

    /** The complete display of this declaration, with the parts `@TypewriterDisplay` omits already filled. */
    private val SdkDeclaration.displayProperty: PropertySpec
        get() =
            PropertySpec
                .builder("display", TypeDisplay::class, KModifier.OVERRIDE)
                .initializer(
                    "%T(\n⇥name = %S,\ndescription = %S,\nicon = %L,\ncolor = %T(0x%Lu),\n⇤)",
                    TypeDisplay::class,
                    display.name,
                    display.description,
                    when (val icon = display.icon) {
                        is Icon.Iconify -> CodeBlock.of("%T(%S)", Icon.Iconify::class, icon.value)
                        is Icon.Svg -> CodeBlock.of("%T(%S)", Icon.Svg::class, icon.source)
                    },
                    Color::class,
                    display.color.argb
                        .toString(16)
                        .uppercase(),
                ).build()

    /** The search scope keyword of a resource type; types that are not resources keep the provider's null. */
    private val SdkDeclaration.searchKeyProperty: PropertySpec?
        get() {
            val key = searchKey ?: return null
            return PropertySpec
                .builder("searchKey", STRING.copy(nullable = true), KModifier.OVERRIDE)
                .initializer("%S", key)
                .build()
        }
}
