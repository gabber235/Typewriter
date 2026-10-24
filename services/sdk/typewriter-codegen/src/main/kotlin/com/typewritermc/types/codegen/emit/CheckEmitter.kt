package com.typewritermc.types.codegen.emit

import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.TypeSpec
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.types.codegen.SdkDeclaration
import com.typewritermc.types.codegen.SdkEmitter
import com.typewritermc.codegen.TypewriterApi as Api

/** `XCheck`: realm checks registered for this declaration. */
internal object CheckEmitter : SdkEmitter {
    override fun FileSpec.Builder.emit(declaration: SdkDeclaration) {
        addType(
            TypeSpec
                .interfaceBuilder(declaration.names.check)
                .addAnnotation(generatedContract(GeneratedContract.Kind.Check, declaration))
                .addSuperinterface(Api.RealmCheckProvider)
                .build(),
        )
    }
}
