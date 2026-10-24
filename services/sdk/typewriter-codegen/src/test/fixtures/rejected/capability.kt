package fixture

import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmCommandOutcome
import com.typewritermc.capability.RealmSearch

class NotCapabilities {
    @RealmCapability.Computation
    suspend fun orphan(request: String): String = request // error: Realm capability functions must belong to a RealmCapabilities class.
}

@RealmCapabilities
class FixtureCapabilities {
    @RealmCapability.Computation
    suspend fun twoInputs(first: String, second: String): String = first // error: Realm capability functions require one value parameter.

    @RealmCapability.Computation
    @RealmCapability.Command
    suspend fun twoKinds(request: String): RealmCommandOutcome = TODO() // error: Realm capability functions require one capability annotation.

    @RealmCapability.Computation
    fun blocking(request: String): String = request // error: Realm computation capabilities must be suspend functions.

    @RealmCapability.Command
    suspend fun wrongOutcome(request: String): String = request // error: Realm command capabilities must be suspend functions returning RealmCommandOutcome.

    @RealmCapability.Search
    fun wrongRequest(request: String): RealmSearch<String> = TODO() // error: Realm capability type must be com.typewritermc.capability.RealmSearchRequest with one concrete argument.

    @RealmCapability.Computation
    private suspend fun hidden(request: String): String = request // error: Realm capability functions and owners must be visible.

    @RealmCapability.Computation
    suspend fun starRequest(request: List<*>): String = "" // error: Star projections are not authorable.

    @RealmCapability.Computation
    suspend fun <T> genericRequest(request: T): String = "" // error: A free type parameter has no declaration owner.
}
