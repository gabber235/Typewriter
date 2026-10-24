package com.typewritermc.authoring

import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract

/**
 * A resource published as its own compiled shard together with everything it owns.
 *
 * Realm compiles every complete compilation unit with its ownership closure into the resource graph format, so
 * implementing this contract is the whole declaration an extension needs to publish its own resource type.
 */
@TypewriterRecordContract
interface CompilationUnit : Resource
