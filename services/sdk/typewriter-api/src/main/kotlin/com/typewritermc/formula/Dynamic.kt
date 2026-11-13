package com.typewritermc.formula

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.FieldPath
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.checking.DraftType
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.types.catalog.BindKey
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Says what content means: which names the formulas of a resource can see, what others get when they name it, and
 * which type parameters its content computes. Registration runs once when the extension loads, on the realm and on
 * every engine; only the registered blocks read content. Hooks register per draft type, as realm checks do, so a hook
 * on a parent contract also runs for its subtypes in other artifacts. A provider object carries
 * `@TypewriterDynamicProvider`, and codegen emits its adapter.
 */
interface DynamicProvider {
    fun Dynamics.register()
}

@TypewriterDsl
interface Dynamics {
    /** A hook for every resource that [type] matches, reading it through its draft. */
    fun <D> each(
        type: DraftType<D>,
        dynamic: DynamicBuilder.(D) -> Unit,
    )

    /**
     * A hook for every resource of [definition], whatever its type arguments, such as any `Definition<T>`. It matches
     * by definition alone, as a draft type's match does, so it reads no type argument.
     */
    fun each(
        definition: TypeDefinitionId,
        dynamic: DynamicBuilder.(ResourceId) -> Unit,
    )

    /**
     * Computes [parameter] from the content of each resource of exactly its type, read through the draft the handle
     * carries. Registering it makes the parameter computed, so a creator never chooses it; a parameter without a bind
     * stays creator chosen. Only the artifact that declares the type may bind it.
     */
    fun <D> bind(
        parameter: BindParameter<D>,
        bind: BindBuilder.(D) -> Unit,
    )
}

/**
 * A type parameter of a resource type that a bind may compute, with the draft its bind block reads. Codegen emits one
 * per type parameter in `XBind`. The draft reads every field whose type holds a type parameter as unavailable, so a bind
 * computes from concrete content alone.
 */
class BindParameter<D>
    @GeneratedSdkApi
    constructor(
        val key: BindKey,
        internal val draft: DraftType<D>,
    )

/** The record type one bind block computes for one resource. It reads authored content through its own receiver. */
@TypewriterDsl
interface BindBuilder : AuthoredReads {
    /** A field [name] of the computed record holding [type]; [hasDefault] lets a value leave it out. */
    fun field(
        name: String,
        type: TypeUse,
        hasDefault: Boolean = false,
    )
}

/** What one hook says about one resource. It reads authored content through its own receiver. */
@TypewriterDsl
interface DynamicBuilder : AuthoredReads {
    /** What the formulas of one own field can see. It wins over every container's contents. */
    fun scope(
        field: FieldPath,
        block: ScopeBuilder.() -> Unit,
    )

    /** What the formulas of this resource's contents can see. */
    fun scopeContents(block: ScopeBuilder.() -> Unit)

    /** What others get when they name this resource. Without exports, naming it gives a reference to it. */
    fun exports(block: ExportBuilder.() -> Unit)
}

/** One level of names. Two resources under one name on one level are an ambiguity where a formula uses that name. */
@TypewriterDsl
interface ScopeBuilder : AuthoredReads {
    /** [name] means the resource [id], so a formula naming it can hold a reference to it. */
    fun resource(
        name: String,
        id: ResourceId,
    )
}

@TypewriterDsl
interface ExportBuilder {
    /** Naming this resource gives the value of [field]; a field holding a `Var<T, _>` reads as its `T`. */
    fun value(field: FieldPath)
}

/** The provider codegen emits for one `@TypewriterDynamicProvider` object. */
interface GeneratedDynamicProvider : DynamicProvider
