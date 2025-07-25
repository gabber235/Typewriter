package com.typewritermc.example.entries.static

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.AssetManager
import com.typewritermc.engine.paper.entry.entries.AssetEntry
import org.koin.java.KoinJavaComponent

//<code-block:asset_entry>
@Entry("example_asset", "An example asset entry.", Colors.BLUE, "material-symbols:home-storage-rounded")
class ExampleAssetEntry(
    override val id: String = "",
    override val name: String = "",
    override val path: String = "",
) : AssetEntry
//</code-block:asset_entry>

//<code-block:asset_access>
suspend fun accessAssetData(ref: Ref<out AssetEntry>) {
    val assetManager = KoinJavaComponent.get<AssetManager>(AssetManager::class.java)
    val entry = ref.get() ?: return
    val content: String? = assetManager.fetchStringAsset(entry)
    // Do something with the content
}
//</code-block:asset_access>