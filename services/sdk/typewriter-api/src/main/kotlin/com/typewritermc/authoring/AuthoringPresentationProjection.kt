package com.typewritermc.authoring

import com.typewritermc.types.ResourceId

data class AuthoringPresentationSubject(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val content: DraftBinding,
    val descriptor: ResourceTypeDescriptor,
)

fun AuthoringPresentationSubject.toPresentationSubject(): PresentationSubject = PresentationSubject(resource, content, descriptor)

fun interface AuthoringPresentationProjection {
    fun project(subject: AuthoringPresentationSubject): PresentationSubject
}
