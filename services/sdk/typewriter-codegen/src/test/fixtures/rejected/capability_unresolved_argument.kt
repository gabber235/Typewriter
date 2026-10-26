package fixture

import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmSearch
import com.typewritermc.capability.RealmSearchRequest

@RealmCapabilities
class UnresolvedArgumentCapabilities {
    @RealmCapability.Search
    suspend fun anything(request: RealmSearchRequest<*>): RealmSearch<String> = TODO() // error: Realm capability type arguments must resolve.
}
